resource "azurerm_public_ip" "fw_pip" {
  name = "${var.fw_name}-pip"
  resource_group_name = var.hub_resource_group_name
  location = var.location
  allocation_method = "Static"
  sku = "Standard"
}

resource "azurerm_firewall" "fw" {
  name = var.fw_name
  location = var.location
  resource_group_name = var.hub_resource_group_name
  sku_name = "AZFW_VNet"
  sku_tier = "Standard"

  ip_configuration {
    name = "azfw-ipconfig"
    subnet_id = module.hub_network.subnets.fw.resource_id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }
}

resource "azurerm_firewall_network_rule_collection" "aro" {
  name = "Aro-required-ports"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_resource_group_name
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

# Minimum Required FQDN / application rules
resource "azurerm_firewall_application_rule_collection" "min" {
  name = "Minimum-reqired-FQDN"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_resource_group_name
  priority = 200
  action = "Allow"

  rule {
    name = "minimum_required_group_target_fqdns"
    source_addresses = concat(var.hub_prefix, var.spoke_prefix)

    target_fqdns = [
      "arosvc.${var.location}.data.azurecr.io",
      "*.quay.io",
      "registry.redhat.io",
      "mirror.openshift.com",
      "api.openshift.com",
      "arosvc.azurecr.io",
      "management.azure.com",
      "login.microsoftonline.com",
      "gcs.prod.monitoring.core.windows.net",
      "*.blob.core.windows.net",
      "*.servicebus.windows.net",
      "*.table.core.windows.net"
    ]

    protocol {
      port = "80"
      type = "Http"
    }

    protocol {
      port = "443"
      type = "Https"
    }
  }
  timeouts {
    create = "60m"
    delete = "45m"
  }
}

# FIRST GROUP: INSTALLING AND DOWNLOADING PACKAGES AND TOOLS
resource "azurerm_firewall_application_rule_collection" "aro" {
  name = "Aro-required-urls"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_resource_group_name
  priority = 201
  action = "Allow"

  rule {
    name = "first_group_target_fqdns"
    source_addresses = concat(var.hub_prefix, var.spoke_prefix)

    target_fqdns = [
      "quay.io",
      "registry.redhat.io",
      "sso.redhat.com",
      "openshift.org"
    ]

    protocol {
      port = "80"
      type = "Http"
    }

    protocol {
      port = "443"
      type = "Https"
    }
  }
  timeouts {
    create = "60m"
    delete = "45m"
  }
}

# SECOND GROUP: TELEMETRY
resource "azurerm_firewall_application_rule_collection" "telem" {
  name = "Telemetry-URLs"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_resource_group_name
  priority = 202
  action = "Allow"

  rule {
    name = "second_group_target_fqdns"
    source_addresses = concat(var.hub_prefix, var.spoke_prefix)

    target_fqdns = [
      "cert-api.access.redhat.com",
      "api.access.redhat.com",
      "infogw.api.openshift.com",
      "cloud.redhat.com"
    ]

    protocol {
      port = "80"
      type = "Http"
    }

    protocol {
      port = "443"
      type = "Https"
    }
  }
}

# THIRD GROUP: CLOUD APIs
resource "azurerm_firewall_application_rule_collection" "cloud" {
  name = "Cloud-APIs"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_resource_group_name
  priority = 203
  action = "Allow"

  rule {
    name = "third_group_target_fqdns"
    source_addresses = concat(var.hub_prefix, var.spoke_prefix)

    target_fqdns = [
      "management.azure.com"
    ]

    protocol {
      port = "80"
      type = "Http"
    }

    protocol {
      port = "443"
      type = "Https"
    }
  }
  timeouts {
    create = "60m"
    delete = "45m"
  }
}

# FOURTH GROUP: OTHER OPENSHIFT REQUIREMENTS
resource "azurerm_firewall_application_rule_collection" "open_shift" {
  name = "OpenShift-URLs"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_resource_group_name
  priority = 204
  action = "Allow"

  rule {
    name = "fourth_group_target_fqdns"
    source_addresses = concat(var.hub_prefix, var.spoke_prefix)

    target_fqdns = [
      "mirror.openshift.com",
      "storage.googleapis.com",
      "api.openshift.com",
      "registry.access.redhat.com"
    ]

    protocol {
      port = "80"
      type = "Http"
    }

    protocol {
      port = "443"
      type = "Https"
    }
  }
  timeouts {
    create = "60m"
    delete = "45m"
  }
}

# FIFTH GROUP: MICROSOFT & RED HAT ARO MONITORING SERVICE
resource "azurerm_firewall_application_rule_collection" "monitoring" {
  name = "Monitoring-URLs"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_resource_group_name
  priority = 205
  action = "Allow"

  rule {
    name = "fifth_group_target_fqdns"
    source_addresses = concat(var.hub_prefix, var.spoke_prefix)

    target_fqdns = [
      "login.microsoftonline.com", 
      "gcs.prod.monitoring.core.windows.net", 
      "*.blob.core.windows.net",
      "*.servicebus.windows.net",
      "*.table.core.windows.net"
    ]

    protocol {
      port = "80"
      type = "Http"
    }

    protocol {
      port = "443"
      type = "Https"
    }
  }
  timeouts {
    create = "60m"
    delete = "45m"
  }
}