output "console_url" {
  value = module.aro.console_url
}

output "api_server_ip" {
  value = module.aro.api_server_ip
}

output "ingress_ip" {
  value = module.aro.ingress_ip
}

output "AFD_endpoint_FQDN" {
  value = module.frontdoor.AFD_endpoint
}

output "vm_admin_username" {
  value = var.vm_admin_username
}

output "vm_admin_password" {
  value = module.kv.vm_admin_password
  sensitive = true    
  }

output "kv_hub_name" {
  value = module.kv.kv_hub_name
}