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
terraform init
terraform apply --auto-approve -var "tenancy_ocid=$TENANCY_OCID"
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

# Wait for OKE worker nodes to become ready.
until [ $(kubectl get nodes | tail -n +2 | awk '{print $2}' | grep -e '^Ready$' | wc -l) == "2" ]; do
    echo "Waiting for Kubernetes nodes to become ready. This may take a few minutes."
    sleep 15
done

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update

pushd k8s

helm install ingress-nginx ingress-nginx/ingress-nginx \
    -n ingress-nginx \
    --create-namespace \
    --version 2.11.2 \
    --wait \
    -f ingress-nginx/values.yaml

helm install cert-manager jetstack/cert-manager \
    -n cert-manager \
    --create-namespace \
    --version v0.16.1 \
    --wait \
    -f cert-manager/values.yaml

helm install openfaas ./openfaas \
  -n openfaas \
  --create-namespace \
  --wait

helm install grafana stable/grafana \
  -n grafana \
  --create-namespace \
  --version 5.5.5 \
  --wait \
  -f grafana/values.yaml

popd

# Setup local hosts entry for external LoadBalancer IP
OPENFAAS_GATEWAY_IP=""
while [ -z $OPENFAAS_GATEWAY_IP ]; do
    echo "Waiting for gateway external IP"
    sleep 5
    OPENFAAS_GATEWAY_IP=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
done
echo "$OPENFAAS_GATEWAY_IP gateway.example" >> /etc/hosts

# Trust self-signed cert when interacting with OpenFaaS gateway
kubectl -n openfaas get secret openfaas-tls -o "jsonpath={.data['tls\.crt']}" | base64 -d > /usr/local/share/ca-certificates/openfaas.crt
update-ca-certificates

OPENFAAS_USER=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-user}" | base64 -d)
OPENFAAS_PASSWORD=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 -d)

echo $OPENFAAS_PASSWORD | faas-cli login -g https://gateway.example -u $OPENFAAS_USER -s
faas-cli template pull
faas-cli deploy -f app.yaml -g https://gateway.example

echo "Add '$OPENFAAS_GATEWAY_IP gateway.example' to your local hosts file"
echo "Then access app at https://gateway.example/function/app"
echo "You can also sign in to the OpenFaas management console at https://gateway.example with the credentials $OPENFAAS_USER:$OPENFAAS_PASSWORD"
