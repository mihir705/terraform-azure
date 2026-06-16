# Key Vault Key Module

Terraform module to create a cryptographic key in an Azure Key Vault, mirroring the AWS KMS module.

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| azurerm | >= 3.100 |

## Usage

Create a vault first, then reference it by key:

```hcl
key_vault_keys = {
  app-encryption = {
    name      = "app-encryption"
    vault_key = "app"
    key_type  = "RSA"
    key_size  = 2048
    key_opts  = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
  }
}
```

See [terraform.tfvars.example](./terraform.tfvars.example).

## Outputs

| Name | Description |
|------|-------------|
| `key_id` | Key Vault key versionless ID |
| `key_vault_id` | Parent Key Vault ID |
| `key_name` | Key name |
