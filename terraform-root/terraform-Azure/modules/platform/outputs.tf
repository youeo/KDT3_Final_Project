output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "storage_container_name" {
  value = azurerm_storage_container.this.name
}

output "mysql_server_name" {
  value = azurerm_mysql_flexible_server.mysql.name
}

output "mysql_fqdn" {
  value = azurerm_mysql_flexible_server.mysql.fqdn
}

output "mysql_database_name" {
  value = azurerm_mysql_flexible_database.petclinic.name
}

output "mysql_admin_username" {
  value = data.azurerm_key_vault_secret.db_username.value
}

output "mysql_admin_password" {
  value = data.azurerm_key_vault_secret.db_password.value
}
