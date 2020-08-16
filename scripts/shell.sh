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

oci session authenticate --region $HOME_REGION

msg 'Configuring access to OKE cluster'
pushd tf
CLUSTER_OCID=$(terraform output -json | jq -r '.cluster_ocid.value')
popd

oci --auth security_token ce cluster create-kubeconfig \
    --cluster-id "$CLUSTER_OCID" \
    --overwrite

cat << EOF > /root/.kube/config
$(yq r -j /root/.kube/config | jq '.users[0].user.exec.args |= . + ["--auth", "security_token"]' | yq r -P -)
EOF
msg 'Finished configuring access to OKE cluster'

msg 'Adding host record for gateway.example'
OPENFAAS_GATEWAY_IP=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "$OPENFAAS_GATEWAY_IP gateway.example" >> /etc/hosts
msg 'Finished host record'

msg 'Adding gateway self-signed cert to local trust store'
kubectl -n openfaas get secret openfaas-ca -o "jsonpath={.data['ca\.crt']}" | base64 -d > /usr/local/share/ca-certificates/openfaas.crt
update-ca-certificates
msg 'Finished cert trust'

msg 'Authenticating faas-cli to gateway'
OPENFAAS_USER=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-user}" | base64 -d)
OPENFAAS_PASSWORD=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 -d)
echo $OPENFAAS_PASSWORD | faas-cli login -g https://gateway.example -u $OPENFAAS_USER -s
msg 'Finished faas-cli login'

bash
