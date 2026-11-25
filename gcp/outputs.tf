output "work_bucket_name" {
  description = "GCS bucket used for Nextflow work data."
  value       = module.nextflow_batch.work_bucket_name
}

output "work_bucket_url" {
  description = "URL of the GCS bucket used for Nextflow work data."
  value       = module.nextflow_batch.work_bucket_url
}

output "work_uri" {
  description = "GCS URI to use as the Nextflow work directory."
  value       = module.nextflow_batch.work_uri
}

output "project_id" {
  description = "GCP project ID where resources were created."
  value       = module.nextflow_batch.project_id
}

output "region" {
  description = "GCP region used for Batch jobs and storage."
  value       = module.nextflow_batch.region
}

output "nf_launch_run_service_account_email" {
  description = "Service account email intended for launching Nextflow workflows."
  value       = module.nextflow_batch.nf_launch_run_service_account_email
}

output "nextflow_job_service_account_email" {
  description = "Service account email used by Google Cloud Batch task VMs."
  value       = module.nextflow_batch.nextflow_job_service_account_email
}

output "nfcc_datalink_service_account_email" {
  description = "Service account email intended for nf-command-center data link operations."
  value       = module.nextflow_batch.nfcc_datalink_service_account_email
}

output "head_machine_type" {
  description = "Recommended machine type for Nextflow head/driver processes."
  value       = module.nextflow_batch.head_machine_type
}

output "worker_machine_type" {
  description = "Recommended machine type for Nextflow worker/task processes."
  value       = module.nextflow_batch.worker_machine_type
}

output "use_spot" {
  description = "Recommended default for running Google Batch tasks on Spot VMs."
  value       = module.nextflow_batch.use_spot
}

output "nextflow_config_parameters" {
  description = "Parameters to copy into a Nextflow Google Batch configuration."
  value = {
    workDir             = module.nextflow_batch.work_uri
    project             = module.nextflow_batch.project_id
    location            = module.nextflow_batch.region
    serviceAccountEmail = module.nextflow_batch.nextflow_job_service_account_email
    headMachineType     = module.nextflow_batch.head_machine_type
    workerMachineType   = module.nextflow_batch.worker_machine_type
    spot                = module.nextflow_batch.use_spot
  }
}
