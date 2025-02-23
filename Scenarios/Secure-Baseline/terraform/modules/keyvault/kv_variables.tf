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
