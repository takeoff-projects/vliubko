resource "google_secret_manager_secret" "cloudsql_oms_lite_creds" {
  secret_id = "cloudsql_oms_lite_creds"
  replication {
    automatic = true
  }
  project = var.google_project_id

  depends_on = [
    google_project_service.project_services
  ]
}


# WARNING! Only for demo purposes!
# Please, manually create a version of any secret in the GCP Console.
# This needs to be done manually as this is how we manage to not store any secret values in code. 
# Think of this like storing a value in your password manager.
# 
resource "google_secret_manager_secret_version" "cloudsql_oms_lite_creds" {
  secret = google_secret_manager_secret.cloudsql_oms_lite_pwd.id

  secret_data = jsonencode("{\n\"instanceConnectionName\": ${module.cloudsql.instance_connection_name},\n\"dbUser\": \"oms-lite\",\n\"dbPwd\": \"kaka-zaza\",\n\"dbName\": \"oms-lite\"\n}")
}
