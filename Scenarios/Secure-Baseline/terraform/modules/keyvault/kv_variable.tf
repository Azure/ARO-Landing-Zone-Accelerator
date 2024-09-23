data "azurerm_client_config" "current" {}

variable "kv_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vm_admin_password" {
  type = string
  sensitive = true
}

variable "vm_admin_username" {
  type = string
  sensitive = true
}

variable "tags" {
  type = map(string)
  default = {
    environment = "development"
    owner       = "your@email.address"
  }
}