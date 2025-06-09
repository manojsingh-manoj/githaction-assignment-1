terraform {
  backend "azurerm" {
    resource_group_name  = "rg-storage-assignment1"
    storage_account_name = "manojsingh04062025"
    container_name       = "tfstate"
    #key                  = "terraform.tfstate"
  }
}