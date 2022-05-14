resource "azurerm_container_registry" "acr" {
  name                          = var.acr_name
  resource_group_name           = var.rg_name
  location                      = var.location
  admin_enabled                 = var.admin_enabled
  sku                           = title(var.sku)
  public_network_access_enabled = var.public_network_access_enabled
  quarantine_policy_enabled     = var.sku == "Premium" ? try(var.quarantine_policy_enabled, null) : null
  zone_redundancy_enabled       = var.sku == "Premium" ? try(var.zone_redundancy_enabled, null) : null
  export_policy_enabled         = var.sku == "Premium" ? try(var.export_policy_enabled, null) : null
  data_endpoint_enabled         = var.sku == "Premium" ? try(var.data_endpoint_enabled, null) : null
  anonymous_pull_enabled        = try(var.anonymous_pull_enabled, null)
  network_rule_bypass_option    = try(var.network_rule_bypass_option, null)
  tags                          = var.tags

  dynamic "georeplications" {
    for_each = lookup(var.settings, "georeplications", {}) != {} ? [1] : []
    content {
      location                = lookup(var.settings.georeplications, "location", null)
      zone_redundancy_enabled = lookup(var.settings.georeplications, "zone_redundancy_enabled", null)
      tags                    = lookup(var.settings.georeplications, "tags", null)
    }
  }

  dynamic "network_rule_set" {
    for_each = lookup(var.settings, "network_rule_set", {}) != {} ? [1] : []
    content {
      default_action = lookup(var.settings.network_rule_set, "default_action", null)

      dynamic "ip_rule" {
        for_each = lookup(var.settings.network_rule_set, "ip_rule", {}) != {} ? [1] : []
        content {
          action   = lookup(var.settings.network_rule_set.ip_rule, "action", null)
          ip_range = lookup(var.settings.network_rule_set.ip_rule, "ip_range", null)
        }
      }

      dynamic "virtual_network" {
        for_each = lookup(var.settings.network_rule_set, "virtual_network", {}) != {} ? [1] : []
        content {
          action    = lookup(var.settings.network_rule_set.virtual_network, "action", null)
          subnet_id = lookup(var.settings.network_rule_set.virtual_network, "subnet_id", null)
        }
      }
    }
  }

  dynamic "retention_policy" {
    for_each = lookup(var.settings, "retention_policy", {}) != {} ? [1] : []
    content {
      days    = lookup(var.settings.retention_policy, "days", null)
      enabled = lookup(var.settings.retention_policy, "enabled", null)
    }
  }

  dynamic "trust_policy" {
    for_each = lookup(var.settings, "trust_policy", {}) != {} ? [1] : []
    content {
      enabled = lookup(var.settings.trust_policy, "enabled", null)
    }
  }

  dynamic "identity" {
    for_each = length(var.identity_ids) == 0 && var.identity_type == "SystemAssigned" ? [var.identity_type] : []
    content {
      type = var.identity_type
    }
  }

  dynamic "identity" {
    for_each = length(var.identity_ids) > 0 || var.identity_type == "UserAssigned" ? [var.identity_type] : []
    content {
      type         = var.identity_type
      identity_ids = length(var.identity_ids) > 0 ? var.identity_ids : []
    }
  }

  dynamic "encryption" {
    for_each = lookup(var.settings, "encryption", {}) != {} ? [1] : []
    content {
      enabled            = lookup(var.settings.encryption, "enabled", null)
      key_vault_key_id   = lookup(var.settings.encryption, "key_vault_key_id", null)
      identity_client_id = lookup(var.settings.encryption, "identity_client_id", null)
    }
  }
}
