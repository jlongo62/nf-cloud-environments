# GCP Terraform state environment

Creates a private, single-region Google Cloud Storage bucket for Terraform remote state. The bucket uses the configured `region`; the default bucket name is `nfcc-terraform-state-2c8f311b`.

## Security defaults

- Uniform bucket-level access
- Public access prevention enforced
- Object versioning enabled
- At least three newer versions retained before archived versions age out
- Noncurrent versions retained for 30 days by default
- Non-empty bucket deletion disabled by default
- Optional, unlocked retention policy

Google-managed encryption is used unless the configuration is extended with a customer-managed encryption key.

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

`gcloud config` and the Terraform Google provider use separate configuration chains. The
`GOOGLE_PROJECT` export passes the selected `gcloud` project to the provider, after which
Terraform reads it from `data.google_client_config.current`. No project ID belongs in tfvars.

Then initialize and apply:

```sh
export GOOGLE_PROJECT="$(gcloud config get-value project)"
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan -out=state-environment.tfplan
terraform apply state-environment.tfplan

terraform apply -var-file=terraform.tfvars
terraform destroy -var-file=terraform.tfvars
```

This bootstrap stack initially keeps its own state locally. Do not configure it to use the bucket it creates during the first apply.

## Use the backend

Use the output values in another Terraform root module:

```hcl
terraform {
  backend "gcs" {
    bucket = "nfcc-terraform-state-2c8f311b"
    prefix = "terraform/state"
  }
}
```

After adding the backend, run `terraform init -migrate-state`. Use a distinct prefix for each independently managed root module.

## Destruction

The default `force_destroy = false` prevents accidental deletion while state objects exist. Review all state migrations and backups before enabling destructive bucket removal. A configured retention policy can prevent object deletion until its retention period expires.
