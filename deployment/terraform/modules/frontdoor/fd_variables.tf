variable "location" {
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

variable "aro_name" {
  type = string
  default = "aro"
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
  type    = string
  default = "openshift-cluster-aro"
}

variable "aro_cluster_lb_name" {
  type    = string
  default = "aro-internal-id"
}

variable "aro_cluster_name" {
  type    = string
  default = "aro-cluster"
}
