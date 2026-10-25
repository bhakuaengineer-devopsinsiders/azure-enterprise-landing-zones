variable "tenant_id" {
  type        = string
  description = "The Microsoft Entra ID tenant ID for Key Vault authentication."
  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.tenant_id))
    error_message = "The tenant_id must be a valid 36-character UUID string."
  }
}

variable "global_tags" {
  type        = map(string)
  description = "Global tags applied across all infrastructure resources."
  default = {
    "Project"    = "Enterprise Landing Zone"
    "Architect"  = "Bhakua Engineer"
    "Compliance" = "CIS-Azure-v2.0"
  }
}

variable "resource_groups" {
  type = map(object({
    name        = string
    location    = string
    environment = string
    tags        = optional(map(string), {})
  }))
  description = "Map of resource groups to deploy across subscription boundaries."
}

variable "vnets" {
  type = map(object({
    name               = string
    resource_group_key = string
    address_space      = list(string)
    tags               = optional(map(string), {})
    subnets = map(object({
      name           = string
      address_prefix = string
      nsg_key        = optional(string)
    }))
  }))
  description = "Map of Virtual Networks with nested subnets."
}

variable "nsgs" {
  type = map(object({
    name               = string
    resource_group_key = string
    tags               = optional(map(string), {})
    rules = map(object({
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string)
      destination_port_range     = optional(string)
      destination_port_ranges    = optional(list(string))
      source_address_prefix      = optional(string)
      source_address_prefixes    = optional(list(string))
      destination_address_prefix = optional(string)
      description                = optional(string)
    }))
  }))
  description = "Map of Network Security Groups with prioritized rule configurations."
}

variable "route_tables" {
  type = map(object({
    name                          = string
    resource_group_key            = string
    disable_bgp_route_propagation = optional(bool, false)
    tags                          = optional(map(string), {})
    routes = map(object({
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    }))
  }))
  description = "Map of Route Tables and custom User Defined Routes (UDRs)."
}

variable "hub_vnet_rg_key" {
  type        = string
  description = "Key identifying the hub resource group."
  default     = "hub_connectivity"
}

variable "hub_vnet_key" {
  type        = string
  description = "Key identifying the hub virtual network."
  default     = "hub_vnet"
}

variable "spoke_peerings" {
  type = map(object({
    spoke_rg_key       = string
    spoke_vnet_key     = string
    enabled            = optional(bool, true)
    use_remote_gateway = optional(bool, false)
  }))
  description = "Map of spokes to peer with the central Hub VNet."
  default     = {}
}

variable "key_vaults" {
  type = map(object({
    name               = string
    resource_group_key = string
    sku_name           = string
    tags               = optional(map(string), {})
    network_acls = optional(object({
      default_action = string
      bypass         = string
      ip_rules       = optional(list(string), [])
      subnet_ids     = optional(list(string), [])
    }))
  }))
  description = "Map of Azure Key Vaults with dynamic network ACL configurations."
  default     = {}
}
