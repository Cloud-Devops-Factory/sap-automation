/*
  Description:
  Set up storage accounts for sap library 
*/

// Imports existing storage account to use for tfstate
data "azurerm_storage_account" "storage_tfstate" {
  provider            = azurerm.main
  count               = local.sa_tfstate_exists ? 1 : 0
  name                = split("/", local.sa_tfstate_arm_id)[8]
  resource_group_name = split("/", local.sa_tfstate_arm_id)[4]
}

// Creates storage account for storing tfstate
resource "azurerm_storage_account" "storage_tfstate" {
  provider                  = azurerm.main
  count                     = local.sa_tfstate_exists ? 0 : 1
  name                      = local.sa_tfstate_name
  resource_group_name       = local.rg_name
  location                  = local.rg_library_location
  account_replication_type  = local.sa_tfstate_account_replication_type
  account_tier              = local.sa_tfstate_account_tier
  account_kind              = local.sa_tfstate_account_kind
  enable_https_traffic_only = local.sa_tfstate_enable_secure_transfer
  allow_blob_public_access  = true
  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  network_rules {
    default_action = "Allow"
    ip_rules = var.use_private_endpoint ? (
      [length(local.deployer_public_ip_address) > 0 ? local.deployer_public_ip_address : null]) : (
      []
    )
    virtual_network_subnet_ids = var.use_private_endpoint ? [local.subnet_mgmt_id] : []
  }
}

data "azurerm_storage_container" "storagecontainer_tfstate" {
  provider             = azurerm.main
  count                = local.sa_tfstate_container_exists ? 1 : 0
  name                 = local.sa_tfstate_container_name
  storage_account_name = local.sa_tfstate_exists ? data.azurerm_storage_account.storage_tfstate[0].name : azurerm_storage_account.storage_tfstate[0].name
}

// Creates the storage container inside the storage account for sapsystem
resource "azurerm_storage_container" "storagecontainer_tfstate" {
  provider              = azurerm.main
  count                 = local.sa_tfstate_container_exists ? 0 : 1
  name                  = local.sa_tfstate_container_name
  storage_account_name  = local.sa_tfstate_exists ? data.azurerm_storage_account.storage_tfstate[0].name : azurerm_storage_account.storage_tfstate[0].name
  container_access_type = local.sa_tfstate_container_access_type
}

//Ansible container

data "azurerm_storage_container" "storagecontainer_ansible" {
  provider             = azurerm.main
  count                = local.sa_ansible_container_exists ? 1 : 0
  name                 = local.sa_ansible_container_name
  storage_account_name = local.sa_tfstate_exists ? data.azurerm_storage_account.storage_tfstate[0].name : azurerm_storage_account.storage_tfstate[0].name
}

// Creates the storage container inside the storage account for sapsystem
resource "azurerm_storage_container" "storagecontainer_ansible" {
  provider              = azurerm.main
  count                 = local.sa_ansible_container_exists ? 0 : 1
  name                  = local.sa_ansible_container_name
  storage_account_name  = local.sa_tfstate_exists ? data.azurerm_storage_account.storage_tfstate[0].name : azurerm_storage_account.storage_tfstate[0].name
  container_access_type = local.sa_tfstate_container_access_type
}

