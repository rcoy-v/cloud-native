#!/usr/bin/env bash
set -euo pipefail

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

msg() {
    printf "\n--- $1 ---\n\n"
}

msg 'Starting destroy script'

oci session authenticate --region $HOME_REGION

msg 'Configuring access to OKE cluster'
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
msg 'Finished configuring access to OKE cluster'


# Delete Kubernetes resources before destroying the OKE cluster, e.g. LoadBalancer services.
# OKE will not clean up any dynamically created infrastructure when a cluster is removed.
# This can prevent Terraform managed resources from being destroyed.
pushd k8s

msg 'Removing openfaas'
helm uninstall openfaas -n openfaas
kubectl delete ns openfaas
msg 'Finished removing openfaas'

msg 'Removing grafana'
helm uninstall grafana -n grafana
kubectl delete ns grafana
msg 'Finished removing grafana'

msg 'Removing ingress-nginx'
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete ns ingress-nginx
msg 'Finished removing ingress-nginx'

msg 'Removing cert-manager'
helm uninstall cert-manager -n cert-manager
kubectl delete ns cert-manager
msg 'Finished removing cert-manager'

popd

msg 'Destroying Terraform'
pushd tf
terraform init
terraform destroy --auto-approve -var "tenancy_ocid=$TENANCY_OCID"
popd
msg 'Finished Terraform'

msg 'Finished destroy script'
