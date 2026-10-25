terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.95.0"
    }
  }
  backend "azurerm" {
    # Backend configuration passed via backend config file or pipeline CLI
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# --------------------------------------------------------------------------------------------------
# 1. Resource Groups: Orchestrated via for_each over structured map with environment tags
# --------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  for_each = var.resource_groups

  name     = each.value.name
  location = each.value.location
  tags     = merge(var.global_tags, each.value.tags, {
    "ManagedBy"   = "Terraform"
    "Environment" = each.value.environment
  })
}

# --------------------------------------------------------------------------------------------------
# 2. Virtual Networks & Dynamic Subnet Blocks with NSG association
# --------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  for_each = var.vnets

  name                = each.value.name
  location            = azurerm_resource_group.rg[each.value.resource_group_key].location
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name
  address_space       = each.value.address_space

  dynamic "subnet" {
    for_each = each.value.subnets
    content {
      name           = subnet.value.name
      address_prefix = subnet.value.address_prefix
      security_group = lookup(subnet.value, "nsg_key", null) != null ? azurerm_network_security_group.nsg[subnet.value.nsg_key].id : null
    }
  }

  tags = merge(var.global_tags, each.value.tags)
}

# --------------------------------------------------------------------------------------------------
# 3. Network Security Groups with Advanced Dynamic Security Rules
# --------------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  for_each = var.nsgs

  name                = each.value.name
  location            = azurerm_resource_group.rg[each.value.resource_group_key].location
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name

  dynamic "security_rule" {
    for_each = each.value.rules
    content {
      name                       = security_rule.key
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = lookup(security_rule.value, "source_port_range", "*")
      destination_port_range     = lookup(security_rule.value, "destination_port_range", null)
      destination_port_ranges    = lookup(security_rule.value, "destination_port_ranges", null)
      source_address_prefix      = lookup(security_rule.value, "source_address_prefix", null)
      source_address_prefixes    = lookup(security_rule.value, "source_address_prefixes", null)
      destination_address_prefix = lookup(security_rule.value, "destination_address_prefix", "*")
      description                = lookup(security_rule.value, "description", "Automated CIS rule")
    }
  }

  tags = merge(var.global_tags, each.value.tags)
}

# --------------------------------------------------------------------------------------------------
# 4. Route Tables with Dynamic UDRs (User Defined Routes)
# --------------------------------------------------------------------------------------------------
resource "azurerm_route_table" "udr" {
  for_each = var.route_tables

  name                          = each.value.name
  location                      = azurerm_resource_group.rg[each.value.resource_group_key].location
  resource_group_name           = azurerm_resource_group.rg[each.value.resource_group_key].name
  disable_bgp_route_propagation = lookup(each.value, "disable_bgp_route_propagation", false)

  dynamic "route" {
    for_each = each.value.routes
    content {
      name                   = route.key
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
    }
  }

  tags = merge(var.global_tags, each.value.tags)
}

# --------------------------------------------------------------------------------------------------
# 5. Hub-and-Spoke Bidirectional Virtual Network Peering Mesh
# --------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = {
    for k, v in var.spoke_peerings : k => v
    if lookup(v, "enabled", true)
  }

  name                         = "peer-hub-to-${each.key}"
  resource_group_name          = azurerm_resource_group.rg[var.hub_vnet_rg_key].name
  virtual_network_name         = azurerm_virtual_network.vnet[var.hub_vnet_key].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[each.value.spoke_vnet_key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = {
    for k, v in var.spoke_peerings : k => v
    if lookup(v, "enabled", true)
  }

  name                         = "peer-${each.key}-to-hub"
  resource_group_name          = azurerm_resource_group.rg[each.value.spoke_rg_key].name
  virtual_network_name         = azurerm_virtual_network.vnet[each.value.spoke_vnet_key].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[var.hub_vnet_key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = lookup(each.value, "use_remote_gateway", false)
}

# --------------------------------------------------------------------------------------------------
# 6. Azure Key Vault with Dynamic Network ACLs & Access Policies
# --------------------------------------------------------------------------------------------------
resource "azurerm_key_vault" "akv" {
  for_each = var.key_vaults

  name                       = each.value.name
  location                   = azurerm_resource_group.rg[each.value.resource_group_key].location
  resource_group_name        = azurerm_resource_group.rg[each.value.resource_group_key].name
  tenant_id                  = var.tenant_id
  sku_name                   = each.value.sku_name
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  dynamic "network_acls" {
    for_each = lookup(each.value, "network_acls", null) != null ? [each.value.network_acls] : []
    content {
      default_action             = network_acls.value.default_action
      bypass                     = network_acls.value.bypass
      ip_rules                   = lookup(network_acls.value, "ip_rules", [])
      virtual_network_subnet_ids = lookup(network_acls.value, "subnet_ids", [])
    }
  }

  tags = merge(var.global_tags, each.value.tags)
}
