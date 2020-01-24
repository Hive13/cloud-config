provider "azurerm" {
}

resource "azurerm_resource_group" "hive13-cto-hiveinfra" {
  name     = "hive13-cto-hiveinfra"
  location = "eastus"
  tags = {
    terraform = true
  }
}

resource "azurerm_network_interface" "hive13-vm-weefee-nic" {
  name = "hive13-weefee-nic"
  location = azurerm_resource_group.hive13-cto-hiveinfra.location
  resource_group_name = azurerm_resource_group.hive13-cto-hiveinfra.name

  ip_configuration {
    name = "WeefeeNicConfig1"
    subnet_id = azurerm_subnet.hive13az-vms.id
    private_ip_address_allocation = "Static"
    private_ip_address = var.weefee_nic_staticprivate
  }

  tags = {
    terraform = true
  }
}

resource "azurerm_virtual_machine" "hive13-vm-weefee" {
  name = "hive13-vm-weefee"
  location = azurerm_resource_group.hive13-cto-hiveinfra.location
  resource_group_name = azurerm_resource_group.hive13-cto-hiveinfra.name

  network_interface_ids = [azurerm_network_interface.hive13-vm-weefee-nic.id]
  vm_size = "Standard_B1s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name = "hive13-vm-weefee-osdisk"
    create_option = "FromImage"
    disk_size_gb = 50
    caching = "ReadWrite"
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name = "hive13az-weefee"
    admin_username = "hive13"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = var.hive13_ssh_key
      path = "/home/hive13/.ssh/authorized_keys"
    }
  }

  tags = {
    terraform = true
  }
}

resource "azurerm_resource_group" "hive13-vnet" {
  name     = "hive13-vnet"
  location = "eastus"
  tags = {
    terraform = true
  }
}

resource "azurerm_virtual_network" "hive13az" {
  name = "hive13az"
  address_space = var.vnet_address_space
  location = "eastus"
  resource_group_name = azurerm_resource_group.hive13-vnet.name
  dns_servers = var.vnet_dns_servers
  tags = {
    terraform = true
  }
}

resource "azurerm_subnet" "hive13az-gw" {
  name = "GatewaySubnet"
  address_prefix = var.gateway_subnet_prefix
  resource_group_name = azurerm_resource_group.hive13-vnet.name
  virtual_network_name = azurerm_virtual_network.hive13az.name
}  

resource "azurerm_subnet" "hive13az-vms" {
  name                 = "hive13az-vms"
  address_prefix       = var.vms_subnet_prefix
  resource_group_name  = azurerm_resource_group.hive13-vnet.name
  virtual_network_name = azurerm_virtual_network.hive13az.name
}

resource "azurerm_public_ip" "hive13az-gwip" {
  name = "hive13az-gwip"
  location = azurerm_resource_group.hive13-vnet.location
  resource_group_name = azurerm_resource_group.hive13-vnet.name
  allocation_method = "Dynamic"
  domain_name_label = "hive13az-gwip"

}

resource "azurerm_virtual_network_gateway" "hive13az-gw" {
  name = "hive13az-gw"
  location = azurerm_resource_group.hive13-vnet.location
  resource_group_name = azurerm_resource_group.hive13-vnet.name
  
  type = "Vpn"
  vpn_type = "RouteBased"
  
  active_active = false
  enable_bgp = false
  sku = "Basic"

  ip_configuration {
    name = "hive13az-gwipconf"
    public_ip_address_id = azurerm_public_ip.hive13az-gwip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id = azurerm_subnet.hive13az-gw.id
  }

  tags = {
    terraform = true
  }
}

resource "azurerm_local_network_gateway" "hive13int" {
  name = "hive13int"
  location = azurerm_resource_group.hive13-vnet.location
  resource_group_name = azurerm_resource_group.hive13-vnet.name
  gateway_address = var.s2s_local_gateway_ip
  address_space = var.s2s_local_address_space

  tags = {
    terraform = true
  }
}

resource "azurerm_virtual_network_gateway_connection" "hive13-s2s" {
  name = "hive13-s2s"
  location = azurerm_resource_group.hive13-vnet.location
  resource_group_name = azurerm_resource_group.hive13-vnet.name

  type = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.hive13az-gw.id
  local_network_gateway_id = azurerm_local_network_gateway.hive13int.id
  
  shared_key = var.s2s_ipsec_psk

  tags = {
    terraform = true
  }
}
