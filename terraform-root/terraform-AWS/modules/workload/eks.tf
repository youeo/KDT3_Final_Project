# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name = "${local.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })

  tags = { Name = "${local.cluster_name}-cluster-role" }
}

# EKS 클러스터용 보안 그룹 (컨트롤 플레인)
resource "aws_security_group" "eks_cluster" {
  name        = "${local.cluster_name}-cluster-sg"
  vpc_id      = var.vpc_id
  description = "EKS Cluster Control Plane SG"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.cluster_name}-cluster-sg" }
}

# 클러스터 규칙 1: Bastion -> EKS API
resource "aws_security_group_rule" "eks_cluster_api_from_bastion" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.bastion_sg.id
  description              = "Allow Bastion to access EKS API"
}

# 클러스터 규칙 2: Nodes -> EKS API
resource "aws_security_group_rule" "eks_cluster_api_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "Allow worker nodes to access EKS API"
}

# 노드용 보안 그룹 (데이터 플레인)
resource "aws_security_group" "eks_nodes" {
  name        = "${local.cluster_name}-node-sg"
  vpc_id      = var.vpc_id
  description = "EKS Node SG"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.cluster_name}-node-sg" }
}

# 노드 규칙 1: 노드 간 통신 (Self)
resource "aws_security_group_rule" "nodes_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_nodes.id
  self              = true
}

# 노드 규칙 2: 컨트롤 플레인 -> 노드
resource "aws_security_group_rule" "nodes_from_cluster" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

# 노드 규칙 3: Bastion -> 노드 (kubectl)
resource "aws_security_group_rule" "nodes_kubectl_from_bastion" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.bastion_sg.id
  description              = "mgmt kubectl access"
}

# 노드 규칙 4: Bastion -> NodePort
resource "aws_security_group_rule" "nodes_nodeport_from_bastion" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.bastion_sg.id
  description              = "mgmt NodePort access"
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# 2. EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = local.private_subnet_ids
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = true # 실무 필수: 내부 보안망 강화
    endpoint_public_access  = true # 개발 편의상 퍼블릭 오픈 (WSL 접속용)
  }

  # API와 ConfigMap 방식을 둘 다 지원하도록 설정
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    # entry 등록 오류 방지 false로 설정
    # admin 권한을 AWS, tf가 둘 다 만드려고 해서 false로 처리, 실제론 true로 하는게 맞음
    bootstrap_cluster_creator_admin_permissions = false
  }

  # 클러스터 로그 활성화
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}

# mgmt role 등 kubectl 접근 허용
resource "aws_eks_access_entry" "admin" {
  cluster_name = aws_eks_cluster.main.name

  for_each      = local.admin_arns_map
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name = aws_eks_cluster.main.name

  for_each      = local.admin_arns_map
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# bastion의 종속성 때문에 따로 관리, bastion이 생성된 후에 EKS 접근 권한 부여
resource "aws_eks_access_entry" "bastion" {
  count         = 1
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = local.normalized_bastion_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "bastion" {
  count         = 1
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = local.normalized_bastion_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# EKS node role
resource "aws_iam_role" "node" {
  name = "${local.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",          # EC2 인스턴스가 출근할 수 있게 함
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",               # 내부 파드에 IP 분배, 통신 가능하게 함
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", # 노드가 ECR에 접근해서 이미지 다운로드할 수 있게 함
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",       # 베스천 없이 파드 접속용 SSM 권한
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ])
  policy_arn = each.value
  role       = aws_iam_role.node.name
}

resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${local.cluster_name}-node-template"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.eks_nodes.id]
  }

  # 매우 중요: EC2 인스턴스가 켜질 때 'Name' 태그를 명시적으로 지정
  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, {
      Name = "${local.cluster_name}-system-node"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "system-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = local.private_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 6
    min_size     = 2
  }

  # m 시리즈가 t 시리즈보다 안정적 (고정 성능이라 에이전트같은 상시 서비스가 안정적임)
  instance_types = ["m5.large"]

  # 템플릿을 노드 그룹에 연결
  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  # 노드 그룹 자체에도 태그를 유지
  tags = merge(local.common_tags, {
    Name                                              = "${local.cluster_name}-node-group"
    "k8s.io/cluster-autoscaler/enabled"               = "true"
    "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
  })

  # 업데이트나 생성 시 순서 보장
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_iam_role_policy_attachment.node_policies]
}

# ALB Ingress Controller용 인라인 정책
resource "aws_iam_role_policy" "node_alb" {
  name = "${local.cluster_name}-node-alb-policy"
  role = aws_iam_role.node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]
        Resource = "*"
      }
    ]
  })
}

# CA용 IAM Role (IRSA 방식)
resource "aws_iam_role" "cluster_autoscaler" {
  name = "${local.cluster_name}-ca-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
        }
      }
    }]
  })
}

# CA 필수 정책
resource "aws_iam_role_policy" "cluster_autoscaler_policy" {
  name = "${local.cluster_name}-ca-policy"
  role = aws_iam_role.cluster_autoscaler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_iam_policy" "external_secrets" {
  name        = "ExternalSecretsPolicy"
  description = "Allow External Secrets to read AWS Secrets Manager"
  policy      = data.aws_iam_policy_document.external_secrets.json
}

# IRSA용 IAM Role 생성
module "iam_assumable_role_external_secrets" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version   = "5.44.0"
  role_name = "external-secrets-role"
  role_policy_arns = {
    policy = aws_iam_policy.external_secrets.arn
  }
  oidc_providers = {
    ex = {
      provider_arn               = aws_iam_openid_connect_provider.eks.arn # EKS 클러스터의 OIDC ARN
      namespace_service_accounts = ["external-secrets:external-secrets-sa"]
    }
  }
}

# AWS Load Balancer Controller (LBC) 추가
# 최신 LBC 공식 IAM 정책 데이터 원격 다운로드
data "http" "lbc_iam_policy_latest" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json"
}

# 2. 다운로드한 JSON 기반으로 전용 IAM Policy 생성
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${local.cluster_name}-lbc-policy"
  path        = "/"
  description = "AWS Load Balancer Controller Policy via Terraform"
  policy      = data.http.lbc_iam_policy_latest.response_body
}

# LBC 전용 IRSA IAM Role 생성 (기존 OpenID Connect Provider 연동)
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${local.cluster_name}-lbc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller",
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

# 생성한 전용 Policy와 Role 결합
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
  role       = aws_iam_role.aws_load_balancer_controller.name
}

# Helm Provider를 통한 LBC 배포 및 Service Account(SA) 자동 생성 제어
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2" # AWS EKS 1.28~1.30 스펙에 가장 안정적인 차트 버전 선점

  values = [
    jsonencode({
      clusterName = aws_eks_cluster.main.name
      vpcId       = local.vpc_id
      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller.arn
        }
      }
    })
  ]

  # 노드 그룹이 준비 완료된 뒤 안전하게 헬름이 내려앉도록 의존성 설정
  depends_on = [
    aws_eks_node_group.system,
    aws_iam_role_policy_attachment.aws_load_balancer_controller_attach
  ]
}