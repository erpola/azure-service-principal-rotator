resource "azurerm_service_plan" "sp" {
  name                = "${local.prefix}-spl"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "P1v2"
  tags                = local.tags
}

resource "azurerm_user_assigned_identity" "identity" {
  name                = "${local.prefix}${random_id.rid.hex}-fa-identity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_linux_function_app" "fa" {
  name                          = "${local.prefix}${random_id.rid.hex}-fa"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  service_plan_id               = azurerm_service_plan.sp.id
  storage_account_name          = azurerm_storage_account.sa.name
  storage_account_access_key    = azurerm_storage_account.sa.primary_access_key
  virtual_network_subnet_id     = length(azurerm_subnet.subnet) > 0 ? azurerm_subnet.subnet[0].id : null
  public_network_access_enabled = (length(azurerm_subnet.subnet) > 0 && var.public_network_access_enabled != true) ? false : true
  tags                          = local.tags

  depends_on = [
    azuread_app_role_assignment.msgraph_application_readwrite_all,
    azuread_app_role_assignment.msgraph_user_read_all
  ]

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "python",
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true",
    "AzureWebJobsFeatureFlags"       = "EnableWorkerIndexing",
    "KEY_VAULT_URL"                  = data.azurerm_key_vault.kv.vault_uri,
    "ROTATION_INTERVAL"              = var.target_key_vault_rotation_interval_in_days,
    "RUN_CLEANUP"                    = var.run_cleanup
    "MANAGED_IDENTITY_CLIENT_ID"     = azurerm_user_assigned_identity.identity.client_id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity.id]
  }

  site_config {
    always_on = true

    application_stack {
      python_version = "3.10"
    }

    application_insights_key               = azurerm_application_insights.ai.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.ai.connection_string
  }

  lifecycle {
    ignore_changes = [
      tags["hidden-link: /app-insights-conn-string"],
      tags["hidden-link: /app-insights-instrumentation-key"],
      tags["hidden-link: /app-insights-resource-id"]
    ]
  }
}

resource "azurerm_linux_function_app_slot" "staging" {
  name                       = "staging"
  function_app_id            = azurerm_linux_function_app.fa.id
  storage_account_name       = azurerm_linux_function_app.fa.storage_account_name
  storage_account_access_key = azurerm_linux_function_app.fa.storage_account_access_key
  virtual_network_subnet_id  = azurerm_linux_function_app.fa.virtual_network_subnet_id
  app_settings               = azurerm_linux_function_app.fa.app_settings
  tags                       = local.tags

  dynamic "identity" {
    for_each = azurerm_linux_function_app.fa.identity
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "site_config" {
    for_each = azurerm_linux_function_app.fa.site_config
    content {
      application_insights_connection_string = site_config.value.application_insights_connection_string
      application_insights_key               = site_config.value.application_insights_key
      always_on                              = true
      dynamic "application_stack" {
        for_each = site_config.value.application_stack
        content {
          python_version = application_stack.value.python_version
        }
      }
    }
  }
}

resource "null_resource" "deploy" {
  depends_on = [azurerm_linux_function_app.fa]

  triggers = {
    function_app_id = azurerm_linux_function_app.fa.id
    hashed_content  = substr(data.archive_file.func.output_base64sha256, 0, 16)
  }

  provisioner "local-exec" {
    command = "az functionapp deployment source config-zip -g ${azurerm_resource_group.rg.name} -n ${azurerm_linux_function_app.fa.name} --src ${data.archive_file.func.output_path} --build-remote true"
  }

}