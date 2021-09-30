resource "google_api_gateway_api" "api" {
  provider     = google-beta
  api_id       = "api"
  display_name = "API Gateway"

  labels = {
    author  = "vliubko"
    service = "oms-lite"
  }
}

resource "google_api_gateway_api_config" "api_gw" {
  provider = google-beta
  api = google_api_gateway_api.api.api_id
  api_config_id = "config"

  # gateway_config {
  #   backend_config {
  #     google_service_account = google_service_account.api_gateway.email
  #   }
  # }

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
  provider = google-beta
  api_config = google_api_gateway_api_config.api_gw.id
  gateway_id = "${var.app_name}-gw"
}