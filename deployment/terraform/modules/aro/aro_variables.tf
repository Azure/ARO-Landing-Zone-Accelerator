data "azuread_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "spoke" {
  name = var.spoke_rg_name
}

variable "base_name" {
  type = string
  default = "aro"
}

variable "spoke_rg_name" {
  type = string
  default = "spoke-aro"
}

variable "spoke_vnet_id" {
  type = string
}

variable "hub_vnet_id" {
  type = string
}

variable "master_subnet_id" {
  type = string
}

variable "worker_subnet_id" {
  type = string
}

variable "location" {
  type = string
}

# variable "aro_sp_object_id" {
#   type = string
# }

# variable "aro_sp_password" {
#   type = string
#   sensitive = true
# }

# variable "aro_rp_object_id" {
#   type = string
# }

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
