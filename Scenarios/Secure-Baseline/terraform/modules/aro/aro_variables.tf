data "azuread_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "spoke" {
  name = var.spoke_rg_name
}

variable "base_name" {
  type = string
  default = "aro"
  description = "ARO cluster name"
}

variable "spoke_rg_name" {
  type = string
  default = "spoke-aro"
}

variable "spoke_vnet_id" {
  description = "The ID of the spoke VNet"
  type        = string
}

variable "master_subnet_id" {
  type = string
  description = "master subnet"
}

variable "worker_subnet_id" {
  type = string
  description = "worker subnet"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region"
}

variable "sp_client_id" {
  description = "Service principal client id"
}

variable "sp_client_secret" {
  description = "Service principal secret"
}

variable "aro_rp_object_id" {
  type = string
}

variable "roles" {
  description = "Roles to be assigned to the Principal"
  type        = list(object({ role = string }))
  default = [
    {
      role = "Contributor"
    },
    {
      role = "User Access Administrator"
    }
  ]
}

variable "rh_pull_secret" {
  type        = string
  default     = null
  description = <<EOF
  Pull Secret for the ARO cluster
  Default null
  EOF
}

variable "domain" {
  type        = string
  default = null
  description = "Domain for the cluster."

  validation {
    condition     = var.domain != "" && var.domain != null
    error_message = "Invalid 'domain'. Must be not be empty."
  }
}

variable "tags" {
  type = map(string)
  default = {
    environment = "development"
    owner       = "your@email.address"
  }
}

variable "aro_version" {
  type        = string
  description = <<EOF
  ARO version
  Default "4.15.35"
  EOF
  default     = "4.15.35"
}

variable "main_vm_size" {
  type        = string
  description = "VM size for the main, control plane VMs."
  default     = "Standard_D8s_v3"

  validation {
    condition     = var.main_vm_size != "" && var.main_vm_size != null
    error_message = "Invalid 'main_vm_size'. Must be not be empty."
  }
}

variable "worker_vm_size" {
  type        = string
  description = "VM size for the worker VMs."
  default     = "Standard_D4s_v3"

  validation {
    condition     = var.worker_vm_size != "" && var.worker_vm_size != null
    error_message = "Invalid 'worker_vm_size'. Must be not be empty."
  }
}

variable "worker_disk_size_gb" {
  type        = number
  default     = 128
  description = "Disk size for the worker nodes."

  validation {
    condition     = var.worker_disk_size_gb >= 128
    error_message = "Invalid 'worker_disk_size_gb'. Minimum of 128GB."
  }
}

variable "worker_node_count" {
  type        = number
  default     = 3
  description = "Number of worker nodes."

  validation {
    condition     = var.worker_node_count >= 3
    error_message = "Invalid 'worker_node_count'. Minimum of 3."
  }
}

variable "outbound_type" {
  type        = string
  description = <<EOF
  Outbound Type - Loadbalancer or UserDefinedRouting
  Default "Loadbalancer"
  EOF
  default     = "UserDefinedRouting"

  validation {
    condition     = contains(["Loadbalancer", "UserDefinedRouting"], var.outbound_type)
    error_message = "Invalid 'outbound_type'. Only 'Loadbalancer' or 'UserDefinedRouting' are allowed."
  }
}

variable "acr_private" {
  type        = bool
  default     = true
  description = <<EOF
  Deploy ACR for Private ARO clusters.
  Default "false"
  EOF
}

variable "aro_pod_cidr_block" {
  type        = string
  default     = "10.128.0.0/14"
  description = "cidr range for pods within the cluster network"
}

variable "aro_service_cidr_block" {
  type        = string
  default     = "172.30.0.0/16"
  description = "cidr range for services within the cluster network"
}

variable "restrict_egress_traffic" {
  type        = bool
  default     = false
  description = <<EOF
  Enable the Restrict Egress Traffic for Private ARO clusters.
  Default "false"
  EOF
}

variable "api_server_profile" {
  type        = string
  description = <<EOF
  Api Server Profile Visibility - Public or Private
  Default "Public"
  EOF
  default     = "Private"

  validation {
    condition     = contains(["Public", "Private"], var.api_server_profile)
    error_message = "Invalid 'api_server_profile'. Only 'Public' or 'Private' are allowed."
  }
}

variable "ingress_profile" {
  type        = string
  description = <<EOF
  Ingress Controller Profile Visibility - Public or Private
  Default "Public"
  EOF
  default     = "Private"

  validation {
    condition     = contains(["Public", "Private"], var.ingress_profile)
    error_message = "Invalid 'ingress_profile'. Only 'Public' or 'Private' are allowed."
  }
}