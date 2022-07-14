# There are lots of items missting from the Azure FD TF provider: https://github.com/hashicorp/terraform-provider-azurerm/issues?page=2&q=is%3Aissue+is%3Aopen+frontdoor

data "external" "aro_ilb_name" {
  program = [
    "az", "network", "lb", "list", "-g", "openshift-cluster-aro", "--query", "[0].{name:name}", "-o", "json"
  ]
}

data "azurerm_lb" "aro_ilb" {
  name = data.external.aro_ilb_name.result.name
  resource_group_name = var.aro_resource_group_name
}

resource "azurerm_private_link_service" "pl" {
  name = var.afd_pls_name
  resource_group_name = var.spoke_rg_name
  location = var.location

  nat_ip_configuration {
    name = "primary"
    private_ip_address_version = "IPv4"
    subnet_id = var.aro_worker_subnet_id
    primary = true
  }
  load_balancer_frontend_ip_configuration_ids = ["${data.azurerm_lb.aro_ilb.frontend_ip_configuration[0].id}"]
}

resource "azurerm_cdn_frontdoor_profile" "fd" {
  name = var.afd_name
  resource_group_name = var.spoke_rg_name
  sku_name = var.afd_sku
}

resource "azurerm_monitor_diagnostic_setting" "afd_diag" {
  name = "afdtoLogAnalytics"
  target_resource_id = azurerm_cdn_frontdoor_profile.fd.id
  log_analytics_workspace_id = var.la_id

  log {
    category = "FrontDoorAccessLog"
    enabled = true
    retention_policy {
      enabled = false
      days = 0
    }
  }

  log {
    category = "FrontDoorHealthProbeLog"
    enabled = true
    retention_policy {
      enabled = false
      days = 0
    }
  }

   log {
    category = "FrontDoorWebApplicationFirewallLog"
    enabled = true
    retention_policy {
      enabled = false
      days = 0
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
      days = 0
    }
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "fd" {
  name = "aro-ilb${var.random}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
}