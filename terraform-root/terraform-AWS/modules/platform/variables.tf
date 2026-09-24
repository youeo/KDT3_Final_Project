variable "namespace" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "node_security_group_id" {
  type = string
}

variable "bastion_security_group_id" {
  type = string
}

variable "azure_ip_cidr_block" {
  type = string
}

variable "private_subnets_dms" {
  type = list(string)
}

variable "target_username" {
  type = string
}

variable "target_password" {
  type = string
}

variable "target_db_address" {
  type = string
}

variable "ingress_dns_name" {
  type = string
}