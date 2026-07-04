locals {
  rg = provider::azurerm::parse_resource_id(var.resource_group_id)
}

resource "azurerm_container_registry" "this" {
  for_each = var.container_registries

  resource_group_name = local.rg.resource_group_name
  location            = var.location
  tags                = merge(var.tags, coalesce(each.value.tags, {}))

  name                          = each.key
  sku                           = each.value.sku
  admin_enabled                 = each.value.admin_enabled
  anonymous_pull_enabled        = each.value.anonymous_pull_enabled
  public_network_access_enabled = each.value.public_network_access_enabled
  data_endpoint_enabled         = each.value.data_endpoint_enabled
  export_policy_enabled         = each.value.export_policy_enabled
  quarantine_policy_enabled     = each.value.quarantine_policy_enabled
  trust_policy_enabled          = each.value.trust_policy_enabled
  retention_policy_in_days      = each.value.retention_policy_in_days
  network_rule_bypass_option    = each.value.network_rule_bypass_option
  zone_redundancy_enabled       = each.value.zone_redundancy_enabled

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "georeplications" {
    for_each = each.value.georeplications

    content {
      location                  = georeplications.value.location
      regional_endpoint_enabled = georeplications.value.regional_endpoint_enabled
      zone_redundancy_enabled   = georeplications.value.zone_redundancy_enabled
      tags                      = georeplications.value.tags
    }
  }
}
