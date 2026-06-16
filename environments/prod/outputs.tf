output "environment" {
  description = "Outputs for resources managed in this environment. Only includes resource types configured in terraform.tfvars."
  value = merge(
    length(var.resource_groups) > 0 ? {
      resource_groups = {
        names     = { for name, rg in module.resource_group : name => rg.resource_group_name }
        locations = { for name, rg in module.resource_group : name => rg.location }
        ids       = { for name, rg in module.resource_group : name => rg.resource_group_id }
      }
    } : {},
    length(var.storage_accounts) > 0 ? {
      storage_accounts = {
        ids            = { for name, sa in module.storage_account : name => sa.storage_account_id }
        names          = { for name, sa in module.storage_account : name => sa.storage_account_name }
        blob_endpoints = { for name, sa in module.storage_account : name => sa.primary_blob_endpoint }
      }
    } : {},
    length(var.key_vaults) > 0 ? {
      key_vaults = {
        ids   = { for name, kv in module.key_vault : name => kv.key_vault_id }
        names = { for name, kv in module.key_vault : name => kv.key_vault_name }
        uris  = { for name, kv in module.key_vault : name => kv.key_vault_uri }
      }
    } : {},
    length(var.key_vault_secrets) > 0 ? {
      key_vault_secrets = {
        ids   = { for name, secret in module.key_vault_secret : name => secret.secret_id }
        names = { for name, secret in module.key_vault_secret : name => secret.secret_name }
      }
    } : {},
    length(var.key_vault_keys) > 0 ? {
      key_vault_keys = {
        ids   = { for name, key in module.key_vault_key : name => key.key_id }
        names = { for name, key in module.key_vault_key : name => key.key_name }
      }
    } : {},
    length(var.vnets) > 0 ? {
      vnets = {
        ids                = { for name, vnet in module.vnet : name => vnet.vnet_id }
        names              = { for name, vnet in module.vnet : name => vnet.vnet_name }
        public_subnet_ids  = { for name, vnet in module.vnet : name => vnet.public_subnet_ids }
        private_subnet_ids = { for name, vnet in module.vnet : name => vnet.private_subnet_ids }
      }
    } : {},
    length(var.network_security_groups) > 0 ? {
      network_security_groups = {
        ids   = { for name, nsg in module.nsg : name => nsg.network_security_group_id }
        names = { for name, nsg in module.nsg : name => nsg.network_security_group_name }
      }
    } : {},
    length(var.load_balancers) > 0 ? {
      load_balancers = {
        ids         = { for name, lb in module.load_balancer : name => lb.load_balancer_id }
        names       = { for name, lb in module.load_balancer : name => lb.load_balancer_name }
        public_ips  = { for name, lb in module.load_balancer : name => lb.load_balancer_public_ip_address }
        private_ips = { for name, lb in module.load_balancer : name => lb.load_balancer_frontend_private_ip_address }
      }
    } : {},
    length(var.application_gateways) > 0 ? {
      application_gateways = {
        ids                 = { for name, agw in module.application_gateway : name => agw.application_gateway_id }
        names               = { for name, agw in module.application_gateway : name => agw.application_gateway_name }
        public_ip_addresses = { for name, agw in module.application_gateway : name => agw.public_ip_address }
      }
    } : {},
    length(var.function_apps) > 0 ? {
      function_apps = {
        names     = { for name, fn in module.function_app : name => fn.function_app_name }
        ids       = { for name, fn in module.function_app : name => fn.function_app_id }
        hostnames = { for name, fn in module.function_app : name => fn.default_hostname }
      }
    } : {},
    length(var.cdn_profiles) > 0 ? {
      cdn = {
        profile_ids   = { for name, cdn in module.cdn : name => cdn.profile_id }
        endpoint_urls = { for name, cdn in module.cdn : name => cdn.endpoint_host_name }
      }
    } : {},
    length(var.container_registries) > 0 ? {
      container_registries = {
        names         = { for name, acr in module.container_registry : name => acr.registry_name }
        ids           = { for name, acr in module.container_registry : name => acr.registry_id }
        login_servers = { for name, acr in module.container_registry : name => acr.login_server }
      }
    } : {},
    length(var.rbac_roles) > 0 ? {
      rbac_roles = {
        principal_ids = { for name, role in module.rbac_role : name => role.principal_id }
        identity_ids  = { for name, role in module.rbac_role : name => role.user_assigned_identity_id }
      }
    } : {},
    length(var.virtual_machines) > 0 ? {
      virtual_machines = {
        ids         = { for name, vm in module.virtual_machine : name => vm.vm_id }
        names       = { for name, vm in module.virtual_machine : name => vm.vm_name }
        private_ips = { for name, vm in module.virtual_machine : name => vm.private_ip_address }
        public_ips  = { for name, vm in module.virtual_machine : name => vm.public_ip_address }
      }
    } : {},
    length(var.postgresql_servers) > 0 ? {
      postgresql = {
        ids   = { for name, db in module.postgresql_flexible : name => db.server_id }
        names = { for name, db in module.postgresql_flexible : name => db.server_name }
        fqdns = { for name, db in module.postgresql_flexible : name => db.fqdn }
      }
    } : {},
    length(var.api_management_services) > 0 ? {
      api_management = {
        ids          = { for name, apim in module.api_management : name => apim.service_id }
        names        = { for name, apim in module.api_management : name => apim.service_name }
        gateway_urls = { for name, apim in module.api_management : name => apim.gateway_url }
      }
    } : {},
    length(var.service_bus_topics) > 0 ? {
      service_bus_topics = {
        topic_ids   = { for name, topic in module.service_bus_topic : name => topic.topic_id }
        topic_names = { for name, topic in module.service_bus_topic : name => topic.topic_name }
      }
    } : {},
    length(var.service_bus_queues) > 0 ? {
      service_bus_queues = {
        queue_ids   = { for name, queue in module.service_bus_queue : name => queue.queue_id }
        queue_names = { for name, queue in module.service_bus_queue : name => queue.queue_name }
      }
    } : {},
    length(var.storage_queues) > 0 ? {
      storage_queues = {
        queue_names = { for name, queue in module.storage_queue : name => queue.queue_name }
        queue_urls  = { for name, queue in module.storage_queue : name => queue.queue_url }
      }
    } : {},
    length(var.aks_clusters) > 0 ? {
      aks = {
        cluster_names = { for name, cluster in module.aks : name => cluster.cluster_name }
        cluster_ids   = { for name, cluster in module.aks : name => cluster.cluster_id }
        oidc_issuers  = { for name, cluster in module.aks : name => cluster.oidc_issuer_url }
      }
    } : {},
    length(var.container_apps) > 0 ? {
      container_apps = {
        environment_ids = { for name, app in module.container_apps : name => app.environment_id }
        app_fqdns       = { for name, app in module.container_apps : name => app.container_app_fqdns }
      }
    } : {},
    length(var.storage_shares) > 0 ? {
      storage_shares = {
        share_names = { for name, share in module.storage_share : name => share.share_name }
        share_urls  = { for name, share in module.storage_share : name => share.share_url }
      }
    } : {},
    length(var.aadb2c_directories) > 0 ? {
      aadb2c = {
        tenant_ids   = { for name, b2c in module.aadb2c : name => b2c.tenant_id }
        domain_names = { for name, b2c in module.aadb2c : name => b2c.domain_name }
      }
    } : {},
    length(var.event_hubs_namespaces) > 0 ? {
      event_hubs = {
        namespace_ids           = { for name, eh in module.event_hubs : name => eh.namespace_id }
        event_hub_ids           = { for name, eh in module.event_hubs : name => eh.event_hub_id }
        kafka_bootstrap_servers = { for name, eh in module.event_hubs : name => eh.kafka_bootstrap_servers }
      }
    } : {},
  )
}
