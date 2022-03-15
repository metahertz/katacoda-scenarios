#!/usr/bin/bash
WORKSHOP_HOMEDIR=/root

mkdir ${WORKSHOP_HOMEDIR}/.bcworkshop || true

echo "Welcome to the Bridgecrew K8S Workshop, lets get some quick setup details!"
echo "Enter your forked kustomizegoat URL..." 
read ; echo ${REPLY} > ${WORKSHOP_HOMEDIR}/.bcworkshop/gitcloneurl  
echo "Enter your Bridgecrew API Token..."
read ; echo ${REPLY} > ${WORKSHOP_HOMEDIR}/.bcworkshop/bridgecrewtoken


echo "Installing Checkov Kubernetes admission controller..." | tee > /opt/.signals-intro-bg-status
curl -o ${WORKSHOP_HOMEDIR}/setup.sh https://raw.githubusercontent.com/bridgecrewio/checkov/master/admissioncontroller/setup.sh
chmod +x ${WORKSHOP_HOMEDIR}/setup.sh
sed -i 's/\/usr\/local\/opt\/openssl\/bin\/openssl/openssl/' setup.sh
${WORKSHOP_HOMEDIR}/setup.sh bc-k8s-ws-cls1 $(cat ${WORKSHOP_HOMEDIR}/.bcworkshop/bridgecrewtoken)




echo "Logging into to Argo via CLI..." | tee > /opt/.signals-intro-bg-status
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > ${WORKSHOP_HOMEDIR}/.bcworkshop/.argo-password
argocd login 127.0.0.1:32443 --insecure --username admin --password $(cat ${WORKSHOP_HOMEDIR}/.bcworkshop/.argo-password)


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
    targetRevision: namespacing
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
    targetRevision: namespacing
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
argocd app create --file ${WORKSHOP_HOMEDIR}/.bcworkshop/argo-dev.yaml
argocd app create --file ${WORKSHOP_HOMEDIR}/.bcworkshop/argo-prod.yaml


