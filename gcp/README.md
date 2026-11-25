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

## Principals and permissions

The deployment creates these environment-specific service accounts and
bindings:

- The launch-run account has `roles/batch.jobsEditor` on the project and
  `roles/iam.serviceAccountUser` on the Nextflow job account. It also has
  access to the work bucket for staging and collecting workflow data.
- The Nextflow job account has `roles/batch.agentReporter` and
  `roles/logging.logWriter` on the project, plus work-bucket access for Batch
  task VMs.
- The nf-command-center datalink account has work-bucket access for data-link
  operations.

Enabling `batch.googleapis.com` creates the Google-managed Batch service
agent and grants it `roles/batch.serviceAgent` automatically. That managed
binding is intentionally not duplicated in Terraform.

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

Authenticate without placing credentials in Terraform files:

```sh
gcloud auth login
gcloud auth application-default login
gcloud projects list
gcloud config set project YOUR_PROJECT_ID
gcloud config get-value project
gcloud auth application-default set-quota-project YOUR_PROJECT_ID
export GOOGLE_PROJECT="$(gcloud config get-value project)"
echo $GOOGLE_PROJECT
```

```sh
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars for your region and optional project override.
bash scripts/init-gcp-backend.sh
terraform init
terraform fmt -check
terraform validate
terraform plan -out=nf-gcp.tfplan
terraform apply nf-gcp.tfplan

terraform apply -var-file=terraform.tfvars
terraform destroy -var-file=terraform.tfvars
```

This deployment stores Terraform state in the GCS bucket created by
`state-environment/gcp`, under `terraform/state/gcp/<environment>`. The init
wrapper reads `environment` from `terraform.tfvars` and passes the matching
backend prefix to Terraform. For an existing local state, run
`bash scripts/init-gcp-backend.sh -migrate-state` and review the migration
prompt before continuing. If `bucket_name` is set, the environment is
appended to keep work buckets distinct.

Review every plan before applying it. To remove resources later, run `terraform destroy` after reviewing the destroy plan. The default `force_destroy_bucket = false` prevents Terraform from deleting a non-empty work bucket.

## Resource inventory

For only the resource type and name:

```sh
terraform show -json |
jq -r '
  def resource_name:
    (.values.account_id // .values.name // .values.service // .values.id // .name);
  def rows($module):
    ($module.resources[]? | select(.mode != "data") | [.type, resource_name]),
    ($module.child_modules[]? | rows(.));
  ["TYPE", "NAME"],
  (rows(.values.root_module))
  | @tsv
' |
column -t -s $'\t'
```

After applying, list every resource in the state, including resources inside
the reusable module:

```sh
terraform show -json |
jq -r '
  def rows($module):
    ($module.resources[]? | select(.mode != "data") | [.type, resource_name, .address]),
    ($module.child_modules[]? | rows(.));
  ["TYPE", "NAME", "ADDRESS"],
  (rows(.values.root_module))
  | @tsv
' |
column -t -s $'\t'
```

The output includes the Terraform resource type, resource name, and full
provider resource name when available, and the full resource address. Data
resources are excluded. Save it as a file when needed:

```sh
terraform show -json |
jq -r 'def resource_name: (.values.account_id // .values.name // .values.service // .values.id // .name); def rows($module): ($module.resources[]? | select(.mode != "data") | [.type, resource_name, .address]), ($module.child_modules[]? | rows(.)); ["TYPE", "NAME", "ADDRESS"], (rows(.values.root_module)) | @tsv' |
column -t -s $'\t' > gcp-resource-inventory.txt
```

## Configure Nextflow

Use outputs after deployment:

```sh
terraform output -raw work_uri
terraform output -raw project_id
terraform output -raw region
terraform output -raw nextflow_job_service_account_email

# All Nextflow Google Batch parameters as one JSON object.
terraform output -json nextflow_config_parameters
```

Then copy and edit `nextflow.gcp.config.example` to configure `google-batch` with the returned values. Set `workDir` to the emitted `work_uri`, and assign `label 'head'` or `label 'worker'` in your pipeline processes when you want explicit head/worker machine-type selection.

## Files

- `versions.tf`: Terraform and Google provider version constraints
- `providers.tf`: Google provider configuration
- `main.tf`: shared labels and module invocation
- `variables.tf`: deployment inputs
- `outputs.tf`: useful module outputs
- `terraform.tfvars.example`: safe configuration template
- `scripts/init-gcp-backend.sh`: initializes the environment-specific GCS backend
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
