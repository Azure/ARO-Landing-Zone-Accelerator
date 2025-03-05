variable "location" {
  type = string
}

variable "ingress_ip" {
  type = string
}

variable "afd_name" {
  type = string
  default = "aroafd"
}

variable "spoke_rg_name" {
  type = string
  default = "spoke-aro"
}

variable "afd_pls_name" {
  type = string
  default = "aro-pls"
}

variable "aro_worker_subnet_id" {
  type = string
}

variable "afd_sku" {
  type = string
  default = "Premium_AzureFrontDoor"
}

variable "la_id" {
  type = string
}

variable "random" {
  type = string
}

variable "aro_resource_group_name" {
  type = string
  default = "openshift-cluster-aro"
}