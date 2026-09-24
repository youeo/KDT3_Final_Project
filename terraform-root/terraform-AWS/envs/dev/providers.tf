terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.0"
      configuration_aliases = [aws.us_east_1]
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    # ap-northeast-2 Region Healthcheck 관련
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  # [부트스트랩 전략]: 최초 1회는 이 backend 블록을 주석 처리하고 로컬에서 apply 한 뒤,
  # 생성된 S3/DynamoDB 정보 채워 넣고 주석 풀고 init 하시면 원격 마이그레이션이 완료
  backend "s3" {
    bucket       = "tf-core-tfstate-1"
    key          = "dev/test/terraform.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-northeast-2"

  default_tags {
    tags = {
      Organization = local.org
      Project      = local.project
      ManagedBy    = "Terraform"
    }
  }
}

# ACM을 위한 us-east-1 리전
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# 쿠버네티스 프로바이더 정의
# 방금 만든 EKS 클러스터의 주소와 인증서를 실시간으로 바인딩
provider "kubernetes" {
  host                   = module.workload.cluster_endpoint
  cluster_ca_certificate = base64decode(module.workload.cluster_ca)

  # AWS 로그인이 완료된 WSL 환경에서 자격증명을 자동으로 연동하기 위한 설정
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.workload.cluster_name]
  }
}

provider "helm" {
  kubernetes = {
    # kubernetes 프로바이더 설정을 그대로 가져오도록 구성
    host                   = module.workload.cluster_endpoint
    cluster_ca_certificate = base64decode(module.workload.cluster_ca)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.workload.cluster_name]
    }
  }
}

provider "kubectl" {
  host                   = module.workload.cluster_endpoint
  cluster_ca_certificate = base64decode(module.workload.cluster_ca)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.workload.cluster_name]
  }
}
