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

msg 'Starting create script'

oci session authenticate --region $HOME_REGION

msg 'Applying Terraform'
pushd tf
terraform init
terraform apply --auto-approve -var "tenancy_ocid=$TENANCY_OCID"
CLUSTER_OCID=$(terraform output -json | jq -r '.cluster_ocid.value')
popd
msg 'Finished Terraform'

msg 'Configuring access to OKE cluster'
oci --auth security_token ce cluster create-kubeconfig \
    --cluster-id "$CLUSTER_OCID" \
    --overwrite

# Use security token authentication method for kubectl.
# Not possible to set directly through oci.
cat << EOF > /root/.kube/config
$(yq r -j /root/.kube/config | jq '.users[0].user.exec.args |= . + ["--auth", "security_token"]' | yq r -P -)
EOF
msg 'Finished configuring access to OKE cluster'

# Wait for OKE worker nodes to become ready.
until [ $(kubectl get nodes | tail -n +2 | awk '{print $2}' | grep -e '^Ready$' | wc -l) == "2" ]; do
    echo "Waiting for Kubernetes nodes to become ready. This may take a few minutes."
    sleep 15
done

msg 'Preparing Helm charts'
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
msg 'Finished Helm preparation'

pushd k8s

msg 'Installing ingress-nginx'
helm upgrade ingress-nginx ingress-nginx/ingress-nginx \
    -n ingress-nginx \
    --create-namespace \
    --version 2.11.2 \
    --install \
    --wait \
    -f ingress-nginx/values.yaml
msg 'Finished ingress-nginx'

if ! helm status cert-manager -n cert-manager &> /dev/null; then
    msg 'Installing cert-manager'
    helm install cert-manager jetstack/cert-manager \
        -n cert-manager \
        --create-namespace \
        --version v0.16.1 \
        --wait \
        -f cert-manager/values.yaml
    msg 'Finished cert-manager'
else
    msg 'cert-manager already installed; skipping'
fi

msg 'Installing openfaas'
helm upgrade openfaas ./openfaas \
  -n openfaas \
  --create-namespace \
  --install \
  --wait
msg 'Finished openfaas'

msg 'Installing grafana'
helm upgrade grafana stable/grafana \
  -n grafana \
  --create-namespace \
  --version 5.5.5 \
  --install \
  --wait \
  -f grafana/values.yaml
msg 'Finished openfaas'

popd

msg 'Gathering load balancer and gateway information'
# Setup local hosts entry for external LoadBalancer IP
OPENFAAS_GATEWAY_IP=""
while [ -z $OPENFAAS_GATEWAY_IP ]; do
    echo "Waiting for gateway external IP"
    sleep 5
    OPENFAAS_GATEWAY_IP=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
done
echo "$OPENFAAS_GATEWAY_IP gateway.example" >> /etc/hosts

# Trust self-signed cert when interacting with OpenFaaS gateway
kubectl -n openfaas get secret openfaas-ca -o "jsonpath={.data['tls\.crt']}" | base64 -d > /usr/local/share/ca-certificates/openfaas.crt
update-ca-certificates
msg 'Finished gathering load balancer and gateway information'

msg 'Deploying app function'
OPENFAAS_USER=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-user}" | base64 -d)
OPENFAAS_PASSWORD=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 -d)

echo $OPENFAAS_PASSWORD | faas-cli login -g https://gateway.example -u $OPENFAAS_USER -s
faas-cli template pull
faas-cli deploy -f app.yaml -g https://gateway.example
msg 'Finished deploying app function'

msg 'Testing public connectivity to function'
until curl https://gateway.example/function/app -m 5; do
    echo "Waiting for app to deploy"
done
msg 'Finished testing connectivity'

cat << EOF
Add '$OPENFAAS_GATEWAY_IP gateway.example' to your local hosts file
Then access app at https://gateway.example/function/app

You can also sign in to the OpenFaas management console at https://gateway.example with the credentials $OPENFAAS_USER:$OPENFAAS_PASSWORD
EOF

msg 'Finished create script'
