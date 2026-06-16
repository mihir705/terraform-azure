terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstateuse1mihir"
    container_name       = "tfstate"
    key                  = "terraform-azure/prod/terraform.tfstate"
  }
}
