provider "google" {
  region = var.region
}

data "google_client_config" "current" {}
