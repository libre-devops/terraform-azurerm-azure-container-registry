variable "container_registries" {
  description = <<-DESC
    Azure container registries keyed by name. Fast to get going: an entry with just a name gets a
    Standard registry with the admin account OFF, anonymous pull OFF, and public network access
    on, all overridable. Flexible when it matters: the full provider surface is here.

    SECURE DEFAULTS overriding a bare registry: admin_enabled false (the admin account is a
    shared-credential surface; use AcrPull/AcrPush role assignments or a token instead) and
    anonymous_pull_enabled false. sku defaults to Standard.

    GEOREPLICATION and ZONE REDUNDANCY are Premium-only; a check enforces that georeplications
    are only set on a Premium registry. IDENTITY attaches a system and/or user assigned identity
    (for customer-managed keys or pulling base images from another registry).
  DESC
  type = map(object({
    sku                           = optional(string, "Standard")
    admin_enabled                 = optional(bool, false)
    anonymous_pull_enabled        = optional(bool, false)
    public_network_access_enabled = optional(bool, true)
    data_endpoint_enabled         = optional(bool)
    export_policy_enabled         = optional(bool)
    quarantine_policy_enabled     = optional(bool)
    trust_policy_enabled          = optional(bool)
    retention_policy_in_days      = optional(number)
    network_rule_bypass_option    = optional(string)
    zone_redundancy_enabled       = optional(bool)

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    georeplications = optional(list(object({
      location                  = string
      regional_endpoint_enabled = optional(bool)
      zone_redundancy_enabled   = optional(bool)
      tags                      = optional(map(string))
    })), [])

    tags = optional(map(string))
  }))
  default = {}

  validation {
    condition     = alltrue([for r in values(var.container_registries) : contains(["Basic", "Standard", "Premium"], r.sku)])
    error_message = "sku must be one of Basic, Standard, or Premium."
  }

  validation {
    condition     = alltrue([for r in values(var.container_registries) : length(r.georeplications) == 0 || r.sku == "Premium"])
    error_message = "georeplications require a Premium sku."
  }

  validation {
    condition     = alltrue([for r in values(var.container_registries) : !coalesce(r.zone_redundancy_enabled, false) || r.sku == "Premium"])
    error_message = "zone_redundancy_enabled requires a Premium sku."
  }

  validation {
    condition     = alltrue([for r in values(var.container_registries) : r.network_rule_bypass_option == null || contains(["AzureServices", "None"], r.network_rule_bypass_option)])
    error_message = "network_rule_bypass_option must be AzureServices or None."
  }
}

variable "location" {
  description = "Azure region for all registries in this module."
  type        = string
}

variable "resource_group_id" {
  description = "Id of the resource group the registries live in; the module parses the name from it."
  type        = string
}

variable "tags" {
  description = "Tags applied to all registries; per-registry tags override these."
  type        = map(string)
  default     = {}
}
