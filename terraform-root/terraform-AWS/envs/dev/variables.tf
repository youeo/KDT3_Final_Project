variable "additional_admin_arns" {
  description = <<-EOT
    aws-auth ConfigMap에 system:masters로 추가할 IAM Role/User ARN 목록.
    terraform apply 실행 계정(임시 ARN 포함)은 자동으로 추가되므로
    추가 팀원 Role ARN만 여기에 지정하면 됩니다.

    예시:
      additional_admin_arns = [
        "arn:aws:iam::123456789012:role/DevOpsAdminRole",
        "arn:aws:iam::123456789012:role/CICDRole",
      ]
  EOT
  type        = list(string)
  # default     = []
  default = [
    "",
  ]
}

# variable "target_username" {
#   type = string
# }

# variable "target_password" {
#   type = string
# }

# variable "target_db_address" {
#   type = string
# }

# variable "azure_vnet_cidr" {
#   type = string
# }

# variable "azure_vpn_gw_pip" {
#   type = string
# }

# variable "azure_inbound_ips" {
#   type = string
# }

variable "whatap_license" {
  type        = string
  description = "WhaTap Project License Key"
  default     = "<your-whatap-license-key>"
}


# ap-northeast-2 Region Healthcheck 관련
variable "slack_webhook_url" {
  description = "Slack Incoming Webhook URL for AWS Health events."
  default     = "https://<your-slack-webhook-url>"
  type        = string
  sensitive   = true
}
