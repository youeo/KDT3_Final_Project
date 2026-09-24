variable "namespace" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "bastion_allowed_cidrs" {
  type = list(string)
}
