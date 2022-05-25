## Design considerations

AKS has several interfaces to other Azure services like Azure Active Directory, Azure Storage, and Azure Virtual Network, which requires special attention during the planning phase. AKS also adds extra complexity that requires you to consider applying the same security governance and compliance mechanisms and controls as in the rest of your infrastructure landscape.

Here are some other design considerations for AKS security governance and compliance:

- If you create an AKS cluster in a subscription deployed according to Azure landing zone best practices, get familiar with the Azure policies that will be inherited by the clusters, as described in [Policies included in Azure landing zones reference implementations](https://github.com/Azure/Enterprise-Scale/blob/main/docs/ESLZ-Policies.md).
- Decide whether the cluster's control plane should be accessible via the internet (in which case IP restrictions are recommended), which is the default, or only from within your private network in Azure or on-premises as a private cluster. Note that, as described in [Policies included in Azure landing zones reference implementations](https://github.com/Azure/Enterprise-Scale/blob/main/docs/ESLZ-Policies.md), if your organization is following Azure landing zone best practices, the `Corp` management group will have an Azure Policy associated that forces clusters to be private.
- Evaluate using the built-in [AppArmor](/azure/aks/operator-best-practices-cluster-security#app-armor) Linux security module to limit actions that containers can perform, like read, write, execute, or system functions like mounting file systems. For example, as described in [Policies included in Azure landing zones reference implementations](https://github.com/Azure/Enterprise-Scale/blob/main/docs/ESLZ-Policies.md), all subscriptions will have Azure policies that prevent pods in all AKS clusters from creating privileged containers.
- Evaluate using [`seccomp` (secure computing)](/azure/aks/operator-best-practices-cluster-security#secure-computing) at the process level to limit the process calls that containers can perform. For example, the Azure Policy applied as part of the generic Azure landing zone implementation in the landing zones management group to prevent container privilege escalation to root uses `seccomp` through Azure policies for Kubernetes.
- Decide whether your container registry is accessible via the internet, or only within a specific virtual network. Disabling internet access in a container registry can have negative effects on other systems that rely on public connectivity to access it, such as continuous integration pipelines or Microsoft Defender for image scanning. For more information, see [Connect privately to a container registry using Azure Private Link](/azure/container-registry/container-registry-private-link).
- Decide whether your private container registry will be shared across multiple landing zones or if you'll deploy a dedicated container registry to each landing zone subscription.
- Consider using a security solution like [Microsoft Defender for Kubernetes](/azure/security-center/defender-for-kubernetes-introduction) for threat detection.
- Consider scanning your container images for vulnerabilities.
- Consider disabling Microsoft Defender for servers in the AKS subscription if there are no non-AKS virtual machines, to avoid unnecessary costs.

## Design recommendations

- Limit access to the [Kubernetes cluster configuration](/azure/aks/control-kubeconfig-access) file by using Azure role-based access control.
- [Secure pod access to resources](/azure/aks/developer-best-practices-pod-security#secure-pod-access-to-resources). Provide the least number of permissions, and avoid using root or privileged escalation.
- Use [pod-managed identities](/azure/aks/operator-best-practices-identity#use-pod-managed-identities) and [Azure Key Vault provider for Secrets Store CSI Driver](/azure/aks/csi-secrets-store-driver) to protect secrets, certificates, and connection strings.
- Use [AKS node image upgrade](/azure/aks/node-image-upgrade) to update AKS cluster node images if possible, or [kured](/azure/aks/node-updates-kured) to automate node reboots after applying updates.
- Monitor and enforce configuration by using the [Azure Policy add-on for Kubernetes](/azure/aks/use-azure-policy). In subscriptions deployed according to Azure landing zones best practices, this configuration will happen automatically through an Azure Policy deployed at the management group level.
- View AKS recommendations in [Microsoft Defender for Cloud](/azure/security-center/security-center-introduction).
- Use [Microsoft Defender for Kubernetes](/azure/security-center/defender-for-kubernetes-introduction). Microsoft Defender for Kubernetes is configured automatically in AKS clusters created in subscriptions deployed according to Azure landing zones best practices, which include an Azure Policy to automatically onboard AKS clusters to Microsoft Defender for Cloud at the management group level.
- Deploy a dedicated and private instance of [Azure Container Registry](/azure/container-registry/) to each landing zone subscription.
- Use [Private Link for Azure Container Registry](/azure/container-registry/container-registry-private-link) to connect it to AKS.
- Scan your images for vulnerabilities with [Microsoft Defender for container registries](/azure/security-center/defender-for-container-registries-introduction), or any other image scanning solution.

> [!IMPORTANT]
> Microsoft Defender for Cloud image scanning is not compatible with Container Registry endpoints. For more information, see [Connect privately to a container registry using Private Link](/azure/container-registry/container-registry-private-link).
