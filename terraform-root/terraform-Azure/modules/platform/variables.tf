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

variable "db_subnet_id" {
  type = string
}

# variable "db_username" {
#   type        = string
#   description = "Azure MySQL administrator username"
# }

# variable "db_password" {
#   type        = string
#   sensitive   = true
#   description = "Azure MySQL administrator password"
# }
