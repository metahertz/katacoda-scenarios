#!/usr/bin/bash
WORKSHOP_HOMEDIR=/home/ubuntu
WORKSHOP_AUTOMATION_DIR=${WORKSHOP_HOMEDIR}/.bcworkshop

mkdir ${WORKSHOP_AUTOMATION_DIR} || true

# "Welcome to the Bridgecrew K8S Workshop, lets get some quick setup details!" #Params via Cloudformation
# "Enter your forked kustomizegoat URL..." 
echo $1 > ${WORKSHOP_HOMEDIR}/.bcworkshop/gitcloneurl
# "Enter your Bridgecrew API Token..."
echo $2 > ${WORKSHOP_HOMEDIR}/.bcworkshop/bridgecrewtoken
# "Your SSH public key for SSH Access..."
echo $3 >> ${WORKSHOP_HOMEDIR}/.ssh/authorized_keys


echo "Installing latest Checkov Kubernetes admission controller..." 
curl -o ${WORKSHOP_AUTOMATION_DIR}/checkov-admission-controller-setup.sh https://raw.githubusercontent.com/bridgecrewio/checkov/master/admissioncontroller/setup.sh
chmod +x ${WORKSHOP_AUTOMATION_DIR}/checkov-admission-controller-setup.sh
sed -i 's/\/usr\/local\/opt\/openssl\/bin\/openssl/openssl/' ${WORKSHOP_AUTOMATION_DIR}/checkov-admission-controller-setup.sh
sed -i 's/-sha256/-sha256 -subj "\/C=GB\/ST=USSEnterprise\/L=Quadrant42\/O=ExampleCert\/OU=ExampleCert\/CN=bridgecrewworkshop-user.local"/' ${WORKSHOP_AUTOMATION_DIR}/checkov-admission-controller-setup.sh
cd ${WORKSHOP_AUTOMATION_DIR}; ${WORKSHOP_AUTOMATION_DIR}/checkov-admission-controller-setup.sh bc-k8s-ws-cls1 $(cat ${WORKSHOP_AUTOMATION_DIR}/bridgecrewtoken)

echo "Waiting for Argo installation to be ready..."
until kubectl -n argocd get secret argocd-initial-admin-secret ; do echo "Still waiting on argo..." ; sleep 2 ; done

echo "Logging into to Argo via CLI..." 
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > ${WORKSHOP_AUTOMATION_DIR}/.argo-password

until argocd login 127.0.0.1:32443 --insecure --username admin --password $(cat ${WORKSHOP_AUTOMATION_DIR}/.argo-password) ; do sleep 2; echo "Waiting on sucessful argo login..." ; done

echo "Configuring ARGO example apps..." 
cat > ${WORKSHOP_AUTOMATION_DIR}/argo-dev.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kustomizegoat-dev
spec:
  destination:
    name: ''
    namespace: kustomizegoat-dev
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
    namespace: kustomizegoat-prod
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
until argocd app create --file ${WORKSHOP_AUTOMATION_DIR}/argo-dev.yaml ; do sleep 2; echo "Waiting on sucessful argo app creation (dev)..." ; done
until argocd app create --file ${WORKSHOP_AUTOMATION_DIR}/argo-prod.yaml ; do sleep 2; echo "Waiting on sucessful argo app creation (prod)..." ; done

