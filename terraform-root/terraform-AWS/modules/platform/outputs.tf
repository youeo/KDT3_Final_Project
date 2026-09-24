output "rds_endpoint" {
  value = aws_db_instance.petclinic_db.endpoint
}

output "rds_address" {
  value = aws_db_instance.petclinic_db.address
}

output "rds_port" {
  value = aws_db_instance.petclinic_db.port
}

output "rds_database_name" {
  value = aws_db_instance.petclinic_db.db_name
}

output "rds_username" {
  value = aws_db_instance.petclinic_db.username
}

output "route53_health_check_id" {
  value = aws_route53_health_check.aws_service.id
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.distribution.id
}