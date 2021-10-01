output cloudsql_instance_connection_name {
  value       = module.cloudsql.instance_connection_name
  description = "The connection name of the master instance to be used in connection strings"
}

output cloudsql_db_name {
  value       = var.db_name
}
output cloudsql_db_user {
  value       = var.db_user
}
output cloudsql_db_password {
  value       = var.db_password
}

output app_service_account_email {
  value       = module.oms_lite_sa.email
}

output api_gateway_url {
  value       = google_api_gateway_gateway.api_gw.default_hostname
}
