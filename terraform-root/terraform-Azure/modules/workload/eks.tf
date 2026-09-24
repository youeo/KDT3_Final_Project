resource "azurerm_kubernetes_cluster" "main" {
  name                = local.cluster_name
  location            = local.location
  resource_group_name = local.resource_group_name
  dns_prefix          = replace(local.cluster_name, "_", "-")

  private_cluster_enabled = false

  default_node_pool {
    name = "system"
    # vm_size              = "Standard_D2s_v3"
    vm_size              = "Standard_B2s_v2"
    vnet_subnet_id       = var.private_subnet_ids[0]
    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 4

    # 삭제중 임시 풀 생성
    temporary_name_for_rotation = "tempnodepool"

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }

  tags = merge(local.common_tags, {
    Name = local.cluster_name
  })

  lifecycle {
    precondition {
      condition     = !startswith(local.namespace, "tf-core-ej-")
      error_message = "Refusing to create legacy tf-core-ej AKS or AKS-managed MC_* resource groups from this Terraform stack."
    }
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  # 타겟 범위: 위의 data 소스에서 알아낸 ACR의 순수 고유 ID를 지정
  scope = data.azurerm_container_registry.target_acr.id

  # 역할 이름: 이미지 Pull 권한
  role_definition_name = "AcrPull"

  # 주체자 ID: AKS의 kubelet identity ID 연결
  principal_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id

  skip_service_principal_aad_check = true
}