# IAM Role 생성
resource "aws_iam_role" "dms_vpc_role" {
  name               = "dms-vpc-role"
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
}

# 필요한 정책 연결 (DMS용 기본 정책)
resource "aws_iam_role_policy_attachment" "dms_vpc_role_attach" {
  role       = aws_iam_role.dms_vpc_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

# DMS용 보안 그룹 생성
resource "aws_security_group" "dms_sg" {
  name        = "dms-replication-sg"
  description = "Security group for DMS replication instance"
  vpc_id      = local.vpc_id

  # 소스 DB로 가는 출구 (RDS 보안 그룹 ID를 명시)
  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.db_sg.id]
  }

  # 타겟(Azure)으로 나가는 출구 (VPN 대역 혹은 전체 허용)
  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [local.azure_ip_cidr_block]
  }

  tags = {
    Name = "dms-replication-sg"
  }
}

# DMS 복제 인스턴스용 서브넷 그룹
resource "aws_dms_replication_subnet_group" "dms_subnet_group" {
  replication_subnet_group_id          = "dms-subnet-group"
  replication_subnet_group_description = "DMS subnet group for migration"
  subnet_ids                           = local.private_subnets_dms

  tags = {
    Name = "${local.namespace}-dms-sg"
  }
}

# DMS 복제 인스턴스
resource "aws_dms_replication_instance" "dms_instance" {
  replication_instance_id     = "dms-instance-mysql-to-mysql"
  replication_instance_class  = "dms.t3.medium" # 일단은 제일 작은걸로 구현
  allocated_storage           = 50
  vpc_security_group_ids      = [aws_security_group.dms_sg.id]
  replication_subnet_group_id = aws_dms_replication_subnet_group.dms_subnet_group.id
  publicly_accessible         = false # 프라이빗 환경을 권장함

  tags = {
    Name = "${local.namespace}-dms-ri"
  }
}

# 소스 엔드포인트 (AWS RDS)
resource "aws_dms_endpoint" "source" {
  endpoint_id   = "source-rds-endpoint"
  endpoint_type = "source"
  engine_name   = "mysql"
  username      = aws_db_instance.petclinic_db.username
  password      = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
  server_name   = split(":", aws_db_instance.petclinic_db.endpoint)[0]
  port          = 3306

  depends_on = [
    aws_db_instance.petclinic_db,
    data.aws_secretsmanager_secret_version.db_password
  ]
}

# 타겟 엔드포인트 (Azure MySQL)
resource "aws_dms_endpoint" "target" {
  endpoint_id   = "target-azure-endpoint"
  endpoint_type = "target"
  engine_name   = "mysql"
  username      = local.target_username
  password      = local.target_password
  server_name   = local.target_db_address
  port          = 3306

  # 마이그레이션 이후에는 다시 켜서 정합성 검사 해야함
  extra_connection_attributes = "initstmt=SET FOREIGN_KEY_CHECKS=0"
}

# DMS 마이그레이션 태스크
resource "aws_dms_replication_task" "migration_task" {
  replication_task_id      = "petclinic-migration-task"
  migration_type           = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.dms_instance.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn

  # DMS가 요구하는 정확한 스키마 구조
  table_mappings = jsonencode({
    "rules" = [
      {
        "rule-type" = "selection"
        "rule-id"   = "1"
        "rule-name" = "1"
        "object-locator" = {
          "schema-name" = "petclinic"
          "table-name"  = "%"
        }
        "rule-action" = "include"
      }
    ]
  })

  # 복제 설정
  # DMS가 구조를 건드리지 못하게 설정 (기본키 생성 충돌 오류 방지)
  replication_task_settings = jsonencode({
    "FullLoadSettings" = {
      "TargetTablePrepMode" = "DO_NOTHING"
    },
    "TargetMetadata" = {
      "TargetSchemaMode" = "DoNothing"
      "SupportLobs"      = true
      "FullLobMode"      = true
      "InlineLobMode"    = true
      "ConstraintSettings" = {
        "PrimaryKeyConstraints" = false
        "UniqueConstraints"     = false
        "Indexes"               = false
      }
    },
    "Logging" = {
      "EnableLogging" = true
      "LogComponents" = [
        { "Id" = "SOURCE_UNLOAD", "Severity" = "LOGGER_SEVERITY_DEBUG" },
        { "Id" = "TARGET_LOAD", "Severity" = "LOGGER_SEVERITY_DEBUG" },
        { "Id" = "TRANSFORMATION", "Severity" = "LOGGER_SEVERITY_DEBUG" }
      ]
    }
  })

  tags = {
    Name = "petclinic-migration-task"
  }
}