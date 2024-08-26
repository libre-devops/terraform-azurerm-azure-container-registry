resource "random_string" "random" {
  length  = 6
  special = false
}

locals {
  vnet_address_space  = "10.0.0.0/16"
  now                 = timestamp()
  seven_days_from_now = timeadd(timestamp(), "168h")
}

module "rg" {
  source = "libre-devops/rg/azurerm"

  rg_name  = "rg-${var.short}-${var.loc}-${var.env}-${random_string.random.result}"
  location = local.location
  tags     = local.tags
}

module "subnet_calculator" {
  source = "github.com/libre-devops/terraform-null-subnet-calculator"

  base_cidr    = local.vnet_address_space
  subnet_sizes = [24]
}

module "network" {
  source = "registry.terraform.io/libre-devops/network/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  vnet_name          = "vnet-${var.short}-${var.loc}-${var.env}-${random_string.random.result}"
  vnet_location      = module.rg.rg_location
  vnet_address_space = module.subnet_calculator.base_cidr_set

  subnets = {
    for i, name in module.subnet_calculator.subnet_names :
    name => {
      address_prefixes  = toset([module.subnet_calculator.subnet_ranges[i]])
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      delegation = [
        {
          type = "Microsoft.ContainerInstance/containerGroups"
        }
      ]
    }
  }
}

resource "azurerm_user_assigned_identity" "uid" {
  name                = "uid-${var.short}-${var.loc}-${var.env}-${random_string.random.result}"
  resource_group_name = module.rg.rg_name
  location            = module.rg.rg_location
  tags                = module.rg.rg_tags
}

resource "azurerm_role_assignment" "contributor" {
  principal_id         = azurerm_user_assigned_identity.uid.principal_id
  scope                = module.rg.rg_id
  role_definition_name = "Contributor"
}

module "container_registry" {
  source = "../../"

  depends_on = [
    random_string.random
  ]

  registries = [
    {
      name                  = "acr${var.short}${var.loc}${var.env}01"
      rg_name               = module.rg.rg_name
      location              = module.rg.rg_location
      tags                  = module.rg.rg_tags
      admin_enabled         = true
      sku                   = "Basic"
      export_policy_enabled = true
      identity_type         = "UserAssigned"
      identity_ids          = [azurerm_user_assigned_identity.uid.id]
    },
  ]
}

resource "null_resource" "azure_cli_login" {
  provisioner "local-exec" {
    command = <<EOT
      az login --service-principal \
        --username $ARM_CLIENT_ID \
        --password $ARM_CLIENT_SECRET \
        --tenant $ARM_TENANT_ID
    EOT
    environment = {
      ARM_SUBSCRIPTION_ID = "$ARM_SUBSCRIPTION_ID"
    }
  }
}

locals {
  container_repo    = "azdo-agent-containers"
  container_to_pull = "ghcr.io/libre-devops/azdo-agent-containers/default:latest"
}

resource "null_resource" "import_image" {
  provisioner "local-exec" {
    command = <<EOT
      az acr import --name ${module.container_registry.registry_names[0]} \
        --source ${local.container_to_pull} \
        --image ${local.container_repo}/default:latest
    EOT
  }

  depends_on = [null_resource.azure_cli_login, module.container_registry]
}

resource "azurerm_container_group" "agent_container" {

  depends_on = [
    azurerm_role_assignment.contributor
  ]

  name                = "aci-${var.short}-${var.loc}-${var.env}-${random_string.random.result}"
  location            = module.rg.rg_location
  resource_group_name = module.rg.rg_name
  tags                = module.rg.rg_tags
  os_type             = "Linux"
  ip_address_type     = "Public"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uid.id]
  }

  container {
    name   = "agent1"
    image  = "${module.container_registry.registry_login_servers[0]}/${local.container_repo}/default:latest"
    cpu    = "2"
    memory = "8"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      AZP_URL   = var.AZP_URL
      AZP_TOKEN = var.AZP_TOKEN
      AZP_POOL  = var.AZP_POOL
    }
  }

  image_registry_credential {
    server                    = module.container_registry.registry_login_servers[0]
    user_assigned_identity_id = azurerm_user_assigned_identity.uid.id
  }
}
