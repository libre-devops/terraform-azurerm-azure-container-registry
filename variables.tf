variable "registries" {
  description = "List of registry configurations."
  type = list(object({
    name                          = string
    rg_name                       = string
    location                      = string
    admin_enabled                 = optional(bool, false)
    sku                           = optional(string, "Standard")
    public_network_access_enabled = optional(bool, true)
    trust_policy_enabled          = optional(bool, false)
    retention_policy_in_days      = optional(number)
    quarantine_policy_enabled     = optional(bool, false)
    zone_redundancy_enabled       = optional(bool, false)
    export_policy_enabled         = optional(bool, false)
    data_endpoint_enabled         = optional(bool, false)
    anonymous_pull_enabled        = optional(bool, false)
    network_rule_bypass_option    = optional(string, "AzureServices")
    georeplications = optional(list(object({
      location                  = string
      regional_endpoint_enabled = optional(bool)
      zone_redundancy_enabled   = optional(bool)
      tags                      = optional(map(string))
    })))
    network_rule_set = optional(object({
      default_action = string
      ip_rule = optional(list(object({
        action   = string
        ip_range = string
      })))
      virtual_network = optional(list(object({
        action    = string
        subnet_id = string
      })))
    }))
    identity_type = optional(string)
    identity_ids  = optional(list(string))
    encryption = optional(object({
      key_vault_key_id   = optional(string)
      identity_client_id = optional(string)
    }))
    tags = optional(map(string))
    agent_pool = optional(list(object({
      name                      = string
      instance_count            = optional(number, 1)
      tier                      = optional(string, "S1")
      virtual_network_subnet_id = optional(string)
      tags                      = optional(map(string))
    })))
  }))
  default = []
}
