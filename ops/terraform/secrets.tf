resource "google_secret_manager_secret" "cloudsql_oms_lite_instance_connection" {
  secret_id = "cloudsql_oms_lite_instance_connection"
  replication {
    automatic = true
  }
  project = var.google_project_id

  depends_on = [
    google_project_service.project_services
  ]
}

resource "google_secret_manager_secret" "cloudsql_oms_lite_db_name" {
  secret_id = "cloudsql_oms_lite_db_name"
  replication {
    automatic = true
  }
  project = var.google_project_id

  depends_on = [
    google_project_service.project_services
  ]
}

resource "google_secret_manager_secret" "cloudsql_oms_lite_db_user" {
  secret_id = "cloudsql_oms_lite_db_user"
  replication {
    automatic = true
  }
  project = var.google_project_id

  depends_on = [
    google_project_service.project_services
  ]
}

resource "google_secret_manager_secret" "cloudsql_oms_lite_db_password" {
  secret_id = "cloudsql_oms_lite_db_password"
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
resource "google_secret_manager_secret_version" "cloudsql_oms_lite_instance_connection" {
  secret = google_secret_manager_secret.cloudsql_oms_lite_instance_connection.id

  secret_data = module.cloudsql.instance_connection_name
}

resource "google_secret_manager_secret_version" "cloudsql_oms_lite_db_name" {
  secret = google_secret_manager_secret.cloudsql_oms_lite_db_name.id

  secret_data = var.db_name
}

resource "google_secret_manager_secret_version" "cloudsql_oms_lite_db_user" {
  secret = google_secret_manager_secret.cloudsql_oms_lite_db_user.id

  secret_data = var.db_user
}

resource "google_secret_manager_secret_version" "cloudsql_oms_lite_db_password" {
  secret = google_secret_manager_secret.cloudsql_oms_lite_db_password.id

  secret_data = var.db_password
}
