# Tests for the module. azurerm is mocked (no credentials, no cloud):
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {}

variables {
  resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001"
  location          = "uksouth"
  tags              = { Environment = "tst" }
}

# One registry, nothing but a name: Standard sku with the secure defaults (admin off, anonymous
# pull off).
run "fast_to_get_going" {
  command = apply

  variables {
    container_registries = {
      "acrldouksdev001" = {}
    }
  }

  assert {
    condition     = azurerm_container_registry.this["acrldouksdev001"].sku == "Standard"
    error_message = "sku should default to Standard."
  }

  assert {
    condition     = azurerm_container_registry.this["acrldouksdev001"].admin_enabled == false
    error_message = "The admin account should default off."
  }

  assert {
    condition     = azurerm_container_registry.this["acrldouksdev001"].anonymous_pull_enabled == false
    error_message = "Anonymous pull should default off."
  }
}

# A Premium registry with georeplication, zone redundancy, and a system-assigned identity.
run "premium_georeplicated" {
  command = apply

  variables {
    container_registries = {
      "acrldouksprd001" = {
        sku                     = "Premium"
        zone_redundancy_enabled = true
        identity                = { type = "SystemAssigned" }
        georeplications = [
          { location = "northeurope", zone_redundancy_enabled = true }
        ]
      }
    }
  }

  assert {
    condition     = length(azurerm_container_registry.this["acrldouksprd001"].georeplications) == 1
    error_message = "The georeplication should be configured."
  }

  assert {
    condition     = azurerm_container_registry.this["acrldouksprd001"].identity[0].type == "SystemAssigned"
    error_message = "The system-assigned identity should be attached."
  }
}

run "rejects_georeplication_without_premium" {
  command = plan

  variables {
    container_registries = {
      "acrldoukstst001" = {
        sku             = "Standard"
        georeplications = [{ location = "northeurope" }]
      }
    }
  }

  expect_failures = [var.container_registries]
}

run "rejects_zone_redundancy_without_premium" {
  command = plan

  variables {
    container_registries = {
      "acrldoukstst001" = {
        sku                     = "Standard"
        zone_redundancy_enabled = true
      }
    }
  }

  expect_failures = [var.container_registries]
}

run "rejects_bad_sku" {
  command = plan

  variables {
    container_registries = {
      "acrldoukstst001" = { sku = "Ultra" }
    }
  }

  expect_failures = [var.container_registries]
}
