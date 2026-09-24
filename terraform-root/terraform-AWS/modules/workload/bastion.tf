# IAM 역할
resource "aws_iam_role" "bastion_role" {
  name = "${local.namespace}-bastion-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.namespace}-bastion-ssm-role" }
}

# Bastion EC2가 SSM을 사용할 수 있도록 권한 연결
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Bastion EC2가 ECR을 사용할 수 있도록 권한 연결
resource "aws_iam_role_policy_attachment" "bastion_ecr_push" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# Bastion에서 kubectl 사용을 위한 EKS 조회 권한
resource "aws_iam_role_policy" "bastion_eks" {
  name = "${local.namespace}-bastion-eks-policy"
  role = aws_iam_role.bastion_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:AccessKubernetesApi"
      ]
      Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sts:GetCallerIdentity"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:StartSession",
          "ssm:SendCommand",
          "ssm:TerminateSession"
        ]
        Resource = [
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ssm:*:*:document/AWS-StartSSMSession"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# 테라폼 내부에서 RSA 알고리즘으로 프라이빗 키 생성 (WSL에서 안 만들어도 됨)
resource "tls_private_key" "mgmt_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 위에서 만든 키를 AWS Key Pair 리소스로 등록
resource "aws_key_pair" "mgmt_key_pair" {
  key_name   = "${local.namespace}-mgmt-key"
  public_key = tls_private_key.mgmt_key.public_key_openssh
}

# 내 컴퓨터(WSL)에 프라이빗 키 파일(.pem)로 내보내기
# 로컬 디렉터리에 자동으로 키 파일이 생성
resource "local_file" "ssh_key" {
  filename        = "${abspath(path.root)}/${local.namespace}-mgmt-key.pem"
  content         = tls_private_key.mgmt_key.private_key_pem
  file_permission = "0400" # 보안을 위해 읽기 권한만 부여
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${local.namespace}-bastion-profile"
  role = aws_iam_role.bastion_role.name
}

# 보안 그룹
resource "aws_security_group" "bastion_sg" {
  name   = "${local.namespace}-bastion-sg"
  vpc_id = local.vpc_id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.bastion_allowed_cidrs
    description = "SSH inbound from allowed IPs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound (kubectl, yum, etc.)"
  }

  tags = { Name = "${local.namespace}-bastion-sg" }
}

# EC2 인스턴스
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = local.instance_type
  subnet_id              = local.public_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  key_name = aws_key_pair.mgmt_key_pair.key_name

  root_block_device {
    volume_size = 50
    volume_type = "gp3" # 최신 실무 표준
    encrypted   = true  # 보안 권장 사항
  }

  # SSM Agent는 AL2023에 기본 설치됨
  # kubectl + helm + git + mariadb, maven, docker 추가 설치
  user_data = <<-EOF
    #!/bin/bash
    set -e
    dnf update -y

    # SSM 에이전트 설치
    sudo dnf install -y amazon-ssm-agent
    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent

    # kubectl 설치
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl && mv kubectl /usr/local/bin/

    # Helm 설치
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # git, jq
    sudo dnf install -y git jq awscli

    # MariaDB 클라이언트 설치 (RDS 접속용)
    sudo dnf install -y mariadb105
    
    # Maven이 java 기반이라 먼저 설치
    sudo dnf install java-17-amazon-corretto-devel -y

    # Maven 설치
    sudo dnf install maven -y

    # Docker 설치 (터미널 on/off에 상관 없이 활성화)
    sudo dnf install docker -y
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user

    # kubeconfig 자동 생성
    # 클러스터 이름을 변수로 지정 (실제 클러스터 이름으로 수정 필요)
    CLUSTER_NAME="${aws_eks_cluster.main.name}"
    REGION="ap-northeast-2"

    # ec2-user로 명령 수행을 위해 sudo -u 사용
    sudo -u ec2-user aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

    echo "Bastion 초기화 완료" >> /var/log/bastion-init.log
  EOF

  metadata_options {
    http_tokens   = "required" # IMDSv2 강제 (보안)
    http_endpoint = "enabled"
  }

  tags = {
    Name = "${local.namespace}-bastion-host"
    Role = "bastion"
  }
}
