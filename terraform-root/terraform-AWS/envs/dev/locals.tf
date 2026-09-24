locals {
  org         = "tf-core"
  project     = "test-1"
  environment = "dev"

  namespace = "${local.org}-${local.project}-${local.environment}"
  # 추후 버킷 생성 코드 구현 시 제거함
  bucket_name = "${local.namespace}-tfstate-backup"

  common_tags = {
    Environment = "dev"
    Project     = "Project3-MSA"
    ManagedBy   = "Terraform"
  }

  bastion = {
    instance_type = "t3.micro"
    allowed_cidrs = ["0.0.0.0/0"] # 보안을 위해 실제 사무실/집 IP 대역으로 제한
  }

  # 현재 azure 생성 시 ip 지정 생성됨
  azure_private_dns_resolver = {
    inbound_ips = try(data.terraform_remote_state.azure.outputs.azure_inbound_ips, ["10.0.254.4"])
  }

  azure_vpn = {
    vnet_cidr             = try(data.terraform_remote_state.azure.outputs.azure_vnet_cidr, "10.0.0.0/16")
    vpn_gateway_public_ip = try(data.terraform_remote_state.azure.outputs.azure_vpn_gw_pip, "20.249.153.151")
  }

  # assumed-role ARN을 정규 IAM Role ARN으로 변환하는 로컬 변수
  # sts:AssumedRole  → arn:aws:iam::<acct>:role/<role-name>
  account_id = data.aws_caller_identity.current.account_id
  caller_arn = data.aws_caller_identity.current.arn

  # assumed-role ARN 정규화 (예: arn:aws:sts::XXXX:assumed-role/MyRole/session)
  is_assumed_role = can(regex("assumed-role", local.caller_arn))
  normalized_arn = local.is_assumed_role ? (
    "arn:aws:iam::${local.account_id}:role/${regex("assumed-role/([^/]+)/", local.caller_arn)[0]}"
  ) : local.caller_arn


  # aws-auth에 등록할 추가 IAM 엔트리 (변수 + 현재 호출자 자동 포함)
  all_admin_arns = distinct(concat(
    var.additional_admin_arns,
    [local.normalized_arn]
  ))

  # ap-northeast-2 Region Healthcheck 관련
  aws_health_to_slack_name      = "aws-health-to-slack-seoul-health-to-slack"
  aws_health_to_slack_rule_name = "aws-health-to-slack-seoul-aws-health"
  aws_health_to_slack_role_name = "aws-health-to-slack-seoul-HealthToSlackFunctionRole-U5SBpUx5eXwf"
  aws_health_to_slack_log_group = "/aws/lambda/aws-health-to-slack-seoul-health-to-slack"

  target_username   = try(data.terraform_remote_state.azure.outputs.target_username, "petclinicadmin")
  target_password   = try(data.terraform_remote_state.azure.outputs.target_password, "data1234!")
  target_db_address = try(data.terraform_remote_state.azure.outputs.target_db_address, "10.0.201.4")
}