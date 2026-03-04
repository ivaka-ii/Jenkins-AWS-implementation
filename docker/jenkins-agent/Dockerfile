FROM jenkins/inbound-agent:latest-jdk17

USER root

# Install core build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl unzip git jq make \
    && rm -rf /var/lib/apt/lists/*

# AWS CLI v2
RUN curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscli.zip \
    && unzip -qo /tmp/awscli.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/aws /tmp/awscli.zip

# Terraform
ARG TERRAFORM_VERSION=1.9.8
RUN curl -sL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
      -o /tmp/terraform.zip \
    && unzip -qo /tmp/terraform.zip -d /usr/local/bin \
    && rm /tmp/terraform.zip \
    && terraform version

# tflint
ARG TFLINT_VERSION=0.53.0
RUN curl -sL "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip" \
      -o /tmp/tflint.zip \
    && unzip -qo /tmp/tflint.zip -d /usr/local/bin \
    && rm /tmp/tflint.zip

# checkov (Python-based IaC scanner)
RUN apt-get update && apt-get install -y --no-install-recommends python3-pip \
    && pip3 install --no-cache-dir --break-system-packages checkov \
    && rm -rf /var/lib/apt/lists/*

USER jenkins
