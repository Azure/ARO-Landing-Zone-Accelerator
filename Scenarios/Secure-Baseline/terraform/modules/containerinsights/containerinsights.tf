resource "azurerm_log_analytics_solution" "ci" {
  solution_name = "ContainerInsights"
  location      = var.location
  resource_group_name = var.spoke_rg_name
  workspace_resource_id = var.workspace_resource_id
  workspace_name = var.workspace_name

  plan {
    publisher = "Microsoft"
    product = "OMSGallery/ContainerInsights"
  }
}