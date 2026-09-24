variable "namespace" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "account_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids_lb" {
  type = list(string)
}

variable "public_subnet_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "bastion_allowed_cidrs" {
  type = list(string)
}

variable "all_admin_arns" {
  description = "EKS 접근 권한을 추가할 관리자 IAM ARN 리스트"
  type        = list(string)
}