variable "region" {
  description = "Default Google Cloud region for provider operations."
  type        = string
  default     = "us-central1"
}

variable "resource_suffix" {
  description = "Required suffix applied to resources in this state environment."
  type        = string
  default     = "-2c8f311b"

  validation {
    condition     = var.resource_suffix == "-2c8f311b"
    error_message = "resource_suffix must remain -2c8f311b."
  }
}

variable "bucket_name" {
  description = "Optional globally unique bucket name; defaults to nfcc-terraform-state plus resource_suffix."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.bucket_name == null || can(regex(
      "^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$",
      var.bucket_name,
    ))
    error_message = "bucket_name must be a valid Cloud Storage bucket name."
  }
}

variable "force_destroy" {
  description = "Allow Terraform to delete a non-empty state bucket. Keep false for normal use."
  type        = bool
  default     = false
}

variable "retention_period_seconds" {
  description = "Optional object retention period. Set to null to omit a retention policy."
  type        = number
  default     = null
  nullable    = true

  validation {
    condition     = var.retention_period_seconds == null || var.retention_period_seconds >= 86400
    error_message = "retention_period_seconds must be null or at least 86400 seconds."
  }
}

variable "noncurrent_version_retention_days" {
  description = "Days to retain noncurrent state object versions."
  type        = number
  default     = 30

  validation {
    condition     = var.noncurrent_version_retention_days >= 7
    error_message = "noncurrent_version_retention_days must be at least 7."
  }
}

variable "labels" {
  description = "Additional labels for the state bucket."
  type        = map(string)
  default     = {}
}
