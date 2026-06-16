# Container Apps Module

Terraform module to create an Azure Container Apps Environment and Container Apps with scale rules, ingress, and optional secrets from Key Vault.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_log_analytics_workspace` | No | Created when `create_log_analytics_workspace = true` |
| `azurerm_container_app_environment` | Yes | Container Apps Environment |
| `azurerm_container_app` | Yes | One per `container_apps` entry |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |
| [Random Provider](https://registry.terraform.io/providers/hashicorp/random/latest) | >= 3.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples.

### Web API with HTTP scaling

```hcl
container_app_environments = {
  platform = {
    name                = "my-company-cae-prod"
    resource_group_name = "my-company-rg-prod"
    location            = "eastus"
    vnet_key            = "main"
    subnet_key          = "container-apps"

    container_apps = {
      api = {
        ingress = {
          external_enabled = true
          target_port      = 8080
        }

        template = {
          min_replicas = 1
          max_replicas = 10
          containers = {
            api = {
              name  = "api"
              image = "mycompanyprod.azurecr.io/api:latest"
              cpu   = 0.5
              memory = "1Gi"
            }
          }
          scale_rules = [
            {
              name = "http-scaling"
              http = { concurrent_requests = "100" }
            }
          ]
        }
      }
    }

    tags = { Purpose = "platform" }
  }
}
```

## Environment-level wiring

| Field | Resolves from |
|-------|----------------|
| `vnet_key` + `subnet_key` | Delegated infrastructure subnet from VNet module |
| `secrets.*.key_vault_secret_id` | Key Vault module |
| `secrets.*.identity` | User-assigned identity with Key Vault access |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Environment name | `string` | — | yes |
| `resource_group_name` | Resource group | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `infrastructure_subnet_id` | Delegated subnet | `string` | `null` | no |
| `container_apps` | Container apps map | `map(object)` | — | yes |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `environment_id` | Container Apps Environment ID |
| `default_domain` | Default domain suffix |
| `container_app_fqdns` | App FQDNs by logical name |
| `latest_revision_names` | Latest revision names |

## Notes

- Provide a **delegated subnet** (`Microsoft.App/environments`) for VNet-integrated environments.
- Key Vault secrets require a **user-assigned managed identity** with Get permission on the vault.
- HTTP scale rules use KEDA; set `min_replicas = 0` for scale-to-zero.
