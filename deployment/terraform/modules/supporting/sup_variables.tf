variable "spoke_rg_name" {
  type = string
  default = "spoke-aro"
}

variable "location" {
  type = string
}

variable "base_name" {
  type = string
  default = "aroacr"
}

variable "vnet_name" {
  type = string
  default = "spoke-aro"
}

variable "private_endpoint_subnet_name" {
  type = string
  default = "PrivateEndpoint-subnet"
}