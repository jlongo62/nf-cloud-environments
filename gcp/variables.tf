variable "project_name" {
  description = "Name used to identify resources created by this project."
  type        = string
  default     = "nf-gcp"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,23}$", var.project_name))
    error_message = "project_name must contain 2-24 lowercase letters, numbers, or hyphens, and start with a letter."
  }
}

variable "environment" {
  description = "Deployment environment name used in resource and state names."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,14}[a-z0-9]$", var.environment))
    error_message = "environment must be 2-16 lowercase letters, numbers, or hyphens, start with a letter, and end with a letter or number."
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
  description = "GCP region for Cloud Batch and Cloud Storage."
  type        = string
  default     = "us-central1"
}

variable "bucket_name" {
  description = "Optional globally unique base name for the environment-specific GCS work bucket."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.bucket_name == null || (length(var.bucket_name) <= 46 && can(regex("^[a-z0-9][a-z0-9._-]{1,44}[a-z0-9]$", var.bucket_name)))
    error_message = "bucket_name must be 3-46 characters and use lowercase letters, numbers, periods, underscores, or hyphens; the environment suffix is appended."
  }
}

variable "work_prefix" {
  description = "Object prefix reserved for Nextflow work data."
  type        = string
  default     = "nextflow"
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
  description = "Additional labels to apply to resources."
  type        = map(string)
  default     = {}
}
