#!/bin/bash
WORKSHOP_HOMEDIR=/root

echo "Setting up KIND cli..." | tee > /opt/.signals-intro-bg-status

curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/bin/kind

echo "Setting up KIND cluster..." | tee > /opt/.signals-intro-bg-status

/usr/bin/kind create cluster --name bridgecrew-workshop

echo "Installing kubectl cli..." | tee > /opt/.signals-intro-bg-status
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/bin/kubectl

# Looks like we cant change the VSCode basedir from /root :(
#echo "Setting up user environment..."
#useradd -m workshop.

echo "Setting up pipenv..." | tee > /opt/.signals-intro-bg-status
apt install -y pipenv
cd ${WORKSHOP_HOMEDIR}; pipenv --python 3.8

echo "Installing Checkov..." | tee > /opt/.signals-intro-bg-status
cd ${WORKSHOP_HOMEDIR}; pipenv install checkov

echo "Installing Yor..." | tee > /opt/.signals-intro-bg-status
docker pull bridgecrew/yor

echo "Cloning KustomizeGoat" | tee > /opt/.signals-intro-bg-status
cd ${WORKSHOP_HOMEDIR}; git clone https://github.com/bridgecrewio/kustomizegoat.git

echo "done" >> /opt/.signals-intro-bg-finished