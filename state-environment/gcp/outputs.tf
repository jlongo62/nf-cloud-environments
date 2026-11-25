output "bucket_name" {
  description = "Name of the GCS bucket that stores Terraform state."
  value       = google_storage_bucket.terraform_state.name
}

output "bucket_url" {
  description = "Canonical URL of the Terraform state bucket."
  value       = google_storage_bucket.terraform_state.url
}

output "backend_configuration" {
  description = "Values for a Terraform gcs backend block."
  value = {
    bucket = google_storage_bucket.terraform_state.name
    prefix = "terraform/state"
  }
}
