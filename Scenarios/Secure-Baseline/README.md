# ARO Secure Baseline

A deployment of ARO-hosted workloads typically requires a separation of duties and lifecycle management in different areas, such as prerequisites, the host network, the cluster infrastructure, the shared services and finally the workload itself. This reference implementation is no different. Also, be aware that our primary purpose is to illustrate the topology and decisions involved in the deployment of an ARO cluster. We feel a "step-by-step" flow will help you learn the pieces of the solution and will give you insight into the relationship between them. Ultimately, lifecycle/SDLC management of your cluster and its dependencies will depend on your situation (organizational structures, standards, processes and tools), and will be implemented as appropriate for your needs.

There are various ways to secure your ARO cluster. From a network security perspective, these can be classified into securing the control plane and securing the workload.

By the end of this, you would have deployed a secure ARO cluster, compliant with ARO landing zone accelerator guidance and best practices. We will also be deploying a workload known as the Ratings app that is also featured in the [Azure Kubernetes Services Workshop](https://docs.microsoft.com/en-us/learn/modules/aks-workshop/). Check out the workshop for some intermediate level training on AKS.

For this scenario, we have various IaC technology as well as the Azure CLI option that you can choose from depending on your preference. At this time only the Terraform version is available in IaC.

## Deployment

The deployment of this solution can be done individually through various means. Walking through the Azure CLI option will ensure that your ARO environment is not only configured but you control every aspect of the deployment. Alternatively, you can deploy the server environment using other methods. The options available are deployed below:

* [Terraform](./terraform/README.md) (Under Development but can still be used)
* [Azure CLI](./Azure-CLI/README.md)

Below is the architecture of this scenario:
![Architectural diagram for the secure baseline scenario.](../../media/aro_landing_zone_Architecture.png)

The architecture is very similar to the [AKS secure baseline private cluster](https://github.com/Azure/AKS-Landing-Zone-Accelerator/tree/main/Scenarios/AKS-Secure-Baseline-PrivateCluster) architecture with minor tweaks to optimize it for ARO. The main differences are as follows:
1. The use of Front door as opposed to application gateway to take advantage of more of the ARO features such as its ingress controller
1. The use for Azure ARC for Kubernetes in order to take advantage of native monitoring of the cluster
1. The use of CosmosDB as opposed to using a database pod

For more information about the architecture, please check out the [ARO Landing Zone Accelerator documentation](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/azure-red-hat-openshift/landing-zone-accelerator) on Microsoft Docs.

## Next Steps to implement ARO Landing Zone Accelerator

Pick one of these options below

:arrow_forward: [Azure CLI](./Azure-CLI/README.md)

:arrow_forward: [Terraform](./terraform/README.md)
