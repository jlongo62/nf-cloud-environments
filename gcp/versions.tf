terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  backend "gcs" {
    bucket = "terraform-state-2c8f311b"
    prefix = "terraform/state/gcp"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}
