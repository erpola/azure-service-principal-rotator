terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~>3.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix}-rg"
  location = var.location
  tags     = local.tags
}

resource "random_id" "rid" {
  byte_length = 2
}