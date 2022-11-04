# Variables

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "hub_name" {
  type    = string
  default = "hub-aro"
}

variable "spoke_name" {
  type    = string
  default = "spoke-aro"
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

variable "aro_sp_client_id" {
  type = string
}

variable "aro_sp_password" {
  type = string
}

variable "aro_rp_object_id" {
  type = string
}

variable "aro_base_name" {
  type = string
}

variable "aro_domain" {
  type = string
}
