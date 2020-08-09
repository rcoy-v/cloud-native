#!/usr/bin/env bash
set -euo pipefail

oci session authenticate --region $HOME_REGION

pushd tf
CLUSTER_OCID=$(terraform output -json | jq -r '.cloud_native_cluster_ocid.value')
popd

oci --auth security_token ce cluster create-kubeconfig \
    --cluster-id "$CLUSTER_OCID" \
    --overwrite

# Use security token authentication method for kubectl.
# Not possible to set directly through oci.
cat << EOF > /root/.kube/config
$(yq r -j /root/.kube/config | jq '.users[0].user.exec.args |= . + ["--auth", "security_token"]' | yq r -P -)
EOF

helm template openfaas k8s/openfaas/ --namespace openfaas | kubectl delete -f -

pushd tf
terraform init
terraform destroy --auto-approve -var "tenancy_ocid=$TENANCY_OCID"
popd
