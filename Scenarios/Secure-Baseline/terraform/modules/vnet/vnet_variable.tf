# General

variable "subscription_id" {
  description = "The subscription ID"
  type        = string
}

variable "hub_resource_group_name" {
  type = string
}

variable "spoke_resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

# Hub Network

variable "hub_name" {
  type = string
}


variable "hub_prefix" {
  type = list
  default = ["10.0.0.0/16"]
}

variable "fw_subnet_prefix" {
  type = list
  default = ["10.0.0.0/26"]
}

variable "bastion_subnet_prefix" {
  type = list
  default = ["10.0.0.64/26"]
}

variable "vm_subnet_name" {
  type = string
  default = "VM-Subnet"
}

variable "vm_subnet_prefix" {
  type = list
  default = ["10.0.1.0/24"]
}

# Spoke Network

variable "spoke_name" {
  type = string
}

variable "spoke_prefix" {
  type = list
  default = ["10.1.0.0/16"]
}

variable "master_aro_name" {
  type = string
  default = "master-aro-subnet"
}

variable "master_aro_subnet_prefix" {
  type = list
  default = ["10.1.0.0/23"]
}

variable "worker_aro_name" {
  type = string
  default = "worker-aro-subnet"
}

variable "worker_aro_subnet_prefix" {
  type = list
  default = ["10.1.2.0/23"]
}

variable "private_endpoint_subnet_name" {
  type = string
  default = "PrivateEndpoint-subnet"
}

variable "private_endpoint_subnet_prefix" {
  type = list
  default = ["10.1.6.0/25"]
}

variable "private_runner_name" {
  type= string
  default = "PrivateRunner-subnet"
}

variable "private_runner_subnet_prefix" {
  type = list
  default = ["10.1.4.0/24"]
}

variable "app_gw_subnet" {
  type = string
  default = "AppGW-subnet"
}

variable "app_gw_subnet_prefix" {
  type = list
  default = ["10.1.5.0/27"]
}

# Azure Firewall
variable "fw_name" {
  type = string
  default = "azfw"
}

# Monitoring

data "azuread_service_principal" "aro_resource_provisioner" {
    display_name            = "Azure Red Hat OpenShift RP"
}