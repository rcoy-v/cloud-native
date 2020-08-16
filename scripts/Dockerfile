FROM python:alpine

RUN apk add --update --no-progress --no-cache\
    alpine-sdk \
    libffi \
    libffi-dev \
    openssl \
    openssl-dev \
    ca-certificates \
    terraform \
    bash \
    jq \
    tmux \
    npm

RUN wget -qO /usr/bin/yq https://github.com/mikefarah/yq/releases/download/3.3.2/yq_linux_amd64 && \
    chmod +x /usr/bin/yq && \
    yq -h &> /dev/null

RUN pip install --quiet oci-cli && \
    oci -v &> /dev/null

RUN wget -qO /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    kubectl version --client &> /dev/null

RUN wget -qO /opt/helm.tar.gz https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz && \
    cd /opt && \
    tar -zxf helm.tar.gz && \
    chmod +x linux-amd64/helm && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    helm version &> /dev/null

RUN wget -qO /usr/local/bin/faas-cli https://github.com/openfaas/faas-cli/releases/download/0.12.8/faas-cli && \
    chmod +x /usr/local/bin/faas-cli && \
    faas-cli version &> /dev/null

RUN npm i -qg artillery --unsafe-perm=true && \
    artillery version &> /dev/null

WORKDIR /usr/src/app

ENTRYPOINT ["echo", "Specify a script as entrypoint"]
