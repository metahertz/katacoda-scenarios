FROM gitpod/workspace-full

LABEL maintainer="mattjohnson@paloaltonetworks.com"
WORKDIR /

RUN apt update && apt install -y curl

# Install KIND
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64 \
    && chmod +x ./kind \
    && mv ./kind /usr/bin/kind 

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/bin/kubectl

# Install pipenv
#RUN apt update \
#    && apt install -y pipenv

# Create pipenv
#RUN pipenv --python 3.8

# Install Checkov
RUN pip3 install checkov

