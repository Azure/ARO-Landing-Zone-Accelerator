## Security for the ARO landing zone accelerator

This article provides design considerations and recommendations for security when using the ARO landing zone accelerator.

## Design considerations

ARO has several interfaces to other Azure services like Azure Active Directory, Azure Container Registry, Azure Storage, and Azure Virtual Network which requires special attention during the planning phase. ARO also adds extra complexity that requires you to consider applying the same security governance and compliance mechanisms and controls as in the rest of your infrastructure landscape.

Here are some other design considerations for ARO security governance and compliance:

- If you create an ARO cluster in a subscription deployed according to Azure landing zone best practices, get familiar with the Azure policies that will be inherited by the clusters, as described in [Policies included in Azure landing zones reference implementations](https://github.com/Azure/Enterprise-Scale/blob/main/docs/ESLZ-Policies.md).
- Decide whether the cluster's control plane should be accessible via the internet (in which case IP restrictions are recommended), which is the default, or only from within your private network in Azure or on-premises as a private cluster. Note that, as described in [Policies included in Azure landing zones reference implementations](https://github.com/Azure/Enterprise-Scale/blob/main/docs/ESLZ-Policies.md), if your organization is following Azure landing zone best practices, the `Corp` management group will have an Azure Policy associated that forces clusters to be private.
- Decide whether your container registry is accessible via the internet, or only within a specific virtual network. Disabling internet access in a container registry can have negative effects on other systems that rely on public connectivity to access it, such as continuous integration pipelines or Microsoft Defender for image scanning. For more information, see [Connect privately to a container registry using Azure Private Link](/azure/container-registry/container-registry-private-link).
- Decide whether your private container registry will be shared across multiple landing zones or if you'll deploy a dedicated container registry to each landing zone subscription.
- Consider using a security solution like [Microsoft Defender for Containers](/azure/defender-for-cloud/defender-for-containers-introduction) for threat detection, once ARO cluster is [Connected to Arc-enabled Kubernetes](/azure/azure-arc/kubernetes/quickstart-connect-cluster).
- Consider scanning your container images for vulnerabilities.

## Design recommendations

- Limit access to the [ARO cluster configuration](/azure/openshift/configure-azure-ad-cli) file by integrating with Azure AD or your own [identity provider](https://docs.openshift.com/container-platform/4.10/authentication/identity_providers/configuring-ldap-identity-provider.html) and assign appropriate [OpenShift RBAC roles](https://docs.openshift.com/container-platform/4.10/authentication/using-rbac.html) such as cluster-admin or cluster-reader, etc.
- [Secure pod access to resources](/azure/aks/developer-best-practices-pod-security#secure-pod-access-to-resources). Provide the least number of permissions, and avoid using root or privileged escalation.
- Use [Azure Key Vault provider for Secrets Store CSI Driver](/azure/aks/csi-secrets-store-driver) to protect secrets, certificates, and connection strings. Even though, the doc refers to AKS it works with ARO cluster as well.
- For Azure Red Hat OpenShift 4 clusters, etcd data isn't encrypted by default, but it's recommended to [enable etcd encryption](https://docs.openshift.com/container-platform/4.10/security/encrypting-etcd.html) to provide an additional layer of data security.
- It's recommended to keep the ARO cluster on the latest OpenShift version to avoid potential security or upgrade issues. [ARO only supports two generally available (GA)](/azure/openshift/support-lifecycle#red-hat-openshift-container-platform-version-support-policy) minor versions of Red Hat OpenShift Container Platform. [Upgrade an ARO Cluster](/azure/openshift/howto-upgrade) if the cluster is on N-2 version or older (N being the latest GA minor version that is released).
- Monitor and enforce configuration by using the [Azure Policy Extension](/azure/governance/policy/concepts/policy-for-kubernetes#install-azure-policy-extension-for-azure-arc-enabled-kubernetes) by [connecting ARO cluster to Arc-enabled Kubernetes](/azure/azure-arc/kubernetes/quickstart-connect-cluster).

- Use [Microsoft Defender for Containers](/azure/defender-for-cloud/defender-for-containers-introduction) for securing ARO cluster, containers and applications, by [connecting ARO cluster to Arc-enabled Kubernetes](/azure/azure-arc/kubernetes/quickstart-connect-cluster).

- Deploy a dedicated and private instance of [Azure Container Registry](/azure/container-registry/) to each landing zone subscription.
- Use [Private Link for Azure Container Registry](/azure/container-registry/container-registry-private-link) to connect it to ARO.
- Scan your images for vulnerabilities with [Microsoft Defender for container registries](/azure/security-center/defender-for-container-registries-introduction), or any other image scanning solution.

> [!IMPORTANT]
> Microsoft Defender for Cloud image scanning is not compatible with Container Registry endpoints. For more information, see [Connect privately to a container registry using Private Link](/azure/container-registry/container-registry-private-link).
