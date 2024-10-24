# Azure Service Principal Rotator

This Azure Function App automates the rotation of credentials for Azure App Registrations. It utilizes Azure Managed Identity and Key Vault to securely manage and rotate credentials, enhancing security and compliance.

## Table of Contents

- [Overview](#overview)
- [Environment Variables](#environment-variables)
- [Setup and Deployment](#setup-and-deployment)
  - [Terraform Deployment](#terraform-deployment)
- [Usage](#usage)

## Overview

The `RotatorFunction` is designed to:

- Find App Registrations with credentials nearing expiration.
- Rotate credentials automatically.
- Optionally clean up old password credentials.

By running this function on a scheduled basis, you can ensure that all App Registrations maintain up-to-date credentials without manual intervention.

## Environment Variables

The function relies on several environment variables:

- `MANAGED_IDENTITY_CLIENT_ID`: The Client ID of the Managed Identity used for authentication.
- `KEY_VAULT_URL`: The URL of your Azure Key Vault (e.g., `https://<your-key-vault-name>.vault.azure.net/`).
- `ROTATION_INTERVAL`: The rotation interval in days (integer value).
- `RUN_CLEANUP` (optional): Set to `1` to enable cleanup of old credentials. Defaults to `0`.

## Setup and Deployment

### Terraform Deployment

You can deploy the Azure Function and all its dependencies using Terraform. The provided Terraform configuration sets up the necessary resources, including the Function App, Storage Account, Key Vault access, and Managed Identity.

#### Requirements

Ensure you have the following installed:

- **Terraform**: Version compatible with the providers listed in the [Terraform Docs](#terraform-documentation)
- **Azure CLI**: For authentication.

#### Usage

1. **Initialize Terraform**

   ```bash
   terraform init
   ```

2. **Plan the Deployment**

   ```bash
   terraform plan -out=tfplan
   ```

3. **Apply the Deployment**

   ```bash
   terraform apply tfplan
   ```

4. **Provide the Required Variables**

   You can pass variables via command-line options or a `terraform.tfvars` file.

   Example `terraform.tfvars`:

   ```hcl
   environment                       = "example"
   location                          = "eastus"
   project                           = "sp-rotator"
   subscription_id                   = "<your-subscription-id>"
   target_key_vault_name             = "<your-key-vault-name>"
   target_key_vault_resource_group_name = "<your-key-vault-rg-name>"
   target_key_vault_rotation_interval_in_days = 30
   public_network_access_enabled     = true
   run_cleanup                       = 1
   ```

5. **Post-Deployment**

   - The Function App will be deployed, and the code will be uploaded.
   - Managed Identity will have the necessary permissions assigned.
   - Environment variables will be set in the Function App configuration.

#### Terraform Documentation

<details>
<summary>Click to expand Terraform documentation</summary>

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~>2.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~>3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~>4.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~>3.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~>3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.6.0 |
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | 3.0.2 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.5.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.3 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_app_role_assignment.msgraph_application_readwrite_all](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment) | resource |
| [azuread_app_role_assignment.msgraph_user_read_all](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment) | resource |
| [azurerm_application_insights.ai](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_linux_function_app.fa](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_linux_function_app_slot.staging](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app_slot) | resource |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.key_vault_secrets_officer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.sa_sbdo](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.sa_share_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.subnet_network_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_service_plan.sp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_storage_account.sa](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_subnet.subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_user_assigned_identity.identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [null_resource.deploy](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_id.rid](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [archive_file.func](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [azuread_application_published_app_ids.well_known](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/application_published_app_ids) | data source |
| [azuread_service_principal.msgraph](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |
| [azurerm_key_vault.kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | The environment of the resources | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The location of the resources | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | The name of the project | `string` | n/a | yes |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | If true, the function app will be accessible from the public internet | `bool` | `true` | no |
| <a name="input_run_cleanup"></a> [run\_cleanup](#input\_run\_cleanup) | If 1, the function will remove any old keys | `number` | `0` | no |
| <a name="input_subnet_base_cidr"></a> [subnet\_base\_cidr](#input\_subnet\_base\_cidr) | The base CIDR for the subnets | `string` | `""` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Azure Subscription ID | `string` | n/a | yes |
| <a name="input_target_key_vault_name"></a> [target\_key\_vault\_name](#input\_target\_key\_vault\_name) | The name of the key vault | `string` | n/a | yes |
| <a name="input_target_key_vault_resource_group_name"></a> [target\_key\_vault\_resource\_group\_name](#input\_target\_key\_vault\_resource\_group\_name) | The name of the resource group the key vault is in | `string` | n/a | yes |
| <a name="input_target_key_vault_rotation_interval_in_days"></a> [target\_key\_vault\_rotation\_interval\_in\_days](#input\_target\_key\_vault\_rotation\_interval\_in\_days) | The number of days between key rotations | `number` | n/a | yes |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name) | The name of the virtual network | `string` | `""` | no |
| <a name="input_virtual_network_resource_group_name"></a> [virtual\_network\_resource\_group\_name](#input\_virtual\_network\_resource\_group\_name) | The name of the resource group the virtual network is in | `string` | `""` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->