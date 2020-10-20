# Requires:
# - caf_launchpad scenario 200+
# - caf_foundations
# - caf_neworking with 200-multi-region-hub
# - 200-basic-ml networking_spoke

resource_groups = {
  dap_synapse_re1 = {
    name = "dap-synapse"
  }
  # dap_azure_ml_re1 = {
  #   name = "azure-ml"
  # }
}

synapse_workspaces = {
  synapse_wrkspc_re1 = {
    name                    = "synapsewpc"
    resource_group_key      = "dap_synapse_re1"
    sql_administrator_login = "dbadmin"
    # sql_administrator_login_password = "<string password>"   # If not set use module autogenerate a strong password and stores it in the keyvault
    keyvault_key = "secrets"
    data_lake_filesystem = {
      storage_account_key = "synapsestorage_re1"
      container_key       = "synaspe_filesystem"
    }
    workspace_firewall = {
      name     = "AllowAll"
      start_ip = "0.0.0.0"
      end_ip   = "255.255.255.255"
    }
    synapse_sql_pools = {
      sql_pool_re1 = {
        name                  = "sqlpool1"
        synapse_workspace_key = "synapse_wrkspc_re1"
        sku_name              = "DW100c"
        create_mode           = "Default"
      }
    }
    synapse_spark_pools = {
      spark_pool_re1 = {
        name                  = "sprkpool1" #[name can contain only letters or numbers, must start with a letter, and be between 1 and 15 characters long]
        synapse_workspace_key = "synapse_wrkspc_re1"
        node_size_family      = "MemoryOptimized"
        node_size             = "Small"
        auto_scale = {
          max_node_count = 50
          min_node_count = 3
        }
        auto_pause = {
          delay_in_minutes = 15
        }
        tags = "Production"
      }
    }
  }
}

storage_accounts = {
  synapsestorage_re1 = {
    name                     = "synapsere1"
    resource_group_key       = "dap_synapse_re1"
    account_kind             = "StorageV2"
    account_tier             = "Standard"
    account_replication_type = "LRS"
    access_tier              = "Hot"
    is_hns_enabled           = true

    data_lake_filesystems = {
      synaspe_filesystem = {
        name = "synapsefilesystem"
        properties = {
          dap = "200-synapse"
        }
      }
    }
  }
}

keyvaults = {
  secrets = {
    name                = "secrets"
    resource_group_key  = "dap_synapse_re1"
    sku_name            = "premium"
    soft_delete_enabled = true

    # you can setup up to 5 profiles
    # diagnostic_profiles = {
    #   operations = {
    #     definition_key   = "default_all"
    #     destination_type = "log_analytics"
    #     destination_key  = "central_logs"
    #   }
    # }
  }
}

keyvault_access_policies = {
  secrets = {
    logged_in_user = {
      secret_permissions = ["Set", "Get", "List", "Delete", "Purge", "Recover"]
    }
    logged_in_aad_app = {
      secret_permissions = ["Set", "Get", "List", "Delete", "Purge", "Recover"]
    }
    dap_admins = {
      azuread_group_key  = "dap_admins"
      secret_permissions = ["Get", "List"]
    }
  }
}


#
# IAM
#
/* azuread_groups = {
  dap_admins = {
    name        = "dap-admins"
    description = "Provide access to the Data Analytics Platform services and the jumpbox Keyvault secret."
    members = {
      user_principal_names = [
      ]
      group_names = []
      object_ids  = []
      group_keys  = []

      service_principal_keys = [
      ]
    }
    prevent_duplicate_name = false
  }
} */

role_mapping = {
  built_in_role_mapping = {
    storage_accounts = {
      synapsestorage_re1 = {
        "Storage Blob Data Contributor" = {
          synapse_workspaces = {
            keys = ["synapse_wrkspc_re1"]
          }
        }
      }
    }
  }
}