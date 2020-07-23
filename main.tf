provider "azurerm" {
}

terraform {
  backend "remote" {
    organization = "hive13"

    workspaces {
      name = "azure-config"
    }
  }
}

resource "azurerm_resource_group" "hive13-cto-hiveinfra" {
  name     = "hive13-cto-hiveinfra"
  location = "eastus"
  tags = {
    terraform = true
  }
}

# ------------------------------
# BEGIN DOCKER VOLUME FILE SHARE
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

# STORAGE ACCOUNT
resource "azurerm_storage_account" "hive13dockervol" {
  name                     = "hive13dockervol"
  resource_group_name      = azurerm_resource_group.hive13-cto-hiveinfra.name
  location                 = azurerm_resource_group.hive13-cto-hiveinfra.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    terraform = true
  }
}

# FILE SHARE
resource "azurerm_storage_share" "docker-vol" {
  name                 = "docker-vol"
  storage_account_name = azurerm_storage_account.hive13dockervol.name
  quota                = 50
}

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# END DOCKER VOLUME FILE SHARE
# ----------------------------

# ----------------------
# BEGIN UNIFI CONTROLLER
# vvvvvvvvvvvvvvvvvvvvvv

# NIC
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

# VM
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

# ^^^^^^^^^^^^^^^^^^^^
# END UNIFI CONTROLLER
# --------------------

# --------------------------
# BEGIN APACHE REVERSE PROXY
# vvvvvvvvvvvvvvvvvvvvvvvvvv

# NSG
resource "azurerm_network_security_group" "hive13az-revprox-nsg" {
  name = "hive13-revprox-nsg"
  location = azurerm_resource_group.hive13-cto-hiveinfra.location
  resource_group_name = azurerm_resource_group.hive13-cto-hiveinfra.name

  security_rule {
    name = "Port80In"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "80"
    source_address_prefix = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "Port443In"
    priority = 101
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "443"
    source_address_prefix = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "Port22In"
    priority = 102
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "Internet"
    destination_address_prefix = "*"
  }

  tags = {
    terraform = true
  }
}

# PUBLIC IP
resource "azurerm_public_ip" "hive13az-revproxip" {
  name = "hive13az-revproxip"
  location = azurerm_resource_group.hive13-vnet.location
  resource_group_name = azurerm_resource_group.hive13-vnet.name
  allocation_method = "Dynamic"
  domain_name_label = "hive13az-revprox"

}

# NIC
resource "azurerm_network_interface" "hive13-vm-revprox-nic" {
  name = "hive13-revprox-nic"
  location = azurerm_resource_group.hive13-cto-hiveinfra.location
  resource_group_name = azurerm_resource_group.hive13-cto-hiveinfra.name

  network_security_group_id = azurerm_network_security_group.hive13az-revprox-nsg.id

  ip_configuration {
    name = "RevproxNicConfig1"
    subnet_id = azurerm_subnet.hive13az-vms.id
    private_ip_address_allocation = "Static"
    private_ip_address = var.revprox_nic_staticprivate
    public_ip_address_id = azurerm_public_ip.hive13az-revproxip.id
  }

  tags = {
    terraform = true
  }
}

