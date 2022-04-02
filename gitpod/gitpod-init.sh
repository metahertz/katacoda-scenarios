#!/usr/bin/bash
WORKSHOP_USER=gitpod
WORKSHOP_WORKDIR=/workspace/kubernetes-devsecops-workshop
WORKSHOP_HOMEDIR=/home/gitpod

# Gitpod prebuild container image already has installed Kind, Kubectl and Checkov for us.

echo "Configuring KIND cluster environment..." 
cat > ${WORKSHOP_HOMEDIR}/kind-config.yaml << EOF
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
EOF

echo "Setting up KIND cluster..."
cd ${WORKSHOP_HOMEDIR}; sudo /usr/bin/kind create cluster --name bridgecrew-workshop --config=${WORKSHOP_HOMEDIR}/kind-config.yaml

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

echo "Writing default Argo UI creds to ~/.argo-password" 
cd ${WORKSHOP_HOMEDIR}; kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > ${WORKSHOP_HOMEDIR}/.argo-password
echo "" >> ${WORKSHOP_HOMEDIR}/.argo-password

echo "Installing Yor..." 
sudo docker pull bridgecrew/yor

echo "Cloning KustomizeGoat..." 
cd ${WORKSHOP_WORKDIR}; git clone https://github.com/bridgecrewio/kustomizegoat.git

echo "done"