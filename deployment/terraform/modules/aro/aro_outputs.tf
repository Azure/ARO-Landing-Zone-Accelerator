output "cluster_resource_group_id" {
  value = azureopenshift_redhatopenshift_cluster.cluster.cluster_profile[0].resource_group_id
}

output "cluster_internal_id" {
  value = azureopenshift_redhatopenshift_cluster.cluster.internal_cluster_id
}

output "cluster_name" {
  value = azureopenshift_redhatopenshift_cluster.cluster.name
}
