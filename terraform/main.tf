terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.85.0"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = "3.85.0"
    }
  }
}

provider "google" {
  project = var.google_project_id
  region  = "us-central1"
  zone    = "us-central1-c"
}

provider "google-beta" {
  project = var.google_project_id
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_project_service" "project_services" {
  for_each                   = toset(var.google_apis)
  project                    = var.google_project_id
  service                    = each.value
}

# ---------------------------------------------------------------------------------------------------------------------
# Firebase + Firestore
# ---------------------------------------------------------------------------------------------------------------------

resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.google_project_id
}
