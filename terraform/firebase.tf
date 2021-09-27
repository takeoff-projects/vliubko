# ---------------------------------------------------------------------------------------------------------------------
# Firebase + Firestore
# ---------------------------------------------------------------------------------------------------------------------

resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.google_project_id
}

resource "google_app_engine_application" "firestore" {
  project       = var.google_project_id
  location_id   = var.firebase_location
  database_type = var.firestore_database_type
}

data "local_file" "firestore_rules" {
  filename = var.firestore_rules_filename
}

data "google_client_config" "current" {}

resource "null_resource" "firestore_rules" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/firestore_rules.sh"
    environment = {
      API_URL = var.firebase_rules_api_url
      PROJECT = var.google_project_id
      RULES   = data.local_file.firestore_rules.content
      TOKEN   = data.google_client_config.current.access_token
    }
  }
  depends_on = [
    google_app_engine_application.firestore
  ]
}