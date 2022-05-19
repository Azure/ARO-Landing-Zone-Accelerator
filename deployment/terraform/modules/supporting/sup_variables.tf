variable "spoke_rg_name" {
  type = string
  default = "spoke-aro"
}

variable "hub_rg_name" {
  type = string
  default = "hub-aro"
}

variable "base_name" {
  type = string
  default = "aroacr"
}

variable "hub_vnet_name" {
  type = string
  default = "hub-aro"
}

variable "spoke_vnet_name" {
  type = string
  default = "spoke-aro"
}

variable "private_endpoint_subnet_name" {
  type = string
  default = "PrivateEndpoint-subnet"
}

resource "random_integer" "ri" {
  min = 10000
  max = 99999

  keepers = {
    rg_id = data.azurerm_resource_group.spoke.id
  }
}