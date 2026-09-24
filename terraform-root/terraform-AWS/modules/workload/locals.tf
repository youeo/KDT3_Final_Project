locals {
  namespace = var.namespace

  cluster_name = "${local.namespace}-eks"

  account_id = var.account_id

  common_tags = {
    Environment = "dev"
    Project     = "Project3-MSA"
    ManagedBy   = "Terraform"
  }

  # Bastion Role도 동일한 정규화 로직 적용
  # try를 사용하여 값이 없으면 null을 반환하게 함
  bastion_raw_arn = try(aws_iam_role.bastion_role.arn, null)

  is_bastion_assumed = local.bastion_raw_arn != null ? can(regex("assumed-role", local.bastion_raw_arn)) : false
  normalized_bastion_arn = local.bastion_raw_arn != null ? (
    local.is_bastion_assumed ?
    "arn:aws:iam::${local.account_id}:role/${regex("assumed-role/([^/]+)/", local.bastion_raw_arn)[0]}" :
    local.bastion_raw_arn
  ) : null

  vpc_id                = var.vpc_id
  private_subnet_ids    = var.private_subnet_ids
  public_subnet_ids_lb  = var.public_subnet_ids_lb
  public_subnet_id      = var.public_subnet_id
  instance_type         = var.instance_type
  bastion_allowed_cidrs = var.bastion_allowed_cidrs
  admin_arns            = var.all_admin_arns
  admin_arns_map        = { for arn in distinct(local.admin_arns) : arn => arn if arn != null }

  # 배포할 마이크로서비스 목록 정의
  petclinic_services = toset([
    "config-server",
    "discovery-server",
    "api-gateway",
    "admin-server",
    "customers-service",
    "vets-service",
    "visits-service",
    "genai-service"
  ])

  ecr_registry = "<aws_account_id>.dkr.ecr.<region>.amazonaws.com"
}