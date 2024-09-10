#!/bin/bash

# Check if both arguments are provided
if [ $# -ne 5 ]; then
    echo "Usage: $0 <SPOKE_RG_NAME> <FRONT_DOOR_FQDN> <SP_APP_ID> <SP_PASSWORD> <TENANT_ID>"
    exit 1
fi

# Set variables from command-line arguments
SPOKE_RG_NAME=$1
FRONT_DOOR_FQDN=$2
SP_APP_ID=$3
SP_PASSWORD=$4
TENANT_ID=$5

echo "Logging in using the service principal..."
az login --service-principal -u $SP_APP_ID -p $SP_PASSWORD --tenant $TENANT_ID

echo "Setting up environment..."
AROCLUSTER=$(az aro list -g $SPOKE_RG_NAME --query "[0].name" -o tsv)
LOCATION=$(az aro show -g $SPOKE_RG_NAME -n $AROCLUSTER --query location -o tsv)
apiServer=$(az aro show -g $SPOKE_RG_NAME -n $AROCLUSTER --query apiserverProfile.url -o tsv)
webConsole=$(az aro show -g $SPOKE_RG_NAME -n $AROCLUSTER --query consoleProfile.url -o tsv)
echo "ARO Cluster: $AROCLUSTER"
echo "Location: $LOCATION"

# Log in to ARO cluster
echo "Logging in to ARO cluster..."
kubeadmin_password=$(az aro list-credentials --name $AROCLUSTER --resource-group $SPOKE_RG_NAME --query kubeadminPassword --output tsv)
oc login $apiServer -u kubeadmin -p $kubeadmin_password

oc new-project contoso
oc adm policy add-scc-to-user anyuid -z default

echo "Creating Deployment..."
cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: contoso-website
  namespace: contoso
spec:
  selector:
    matchLabels:
      app: contoso-website
  template:
    metadata:
      labels:
        app: contoso-website
    spec:
      containers:
      - name: contoso-website
        image: mcr.microsoft.com/mslearn/samples/contoso-website
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi
        ports:
        - containerPort: 80
          name: http
      securityContext:
        runAsUser: 0
        fsGroup: 0
EOF

sleep 10

echo "Creating Service..."
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Service
metadata:
  name: contoso-service
  namespace: contoso
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: http
      name: http
  selector:
    app: contoso-website
  type: ClusterIP
EOF

sleep 10

echo "Creating Ingress..."
cat <<EOF | oc apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: contoso-ingress
  namespace: contoso
spec:
  rules:
    - host: $FRONT_DOOR_FQDN
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: contoso-service
                port:
                  number: 80
EOF

echo "Script completed"