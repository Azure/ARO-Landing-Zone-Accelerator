

output "console_url" {
  value = azurerm_redhat_openshift_cluster.cluster.console_url
}

output "api_server_ip" {
  value = azurerm_redhat_openshift_cluster.cluster.api_server_profile[0].ip_address
}

output "ingress_ip" {
  value = azurerm_redhat_openshift_cluster.cluster.ingress_profile[0].ip_address
}