# Application Gateway Module

Terraform module to create an Azure Application Gateway v2 (L7 load balancer), mirroring the AWS ALB module.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_application_gateway` | Yes | Standard_v2 or WAF_v2 |
| `azurerm_public_ip` | No | Created for internet-facing gateways |

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| azurerm | >= 3.100 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example).

```hcl
module "web_gateway" {
  source = "./modules/application-gateway"

  name                = "my-web-gateway-prod"
  resource_group_name = "my-rg-prod"
  location            = "eastus"
  vnet_id             = module.vnet.vnet_id
  subnet_id           = module.vnet.public_subnet_ids["public-a"]

  target_groups = {
    app = {
      port     = 8080
      protocol = "Http"
      targets = [
        { ip_address = "10.0.1.4" }
      ]
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "Http"
      default_action = {
        type             = "forward"
        target_group_key = "app"
      }
    }
  }

  tags = {
    Environment = "prod"
  }
}
```

## Inputs

See [variables.tf](./variables.tf) for the full list.

## Outputs

| Name | Description |
|------|-------------|
| `application_gateway_id` | Application Gateway resource ID |
| `application_gateway_name` | Application Gateway name |
| `public_ip_address` | Public IP address when internet-facing |
| `backend_pool_names` | Backend pool names by target group key |
| `listener_names` | Listener names by listener key |

## Notes

- Application Gateway requires a dedicated subnet (`/24` or larger).
- Enable `enable_waf = true` for WAF_v2 SKU with OWASP 3.2 rules.
- HTTPS listeners require Key Vault certificate integration (extend module as needed).
