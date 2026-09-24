module "network" {
  source = "../../modules/network"

  namespace = local.namespace
  location  = local.location

  aws_vpc_cidr = local.aws_vpc_cidr

  tunnel1_ip  = var.vpn_tunnel1_outside_ip
  tunnel2_ip  = var.vpn_tunnel2_outside_ip
  tunnel1_key = var.vpn_tunnel1_preshared_key
  tunnel2_key = var.vpn_tunnel2_preshared_key
}

module "platform" {
  source = "../../modules/platform"

  namespace           = local.namespace
  location            = local.location
  resource_group_name = module.network.resource_group_name
  vnet_id             = module.network.vnet["main"].id
  db_subnet_id        = module.network.subnet["db"].id
}

module "workload" {
  source = "../../modules/workload"

  depends_on = [module.platform]

  namespace           = local.namespace
  location            = local.location
  resource_group_name = module.network.resource_group_name
  vnet_id             = module.network.vnet["main"].id
  public_subnet_id    = module.network.subnet["public-a"].id
  private_subnet_ids = [
    module.network.subnet["private-a"].id,
    module.network.subnet["private-c"].id
  ]
  bastion_allowed_cidrs = var.bastion_allowed_cidrs
}
