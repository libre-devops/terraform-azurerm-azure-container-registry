```hcl
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
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_container_registry.acr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry) | resource |
| [azurerm_container_registry_agent_pool.agent_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry_agent_pool) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_registries"></a> [registries](#input\_registries) | List of registry configurations. | <pre>list(object({<br>    name                          = string<br>    rg_name                       = string<br>    location                      = string<br>    admin_enabled                 = optional(bool, false)<br>    sku                           = optional(string, "Standard")<br>    public_network_access_enabled = optional(bool, true)<br>    trust_policy_enabled          = optional(bool, false)<br>    retention_policy_in_days      = optional(number)<br>    quarantine_policy_enabled     = optional(bool, false)<br>    zone_redundancy_enabled       = optional(bool, false)<br>    export_policy_enabled         = optional(bool, false)<br>    data_endpoint_enabled         = optional(bool, false)<br>    anonymous_pull_enabled        = optional(bool, false)<br>    network_rule_bypass_option    = optional(string, "AzureServices")<br>    georeplications = optional(list(object({<br>      location                  = string<br>      regional_endpoint_enabled = optional(bool)<br>      zone_redundancy_enabled   = optional(bool)<br>      tags                      = optional(map(string))<br>    })))<br>    network_rule_set = optional(object({<br>      default_action = string<br>      ip_rule = optional(list(object({<br>        action   = string<br>        ip_range = string<br>      })))<br>      virtual_network = optional(list(object({<br>        action    = string<br>        subnet_id = string<br>      })))<br>    }))<br>    identity_type = optional(string)<br>    identity_ids  = optional(list(string))<br>    encryption = optional(object({<br>      key_vault_key_id   = optional(string)<br>      identity_client_id = optional(string)<br>    }))<br>    tags = optional(map(string))<br>    agent_pool = optional(list(object({<br>      name                      = string<br>      instance_count            = optional(number, 1)<br>      tier                      = optional(string, "S1")<br>      virtual_network_subnet_id = optional(string)<br>      tags                      = optional(map(string))<br>    })))<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acr_admin_password"></a> [acr\_admin\_password](#output\_acr\_admin\_password) | The Username associated with the Container Registry Admin account - if the admin account is enabled. |
| <a name="output_acr_admin_username"></a> [acr\_admin\_username](#output\_acr\_admin\_username) | The Username associated with the Container Registry Admin account - if the admin account is enabled. |
| <a name="output_acr_id"></a> [acr\_id](#output\_acr\_id) | The ID of the Container Registry |
| <a name="output_acr_login_server"></a> [acr\_login\_server](#output\_acr\_login\_server) | The URL that can be used to log into the container registry |
| <a name="output_acr_principal_id"></a> [acr\_principal\_id](#output\_acr\_principal\_id) | Client ID of system assigned managed identity if created |
