variable "weefee_nic_staticprivate" {
  description = "Static private IP address for the Weefee VM"
}

variable "hive13_ssh_key" {
  description = "SSH public key for the VM admin account"
}

variable "s2s_ipsec_psk" {
  description = "IPsec pre-shared secret for Hive13 site-to-site-VPN"
}

variable "vnet_address_space" {
  description = "Address space of the Hive13 Azure virtual network"
}

variable "vnet_dns_servers" {
  description = "DNS servers to assign to hosts on the Azure virtual network"
}

variable "gateway_subnet_prefix" {
  description = "CIDR representation of the address space on the GatewaySubnet"
}

variable "vms_subnet_prefix" {
  description = "CIDR representation of the address space on the VM subnet"
}

variable "s2s_local_gateway_ip" {
  description = "Public IP of the on-premises side of the Azure S2S VPN"
}

variable "s2s_local_address_space" {
  description = "Address space behind the S2S on-premises gateway"
}

variable "revprox_nic_staticprivate" {
  description = "Static IP of the network interface on the reverse proxy VM"
}

variable "psqlmaster_nic_staticprivate" {
  description = "static IP of the network interface on the PostgreSQL master VM"
}

variable "intwebapp_nic_staticprivate" {
  description = "static IP of the network interface on the Intweb application VM"
}

variable "bitwarden_nic_staticprivate" {
  description = "static IP of the network interface on the Bitwarden server VM"
}

variable "hive13-2701_local_gateway_ip" {
  description = "Public IP of the on-prem side of the tunnel to 2701"
}

variable "hive13-2701_local_address_space" {
  description = "Address space on the local side at 2701"
}

variable "gw2701_ipsec_psk" {
  description = "IPsec pre-shared secret for Hive13 site-to-site-VPN at 2701"
}