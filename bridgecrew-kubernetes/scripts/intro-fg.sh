#!/usr/bin/bash
set +x
WORKSHOP_HOMEDIR=/root

mkdir ${WORKSHOP_HOMEDIR}/.bcworkshop
echo "Welcome to the Bridgecrew K8S Workshop, lets get some quick setup details!"
echo "Enter your forked kustomizegoat URL..." 
read ; echo ${REPLY} > ${WORKSHOP_HOMEDIR}/.bcworkshop/gitcloneurl
echo "Enter your Bridgecrew API Token..."
read ; echo ${REPLY} > ${WORKSHOP_HOMEDIR}/.bcworkshop/bridgecrewtoken

echo "Waiting for initial workshop setup to complete..."

time while [ ! -f /opt/.signals-intro-bg-finished ] ; do tail /opt/.signals-intro-bg-status 2>/dev/null ; sleep 2; done; 

echo "Bridgecrew Workshop Environment Ready!"
echo "--------------------------------------"
echo ""
echo "KIND Kubernetes cluster info:"
kubectl cluster-info --context kind-bridgecrew-workshop

echo ""
echo "Checkov.io version:"
checkov --version

echo ""
echo "Yor.io version:"
docker run --tty --volume /root:/root bridgecrew/yor --version

