#!/usr/bin/env bash
set -euo pipefail

#oci session authenticate --region $HOME_REGION

pushd /tf
terraform init
terraform destroy --auto-approve \
    -var "tenancy_ocid=$TENANCY_OCID"
