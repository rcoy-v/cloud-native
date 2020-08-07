FROM python:alpine
WORKDIR /

RUN apk add --update --no-progress \
    alpine-sdk \
    libffi \
    libffi-dev \
    openssl \
    openssl-dev \
    terraform \
    bash
RUN pip install oci-cli

ENTRYPOINT ["echo", "Specify a script as entrypoint"]
