# terraform-azure

Reusable Terraform modules for Azure Storage Account, Key Vault (secrets and keys), Function App, CDN, Virtual Network, Load Balancer, Application Gateway, Network Security Groups, Container Registry, Azure DevOps-style CI/CD patterns, RBAC roles, Virtual Machines, PostgreSQL Flexible Server, API Management, Service Bus, Storage Queue, AKS, Container Apps, Azure Files, and Event Hubs, deployed per environment.

## Structure

```
terraform-azure/
├── modules/
│   ├── resource-group/
│   ├── storage-account/
│   ├── key-vault/
│   ├── key-vault-secret/
│   ├── key-vault-key/
│   ├── function-app/
│   ├── cdn/
│   ├── vnet/
│   ├── load-balancer/
│   ├── application-gateway/
│   ├── nsg/
│   ├── container-registry/
│   ├── rbac-role/
│   ├── virtual-machine/
│   ├── postgresql-flexible/
│   ├── api-management/
│   ├── service-bus-topic/
│   ├── service-bus-queue/
│   ├── storage-queue/
│   ├── aks/
│   ├── container-apps/
│   ├── storage-share/
│   └── event-hubs/
└── environments/
    └── prod/
        ├── backend.tf
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── versions.tf
        └── terraform.tfvars.example
```

Add more environments by copying `environments/prod` to `environments/dev`, `environments/staging`, etc.

## AWS to Azure module mapping

| AWS module | Azure module |
|------------|--------------|
| `s3` | `storage-account` |
| `secrets-manager` | `key-vault-secret` |
| `kms` | `key-vault-key` |
| — | `key-vault` (vault container; required before secrets/keys) |
| — | `resource-group` (Azure foundation) |
| `lambda` | `function-app` |
| `cloudfront` | `cdn` |
| `vpc` | `vnet` |
| `alb` | `application-gateway` |
| `nlb` | `load-balancer` |
| `security-group` | `nsg` |
| `codebuild` / `codepipeline` | Use Azure DevOps or GitHub Actions outside Terraform, or `container-registry` tasks |
| `iam-policy` / `iam-role` / `iam-user` | `rbac-role` |
| `ec2` | `virtual-machine` |
| `rds` | `postgresql-flexible` |
| `apigateway` | `api-management` |
| `sns` | `service-bus-topic` |
| `sqs` | `service-bus-queue` or `storage-queue` |
| `eks` | `aks` |
| `ecr` | `container-registry` |
| `ecs` | `container-apps` |
| `efs` | `storage-share` |
| `cognito` | Use [Microsoft Entra External ID](https://aka.ms/EEIDOverview) (not Terraform-managed in this repo) |
| `msk` | `event-hubs` |

## How it works

Each **environment** (e.g. `prod`) manages all resources for that environment in one place:

| `terraform.tfvars` block | Module |
|--------------------------|--------|
| `resource_groups` | Resource Group |
| `storage_accounts` | Storage Account |
| `key_vaults` | Key Vault |
| `key_vault_secrets` | Key Vault Secret |
| `key_vault_keys` | Key Vault Key |
| `function_apps` | Function App |
| `cdn_profiles` | CDN |
| `vnets` | Virtual Network |
| `load_balancers` | Load Balancer (L4) |
| `application_gateways` | Application Gateway (L7) |
| `network_security_groups` | Network Security Group |
| `container_registries` | Container Registry |
| `rbac_roles` | RBAC / Managed Identity |
| `virtual_machines` | Virtual Machine |
| `postgresql_servers` | PostgreSQL Flexible Server |
| `api_management_services` | API Management |
| `service_bus_topics` | Service Bus Topic |
| `service_bus_queues` | Service Bus Queue |
| `storage_queues` | Storage Queue |
| `aks_clusters` | AKS |
| `container_apps` | Container Apps |
| `storage_shares` | Azure Files |
| `event_hubs_namespaces` | Event Hubs |

Each module includes a **`terraform.tfvars.example`** alongside its README with focused configuration examples. Copy the blocks you need into `environments/prod/terraform.tfvars`.

Modules are independent. Omit any block from `terraform.tfvars` when you are not managing that resource type. No empty `{}` required.

Outputs are grouped under `environment` and only include resource types you configure.

## Prerequisites

- **Storage account** for Terraform state (already created)
- **Container** named `tfstate` in the storage account

| Environment | State key |
|-------------|-----------|
| prod | `terraform-azure/prod/terraform.tfstate` |

Environment providers:

- `azurerm` — primary region (`azure_location`)
- `azurerm.replica` — secondary region for geo-redundant resources (`azure_replica_location`)
- `random` — generated passwords for secrets and databases
- `archive` — Function App package zip builds

Authenticate with Azure CLI (`az login`) or service principal environment variables before running Terraform.

## Quick start (prod)

```bash
cd environments/prod
cp terraform.tfvars.example terraform.tfvars
# edit backend.tf and terraform.tfvars
terraform init
terraform plan
terraform apply
```

```bash
terraform output environment
```

## Key Vault dependency order

Secrets and keys live inside a Key Vault. Create vaults first, then reference them from secrets/keys:

```hcl
key_vaults = {
  app = {
    name = "my-company-kv-prod"
  }
}

key_vault_secrets = {
  app-config = {
    name         = "app-config"
    vault_key    = "app"
    secret_value = "change-me-in-ci"
  }
}
```

## Function App deployment packages

Zip-based Function Apps load code from a Storage Account blob. The storage account **must be in the same region** as the Function App.

```hcl
storage_accounts = {
  function-artifacts = {
    account_name = "myfuncartifactsprod"
  }
}

function_apps = {
  api-handler = {
    name               = "my-api-handler-prod"
    storage_account_key = "function-artifacts"
    package_source_dir  = "function-src/api-handler"
  }
}
```

## Module documentation

Each module under `modules/` has a README and `terraform.tfvars.example`:

- [modules/aks/README.md](modules/aks/README.md)
- [modules/api-management/README.md](modules/api-management/README.md)
- [modules/application-gateway/README.md](modules/application-gateway/README.md)
- [modules/cdn/README.md](modules/cdn/README.md)
- [modules/container-apps/README.md](modules/container-apps/README.md)
- [modules/container-registry/README.md](modules/container-registry/README.md)
- [modules/event-hubs/README.md](modules/event-hubs/README.md)
- [modules/function-app/README.md](modules/function-app/README.md)
- [modules/key-vault/README.md](modules/key-vault/README.md)
- [modules/key-vault-key/README.md](modules/key-vault-key/README.md)
- [modules/key-vault-secret/README.md](modules/key-vault-secret/README.md)
- [modules/load-balancer/README.md](modules/load-balancer/README.md)
- [modules/nsg/README.md](modules/nsg/README.md)
- [modules/postgresql-flexible/README.md](modules/postgresql-flexible/README.md)
- [modules/rbac-role/README.md](modules/rbac-role/README.md)
- [modules/resource-group/README.md](modules/resource-group/README.md)
- [modules/service-bus-queue/README.md](modules/service-bus-queue/README.md)
- [modules/service-bus-topic/README.md](modules/service-bus-topic/README.md)
- [modules/storage-account/README.md](modules/storage-account/README.md)
- [modules/storage-queue/README.md](modules/storage-queue/README.md)
- [modules/storage-share/README.md](modules/storage-share/README.md)
- [modules/virtual-machine/README.md](modules/virtual-machine/README.md)
- [modules/vnet/README.md](modules/vnet/README.md)

Never commit real secret values to version control.
