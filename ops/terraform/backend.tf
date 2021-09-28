terraform {
  backend "gcs" {
    bucket = "" # should be pass via terraform init -backend-config="bucket=ZAZA"
    prefix = "terraform/state"
  }
}