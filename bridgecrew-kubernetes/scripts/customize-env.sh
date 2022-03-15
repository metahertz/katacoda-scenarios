mkdir ${WORKSHOP_HOMEDIR}/.bcworkshop
echo "Welcome to the Bridgecrew K8S Workshop, lets get some quick setup details!"
echo "Enter your forked kustomizegoat URL..." 
read ; echo ${REPLY} > ${WORKSHOP_HOMEDIR}/.bcworkshop/gitcloneurl  
echo "Enter your Bridgecrew API Token..."
read ; echo ${REPLY} > ${WORKSHOP_HOMEDIR}/.bcworkshop/bridgecrewtoken


echo "Installing Checkov Kubernetes admission controller..." | tee > /opt/.signals-intro-bg-status
curl –o ${WORKSHOP_HOMEDIR}/setup.sh https://raw.githubusercontent.com/bridgecrewio/checkov/master/admissioncontroller/setup.sh
chmod +x ${WORKSHOP_HOMEDIR}/setup.sh
${WORKSHOP_HOMEDIR}/setup.sh bc-k8s-ws-cls1 $(cat ${WORKSHOP_HOMEDIR}/.bcworkshop/bridgecrewtoken)



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
