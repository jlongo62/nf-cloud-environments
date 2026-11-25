# nf-gcp

Terraform baseline for the Google Cloud resources needed by a Nextflow Google Cloud Batch integration. It creates a private GCS work bucket, three service accounts, and the IAM bindings required for Batch job submission and execution.

Google Cloud Batch is job-based and does not use persistent pools. Instead, this baseline returns recommended machine type and Spot settings for head and worker process profiles in Nextflow.

## What this deploys

- A private, versioned GCS bucket with uniform bucket-level access and public access prevention
- A launch-run service account (name derived from `project_name` + `environment`) for workflow submission
- A job service account (name derived from `project_name` + `environment`) for Batch task VMs
- A datalink service account (name derived from `project_name` + `environment`) for nf-command-center data-link operations
- IAM bindings for Batch job submission, service-account usage, job status reporting, logging, and bucket access
- Optional enablement of required APIs: Batch, Compute, IAM, Logging, and Storage

## Prerequisites

- Terraform 1.7 or newer
- A GCP project with billing enabled
- Permission to enable project APIs, create service accounts, create GCS buckets, and assign IAM roles
- Google Cloud CLI (`gcloud`)
- Either set `project_id` in Terraform variables or configure a current GCP project in your provider context (for example, `gcloud config set project <project-id>`)

Do not put service account keys in Terraform files. Prefer Application Default Credentials, Workload Identity Federation, or service-account impersonation.

## Pre-requisite checks

Run these checks before `terraform init`:

```bash
gcloud config get-value project
gcloud services list --enabled --filter='name:batch.googleapis.com OR name:compute.googleapis.com OR name:iam.googleapis.com OR name:logging.googleapis.com OR name:storage.googleapis.com'
```

If `project_id` is omitted in `terraform.tfvars`, Terraform resolves the project from the provider context (`google_client_config.current.project`).

If any required API is missing, enable it:

```bash
gcloud services enable \
  batch.googleapis.com \
  compute.googleapis.com \
  iam.googleapis.com \
  logging.googleapis.com \
  storage.googleapis.com
```

Confirm your Terraform identity has these permissions in the target project:

- Create and update service accounts and IAM bindings
- Create and configure Cloud Storage buckets
- Enable project services/APIs

## Authenticate

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project <project-id>
```

## Deploy

```sh
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars for your region and optional project override.
terraform init
terraform fmt -check
terraform validate
terraform plan -out=nf-gcp.tfplan
terraform apply nf-gcp.tfplan
```

Review every plan before applying it. To remove resources later, run `terraform destroy` after reviewing the destroy plan. The default `force_destroy_bucket = false` prevents Terraform from deleting a non-empty work bucket.

## Configure Nextflow

Use outputs after deployment:

```sh
terraform output -raw work_uri
terraform output -raw project_id
terraform output -raw region
terraform output -raw nextflow_job_service_account_email
```

Then copy and edit `nextflow.gcp.config.example` to configure `google-batch` with the returned values. Set `workDir` to the emitted `work_uri`, and assign `label 'head'` or `label 'worker'` in your pipeline processes when you want explicit head/worker machine-type selection.

## Files

- `versions.tf`: Terraform and Google provider version constraints
- `providers.tf`: Google provider configuration
- `main.tf`: shared labels and module invocation
- `variables.tf`: deployment inputs
- `outputs.tf`: useful module outputs
- `terraform.tfvars.example`: safe configuration template
- `nextflow.gcp.config.example`: starter Nextflow `google-batch` config
- `../modules/nf-gcp-batch`: reusable Batch IAM and GCS module

## GCP secrets payload for nf-command-center

```sh
terraform output -json |
jq '{
  gcp_project_id: .project_id.value,
  gcp_region: .region.value,
  gcp_work_bucket: .work_bucket_name.value,
  gcp_work_uri: .work_uri.value,
  gcp_launch_service_account_email: .nf_launch_run_service_account_email.value,
  gcp_job_service_account_email: .nextflow_job_service_account_email.value,
  gcp_datalink_service_account_email: .nfcc_datalink_service_account_email.value,
  gcp_use_spot: .use_spot.value,
  gcp_head_machine_type: .head_machine_type.value,
  gcp_worker_machine_type: .worker_machine_type.value
}'
```
