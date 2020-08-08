#!/usr/bin/env sh
set -eu

terraform init
terraform destroy -var "tenancy_ocid=${TENANCY_OCID}"
