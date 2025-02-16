variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "bastion_name" {
  type = string
  default = "bastion-hub"
}

variable "bastion_subnet_id" {
  type = string
}

variable "vm_subnet_id" {
  type = string
}

variable "jumpbox_name" {
  type = string
  default = "jumpbox"
}

variable "jumpbox2_name" {
  type = string
  default = "Windowsbox"
}

variable "jumpbox_size" {
  type = string
  default = "Standard_D2s_v3"
}

variable "kv_id" {
  type = string
}

variable "vm_admin_username" {
  type = string
}
