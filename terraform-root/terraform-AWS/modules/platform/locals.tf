locals {
  namespace = var.namespace

  vpc_id                    = var.vpc_id
  private_subnet_ids        = var.private_subnet_ids
  node_security_group_id    = var.node_security_group_id
  bastion_security_group_id = var.bastion_security_group_id

  azure_ip_cidr_block = var.azure_ip_cidr_block
  private_subnets_dms = var.private_subnets_dms

  target_username   = var.target_username
  target_password   = var.target_password
  target_db_address = var.target_db_address

  ingress_dns_name = var.ingress_dns_name
}