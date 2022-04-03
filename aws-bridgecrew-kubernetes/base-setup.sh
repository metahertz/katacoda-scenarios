#!/usr/bin/bash
WORKSHOP_USER=ubuntu
WORKSHOP_HOMEDIR=/home/${WORKSHOP_USER}

echo "Setting up KIND cli..."

curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/bin/kind

echo "Configuring KIND cluster environment..." 
cd ${WORKSHOP_HOMEDIR}; cat > ./kind-config.yaml << EOF
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 32080
    hostPort: 32080
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 32443
    hostPort: 32443
    listenAddress: "0.0.0.0"
    protocol: tcp
- role: worker
- role: worker
EOF

echo "Setting up KIND cluster..."
cd ${WORKSHOP_HOMEDIR}; sudo /usr/bin/kind create cluster --name bridgecrew-workshop --config=kind-config.yaml

echo "Installing kubectl cli..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/bin/kubectl

echo "Providing ${WORKSHOP_USER} access to KIND cluster..."
cd ${WORKSHOP_HOMEDIR}; sudo cp -rfv /root/.kube /home/${WORKSHOP_USER}/.kube
cd ${WORKSHOP_HOMEDIR}; sudo chown -R ${WORKSHOP_USER} /home/${WORKSHOP_USER}/.kube

echo "Installing ArgoCD into cluster..."
cd ${WORKSHOP_HOMEDIR}; kubectl create namespace argocd
cd ${WORKSHOP_HOMEDIR}; kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Setting access to Argo Web UI" 
kubectl patch svc argocd-server -n argocd --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":32080},{"op":"replace","path":"/spec/ports/1/nodePort","value":32443}]'

echo "Installing ArgoCD CLI..."
cd ${WORKSHOP_HOMEDIR}; sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
cd ${WORKSHOP_HOMEDIR}; sudo chmod +x /usr/local/bin/argocd

echo "Setting up pipenv..."
sudo apt install -y pipenv
cd ${WORKSHOP_HOMEDIR}; pipenv --python 3.8

echo "Installing Checkov..."
sudo docker pull bridgecrew/checkov

echo "Installing Yor..." 
sudo docker pull bridgecrew/yor

echo "Cloning KustomizeGoat..." 
cd ${WORKSHOP_HOMEDIR}; git clone https://github.com/bridgecrewio/kustomizegoat.git

echo "Cloning Workshop Utils..." 
cd ${WORKSHOP_HOMEDIR}; git clone https://github.com/metahertz/kubernetes-devsecops-workshop.git
chmod +x ${WORKSHOP_HOMEDIR}/kubernetes-devsecops-workshop/aws-bridgecrew-kubernetes/userscripts/*
#ln -s ${WORKSHOP_HOMEDIR}/userscripts ${WORKSHOP_HOMEDIR}/kubernetes-devsecops-workshop/aws-bridgecrew-kubernetes/userscripts

echo "done"