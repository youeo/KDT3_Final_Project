locals {
  org         = "tf-core"
  project     = "test-1"
  environment = "dev"
  location    = "koreacentral"

  namespace = "${local.org}-${local.project}-${local.environment}"

  aws_vpc_cidr = "172.31.0.0/16"

  vpn = {
    tunnel1_ip  = var.vpn_tunnel1_outside_ip
    tunnel2_ip  = var.vpn_tunnel2_outside_ip
    tunnel1_key = var.vpn_tunnel1_preshared_key
    tunnel2_key = var.vpn_tunnel2_preshared_key
  }
}
