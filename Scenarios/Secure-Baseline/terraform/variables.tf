# Variables

variable "tenant_id" {
  type        = string
  description = "The Tenant ID for the Azure subscription"
  default     = "yourvalue"
}

variable "subscription_id" {
  type        = string
  description = "The Subscription ID for the Azure subscription"
  default     = "yourvalue"
}

variable "location" {
  type        = string
  default     = "eastasia"
  description = "The Azure region where resources will be deployed"
}

variable "hub_name" {
  type        = string
  default     = "hub-lz-aro"
  description = "The name of the hub"
}

variable "spoke_name" {
  type        = string
  default     = "spoke-lz-aro"
  description = "The name of the spoke"
}

variable "aro_spn_name" {
  type        = string
  default     = "aro-lz-sp"
  description = "The name of the service principal for ARO"
}

resource "random_password" "pw" {
  length      = 16
  special     = true
  min_lower   = 3
  min_special = 2
  min_upper   = 3

  keepers = {
    location = var.location
  }
}

resource "random_string" "user" {
  length  = 16
  special = false

  keepers = {
    location = var.location
  }
}

resource "random_string" "random" {
  length = 6
  special = false
  min_lower = 3
  min_upper = 1

  keepers = {
    location = var.location
  }
}

variable "aro_rp_object_id" {
  type        = string
  default     = "yourvalue"
  description = "The object ID of the ARO resource provider"
}

variable "aro_base_name" {
  type        = string
  default     = "aro-cluster"
  description = "The name of the ARO cluster"
}

variable "aro_domain" {
  type        = string
  default     = "yourvalue"
  description = "The domain name for the ARO cluster - must be unique"
}

variable "rh_pull_secret" {
  type        = string
  default     = null
  description = <<EOF
  Pull Secret for the ARO cluster
  Default null
  Warning - if this variable is updated in the state, the ARO cluster will be redeployed
  EOF
}

variable "vm_admin_username" {
  type        = string
  default     = "arolzadmin"
  description = "The admin username for the Jumpbox VMs"
  
}

variable "azfw_diag_settings_name" {
  type        = string
  default     = "aro-azfw-diag"
  description = "diagnostic name for azure firewall"
  
}