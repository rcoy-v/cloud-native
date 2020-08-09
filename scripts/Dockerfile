FROM python:alpine

RUN apk add --update --no-progress \
    alpine-sdk \
    libffi \
    libffi-dev \
    openssl \
    openssl-dev \
    ca-certificates \
    terraform \
    bash \
    jq

RUN wget -qO /usr/bin/yq https://github.com/mikefarah/yq/releases/download/3.3.2/yq_linux_amd64 && \
    chmod +x /usr/bin/yq && \
    yq -h

RUN pip install --quiet oci-cli && \
    oci -v

RUN wget -qO /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.16.8/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    kubectl version --client

RUN wget -qO /opt/helm.tar.gz https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz && \
    cd /opt && \
    tar -zxf helm.tar.gz && \
    chmod +x linux-amd64/helm && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    helm version

RUN wget -qO /usr/local/bin/faas-cli https://github.com/openfaas/faas-cli/releases/download/0.12.8/faas-cli && \
    chmod +x /usr/local/bin/faas-cli && \
    faas-cli version

WORKDIR /usr/src/app

ENTRYPOINT ["echo", "Specify a script as entrypoint"]
