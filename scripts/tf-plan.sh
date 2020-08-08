#!/usr/bin/env sh
set -eu

terraform init
terraform plan -var "tenancy_ocid=${TENANCY_OCID}"
