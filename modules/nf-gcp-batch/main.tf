data "google_client_config" "current" {}

locals {
  compact_prefix         = replace(var.name_prefix, "-", "")
  provider_project_id    = try(trimspace(data.google_client_config.current.project), "")
  effective_project_id   = var.project_id != null && trimspace(var.project_id) != "" ? trimspace(var.project_id) : (local.provider_project_id != "" ? local.provider_project_id : null)
  bucket_hash            = substr(sha256("${coalesce(local.effective_project_id, "unset-project")}:${var.region}:${var.name_prefix}"), 0, 10)
  generated_bucket_name  = "${substr(local.compact_prefix, 0, 20)}-${local.bucket_hash}-work"
  selected_bucket_name   = coalesce(var.bucket_name, local.generated_bucket_name)
  launch_sa_account_id   = substr("${local.compact_prefix}launch", 0, 30)
  job_sa_account_id      = substr("${local.compact_prefix}batchjob", 0, 30)
  datalink_sa_account_id = substr("${local.compact_prefix}datalink", 0, 30)
}

resource "terraform_data" "validate_effective_project_id" {
  input = local.effective_project_id

  lifecycle {
    precondition {
      condition     = local.effective_project_id != null
      error_message = "No GCP project ID was resolved. Set project_id, or configure a current project via gcloud/environment so google_client_config.current.project is available."
    }
  }
}

resource "google_project_service" "required" {
  for_each = var.enable_required_apis ? toset([
    "batch.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "storage.googleapis.com",
  ]) : toset([])

  project                    = local.effective_project_id
  service                    = each.value
  disable_dependent_services = false
  disable_on_destroy         = false

  depends_on = [terraform_data.validate_effective_project_id]
}

resource "google_storage_bucket" "work" {
  name                        = local.selected_bucket_name
  project                     = local.effective_project_id
  location                    = var.region
  force_destroy               = var.force_destroy_bucket
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = var.labels

  versioning {
    enabled = true
  }

  depends_on = [google_project_service.required]
}

resource "google_service_account" "nf_launch_run" {
  project      = local.effective_project_id
  account_id   = local.launch_sa_account_id
  display_name = "Nextflow launch-run service account"

  depends_on = [google_project_service.required]
}

resource "google_service_account" "nextflow_job" {
  project      = local.effective_project_id
  account_id   = local.job_sa_account_id
  display_name = "Nextflow Batch job service account"

  depends_on = [google_project_service.required]
}

resource "google_service_account" "nfcc_datalink" {
  project      = local.effective_project_id
  account_id   = local.datalink_sa_account_id
  display_name = "nf-command-center data link service account"

  depends_on = [google_project_service.required]
}

resource "google_project_iam_member" "nf_launch_run_batch_editor" {
  project = local.effective_project_id
  role    = "roles/batch.jobsEditor"
  member  = "serviceAccount:${google_service_account.nf_launch_run.email}"
}

resource "google_service_account_iam_member" "nf_launch_run_service_account_user" {
  service_account_id = google_service_account.nextflow_job.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.nf_launch_run.email}"
}

resource "google_project_iam_member" "nextflow_job_batch_agent_reporter" {
  project = local.effective_project_id
  role    = "roles/batch.agentReporter"
  member  = "serviceAccount:${google_service_account.nextflow_job.email}"
}

resource "google_project_iam_member" "nextflow_job_logging_writer" {
  project = local.effective_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.nextflow_job.email}"
}

resource "google_storage_bucket_iam_member" "nf_launch_run_work_object_admin" {
  bucket = google_storage_bucket.work.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.nf_launch_run.email}"
}

resource "google_storage_bucket_iam_member" "nextflow_job_work_object_admin" {
  bucket = google_storage_bucket.work.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.nextflow_job.email}"
}

resource "google_storage_bucket_iam_member" "nfcc_datalink_work_object_admin" {
  bucket = google_storage_bucket.work.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.nfcc_datalink.email}"
}

resource "google_storage_bucket_iam_member" "nf_launch_run_work_bucket_reader" {
  bucket = google_storage_bucket.work.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.nf_launch_run.email}"
}

resource "google_storage_bucket_iam_member" "nextflow_job_work_bucket_reader" {
  bucket = google_storage_bucket.work.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.nextflow_job.email}"
}

resource "google_storage_bucket_iam_member" "nfcc_datalink_work_bucket_reader" {
  bucket = google_storage_bucket.work.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.nfcc_datalink.email}"
}
