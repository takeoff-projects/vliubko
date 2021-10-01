module "oms_lite_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.0.3"
  project_id = var.google_project_id
  names      = ["oms-lite"]
  project_roles = [
    "${var.google_project_id}=>roles/cloudtrace.agent",
    "${var.google_project_id}=>roles/cloudsql.client",
    "${var.google_project_id}=>roles/secretmanager.secretAccessor",
  ]
  depends_on = [
    google_project_service.project_services
  ]
}
