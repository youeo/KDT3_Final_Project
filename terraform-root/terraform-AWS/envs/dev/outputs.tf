output "vpn_tunnel1_outside_ip" {
  value = module.network.vpn_tunnel1_outside_ip
}

output "vpn_tunnel2_outside_ip" {
  value = module.network.vpn_tunnel2_outside_ip
}

# 2. 보안이 필요한 값은 sensitive = true 유지
output "vpn_tunnel1_preshared_key" {
  value     = module.network.vpn_tunnel1_preshared_key
  sensitive = true
}

output "vpn_tunnel2_preshared_key" {
  value     = module.network.vpn_tunnel2_preshared_key
  sensitive = true
}

output "cluster_name" {
  value     = module.workload.cluster_name
  sensitive = true
}

output "module" {
  value = {
    network  = module.network
    platform = module.platform
    workload = module.workload
  }
  sensitive = true
}
