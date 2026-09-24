# 백업용 S3 버킷
# resource "aws_s3_bucket" "terraform_backup" {
#   bucket = "${var.namespace}-tfstate-backup"
#   # s3 내부에 내용 있으면 안 지워지는데 지우고 싶으면 이 옵션 사용
#   # force_destroy = true
# }

# # 버킷 버전 관리 (상태파일 백업/복구용)
# resource "aws_s3_bucket_versioning" "terraform_backup" {
#   bucket = aws_s3_bucket.terraform_backup.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# # 버킷 암호화 (보안)
# resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_backup" {
#   bucket = aws_s3_bucket.terraform_backup.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# # 퍼블릭 접근 차단 (보안)
# resource "aws_s3_bucket_public_access_block" "terraform_backup" {
#   bucket = aws_s3_bucket.terraform_backup.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# # 버킷 로깅 (감사)
# resource "aws_s3_bucket_logging" "terraform_backup" {
#   bucket = aws_s3_bucket.terraform_backup.id

#   target_bucket = aws_s3_bucket.terraform_backup.id
#   target_prefix = "logs/"
# }
