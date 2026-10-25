output "resource_group_ids" {
  description = "Map of all provisioned Resource Group IDs."
  value       = { for k, v in azurerm_resource_group.rg : k => v.id }
}

output "vnet_topology" {
  description = "Comprehensive map of deployed VNets and their respective Subnet IDs."
  value = {
    for k, v in azurerm_virtual_network.vnet : k => {
      id            = v.id
      name          = v.name
      address_space = v.address_space
      subnets       = { for s in v.subnet : s.name => s.id }
    }
  }
}

output "nsg_ids" {
  description = "Map of provisioned Network Security Group IDs."
  value       = { for k, v in azurerm_network_security_group.nsg : k => v.id }
}

output "route_table_ids" {
  description = "Map of Route Table IDs deployed with central firewall routes."
  value       = { for k, v in azurerm_route_table.udr : k => v.id }
}

output "key_vault_uris" {
  description = "Map of Azure Key Vault Vault URIs for application secret references."
  value       = { for k, v in azurerm_key_vault.akv : k => v.vault_uri }
}
