
resource "azurerm_cosmosdb_account" "cosmos" {
  name = "${var.base_name}-${random_integer.ri.result}"
  location = data.azurerm_resource_group.spoke.location
  resource_group_name = data.azurerm_resource_group.spoke.name
  offer_type = "Standard"
  kind = "MongoDB"
  mongo_server_version = "4.0"

  consistency_policy {
    consistency_level = "Eventual"
  }

  capabilities {
    name = "EnableMongo"
  }

  public_network_access_enabled = false

  geo_location {
    location = data.azurerm_resource_group.spoke.location
    failover_priority = 0
  }
}

resource "azurerm_private_endpoint" "cosmos" {
  name = "cosmosdbPvtEndpoint"
  location = data.azurerm_resource_group.spoke.location
  resource_group_name = data.azurerm_resource_group.spoke.name
  subnet_id = data.azurerm_subnet.private_endpoint_subnet_name.id

  private_service_connection {
    name = "cosmosdbConnection"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmos.id
    is_manual_connection = false
    subresource_names = ["MongoDB"]
  }

  private_dns_zone_group {
    name = "CosmosDb-ZoneGroup"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.cosmos.id
    ]
  }
}

resource "azurerm_private_dns_zone" "cosmos" {
  name = "privatelink.mongo.cosmos.azure.com"
  resource_group_name = data.azurerm_resource_group.spoke.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos" {
  name = "CosmosDbDNSLink"
  resource_group_name = data.azurerm_resource_group.spoke.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos.name
  virtual_network_id = data.azurerm_virtual_network.hub_vnet.id
  registration_enabled = false
}

resource "azurerm_cosmosdb_mongo_database" "ratingsdb" {
  name = "ratingsdb"
  resource_group_name = data.azurerm_resource_group.spoke.name
  account_name = azurerm_cosmosdb_account.cosmos.name
  throughput = 400
}