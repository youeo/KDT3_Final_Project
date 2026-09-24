output "cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "cluster_endpoint" {
  value = azurerm_kubernetes_cluster.main.kube_config[0].host
}

output "cluster_ca" {
  value     = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  sensitive = true
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
  sensitive = true
}

output "client_key" {
  value     = azurerm_kubernetes_cluster.main.kube_config[0].client_key
  sensitive = true
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.main.node_resource_group
}

output "bastion_public_ip" {
  value = azurerm_public_ip.bastion.ip_address
}

output "bastion_private_ip" {
  value = azurerm_network_interface.bastion.private_ip_address
}

output "bastion_admin_username" {
  value = local.bastion.admin_username
}

output "bastion_private_key_path" {
  value = local_sensitive_file.bastion_private_key.filename
}