resource "azurerm_private_endpoint" "storage_tfstate" {
  count               = var.use_private_endpoint && !local.sa_tfstate_exists ? 1 : 0
  name                = format("%s%s", local.prefix, local.resource_suffixes.storage_private_link_tf)
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.library[0].name : azurerm_resource_group.library[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.library[0].location : azurerm_resource_group.library[0].location
  subnet_id           = local.subnet_mgmt_id

  private_service_connection {
    name                           = format("%s%s", local.prefix, local.resource_suffixes.storage_private_svc_tf)
    is_manual_connection           = false
    private_connection_resource_id = local.sa_tfstate_exists ? data.azurerm_storage_account.storage_tfstate[0].id : azurerm_storage_account.storage_tfstate[0].id
    subresource_names = [
      "File"
    ]
  }
}


// Imports existing storage account for storing SAP bits
data "azurerm_storage_account" "storage_sapbits" {
  provider            = azurerm.main
  count               = local.sa_sapbits_exists ? 1 : 0
  name                = split("/", local.sa_sapbits_arm_id)[8]
  resource_group_name = split("/", local.sa_sapbits_arm_id)[4]
}

// Creates storage account for storing SAP bits
resource "azurerm_storage_account" "storage_sapbits" {
  provider                  = azurerm.main
  count                     = local.sa_sapbits_exists ? 0 : 1
  name                      = local.sa_sapbits_name
  resource_group_name       = local.rg_name
  location                  = local.rg_library_location
  account_replication_type  = local.sa_sapbits_account_replication_type
  account_tier              = local.sa_sapbits_account_tier
  account_kind              = local.sa_sapbits_account_kind
  enable_https_traffic_only = local.sa_sapbits_enable_secure_transfer
  // To support all access levels 'Blob' 'Private' and 'Container'
  allow_blob_public_access = true
  // TODO: soft delete for file share

  network_rules {
    default_action = "Allow"
    ip_rules = var.use_private_endpoint ? (
      [length(local.deployer_public_ip_address) > 0 ? local.deployer_public_ip_address : null]) : (
      []
    )

    virtual_network_subnet_ids = var.use_private_endpoint ? [local.subnet_mgmt_id] : []
  }
}

resource "azurerm_private_endpoint" "storage_sapbits" {
  count               = var.use_private_endpoint && !local.sa_sapbits_exists ? 1 : 0
  name                = format("%s%s", local.prefix, local.resource_suffixes.storage_private_link_sap)
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.library[0].name : azurerm_resource_group.library[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.library[0].location : azurerm_resource_group.library[0].location
  subnet_id           = local.subnet_mgmt_id

  private_service_connection {
    name                           = format("%s%s", local.prefix, local.resource_suffixes.storage_private_svc_sap)
    is_manual_connection           = false
    private_connection_resource_id = local.sa_sapbits_exists ? data.azurerm_storage_account.storage_sapbits[0].id : azurerm_storage_account.storage_sapbits[0].id
    subresource_names = [
      "File"
    ]
  }
}


// Imports existing storage blob container for SAP bits
data "azurerm_storage_container" "storagecontainer_sapbits" {
  provider             = azurerm.main
  count                = (local.sa_sapbits_blob_container_enable && local.sa_sapbits_blob_container_exists) ? 1 : 0
  name                 = local.sa_sapbits_blob_container_name
  storage_account_name = local.sa_sapbits_exists ? data.azurerm_storage_account.storage_sapbits[0].name : azurerm_storage_account.storage_sapbits[0].name
}

// Creates the storage container inside the storage account for SAP bits
resource "azurerm_storage_container" "storagecontainer_sapbits" {
  provider              = azurerm.main
  count                 = (local.sa_sapbits_blob_container_enable && !local.sa_sapbits_blob_container_exists) ? 1 : 0
  name                  = local.sa_sapbits_blob_container_name
  storage_account_name  = local.sa_sapbits_exists ? data.azurerm_storage_account.storage_sapbits[0].name : azurerm_storage_account.storage_sapbits[0].name
  container_access_type = local.sa_sapbits_container_access_type
}

// Creates file share inside the storage account for SAP bits
resource "azurerm_storage_share" "fileshare_sapbits" {
  provider             = azurerm.main
  count                = (local.sa_sapbits_file_share_enable && !local.sa_sapbits_file_share_exists) ? 1 : 0
  name                 = local.sa_sapbits_file_share_name
  storage_account_name = local.sa_sapbits_exists ? data.azurerm_storage_account.storage_sapbits[0].name : azurerm_storage_account.storage_sapbits[0].name
}

/* 
TBD: two options
1. deployer msi has contributor role(or less powerful role: Storage Account Contributor) to all the subscriptions it manages
2. when deploying storage accounts, deployer msi will be assgined a role as Storage Account Contributor, so it can move the terraform.tfstate from local to the storage account.
*/
// Assign contributor role to deployer's msi to access tfstate storage account
resource "azurerm_role_assignment" "deployer_msi_sa_tfstate" {
  provider = azurerm.main
  count = local.deployer_defined && !local.sa_sapbits_exists ? (
    length(local.deployer_msi_principal_id) > 0 ? (
      1) : (
      0
    )) : (
    0
  )

  scope                = local.sa_tfstate_exists ? data.azurerm_storage_account.storage_tfstate[0].id : azurerm_storage_account.storage_tfstate[0].id
  role_definition_name = "Storage Account Contributor"
  principal_id         = local.deployer_msi_principal_id
}


#ToDo Fix later
resource "azurerm_key_vault_secret" "saplibrary_access_key" {
  provider     = azurerm.deployer
  count        = length(local.deployer_kv_user_arm_id) > 0 ? 1 : 0
  name         = "sapbits-access-key"
  value        = local.sa_sapbits_exists ? data.azurerm_storage_account.storage_sapbits[0].primary_access_key : azurerm_storage_account.storage_sapbits[0].primary_access_key
  key_vault_id = local.deployer_kv_user_arm_id
}

resource "azurerm_key_vault_secret" "sapbits_location_base_path" {
  provider = azurerm.deployer
  count    = length(local.deployer_kv_user_arm_id) > 0 ? 1 : 0
  name     = "sapbits-location-base-path"
  value = local.sa_sapbits_exists ? (
    data.azurerm_storage_container.storagecontainer_sapbits[0].id) : (
    azurerm_storage_container.storagecontainer_sapbits[0].id
  )
  key_vault_id = local.deployer_kv_user_arm_id
}

data "azurerm_storage_account_blob_container_sas" "sapbits_sas_token" {
  connection_string = local.sa_sapbits_exists ? (
    data.azurerm_storage_account.storage_sapbits[0].primary_connection_string) : (
    azurerm_storage_account.storage_sapbits[0].primary_connection_string
  )

  container_name = local.sa_sapbits_exists ? data.azurerm_storage_account.storage_sapbits[0].name : azurerm_storage_account.storage_sapbits[0].name

  https_only = true

  start  = formatdate("YYYY-MM-DD", timestamp())
  expiry = formatdate("YYYY-MM-DD", timeadd(timestamp(), "8760h"))

  permissions {
    read   = true
    write  = false
    delete = false
    list   = false
    add    = false
    create = false
  }
}

resource "azurerm_key_vault_secret" "sapbits_sas_token_secret" {
  provider     = azurerm.deployer
  count        = length(local.deployer_kv_user_arm_id) > 0 ? 1 : 0
  name         = "sapbits-sas-token"
  value        = data.azurerm_storage_account_blob_container_sas.sapbits_sas_token.sas
  key_vault_id = local.deployer_kv_user_arm_id

  lifecycle {
    ignore_changes = [
      // Ignore changes to object_id
      value
    ]
  }

}