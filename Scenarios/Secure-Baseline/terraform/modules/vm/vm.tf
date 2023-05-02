
data "azurerm_key_vault_secret" "admin_username" {
  name = "vmadminusername"
  key_vault_id = var.kv_id
}

data "azurerm_key_vault_secret" "admin_password" {
  name = "vmadminpassword"
  key_vault_id = var.kv_id
}

resource "azurerm_public_ip" "bastion" {
  name = "${var.bastion_name}-pip"
  resource_group_name = var.resource_group_name
  location = var.location
  allocation_method = "Static"
  sku = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name = var.bastion_name
  location = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name = "config"
    subnet_id = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_network_interface" "jumpbox" {
  name = "${var.bastion_name}-nic"
  location = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name = "internal"
    subnet_id = var.vm_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                  = var.jumpbox_name
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.jumpbox_size
  admin_username        = data.azurerm_key_vault_secret.admin_username.value
  admin_password        = data.azurerm_key_vault_secret.admin_password.value
  network_interface_ids = [azurerm_network_interface.jumpbox.id]
  disable_password_authentication = false

  os_disk {
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  lifecycle {
    ignore_changes = [
      admin_username,
      admin_password
    ]
  }  
}

resource "azurerm_virtual_machine_extension" "jumpbox" {
  name = "jumpbox"
  virtual_machine_id = azurerm_linux_virtual_machine.jumpbox.id
  publisher = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
  {
    "fileUris": ["https://raw.githubusercontent.com/alainvetier/ARO-Landing-Zone-Accelerator/main/Scenarios/Secure-Baseline/script.sh"],
    "commandToExecute": "sh script.sh"
  }
  SETTINGS
}

resource "azurerm_network_interface" "Jumpbox2" {
  name = "${var.bastion_name}-nic2"
  location = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name = "internal"
    subnet_id = var.vm_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "Jumpbox2" {
  name = var.jumpbox2_name
  resource_group_name = var.resource_group_name
  location = var.location
  size = var.jumpbox_size
  admin_username = data.azurerm_key_vault_secret.admin_username.value
  admin_password = data.azurerm_key_vault_secret.admin_password.value
  network_interface_ids = [
    azurerm_network_interface.Jumpbox2.id
  ]

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  lifecycle {
    ignore_changes = [
      admin_username,
      admin_password
    ]
  }
  priority = "Spot"
  eviction_policy = "Deallocate"
}