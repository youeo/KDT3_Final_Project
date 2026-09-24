data "azurerm_container_registry" "target_acr" {
  name                = "tfcoreacr01"        # ACR 이름
  resource_group_name = "ej-terraform-state" # ACR이 위치한 리소스 그룹명
}