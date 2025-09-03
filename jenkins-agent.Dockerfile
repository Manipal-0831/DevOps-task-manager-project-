FROM jenkins/agent:latest

USER root

# Install basics
RUN apt-get update && apt-get install -y \
    curl wget git unzip jq gnupg lsb-release \
    software-properties-common python3 python3-pip

# Install Docker CLI
RUN curl -fsSL https://get.docker.com | sh

# Install kubectl
RUN set -eux; \
    KUBECTL_VERSION="$(curl -s https://dl.k8s.io/release/stable.txt)"; \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"; \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl; \
    rm kubectl

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
    && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    && apt-get update && apt-get install terraform -y

# Install Trivy
RUN apt-get install -y wget apt-transport-https gnupg lsb-release \
    && wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add - \
    && echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | tee /etc/apt/sources.list.d/trivy.list \
    && apt-get update && apt-get install trivy -y

# Install Bandit (Python security)
RUN pip install bandit

# Install Node.js & npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
     && apt-get install -y nodejs 

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

USER jenkins
