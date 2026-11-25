variable "name_prefix" {
  description = "Lowercase prefix used for GCP resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,24}$", var.name_prefix))
    error_message = "name_prefix must contain 3-25 lowercase letters, numbers, or hyphens, and start with a letter."
  }
}

variable "project_id" {
  description = "Optional GCP project ID. If null, Terraform uses the provider-resolved current project."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.project_id == null || can(regex("^[a-z][a-z0-9-]{4,61}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-63 characters, use lowercase letters, numbers, or hyphens, and start with a letter."
  }
}

variable "region" {
  description = "GCP region used by Google Cloud Batch and Cloud Storage."
  type        = string
  default     = "us-central1"
}

variable "bucket_name" {
  description = "Optional globally unique GCS bucket name for Nextflow work data."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.bucket_name == null || can(regex("^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters and use lowercase letters, numbers, periods, underscores, or hyphens."
  }
}

variable "work_prefix" {
  description = "Object prefix reserved for Nextflow work data."
  type        = string
  default     = "nextflow"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9/_-]{0,127}$", var.work_prefix))
    error_message = "work_prefix must be 1-128 characters and may contain letters, numbers, slashes, hyphens, or underscores."
  }
}

variable "force_destroy_bucket" {
  description = "Allow Terraform to delete a non-empty work bucket."
  type        = bool
  default     = false
}

variable "head_machine_type" {
  description = "Recommended machine type for Nextflow head/driver processes."
  type        = string
  default     = "e2-standard-2"
}

variable "worker_machine_type" {
  description = "Recommended machine type for Nextflow worker/task processes."
  type        = string
  default     = "e2-standard-2"
}

variable "use_spot" {
  description = "Recommended default for running Google Batch tasks on Spot VMs."
  type        = bool
  default     = true
}

variable "enable_required_apis" {
  description = "Enable required Google APIs for Batch and Storage in this project."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Additional labels to apply to GCP resources."
  type        = map(string)
  default     = {}
}
