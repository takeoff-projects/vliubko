# resource "google_service_account" "oms_lite" {
#   account_id   = "oms-lite"
#   display_name = "OMS lite"
# }

# resource "google_cloud_run_service" "oms_lite" {
#   name     = "oms-lite"
#   location = "us-central1"

#   template {
#     spec {
#       service_account_name = 
#       containers {
#         image = "us-docker.pkg.dev/cloudrun/container/hello"
#         env {
#           name = "SOURCE"
#           value = "remote"
#         }
#         env {
#           name = "TARGET"
#           value = "home"
#         }
#       }
#     }

#     metadata {
#       annotations = {
#         "autoscaling.knative.dev/maxScale"      = "1000"
#         # "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.instance.connection_name
#         "run.googleapis.com/client-name"        = "terraform"
#       }
#     }
#   }
#   autogenerate_revision_name = true
# }
