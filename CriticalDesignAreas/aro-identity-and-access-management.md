---
title: Identity and access management considerations for ARO
description: Describes how to improve identity and access management for the Azure RedHat OpenShift Service.
author: jpocloud
ms.author: johnpoole
ms.date: 06/1/2022
ms.topic: conceptual
ms.service: cloud-adoption-framework
ms.subservice: scenario
ms.custom: think-tank, e2e-aro
---

# Identity and access management considerations for ARO

Your organization or enterprise needs to design suitable security settings to meet their requirements. Identity and access management covers multiple aspects like cluster identities, workload identities, and operator access.

## Design recommendation checklist

### **Cluster identities**
> [!div class="checklist"]
> * Define custom Azure RBAC roles for your ARO landing zone to simplify the management of required permissions for the ARO Cluster Service Principal.

### **Cluster access**
> [!div class="checklist"]
> * Configure [Azure AD integration](https://docs.microsoft.com/en-us/azure/openshift/configure-azure-ad-cli) to use Azure AD for authentication of users to your ARO cluster.
> * Define required RBAC roles and role bindings in Kubernetes.
> * Use Kubernetes role bindings that are tied to Azure AD groups for site reliability engineering (SRE), SecOps, and developer access.
> * Use Kubernetes RBAC with Azure AD to [limit privileges](/azure/aks/azure-ad-rbac) and minimize granting administrator privileges to protect configuration and secrets access.
> * Full access should be granted just in time as needed. Use [Privileged Identity Management in Azure AD](/azure/active-directory/privileged-identity-management/pim-configure) and [identity and access management in Azure landing zones](../../ready/landing-zone/design-area/identity-access.md).

### **Cluster workloads**
> [!div class="checklist"]
> * For applications requiring access to sensitive information, use a Service Principal and [Azure Keyvault Provider for Secret Store CSI Driver](https://azure.github.io/secrets-store-csi-driver-provider-azure/) to mount secrets stored in Azure Keyvault to your pods.
> * Use namespaces for restricting RBAC privilege in Kubernetes.