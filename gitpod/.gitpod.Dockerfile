FROM gitpod/workspace-full

LABEL maintainer="mattjohnson@paloaltonetworks.com"
WORKDIR /tmp

RUN sudo apt update && sudo apt install -y curl

# Install KIND
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64 \
    && sudo chmod +x ./kind \
    && sudo mv ./kind /usr/bin/kind 

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && sudo chmod +x ./kubectl \
    && sudo mv ./kubectl /usr/bin/kubectl

# Install pipenv
#RUN apt update \
#    && apt install -y pipenv

# Create pipenv
#RUN pipenv --python 3.8

# Install Checkov
RUN sudo pip3 install checkov

