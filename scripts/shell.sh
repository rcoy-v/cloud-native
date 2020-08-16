#!/usr/bin/env bash
set -euo pipefail

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

OPENFAAS_GATEWAY_IP=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "$OPENFAAS_GATEWAY_IP gateway.example" >> /etc/hosts

kubectl -n openfaas get secret openfaas-tls -o "jsonpath={.data['tls\.crt']}" | base64 -d > /usr/local/share/ca-certificates/openfaas.crt
update-ca-certificates

bash
