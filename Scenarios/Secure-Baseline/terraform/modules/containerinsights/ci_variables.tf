variable "location" {
  type = string
}

variable "spoke_rg_name" {
  type = string
  default = "hub-aro"
}

variable "workspace_resource_id" {
  type = string
}

variable "workspace_name" {
  type = string
}