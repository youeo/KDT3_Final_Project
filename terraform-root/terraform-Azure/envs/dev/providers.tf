terraform {
  required_version = ">= 1.14.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "ej-terraform-state" # 상태 파일을 저장할 리소스 그룹
    storage_account_name = "sttfstateej"        # 생성한 스토리지 계정 이름
    container_name       = "tfstate"            # 컨테이너(폴더) 이름
    key                  = "terraform.tfstate"  # 상태 파일 이름
  }
}

provider "azurerm" {
  features {}

  resource_provider_registrations = "core"
}
