# General

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = object
}

# Hub Network

variable "hub_name" {
  type = string
}

variable "hub_prefix" {
  type = list
}

variable "fw_subnet_prefix" {
  type = list
}

variable "bastion_subnet_prefix" {
  type = string
}

variable "vm_subnet_name" {
  type = string
}

variable "vm_subnet_prefix" {
  type = string
}

# Spoke Network

variable "spoke_name" {
  type = string
}

variable "spoke_prefix" {
  type = list
}

variable "master_aro_name" {
  type = string
}

variable "master_aro_subnet_prefix" {
  type = list
}

variable "worker_aro_name" {
  type = string
}

variable "worker_aro_subnet_prefix" {
  type = list
}

variable "private_endpoint_subnet_name" {
  type = string
}

variable "private_endpoint_subnet_prefix" {
  type = list
}

variable "private_runner_name" {
  type= string
}

variable "private_runner_subnet_prefix" {
  type = string
}

variable "app_gw_subnet" {
  type = string
}

variable "app_gw_subnet_prefix" {
  type = list
}

# Azure Firewall
variable "fw_name" {
  type = string
}