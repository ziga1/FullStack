terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "7a9d1223-2ddc-4942-8531-4aa56719aa8b"
  features {}
}

resource "azurerm_resource_group" "terra-demo" {
  name     = "terra-demo"
  location = "West Europe"
}

resource "azurerm_virtual_network" "terra-demo" {
  name                = "terra-demo-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.terra-demo.location
  resource_group_name = azurerm_resource_group.terra-demo.name
}

resource "azurerm_subnet" "terra-demo" {
  name                 = "SubnetA"
  resource_group_name  = azurerm_resource_group.terra-demo.name
  virtual_network_name = azurerm_virtual_network.terra-demo.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_interface" "terra-demo-vm2" {
  name                = "terra-demo-nic2"
  location            = azurerm_resource_group.terra-demo.location
  resource_group_name = azurerm_resource_group.terra-demo.name

  ip_configuration {
    name                          = "internal2"
    subnet_id                     = azurerm_subnet.terra-demo.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "terra-demo-vm2" {
  name                = "terra-demo-machine02"
  resource_group_name = azurerm_resource_group.terra-demo.name
  location            = azurerm_resource_group.terra-demo.location
  size                = "Standard_B2s"
  admin_username      = "trainer"
  network_interface_ids = [
    azurerm_network_interface.terra-demo-vm2.id,
  ]

  admin_ssh_key {
    username   = "trainer"
    public_key = file("/home/zsila/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  # Add security group for VM2
  resource "azurerm_network_security_group" "vm2" {
    name                = "vm2-nsg"
    resource_group_name = azurerm_resource_group.terra-demo.name
    location            = azurerm_resource_group.terra-demo.location

    security_rule {
      name                       = "SSH"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  network_security_group_id = azurerm_network_security_group.vm2.id
}
