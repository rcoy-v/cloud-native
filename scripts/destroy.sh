#!/usr/bin/env bash
set -euo pipefail

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

oci session authenticate --region $HOME_REGION

pushd tf
CLUSTER_OCID=$(terraform output -json | jq -r '.cluster_ocid.value')
popd

oci --auth security_token ce cluster create-kubeconfig \
    --cluster-id "$CLUSTER_OCID" \
    --overwrite

# Use security token authentication method for kubectl.
# Not possible to set directly through oci.
cat << EOF > /root/.kube/config
$(yq r -j /root/.kube/config | jq '.users[0].user.exec.args |= . + ["--auth", "security_token"]' | yq r -P -)
EOF

# Delete Kubernetes resources before destroying the OKE cluster, e.g. LoadBalancer services.
# OKE will not clean up any dynamically created infrastructure when a cluster is removed.
# This can prevent Terraform managed resources from being destroyed.
pushd k8s
helm template openfaas openfaas/ --namespace openfaas | kubectl delete -f -
kubectl delete -f openfaas/namespaces.yaml
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete ns ingress-nginx
helm uninstall cert-manager -n cert-manager
kubectl delete ns cert-manager
popd

pushd tf
terraform init
terraform destroy --auto-approve -var "tenancy_ocid=$TENANCY_OCID"
popd

echo "Everything has been successfully destroyed."
