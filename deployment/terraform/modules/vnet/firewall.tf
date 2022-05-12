resource "azurerm_public_ip" "fw_pip" {
  name = "${var.fw_name}-pip"
  resource_group_name = var.resource_group_name
  location = var.location
  allocation_method = "Static"
  sku = "Standard"

  tags = var.tags
}

resource "azurerm_firewall" "fw" {
  name = var.fw_name
  location = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name = "azfw-ipconfig"
    subnet_id = azurerm_subnet.fw.id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }
}

resource "azurerm_firewall_network_rule_collection" "aro" {
  name = "Aro-required-ports"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.resource_group_name
  priority = 200
  action = "Allow"

  rule {
    name = "NTP"

    source_addresses = concat(var.hub_prefix, var.spoke_prefix)

    destination_ports = [
      "123"
    ]

    destination_addresses = [
      "*"
    ]

    protocols = [
      "Any"
    ]
  }
}