module "network" {
  source = "../../modules/network"

  namespace = local.namespace

  azure_vpn_gateway_public_ip            = local.azure_vpn.vpn_gateway_public_ip
  azure_ip_cidr_block                    = local.azure_vpn.vnet_cidr
  azure_private_dns_resolver_inbound_ips = local.azure_private_dns_resolver.inbound_ips
}

module "platform" {
  source = "../../modules/platform"

  providers = {
    aws.default   = aws
    aws.us_east_1 = aws.us_east_1
  }

  namespace      = local.namespace
  s3_bucket_name = local.bucket_name

  vpc_id = module.network.vpc["main"].id

  private_subnet_ids = [
    module.network.subnet["private-a-db"].id,
    module.network.subnet["private-c-db"].id
  ]
  node_security_group_id    = module.workload.node_security_group_id
  bastion_security_group_id = module.workload.bastion_security_group_id

  azure_ip_cidr_block = local.azure_vpn.vnet_cidr
  private_subnets_dms = [
    module.network.subnet["private-a-dms"].id,
    module.network.subnet["private-c-dms"].id
  ]

  target_username   = local.target_username
  target_password   = local.target_password
  target_db_address = local.target_db_address

  ingress_dns_name = module.workload.ingress_dns_name
}

module "workload" {
  source = "../../modules/workload"

  namespace = local.namespace

  vpc_id     = module.network.vpc["main"].id
  account_id = local.account_id

  private_subnet_ids = [
    module.network.subnet["private-a"].id,
    module.network.subnet["private-c"].id
  ]
  public_subnet_ids_lb = [
    module.network.subnet["public-a"].id,
    module.network.subnet["public-c"].id
  ]
  public_subnet_id      = module.network.subnet["public-a"].id
  instance_type         = local.bastion.instance_type
  bastion_allowed_cidrs = local.bastion.allowed_cidrs
  all_admin_arns        = local.all_admin_arns
}
