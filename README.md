<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure Container Registry

Terraform module for Azure Container Registry, in the Libre DevOps style: fast to get going,
secure by default, flexible when it matters.

[![CI](https://github.com/libre-devops/terraform-azurerm-azure-container-registry/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-azure-container-registry/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-azure-container-registry?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-azure-container-registry/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-azure-container-registry)](./LICENSE)

---

## Overview

```hcl
module "container_registry" {
  source  = "libre-devops/azure-container-registry/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids["rg-ldo-uks-dev-001"]
  location          = "uksouth"
  tags              = module.tags.tags

  container_registries = {
    "acrldouksdev001" = {}
  }
}
```

That single entry gets a Standard registry with secure defaults a bare registry does not give
you: the admin account is OFF (it is a shared-credential surface; use AcrPull/AcrPush role
assignments or a scoped token instead) and anonymous pull is OFF. Every default has an explicit
override.

- **Registries as a map.** Provision many registries in one call, each toggled and tuned on its
  own via `for_each`.
- **Premium features, guarded.** Georeplication and zone redundancy are Premium-only, and a
  validation rejects setting them on a Basic or Standard registry rather than letting the apply
  fail. `georeplications` is a list of regions, each with its own regional endpoint and zone
  redundancy.
- **Identity ready.** Attach a system and/or user assigned identity for customer-managed key
  encryption or pulling base images from another registry.
- **The full provider surface.** admin, anonymous pull, public network access, the export,
  quarantine, and trust policies, the retention policy, `network_rule_bypass_option`, and zone
  redundancy are all exposed. (The `network_rule_set` block was removed from the provider in
  azurerm 4.x; restrict access with `public_network_access_enabled` plus a private endpoint.)

## Examples

- [`examples/minimal`](./examples/minimal) - one Standard registry with the secure defaults,
  applied and verified in CI.
- [`examples/complete`](./examples/complete) - a Premium registry with a system-assigned
  identity, zone redundancy, a georeplication, a retention policy, and the export and quarantine
  policies set.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.80.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_container_registry.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container_registries"></a> [container\_registries](#input\_container\_registries) | Azure container registries keyed by name. Fast to get going: an entry with just a name gets a<br/>Standard registry with the admin account OFF, anonymous pull OFF, and public network access<br/>on, all overridable. Flexible when it matters: the full provider surface is here.<br/><br/>SECURE DEFAULTS overriding a bare registry: admin\_enabled false (the admin account is a<br/>shared-credential surface; use AcrPull/AcrPush role assignments or a token instead) and<br/>anonymous\_pull\_enabled false. sku defaults to Standard.<br/><br/>GEOREPLICATION and ZONE REDUNDANCY are Premium-only; a check enforces that georeplications<br/>are only set on a Premium registry. IDENTITY attaches a system and/or user assigned identity<br/>(for customer-managed keys or pulling base images from another registry). | <pre>map(object({<br/>    sku                           = optional(string, "Standard")<br/>    admin_enabled                 = optional(bool, false)<br/>    anonymous_pull_enabled        = optional(bool, false)<br/>    public_network_access_enabled = optional(bool, true)<br/>    data_endpoint_enabled         = optional(bool)<br/>    export_policy_enabled         = optional(bool)<br/>    quarantine_policy_enabled     = optional(bool)<br/>    trust_policy_enabled          = optional(bool)<br/>    retention_policy_in_days      = optional(number)<br/>    network_rule_bypass_option    = optional(string)<br/>    zone_redundancy_enabled       = optional(bool)<br/><br/>    identity = optional(object({<br/>      type         = string<br/>      identity_ids = optional(list(string))<br/>    }))<br/><br/>    georeplications = optional(list(object({<br/>      location                  = string<br/>      regional_endpoint_enabled = optional(bool)<br/>      zone_redundancy_enabled   = optional(bool)<br/>      tags                      = optional(map(string))<br/>    })), [])<br/><br/>    tags = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for all registries in this module. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Id of the resource group the registries live in; the module parses the name from it. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all registries; per-registry tags override these. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_registries"></a> [container\_registries](#output\_container\_registries) | Map of registry name to the full container registry object. |
| <a name="output_container_registry_ids"></a> [container\_registry\_ids](#output\_container\_registry\_ids) | Map of registry name to id. |
| <a name="output_container_registry_ids_zipmap"></a> [container\_registry\_ids\_zipmap](#output\_container\_registry\_ids\_zipmap) | Map of registry name to { name, id } for easy composition. |
| <a name="output_identity_principal_ids"></a> [identity\_principal\_ids](#output\_identity\_principal\_ids) | Map of registry name to { system\_assigned } principal id (null where absent). |
| <a name="output_login_servers"></a> [login\_servers](#output\_login\_servers) | Map of registry name to its login server (the pull/push host). |
<!-- END_TF_DOCS -->
