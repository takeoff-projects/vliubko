module "cloudsql" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version = "7.1.0"

  project_id = var.google_project_id

  name = var.app_name

  database_version = "POSTGRES_13"

  db_name       = var.db_name
  user_name     = var.db_user
  user_password = var.db_password

  availability_type = "REGIONAL"
  region            = "us-east1"
  tier              = "db-f1-micro"

  random_instance_name = true
  deletion_protection  = false

  depends_on = [
    google_project_service.project_services
  ]
}
