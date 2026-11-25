#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

tfvars_file="${TFVARS_FILE:-terraform.tfvars}"
if [[ ! -f "$tfvars_file" ]]; then
  printf 'Terraform variables file not found: %s\n' "$tfvars_file" >&2
  exit 1
fi

environment="$({ sed -nE 's/^[[:space:]]*environment[[:space:]]*=[[:space:]]*"([^"]+)".*$/\1/p' "$tfvars_file" | head -n 1; })"
if [[ -z "$environment" ]]; then
  printf 'No environment value found in %s\n' "$tfvars_file" >&2
  exit 1
fi

if [[ ! "$environment" =~ ^[a-z][a-z0-9-]{0,14}[a-z0-9]$ ]]; then
  printf 'Invalid environment value: %s\n' "$environment" >&2
  exit 1
fi

terraform init -backend-config="prefix=terraform/state/gcp/${environment}" "$@"
