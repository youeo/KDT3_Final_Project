# data "aws_iam_policy_document" "ec2_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     effect  = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }

# data "aws_iam_policy" "aws_ssm_core_policy" {
#   name = "AmazonSSMManagedInstanceCore"
# }

# 신뢰 관계(Trust Relationship) 정의
data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["dms.amazonaws.com"]
    }
  }
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "<YOUR_SECRET_ARN>" # 실제 시크릿 ARN으로 교체
}


data "aws_route53_zone" "ajean" {
  name         = "<YOUR_DOMAIN_NAME>."
  private_zone = false # 퍼블릭 DNS이므로 false
}