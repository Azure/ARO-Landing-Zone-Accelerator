resource "azurerm_public_ip" "fw_pip" {
  name = "${var.fw_name}-pip"
  resource_group_name = var.hub_rg_name
  location = var.location
  allocation_method = "Static"
  sku = "Standard"
}

resource "azurerm_firewall" "fw" {
  name = var.fw_name
  location = var.location
  resource_group_name = var.hub_rg_name
  sku_name = "AZFW_VNet"
  sku_tier = "Standard"

  # https://docs.microsoft.com/en-us/azure/virtual-network/what-is-ip-address-168-63-129-16
  # This is the Azure VIP for DNS and is an workaround tracked in issue: https://github.com/hashicorp/terraform-provider-azurerm/issues/9184
  dns_servers = ["168.63.129.16"]

  ip_configuration {
    name = "azfw-ipconfig"
    subnet_id = azurerm_subnet.fw.id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }
}

resource "azurerm_firewall_network_rule_collection" "aro" {
  name = "Aro-required-ports"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_rg_name
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
  name = "Minimum-required-FQDN"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_rg_name
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
  depends_on = [ azurerm_firewall_network_rule_collection.aro ]
}

# FIRST GROUP: INSTALLING AND DOWNLOADING PACKAGES AND TOOLS
resource "azurerm_firewall_application_rule_collection" "aro" {
  name = "Aro-required-urls"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_rg_name
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
  depends_on = [ azurerm_firewall_network_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.min ]
}

# SECOND GROUP: TELEMETRY
resource "azurerm_firewall_application_rule_collection" "telem" {
  name = "Telemetry-URLs"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_rg_name
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
    depends_on = [ azurerm_firewall_network_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.min,
                 azurerm_firewall_application_rule_collection.aro ]
}

# THIRD GROUP: CLOUD APIs
resource "azurerm_firewall_application_rule_collection" "cloud" {
  name = "Cloud-APIs"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_rg_name
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
    depends_on = [ azurerm_firewall_network_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.min,
                 azurerm_firewall_application_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.telem ]
}

# FOURTH GROUP: OTHER OPENSHIFT REQUIREMENTS
resource "azurerm_firewall_application_rule_collection" "open_shift" {
  name = "OpenShift-URLs"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_rg_name
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
  depends_on = [ azurerm_firewall_network_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.min,
                 azurerm_firewall_application_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.telem,
                 azurerm_firewall_application_rule_collection.cloud ]
}

# FIFTH GROUP: MICROSOFT & RED HAT ARO MONITORING SERVICE
resource "azurerm_firewall_application_rule_collection" "monitoring" {
  name = "Monitoring-URLs"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_rg_name
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
  depends_on = [ azurerm_firewall_network_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.min,
                 azurerm_firewall_application_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.telem,
                 azurerm_firewall_application_rule_collection.cloud,
                 azurerm_firewall_application_rule_collection.open_shift ]
}

# SIXTH GROUP: ONBOARDING ARO ON TO ARC
resource "azurerm_firewall_application_rule_collection" "arc" {
  name = "Arc-URLs"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_rg_name
  priority = 206
  action = "Allow"

  rule {
    name = "sixth_group_target_fqdns"
    source_addresses = concat(var.hub_prefix, var.spoke_prefix)

    target_fqdns = [
      "${var.location}.login.microsoft.com",
      "management.azure.com",
      "${var.location}.dp.kubernetesconfiguration.azure.com",
      "login.microsoftonline.com", 
      "login.windows.net", 
      "mcr.microsoft.com", 
      "*.data.mcr.microsoft.com", 
      "gbl.his.arc.azure.com", 
      "*.his.arc.azure.com", 
      "*.servicebus.windows.net", 
      "guestnotificationservice.azure.com", 
      "*.guestnotificationservice.azure.com", 
      "sts.windows.net",
      "k8connecthelm.azureedge.net"
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
  depends_on = [ azurerm_firewall_network_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.min,
                 azurerm_firewall_application_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.telem,
                 azurerm_firewall_application_rule_collection.cloud,
                 azurerm_firewall_application_rule_collection.open_shift,
                 azurerm_firewall_application_rule_collection.monitoring ]
}

# SEVENTH GROUP: Azure Monitor Container Insights extension for Arc
resource "azurerm_firewall_application_rule_collection" "container_insights_arc" {
  name = "Arc-ContainerInsights-URLs"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_rg_name
  priority = 207
  action = "Allow"

  rule {
    name = "seventh_group_target_fqdns"
    source_addresses = concat(var.hub_prefix, var.spoke_prefix)

    target_fqdns = [
      "*.ods.opinsights.azure.com", 
      "*.oms.opinsights.azure.com",
      "dc.services.visualstudio.com",
      "*.monitoring.azure.com",
      "login.microsoftonline.com"
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
  depends_on = [ azurerm_firewall_network_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.min,
                 azurerm_firewall_application_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.telem,
                 azurerm_firewall_application_rule_collection.cloud,
                 azurerm_firewall_application_rule_collection.open_shift,
                 azurerm_firewall_application_rule_collection.monitoring,
                 azurerm_firewall_application_rule_collection.arc ]
}

# EIGHTH GROUP: Docker HUB, GCR Optional for testing purpose
resource "azurerm_firewall_application_rule_collection" "docker_hub" {
  name = "Docker-HUB-URLs"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_rg_name
  priority = 208
  action = "Allow"

  rule {
    name = "eighth_group_target_fqdns"
    source_addresses = concat(var.hub_prefix, var.spoke_prefix)

    target_fqdns = [
      "registry.hub.docker.com",
      "*.docker.io",
      "production.cloudflare.docker.com",
      "auth.docker.io",
      "*.gcr.io"
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
  depends_on = [ azurerm_firewall_network_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.min,
                 azurerm_firewall_application_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.telem,
                 azurerm_firewall_application_rule_collection.cloud,
                 azurerm_firewall_application_rule_collection.open_shift,
                 azurerm_firewall_application_rule_collection.monitoring,
                 azurerm_firewall_application_rule_collection.arc,
                 azurerm_firewall_application_rule_collection.container_insights_arc ]
}

# NINETH GROUP: Miscellaneous - Optional for testing purpose
resource "azurerm_firewall_application_rule_collection" "misc" {
  name = "Miscellaneous-URLs"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.hub_rg_name
  priority = 209
  action = "Allow"

  rule {
    name = "nineth_group_target_fqdns"
    source_addresses = concat(var.hub_prefix, var.spoke_prefix)

    target_fqdns = [
      "quayio-production-s3.s3.amazonaws.com"
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
  depends_on = [ azurerm_firewall_network_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.min,
                 azurerm_firewall_application_rule_collection.aro,
                 azurerm_firewall_application_rule_collection.telem,
                 azurerm_firewall_application_rule_collection.cloud,
                 azurerm_firewall_application_rule_collection.open_shift,
                 azurerm_firewall_application_rule_collection.monitoring,
                 azurerm_firewall_application_rule_collection.arc,
                 azurerm_firewall_application_rule_collection.container_insights_arc,
                 azurerm_firewall_application_rule_collection.docker_hub ]
}

resource "azurerm_virtual_network_dns_servers" "hub" {
  virtual_network_id = azurerm_virtual_network.hub.id
  dns_servers = ["${azurerm_firewall.fw.ip_configuration[0].private_ip_address}"]
}

resource "azurerm_virtual_network_dns_servers" "spoke" {
  virtual_network_id = azurerm_virtual_network.spoke.id
  dns_servers = ["${azurerm_firewall.fw.ip_configuration[0].private_ip_address}"]
}
