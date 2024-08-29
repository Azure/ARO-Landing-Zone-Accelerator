#!/bin/bash

# Set up environment variables
SPOKERGNAME=$SPOKE_RG_NAME  # resource group where ARO is deployed
AROCLUSTER=$(az aro list -g $SPOKERGNAME --query "[0].name" -o tsv)
LOCATION=$(az aro show -g $SPOKERGNAME -n $AROCLUSTER --query location -o tsv)
apiServer=$(az aro show -g $SPOKERGNAME -n $AROCLUSTER --query apiserverProfile.url -o tsv)
webConsole=$(az aro show -g $SPOKERGNAME -n $AROCLUSTER --query consoleProfile.url -o tsv)
ACR_NAME=$(az acr list -g $SPOKERGNAME --query '[0].name' -o tsv)
KV_NAME=$(az keyvault list -g $SPOKERGNAME --query '[0].name' -o tsv)
ACRPWD=$(az acr credential show -n $ACR_NAME --query 'passwords[0].value' -o tsv)
COSMOSDB_NAME=$(az cosmosdb list -g $SPOKERGNAME --query "[0].name" -o tsv)

echo "Setting up environment..."
echo "ARO Cluster: $AROCLUSTER"
echo "Location: $LOCATION"
echo "ACR Name: $ACR_NAME"
echo "Key Vault Name: $KV_NAME"
echo "CosmosDB Name: $COSMOSDB_NAME"

# Log in to ARO cluster
echo "Logging in to ARO cluster..."
kubeadmin_password=$(az aro list-credentials --name $AROCLUSTER --resource-group $SPOKERGNAME --query kubeadminPassword --output tsv)
oc login $apiServer -u kubeadmin -p $kubeadmin_password

# Install the Kubernetes Secret Store CSI
echo "Installing Kubernetes Secret Store CSI..."
oc new-project k8s-secrets-store-csi

# Set SecurityContextConstraints
oc adm policy add-scc-to-user privileged \
  system:serviceaccount:k8s-secrets-store-csi:secrets-store-csi-driver

# Add and update Helm repositories
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo update

# Install the secrets store csi driver
helm install -n k8s-secrets-store-csi csi-secrets-store \
  secrets-store-csi-driver/secrets-store-csi-driver \
  --version v1.3.2 \
  --set "linux.providersDir=/var/run/secrets-store-csi-providers"

# Check that the Daemonsets is running
echo "Checking CSI driver pods..."
oc -n k8s-secrets-store-csi get pods -l "app=secrets-store-csi-driver"

# Add pod security profile label for CSI Driver
oc label csidriver/secrets-store.csi.k8s.io security.openshift.io/csi-ephemeral-volume-profile=restricted

# Deploy Azure Key Vault CSI
echo "Deploying Azure Key Vault CSI..."
helm repo add csi-secrets-store-provider-azure https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
helm repo update

helm install -n k8s-secrets-store-csi azure-csi-provider \
  csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --set linux.privileged=true --set secrets-store-csi-driver.install=false \
  --set "linux.providersDir=/var/run/secrets-store-csi-providers" \
  --version=v1.4.1

# Set SecurityContextConstraints for Azure provider
oc adm policy add-scc-to-user privileged \
  system:serviceaccount:k8s-secrets-store-csi:csi-secrets-store-provider-azure

# Create namespace for the application
oc new-project ratingsapp

# Create secret for ACR access
echo "Creating secret for ACR access..."
oc create secret docker-registry acr-secret \
    --docker-server=$ACR_NAME.azurecr.io \
    --docker-username=$ACR_NAME \
    --docker-password=$ACRPWD \
    --docker-email=unused \
    -n ratingsapp

# Create a service principal for Key Vault access
echo "Creating service principal for Key Vault access..."
SERVICE_PRINCIPAL_NAME="aro-kv-sp-$(date +%s)"
SERVICE_PRINCIPAL_CLIENT_SECRET="$(az ad sp create-for-rbac --skip-assignment --name $SERVICE_PRINCIPAL_NAME --query 'password' -o tsv)"
SERVICE_PRINCIPAL_CLIENT_ID="$(az ad sp list --display-name $SERVICE_PRINCIPAL_NAME --query [0].'appId' -o tsv)"

# Assign role to the service principal
echo "Assigning role to service principal..."
KV_ID=$(az keyvault show --name $KV_NAME --query id -o tsv)
az role assignment create --assignee $SERVICE_PRINCIPAL_CLIENT_ID --role "Key Vault Secrets User" --scope $KV_ID

# Create Kubernetes secret for Key Vault access
echo "Creating Kubernetes secret for Key Vault access..."
oc create secret generic secrets-store-creds \
    --from-literal clientid=${SERVICE_PRINCIPAL_CLIENT_ID} \
    --from-literal clientsecret=${SERVICE_PRINCIPAL_CLIENT_SECRET} \
    -n ratingsapp
oc label secret secrets-store-creds secrets-store.csi.k8s.io/used=true -n ratingsapp

# Get the Object ID of the current user or service principal
CURRENT_USER_OBJECTID=$(az ad signed-in-user show --query id -o tsv)

# Assign the "Key Vault Secrets Officer" role to the current user or service principal
echo "Assigning Key Vault Secrets Officer role to the current user/service principal..."
az role assignment create --assignee $CURRENT_USER_OBJECTID --role "Key Vault Secrets Officer" --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$SPOKERGNAME/providers/Microsoft.KeyVault/vaults/$KV_NAME"

# Wait for role assignment to propagate
echo "Waiting for role assignment to propagate..."
sleep 60

