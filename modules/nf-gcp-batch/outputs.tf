output "work_bucket_name" {
  description = "Name of the private GCS bucket used for Nextflow work data."
  value       = google_storage_bucket.work.name
}

output "work_bucket_url" {
  description = "URL of the private GCS bucket used for Nextflow work data."
  value       = google_storage_bucket.work.url
}

output "work_prefix" {
  description = "Object prefix reserved for Nextflow work data."
  value       = var.work_prefix
}

output "work_uri" {
  description = "GCS URI to use as the Nextflow work directory."
  value       = "gs://${google_storage_bucket.work.name}/${var.work_prefix}"
}

output "project_id" {
  description = "Resolved GCP project ID where resources are deployed."
  value       = local.effective_project_id
}

output "region" {
  description = "GCP region used for Batch jobs and storage."
  value       = var.region
}

output "nf_launch_run_service_account_email" {
  description = "Service account email intended for launching Nextflow workflows."
  value       = google_service_account.nf_launch_run.email
}

output "nextflow_job_service_account_email" {
  description = "Service account email used by Google Cloud Batch task VMs."
  value       = google_service_account.nextflow_job.email
}

output "nfcc_datalink_service_account_email" {
  description = "Service account email intended for nf-command-center data link operations."
  value       = google_service_account.nfcc_datalink.email
}

output "head_machine_type" {
  description = "Recommended machine type for Nextflow head/driver processes."
  value       = var.head_machine_type
}

output "worker_machine_type" {
  description = "Recommended machine type for Nextflow worker/task processes."
  value       = var.worker_machine_type
}

output "use_spot" {
  description = "Recommended default for running Google Batch tasks on Spot VMs."
  value       = var.use_spot
}
