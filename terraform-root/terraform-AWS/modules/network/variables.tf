variable "namespace" {
  type = string
}

variable "azure_vpn_gateway_public_ip" {
  type    = string
  default = ""
}

variable "azure_ip_cidr_block" {
  type    = string
  default = ""
}

variable "azure_private_dns_resolver_inbound_ips" {
  type        = list(string)
  description = "Azure DNS Private Resolver inbound endpoint IPs reached over the AWS-to-Azure VPN."
  default     = []
}
