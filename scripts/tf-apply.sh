#!/usr/bin/env sh
set -eu

terraform init
terraform apply -var "tenancy_ocid=${TENANCY_OCID}"
