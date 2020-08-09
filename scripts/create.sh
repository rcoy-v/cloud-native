#!/usr/bin/env bash
set -euo pipefail

oci session authenticate --region $HOME_REGION

pushd tf
terraform init
terraform apply --auto-approve -var "tenancy_ocid=$TENANCY_OCID"
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

until [ $(kubectl get nodes | tail -n +2 | awk '{print $2}' | grep -e '^Ready$' | wc -l) == "2" ]; do
    echo "Waiting for kubernetes nodes to become ready. This may take a few minutes."
    sleep 15
done

helm template openfaas k8s/openfaas/ --namespace openfaas | kubectl apply -f -
deployments="alertmanager basic-auth-plugin faas-idler gateway nats prometheus queue-worker"
for deployment in $deployments; do
    kubectl -n openfaas rollout status deploy $deployment
done

OPENFAAS_GATEWAY_IP=""
while [ -z $OPENFAAS_GATEWAY_IP ]; do
    echo "Waiting for gateway external IP"
    sleep 5
    OPENFAAS_GATEWAY_IP=$(kubectl get svc gateway-external -n openfaas -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
done
echo "$OPENFAAS_GATEWAY_IP gateway.example" >> /etc/hosts

OPENFAAS_USER=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-user}" | base64 -d)
OPENFAAS_PASSWORD=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 -d)

faas-cli login -g http://gateway.example -u $OPENFAAS_USER -p $OPENFAAS_PASSWORD
faas-cli template pull
faas-cli deploy -f app.yaml

echo "Add $OPENFAAS_GATEWAY_IP gateway.example to your local hosts file"
