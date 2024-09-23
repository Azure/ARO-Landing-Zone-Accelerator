# Variables


variable "aro_spn_name" {
  type = string
}

variable "hub_resource_group_name" {
  type = string
}

variable "spoke_resource_group_name" {
  type        = string
  description = "Name of the resource group containing the spoke virtual network"
}

variable "spoke_vnet_id" {
  type        = string
  description = "Name of the resource group containing the spoke virtual network"
}


variable "spoke_name" {
  type = string
}

data "azuread_client_config" "current" {}

data "azurerm_resource_group" "spoke" {
    name = var.spoke_resource_group_name
}

data "azurerm_resource_group" "hub" {
    name = var.hub_resource_group_name
}


data "azurerm_virtual_network" "spoke" {
  name                = var.spoke_name
  resource_group_name = var.spoke_resource_group_name
}

data "azuread_service_principal" "aro_resource_provisioner" {
    display_name            = "Azure Red Hat OpenShift RP"
}