#!/usr/bin/bash
WORKSHOP_HOMEDIR=/home/ubuntu
WORKSHOP_AUTOMATION_DIR=${WORKSHOP_HOMEDIR}/.bcworkshop

mkdir ${WORKSHOP_AUTOMATION_DIR} || true

echo "Welcome to the Bridgecrew K8S Workshop, lets get some quick setup details!"
echo "Enter your forked kustomizegoat URL..." 
read ; echo ${REPLY} > ${WORKSHOP_HOMEDIR}/.bcworkshop/gitcloneurl  
echo "Enter your Bridgecrew API Token..."
read ; echo ${REPLY} > ${WORKSHOP_HOMEDIR}/.bcworkshop/bridgecrewtoken


echo "Installing latest Checkov Kubernetes admission controller..." 
curl -o ${WORKSHOP_AUTOMATION_DIR}/checkov-admission-controller-setup.sh https://raw.githubusercontent.com/bridgecrewio/checkov/master/admissioncontroller/setup.sh
chmod +x ${WORKSHOP_AUTOMATION_DIR}/checkov-admission-controller-setup.sh
sed -i 's/\/usr\/local\/opt\/openssl\/bin\/openssl/openssl/' ${WORKSHOP_AUTOMATION_DIR}/checkov-admission-controller-setup.sh
sed -i 's/-sha256/-sha256 -subj "\/C=GB\/ST=USSEnterprise\/L=Quadrant42\/O=ExampleCert\/OU=ExampleCert\/CN=bridgecrewworkshop-user.local"' ${WORKSHOP_AUTOMATION_DIR}/checkov-admission-controller-setup.sh
cd ${WORKSHOP_AUTOMATION_DIR}; ${WORKSHOP_AUTOMATION_DIR}/checkov-admission-controller-setup.sh bc-k8s-ws-cls1 $(cat ${WORKSHOP_AUTOMATION_DIR}/bridgecrewtoken)

echo "Waiting for Argo installation to be complete..."
until kubectl -n argocd get secret argocd-initial-admin-secret ; do echo "Still waiting on argo..." ; sleep 2 ; done

echo "Logging into to Argo via CLI..."

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > ${WORKSHOP_AUTOMATION_DIR}/.argo-password
argocd login 127.0.0.1:32443 --insecure --username admin --password $(cat ${WORKSHOP_AUTOMATION_DIR}/.argo-password)


echo "Configuring ARGO example apps..." 
cat > ${WORKSHOP_AUTOMATION_DIR}/argo-dev.yaml << EOF
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
    repoURL: "$(cat ${WORKSHOP_AUTOMATION_DIR}/gitcloneurl)"
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

cat > ${WORKSHOP_AUTOMATION_DIR}/argo-prod.yaml << EOF
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
    repoURL: "$(cat ${WORKSHOP_AUTOMATION_DIR}/gitcloneurl)"
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

echo "Configuring Argo APP deployments..."
argocd app create --file ${WORKSHOP_AUTOMATION_DIR}/argo-dev.yaml
argocd app create --file ${WORKSHOP_AUTOMATION_DIR}/argo-prod.yaml


