output "cluster_resource_group_id" {
  value = azureopenshift_redhatopenshift_cluster.cluster.cluster_profile[0].resource_group_id
}
