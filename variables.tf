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