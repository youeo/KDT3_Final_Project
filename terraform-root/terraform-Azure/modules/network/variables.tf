variable "namespace" {
  type = string
}

variable "location" {
  type = string
}

variable "aws_vpc_cidr" {
  type        = string
  description = "AWS VPC CIDR reachable through the site-to-site VPN."
}

variable "tunnel1_ip" {
  type = string
}

variable "tunnel2_ip" {
  type = string
}

variable "tunnel1_key" {
  type = string
}

variable "tunnel2_key" {
  type = string
}

