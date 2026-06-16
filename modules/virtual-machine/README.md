# Virtual Machine Module

Terraform module to create an Azure Linux virtual machine with a network interface, optional public IP, managed OS/data disks, cloud-init/custom data, and optional managed identity.

## Resources created

| Resource | Always created | Notes |
|----------|----------------|-------|
| `azurerm_linux_virtual_machine` | Yes | Linux VM with managed OS disk |
| `azurerm_network_interface` | Yes | Primary NIC |
| `azurerm_public_ip` | No | Created when `create_public_ip = true` |
| `azurerm_network_interface_security_group_association` | No | When `nsg_id` is set |
| `azurerm_managed_disk` | No | One per `data_disks` entry |
| `azurerm_virtual_machine_data_disk_attachment` | No | Attaches data disks |

## Requirements

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | >= 1.5.0 |
| [AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | >= 3.100 |
| [Random Provider](https://registry.terraform.io/providers/hashicorp/random/latest) | >= 3.0 |

## Usage

See [terraform.tfvars.example](./terraform.tfvars.example) for copy-paste examples.

### Private app server

```hcl
virtual_machines = {
  app = {
    name                = "my-company-app-prod"
    resource_group_name = "my-company-rg-prod"
    location            = "eastus"
    size                = "Standard_B2s"
    admin_username      = "azureuser"
    vnet_key            = "main"
    subnet_key          = "private-a"
    nsg_key             = "app"

    source_image_reference = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"
    }

    admin_ssh_key = {
      username   = "azureuser"
      public_key = file("~/.ssh/id_rsa.pub")
    }

    tags = { Purpose = "application-server" }
  }
}
```

When `vnet_key` is set, the environment stack resolves `subnet_id` from the virtual network module using `subnet_key`, and `nsg_id` from `nsg_key`.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | VM name | `string` | — | yes |
| `resource_group_name` | Resource group | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `subnet_id` | Subnet for NIC | `string` | — | yes |
| `size` | VM size | `string` | — | yes |
| `admin_username` | Admin username | `string` | — | yes |
| `source_image_reference` / `source_image_id` | Image source | `object` | `null` | yes* |
| `nsg_id` | NSG for NIC | `string` | `null` | no |
| `create_public_ip` | Attach public IP | `bool` | `false` | no |
| `custom_data` | Cloud-init script | `string` | `null` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vm_id` | Virtual machine ID |
| `private_ip_address` | Primary private IP |
| `public_ip_address` | Public IP when created |
| `network_interface_id` | NIC ID |
| `os_disk_id` | OS managed disk ID |

## Notes

- **Password auth** is disabled by default; provide `admin_ssh_key` or set `disable_password_authentication = false` with a password.
- OS disks default to **Premium_LRS** with ReadWrite caching.
- Use `create_public_ip` in a public subnet for bastion-style access.
