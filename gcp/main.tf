locals {
  deployment_name  = "${var.project_name}-${var.environment}"
  work_bucket_name = var.bucket_name == null ? null : "${var.bucket_name}-${var.environment}"
  common_labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
    project     = var.project_name
  })
}

module "nextflow_batch" {
  source = "../modules/nf-gcp-batch"

  name_prefix          = local.deployment_name
  project_id           = var.project_id
  region               = var.region
  bucket_name          = local.work_bucket_name
  work_prefix          = var.work_prefix
  force_destroy_bucket = var.force_destroy_bucket
  head_machine_type    = var.head_machine_type
  worker_machine_type  = var.worker_machine_type
  use_spot             = var.use_spot
  enable_required_apis = var.enable_required_apis
  labels               = local.common_labels
}
