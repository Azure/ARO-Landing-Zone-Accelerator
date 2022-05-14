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