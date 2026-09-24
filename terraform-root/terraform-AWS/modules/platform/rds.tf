# 커스텀 파라미터 그룹 생성
# Full Load + CDC인 경우 CDC 과정에서 필요한 작업임
resource "aws_db_parameter_group" "mysql80_custom" {
  name   = "mysql80-custom-params"
  family = "mysql8.4" # RDS 인스턴스 버전과 정확히 일치해야 함

  parameter {
    name  = "binlog_format"
    value = "ROW"
  }
}

resource "aws_db_instance" "petclinic_db" {
  # 서비스별로 DB를 분리하기 위해 고유 이름을 지정
  # 여기서는 예시로 하나를 생성하지만, MSA 서비스별로 이 블록을 복사하거나 
  # for_each를 사용하여 여러 개를 관리할 수 있음
  identifier = "petclinic-db-instance"

  parameter_group_name = aws_db_parameter_group.mysql80_custom.name

  # 사양 설정
  engine            = "mysql"
  engine_version    = "8.4.8"
  instance_class    = "db.t3.micro" # 학습/소규모 운영에 적합
  allocated_storage = 20            # 최소 용량 20GB
  storage_type      = "gp2"

  # 백업 설정
  backup_retention_period = 7             # 7일간 백업 보관
  backup_window           = "03:00-04:00" # 백업 수행 시간

  # 인증 설정 (실무에선 var 변수 사용 필수)
  username = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
  db_name  = "petclinic"

  # 네트워크 및 보안
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true  # 프로젝트 테스트용이면 true, 운영은 false
  publicly_accessible    = false # DB는 외부에서 직접 접근 불가하게!
  # 시크릿 매니저의 자동 비번 생성
  # manage_master_user_password = true

  tags = {
    Name = "${local.namespace}-petclinic-mysql"
  }
}

# RDS가 위치할 서브넷 그룹 (Private 서브넷 권장)
resource "aws_db_subnet_group" "db_subnet" {
  name       = "${local.namespace}-petclinic-db-subnet-group"
  subnet_ids = [local.private_subnet_ids[0], local.private_subnet_ids[1]]
}

# DB 전용 보안 그룹: EKS 클러스터 내의 노드들만 접근 허용
resource "aws_security_group" "db_sg" {
  name   = "${local.namespace}-petclinic-db-sg"
  vpc_id = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.namespace}-petclinic-db-sg" }
}

# EKS 노드 접근 허용 규칙
resource "aws_security_group_rule" "db_ingress_eks" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = local.node_security_group_id
  description              = "Allow EKS nodes to access RDS"
}

# Bastion 접근 허용 규칙
resource "aws_security_group_rule" "db_ingress_bastion" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = local.bastion_security_group_id
  description              = "Allow Bastion to access RDS"
}

# DMS 접근 허용 규칙
resource "aws_security_group_rule" "db_ingress_dms" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = aws_security_group.dms_sg.id
  description              = "Allow DMS to access RDS"
}

# # 시크릿 저장소 정의
# resource "aws_secretsmanager_secret" "db_connection_info" {
#   name = "petclinic/db-connection-info2"
# }

# # RDS 정보와 AWS 관리형 암호를 조합하여 저장
# resource "aws_secretsmanager_secret_version" "db_connection_info_val" {
#   secret_id = aws_secretsmanager_secret.db_connection_info.id
#   secret_string = jsonencode({
#     username = aws_db_instance.petclinic_db.username
#     # AWS가 관리하는 암호의 ARN을 참조합니다
#     password = aws_db_instance.petclinic_db.master_user_secret[0].secret_arn
#     host     = aws_db_instance.petclinic_db.address
#     port     = aws_db_instance.petclinic_db.port
#     dbname   = aws_db_instance.petclinic_db.db_name
#   })
# }
