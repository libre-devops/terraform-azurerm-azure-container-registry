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
