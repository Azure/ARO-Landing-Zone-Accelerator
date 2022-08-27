resource "random_string" "acr" {
  length = 4
  min_numeric = 4
  keepers = {
    name = var.base_name
  }
}

resource "azurerm_container_registry" "acr" {
  name = "${var.base_name}${random_string.acr.result}"
  resource_group_name = var.spoke_rg_name
  location = var.location
  sku = "Premium"
  admin_enabled = true
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "acr" {
  name = "arcPvtEndpoint"
  resource_group_name = var.spoke_rg_name
  location = var.location
  subnet_id = var.private_endpoint_subnet_id

  private_dns_zone_group {
    name = "ACR-ZoneGroup"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns.id
    ]
  }

  private_service_connection {
    name = "acrConnection"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection = false
    subresource_names = [ "registry" ]
  }
}

resource "azurerm_private_dns_zone" "dns" {
  name = "privatelink.azurecr.io"
  resource_group_name = var.spoke_rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name = "AcrDNSLink"
  resource_group_name = var.spoke_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id = var.spoke_vnet_id
}

