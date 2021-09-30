module "api_gw_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.0.3"
  project_id = var.google_project_id
  names      = ["api-gw"]
  project_roles = [
    "${var.google_project_id}=>roles/run.invoker",
  ]
}

resource "google_api_gateway_api" "api" {
  project = var.google_project_id

  provider     = google-beta
  api_id       = "api"
  display_name = "API Gateway"

  labels = {
    author  = "vliubko"
    service = var.app_name
  }
}

resource "google_api_gateway_api_config" "api_gw" {
  project = var.google_project_id

  provider = google-beta
  api = google_api_gateway_api.api.api_id
  api_config_id_prefix = var.app_name

  labels = {
    author  = "vliubko"
    service = var.app_name
  }

  gateway_config {
    backend_config {
      google_service_account = module.api_gw_sa.email
    }
  }

  openapi_documents {
    document {
      path = "openapi.yaml"
      contents = base64encode(templatefile(
        "../../docs/swagger.yaml",
        {
          cloud_run_url: var.cloud_run_url
        }
      ))
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_api_gateway_gateway" "api_gw" {
  project = var.google_project_id

  provider = google-beta
  api_config = google_api_gateway_api_config.api_gw.id
  gateway_id = "${var.app_name}-gw"
}