# VM
resource "azurerm_virtual_machine" "hive13-vm-revprox" {
  name = "hive13-vm-revprox"
  location = azurerm_resource_group.hive13-cto-hiveinfra.location
  resource_group_name = azurerm_resource_group.hive13-cto-hiveinfra.name

  network_interface_ids = [azurerm_network_interface.hive13-vm-revprox-nic.id]
  vm_size = "Standard_B1s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name = "hive13-vm-revprox-osdisk"
    create_option = "FromImage"
    disk_size_gb = 50
    caching = "ReadWrite"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name = "hive13az-revprox"
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


# ^^^^^^^^^^^^^^^^^^^^^^^^
# END APACHE REVERSE PROXY
# ------------------------

# -----------------------
# BEGIN POSTGRESQL MASTER
# vvvvvvvvvvvvvvvvvvvvvvv

# NIC
resource "azurerm_network_interface" "hive13-vm-psqlmaster-nic" {
  name = "hive13-psqlmaster-nic"
  location = azurerm_resource_group.hive13-cto-hiveinfra.location
  resource_group_name = azurerm_resource_group.hive13-cto-hiveinfra.name

  ip_configuration {
    name = "PsqlMasterNicConfig1"
    subnet_id = azurerm_subnet.hive13az-vms.id
    private_ip_address_allocation = "Static"
    private_ip_address = var.psqlmaster_nic_staticprivate
  }

  tags = {
    terraform = true
  }
}

# VM
resource "azurerm_virtual_machine" "hive13-vm-psqlmaster" {
  name = "hive13-vm-psqlmaster"
  location = azurerm_resource_group.hive13-cto-hiveinfra.location
  resource_group_name = azurerm_resource_group.hive13-cto-hiveinfra.name

  network_interface_ids = [azurerm_network_interface.hive13-vm-psqlmaster-nic.id]
  vm_size = "Standard_B1ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name = "hive13-vm-psqlmaster-osdisk"
    create_option = "FromImage"
    disk_size_gb = 50
    caching = "ReadWrite"
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name = "hive13az-psqlmaster"
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

# ^^^^^^^^^^^^^^^^^^^^^
# END POSTGRESQL MASTER
# ---------------------

# -----------------------
# START INTWEB APP SERVER 
# vvvvvvvvvvvvvvvvvvvvvvv

# NIC
resource "azurerm_network_interface" "hive13-vm-intwebapp-nic" {
  name = "hive13-intwebapp-nic"
  location = azurerm_resource_group.hive13-cto-hiveinfra.location
  resource_group_name = azurerm_resource_group.hive13-cto-hiveinfra.name

  ip_configuration {
    name = "IntwebAppNicConfig1"
    subnet_id = azurerm_subnet.hive13az-vms.id
    private_ip_address_allocation = "Static"
    private_ip_address = var.intwebapp_nic_staticprivate
  }

  tags = {
    terraform = true
  }
}

# VM
resource "azurerm_virtual_machine" "hive13-vm-intwebapp" {
  name = "hive13-vm-intwebapp"
  location = azurerm_resource_group.hive13-cto-hiveinfra.location
  resource_group_name = azurerm_resource_group.hive13-cto-hiveinfra.name

  network_interface_ids = [azurerm_network_interface.hive13-vm-intwebapp-nic.id]
  vm_size = "Standard_B1ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name = "hive13-vm-intwebapp-osdisk"
    create_option = "FromImage"
    disk_size_gb = 50
    caching = "ReadWrite"
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name = "hive13az-intwebapp"
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

# ^^^^^^^^^^^^^^^^^^^^^
# END INTWEB APP SERVER
# ---------------------

# --------------------------
# BEGIN BITWARDEN APP SERVER
# vvvvvvvvvvvvvvvvvvvvvvvvvv

# NIC
resource "azurerm_network_interface" "hive13-vm-bitwarden-nic" {
  name = "hive13-bitwarden-nic"
  location = azurerm_resource_group.hive13-cto-hiveinfra.location
  resource_group_name = azurerm_resource_group.hive13-cto-hiveinfra.name

  ip_configuration {
    name = "BitwardenAppNicConfig1"
    subnet_id = azurerm_subnet.hive13az-vms.id
    private_ip_address_allocation = "Static"
    private_ip_address = var.bitwarden_nic_staticprivate
  }

  tags = {
    terraform = true
  }
}

# VM
resource "azurerm_virtual_machine" "hive13-vm-bitwarden" {
  name = "hive13-vm-bitwarden"
  location = azurerm_resource_group.hive13-cto-hiveinfra.location
  resource_group_name = azurerm_resource_group.hive13-cto-hiveinfra.name

  network_interface_ids = [azurerm_network_interface.hive13-vm-bitwarden-nic.id]
  vm_size = "Standard_B1s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name = "hive13-vm-bitwarden-osdisk"
    create_option = "FromImage"
    disk_size_gb = 50
    caching = "ReadWrite"
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name = "hive13az-bitwarden"
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

# ^^^^^^^^^^^^^^^^^^^^^^^^
# END BITWARDEN APP SERVER
# ------------------------

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
  #dns_servers = var.vnet_dns_servers
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

# ---------------------
# START 2929 VPN CONFIG
# vvvvvvvvvvvvvvvvvvvvv

#resource "azurerm_local_network_gateway" "hive13int" {
#  name = "hive13int"
#  location = azurerm_resource_group.hive13-vnet.location
#  resource_group_name = azurerm_resource_group.hive13-vnet.name
#  gateway_address = var.s2s_local_gateway_ip
#  address_space = var.s2s_local_address_space
#
#  tags = {
#    terraform = true
#  }
#}

#resource "azurerm_virtual_network_gateway_connection" "hive13-s2s" {
#  name = "hive13-s2s"
#  location = azurerm_resource_group.hive13-vnet.location
#  resource_group_name = azurerm_resource_group.hive13-vnet.name
#
#  type = "IPsec"
#  virtual_network_gateway_id = azurerm_virtual_network_gateway.hive13az-gw.id
#  local_network_gateway_id = azurerm_local_network_gateway.hive13int.id
#  
#  shared_key = var.s2s_ipsec_psk
#
#  tags = {
#    terraform = true
#  }
#}

# ^^^^^^^^^^^^^^^^^^^
# END 2929 VPN CONFIG
# -------------------

# ---------------------
# START 2701 VPN CONFIG
# vvvvvvvvvvvvvvvvvvvvv

resource "azurerm_local_network_gateway" "hive13-2701gw" {
  name = "hive13-2701gw"
  location = azurerm_resource_group.hive13-vnet.location
  resource_group_name = azurerm_resource_group.hive13-vnet.name
  gateway_address = var.hive13-2701_local_gateway_ip
  address_space = var.hive13-2701_local_address_space

  tags = {
    terraform = true
  }
}

resource "azurerm_virtual_network_gateway_connection" "hive13-2701-s2s" {
  name = "hive13-2701-s2s"
  location = azurerm_resource_group.hive13-vnet.location
  resource_group_name = azurerm_resource_group.hive13-vnet.name

  type = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.hive13az-gw.id
  local_network_gateway_id = azurerm_local_network_gateway.hive13-2701gw.id

  shared_key = var.gw2701_ipsec_psk

  tags = {
    terraform = true
  }
}

# ^^^^^^^^^^^^^^^^^^^
# END 2701 VPN CONFIG
# -------------------