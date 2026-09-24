variable "bastion_allowed_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH to the Azure bastion VM"
  default     = []
}

variable "vpn_tunnel1_outside_ip" {
  type = string
}

variable "vpn_tunnel2_outside_ip" {
  type = string
}

variable "vpn_tunnel1_preshared_key" {
  type = string
}

variable "vpn_tunnel2_preshared_key" {
  type = string
}