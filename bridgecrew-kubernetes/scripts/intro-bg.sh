#!/bin/bash
WORKSHOP_HOMEDIR=/root

echo "Setting up KIND cli..." | tee > /opt/.signals-intro-bg-status

curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/bin/kind

# Looks like we cant change the VSCode basedir from /root :(
#echo "Setting up user environment..."
#useradd -m workshop.

echo "Configuring KIND cluster environment..." | tee > /opt/.signals-intro-bg-status
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
EOF

echo "Setting up KIND cluster..." | tee > /opt/.signals-intro-bg-status
cd ${WORKSHOP_HOMEDIR}; /usr/bin/kind create cluster --name bridgecrew-workshop --config=kind-config.yaml

echo "Installing kubectl cli..." | tee > /opt/.signals-intro-bg-status
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/bin/kubectl

echo "Installing ArgoCD into cluster..." | tee > /opt/.signals-intro-bg-status
cd ${WORKSHOP_HOMEDIR}; kubectl create namespace argocd
cd ${WORKSHOP_HOMEDIR}; kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Setting access to Argo Web UI" | tee > /opt/.signals-intro-bg-status
kubectl patch svc argocd-server -n argocd --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":32080},{"op":"replace","path":"/spec/ports/1/nodePort","value":32443}]'

echo "Installing ArgoCD CLI..." | tee > /opt/.signals-intro-bg-status
cd ${WORKSHOP_HOMEDIR}; curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
cd ${WORKSHOP_HOMEDIR}; chmod +x /usr/local/bin/argocd

echo "Installing Checkov Kubernetes admission controller..." | tee > /opt/.signals-intro-bg-status
curl –o ${WORKSHOP_HOMEDIR}/setup.sh https://raw.githubusercontent.com/bridgecrewio/checkov/master/admissioncontroller/setup.sh
chmod +x ${WORKSHOP_HOMEDIR}/setup.sh
${WORKSHOP_HOMEDIR}/setup.sh bc-k8s-ws-cls1 $(cat ${WORKSHOP_HOMEDIR}/.bcworkshop/bridgecrewtoken)


echo "Writing default Argo UI creds to ~/.argo-password" | tee > /opt/.signals-intro-bg-status
cd ${WORKSHOP_HOMEDIR}; kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > ${WORKSHOP_HOMEDIR}/.argo-password

echo "Configuring ARGO example apps..." | tee > /opt/.signals-intro-bg-status
cd ${WORKSHOP_HOMEDIR}; cat > .bcworkshop/argo-dev.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kustomizegoat-dev
spec:
  destination:
    name: ''
    namespace: kustomizegoat
    server: 'https://kubernetes.default.svc'
  source:
    path: kustomize/overlays/dev
    repoURL: "$(cat ${WORKSHOP_HOMEDIR}/.bcworkshop/gitcloneurl)"
    targetRevision: HEAD
  project: default
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
    syncOptions:
      - CreateNamespace=true
      - ApplyOutOfSyncOnly=true
EOF

cd ${WORKSHOP_HOMEDIR}; cat > .bcworkshop/argo-prod.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kustomizegoat-prod
spec:
  destination:
    name: ''
    namespace: kustomizegoat
    server: 'https://kubernetes.default.svc'
  source:
    path: kustomize/overlays/prod
    repoURL: "$(cat ${WORKSHOP_HOMEDIR}/.bcworkshop/gitcloneurl)"
    targetRevision: HEAD
  project: default
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
    syncOptions:
      - CreateNamespace=true
      - ApplyOutOfSyncOnly=true
EOF



echo "Configuring Argo APP deployments..." | tee > /opt/.signals-intro-bg-status
kubectl apply -f ${WORKSHOP_HOMEDIR}/.bcworkshop/argo-dev.yaml
kubectl apply -f ${WORKSHOP_HOMEDIR}/.bcworkshop/argo-prod.yaml

echo "Setting up pipenv..." | tee > /opt/.signals-intro-bg-status
apt install -y pipenv
cd ${WORKSHOP_HOMEDIR}; pipenv --python 3.8

echo "Installing Checkov..." | tee > /opt/.signals-intro-bg-status
cd ${WORKSHOP_HOMEDIR}; pipenv install checkov

echo "Installing Yor..." | tee > /opt/.signals-intro-bg-status
docker pull bridgecrew/yor

echo "Cloning KustomizeGoat..." | tee > /opt/.signals-intro-bg-status
cd ${WORKSHOP_HOMEDIR}; git clone https://github.com/bridgecrewio/kustomizegoat.git


echo "done" >> /opt/.signals-intro-bg-finished