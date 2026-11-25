locals {
  state_bucket_name = coalesce(var.bucket_name, "terraform-state${var.resource_suffix}")
  labels = merge(var.labels, {
    managed_by  = "terraform"
    purpose     = "terraform-state"
    environment = "state"
  })
}

resource "google_project_service" "storage" {
  project            = data.google_client_config.current.project
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_storage_bucket" "terraform_state" {
  name                        = local.state_bucket_name
  project                     = data.google_client_config.current.project
  location                    = var.region
  force_destroy               = var.force_destroy
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = local.labels

  versioning {
    enabled = true
  }

  dynamic "retention_policy" {
    for_each = var.retention_period_seconds == null ? [] : [var.retention_period_seconds]

    content {
      retention_period = retention_policy.value
      is_locked        = false
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      days_since_noncurrent_time = var.noncurrent_version_retention_days
      num_newer_versions         = 3
      with_state                 = "ARCHIVED"
    }
  }

  depends_on = [google_project_service.storage]
}
