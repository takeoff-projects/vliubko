variable google_project_id {
  type        = string
  description = "Google Cloud Project ID"
}

variable google_apis {
  type        = list
  default     = [
    "cloudresourcemanager.googleapis.com",
    "containerregistry.googleapis.com",
    "firebase.googleapis.com",
    "firestore.googleapis.com",
    "cloudtrace.googleapis.com",
    "apigateway.googleapis.com",
    "servicecontrol.googleapis.com",
    "servicemanagement.googleapis.com",
    "iam.googleapis.com",
  ]
  description = "Google APIs to enable in the project"
}

variable firebase_location {
  type        = string
  default     = "us-central"
  description = "Firebase/Firestore(AppEngine) location. More info here: https://cloud.google.com/appengine/docs/locations"
}

variable firestore_database_type {
  type        = string
  default     = "CLOUD_FIRESTORE"
  description = "The type of the Cloud Firestore or Cloud Datastore database associated with this application."
}

variable "firestore_rules_filename" {
  type = string
  default = "firestore.rules"
}

variable "firebase_rules_api_url" {
  default = "https://firebaserules.googleapis.com/v1"
  type    = string
}