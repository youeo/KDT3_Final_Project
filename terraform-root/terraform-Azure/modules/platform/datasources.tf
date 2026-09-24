# Key Vault 데이터 소스 선언
data "azurerm_key_vault" "vault" {
  name                = "db-certifi"
  resource_group_name = "ej-terraform-state"
}

# 저장해둔 비밀 가져오기
data "azurerm_key_vault_secret" "db_password" {
  name         = "db-password" # 포탈에서 설정한 Secret 이름
  key_vault_id = data.azurerm_key_vault.vault.id
}
data "azurerm_key_vault_secret" "db_username" {
  name         = "db-username" # 포탈에서 설정한 Secret 이름
  key_vault_id = data.azurerm_key_vault.vault.id
}