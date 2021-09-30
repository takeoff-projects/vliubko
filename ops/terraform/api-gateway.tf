resource "google_api_gateway_api" "api" {
  provider     = google-beta
  api_id       = "api"
  display_name = "API Gateway"

  labels = {
    author  = "vliubko"
    service = "oms-lite"
  }
}
