resource "azurerm_key_vault" "sub_kv" {
  name = local.key_vault_name
  location = var.location
  resource_group_name = data.azurerm_resource_group.spoke.name
  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name = "standard"
  purge_protection_enabled = false
  public_network_access_enabled = false
  network_acls {
    bypass = "AzureServices"
    default_action = "Deny"
  }
}

resource "azurerm_private_endpoint" "kv" {
  name = "kvPvtEndpoint"
  resource_group_name = data.azurerm_resource_group.spoke.name
  location = var.location
  subnet_id = var.private_endpoint_subnet_id

  private_service_connection {
    name = "kvConnection"
    private_connection_resource_id = azurerm_key_vault.sub_kv.id
    is_manual_connection = false
    subresource_names = [ "vault" ]
  }

  private_dns_zone_group {
    name = "KeyVault-ZoneGroup"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.kv.id
    ]
  }
}

resource "azurerm_private_dns_zone" "kv" {
  name = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.spoke.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  name = "KeyVaultDNSLink"
  resource_group_name = data.azurerm_resource_group.spoke.name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id = var.spoke_vnet_id
  registration_enabled = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv2" {
  name = "KeyvaultDNSLinkHub"
  resource_group_name = data.azurerm_resource_group.spoke.name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id = var.hub_vnet_id
  registration_enabled = false
}