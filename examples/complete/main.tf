# The module's full surface: a Premium registry with a system-assigned identity, zone
# redundancy, a georeplication to a second region, a retention policy, and the export and
# quarantine policies set. Applied then destroyed in one CI run.
locals {
  location = lookup(var.regions, var.loc, "uksouth")
  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  acr_name = "acr${var.short}${var.loc}${terraform.workspace}002"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
  additional_tags = { Application = "terraform-azurerm-azure-container-registry" }
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

module "container_registry" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  container_registries = {
    (local.acr_name) = {
      sku                        = "Premium"
      zone_redundancy_enabled    = true
      retention_policy_in_days   = 7
      export_policy_enabled      = true
      quarantine_policy_enabled  = true
      network_rule_bypass_option = "AzureServices"

      identity = { type = "SystemAssigned" }

      georeplications = [
        { location = "ukwest", regional_endpoint_enabled = true, zone_redundancy_enabled = false }
      ]
    }
  }
}

output "login_server" {
  value = module.container_registry.login_servers[local.acr_name]
}

output "registry_id" {
  value = module.container_registry.container_registry_ids[local.acr_name]
}

output "resource_group_name" {
  value = local.rg_name
}
