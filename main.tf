resource "azurerm_container_registry" "acr" {
  for_each = { for registry in var.registries : registry.name => registry }

  name                          = each.value.name
  resource_group_name           = each.value.rg_name
  location                      = each.value.location
  admin_enabled                 = each.value.admin_enabled
  sku                           = title(each.value.sku)
  public_network_access_enabled = try(each.value.public_network_access_enabled, null)
  retention_policy_in_days      = try(each.value.retention_policy.days, null)
  trust_policy_enabled          = try(each.value.trust_policy.enabled, null)
  quarantine_policy_enabled     = try(each.value.quarantine_policy_enabled, null)
  zone_redundancy_enabled       = try(each.value.zone_redundancy_enabled, null)
  export_policy_enabled         = try(each.value.export_policy_enabled, null)
  data_endpoint_enabled         = try(each.value.data_endpoint_enabled, null)
  anonymous_pull_enabled        = try(each.value.anonymous_pull_enabled, null)
  network_rule_bypass_option    = try(each.value.network_rule_bypass_option, null)
  tags                          = each.value.tags

  dynamic "georeplications" {
    for_each = title(each.value.sku) == "Premium" && each.value.georeplications != null ? [each.value.georeplications] : []
    content {
      location                  = georeplications.value.location
      zone_redundancy_enabled   = georeplications.value.zone_redundancy_enabled
      tags                      = georeplications.value.tags
      regional_endpoint_enabled = georeplications.value.regional_endpoint_enabled
    }
  }

  dynamic "network_rule_set" {
    for_each = each.value.sku == "Premium" && each.value.network_rule_set != null ? [each.value.network_rule_set] : []
    content {
      default_action = network_rule_set.value.default_action

      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rule != null ? [network_rule_set.value.ip_rule] : []
        content {
          action   = ip_rule.value.action
          ip_range = ip_rule.value.ip_range
        }
      }
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned" ? [each.value.identity_type] : []
    content {
      type = each.value.identity_type
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned, UserAssigned" ? [each.value.identity_type] : []
    content {
      type         = each.value.identity_type
      identity_ids = try(each.value.identity_ids, [])
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "UserAssigned" ? [each.value.identity_type] : []
    content {
      type         = each.value.identity_type
      identity_ids = length(try(each.value.identity_ids, [])) > 0 ? each.value.identity_ids : []
    }
  }

  dynamic "encryption" {
    for_each = each.value.encryption != null ? [each.value.encryption] : []
    content {
      key_vault_key_id   = encryption.value.key_vault_key_id
      identity_client_id = encryption.value.identity_client_id
    }
  }
}

locals {
  flattened_pools = flatten([
    for registry in var.registries :
    registry.agent_pool != null ? [
      for pool in registry.agent_pool : {
        registry_name = registry.name
        pool          = pool
      }
    ] : []
  ])
}


resource "azurerm_container_registry_agent_pool" "agent_pool" {
  for_each = { for item in local.flattened_pools : "${item.registry_name}-${item.pool.name}" => item }

  name                    = each.value.pool.name
  resource_group_name     = azurerm_container_registry.acr[each.value.registry_name].resource_group_name
  location                = azurerm_container_registry.acr[each.value.registry_name].location
  container_registry_name = azurerm_container_registry.acr[each.value.registry_name].name

  instance_count            = try(each.value.pool.instance_count, 1)
  tier                      = try(each.value.pool.tier, "S1")
  virtual_network_subnet_id = try(each.value.pool.virtual_network_subnet_id, null)
  tags                      = try(each.value.pool.tags, null)
}