# Create Key Vault secret for CosmosDB connection string
echo "Creating Key Vault secret for CosmosDB connection string..."
cosmosKey=$(az cosmosdb keys list -n $COSMOSDB_NAME -g $SPOKERGNAME --query "primaryMasterKey" -o tsv)
COSMOSDB_URI_CONNECTIONSTRING="mongodb://$COSMOSDB_NAME:$cosmosKey@$COSMOSDB_NAME.mongo.cosmos.azure.com:10255/ratingsdb?ssl=true&replicaSet=globaldb&retrywrites=false&appName=@$COSMOSDB_NAME@"
az keyvault secret set --vault-name ${KV_NAME} --name 'mongodburi' --value "$COSMOSDB_URI_CONNECTIONSTRING"

# Create SecretProviderClass
echo "Creating SecretProviderClass..."
TENANT_ID=$(az account show --query tenantId -o tsv)

cat <<EOF | oc apply -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: mongo-secret-csi
  namespace: ratingsapp
spec:
  provider: azure
  secretObjects:
    - secretName: mongodburi
      type: Opaque
      data:
      - objectName: MONGODBURI
        key: MONGODBURI
  parameters:
    keyvaultName: "${KV_NAME}"
    usePodIdentity: "false"
    useVMManagedIdentity: "false"
    userAssignedIdentityID: ""
    cloudName: ""
    objects: |
      array:
        - |
          objectName: MONGODBURI
          objectType: secret
          objectVersion: ""
    tenantId: "${TENANT_ID}"
EOF


echo "Azure Key Vault CSI setup complete!"

cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secrets-store-csi-driver-secret-role
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: secrets-store-csi-driver-secret-role-binding
subjects:
- kind: ServiceAccount
  name: secrets-store-csi-driver
  namespace: k8s-secrets-store-csi 
roleRef:
  kind: ClusterRole
  name: secrets-store-csi-driver-secret-role
  apiGroup: rbac.authorization.k8s.io
EOF

echo "Add ClusterRole to read secrets"

cat <<EOF | oc apply -f -
kind: Pod
apiVersion: v1
metadata:
  name: busybox-secrets-store-inline
  namespace: ratingsapp
spec:
  containers:
  - name: busybox
    image: k8s.gcr.io/e2e-test-images/busybox:1.29
    command:
      - "/bin/sleep"
      - "10000"
    volumeMounts:
    - name: secrets-store-inline
      mountPath: "/mnt/secrets-store"
      readOnly: true
    env:
    - name: MONGODB_URI # the application expects to find the MongoDB connection details in this environment variable
      valueFrom:
        secretKeyRef:
          name: mongodburi
          key: MONGODBURI # the name of Secret in KeyVault
  volumes:
    - name: secrets-store-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "mongo-secret-csi"
        nodePublishSecretRef:                       # Only required when using service principal mode
          name: secrets-store-creds                 # Only required when using service principal mode
EOF

# Deploy workload on JumpBox VM for testing
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-api.git
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-web.git
git clone https://github.com/Azure/ARO-Landing-Zone-Accelerator.git

# You should get Login Succeeded
az acr login -n $ACR_NAME

cd mslearn-aks-workshop-ratings-api
# If running from Git Bash terminal skip the sudo word
docker build . -t "$ACR_NAME.azurecr.io/ratings-api:v1"
docker push "$ACR_NAME.azurecr.io/ratings-api:v1"
cd ..

cd mslearn-aks-workshop-ratings-web
# If running from Git Bash terminal skip the sudo word
docker build . -t "$ACR_NAME.azurecr.io/ratings-web:v1"
docker push "$ACR_NAME.azurecr.io/ratings-web:v1"

# Navigate to RatingsApp folder and make necessary changes
cd ..
cd ARO-Landing-Zone-Accelerator/Scenarios/Secure-Baseline/Apps/RatingsApp/

oc adm policy add-scc-to-user privileged \
   system:serviceaccount:ratingsapp:secrets-store-csi-driver

oc adm policy add-scc-to-user privileged \
   system:serviceaccount:ratingsapp:csi-secrets-store-provider-azure

# Fix for this error when describing the replicaset
#   Warning  FailedCreate  25s (x15 over 106s)  replicaset-controller  Error creating: pods "ratings-api-d997c8f74-" is forbidden: unable to validate against any security context constraint: [provider "anyuid": Forbidden: not usable by user or serviceaccount, spec.volumes[0]: Invalid value: "csi": csi volumes are not allowed to be used, provider "nonroot": Forbidden: not usable by user or serviceaccount, provider "hostmount-anyuid": Forbidden: not usable by user or serviceaccount, provider "machine-api-termination-handler": Forbidden: not usable by user or serviceaccount, provider "hostnetwork": Forbidden: not usable by user or serviceaccount, provider "hostaccess": Forbidden: not usable by user or serviceaccount, provider "kube-aad-proxy-scc": Forbidden: not usable by user or serviceaccount, provider "node-exporter": Forbidden: not usable by user or serviceaccount, provider "privileged": Forbidden: not usable by user or serviceaccount, provider "privileged-genevalogging": Forbidden: not usable by user or serviceaccount]
# I have to add a serviceaccount for api deployment and add this privilige
oc adm policy add-scc-to-user privileged \
   system:serviceaccount:ratingsapp:svcrattingsapp

# Deploy ratings service account
oc apply -f 0-ratings-serviceaccount.yaml -n ratingsapp

# Fix for unable to pull image from ACR
# Failed to pull image "aroacr10737.azurecr.io/ratings-api:v1": rpc error: code = Unknown desc = unable to retrieve auth token: invalid username/password: unauthorized: authentication required, visit https://aka.ms/acr/authorization for more information.
oc secrets link svcrattingsapp acr-secret --for=pull,mount -n ratingsapp

# Deploy API
# Change the Azure Container Registry name in the following yaml file before applying
# oc apply -f 1-ratings-api-deployment.yaml -n ratingsapp