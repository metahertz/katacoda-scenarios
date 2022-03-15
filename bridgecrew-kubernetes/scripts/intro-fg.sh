#!/bin/bash
set +x
WORKSHOP_HOMEDIR=/root


echo "Welcome to the Bridgecrew K8S Workshop, lets get some quick setup details!"
echo "Enter your forked kustomizegoat URL..." 
read gitcloneurl
echo "Enter your Bridgecrew API Token..."
read bridgecrewtoken

{ echo "Waiting for initial workshop setup to complete..."; } 2>/dev/null

mkdir ${WORKSHOP_HOMEDIR}/.bcworkshop
echo ${gitcloneurl} > ${WORKSHOP_HOMEDIR}/.bcworkshop/gitcloneurl
echo ${bridgecrewtoken} > ${WORKSHOP_HOMEDIR}/.bcworkshop/bridgecrewtoken

time while [ ! -f /opt/.signals-intro-bg-finished ] ; do tail /opt/.signals-intro-bg-status 2>/dev/null ; sleep 2; done; 

{ echo "Bridgecrew Workshop Environment Ready!" } 2>/dev/null
{ echo "--------------------------------------" } 2>/dev/null
{ echo "" } 2> /dev/null
{ echo "KIND Kubernetes cluster info:" } 2>/dev/null
kubectl cluster-info --context kind-bridgecrew-workshop

{ echo "" } 2>/dev/null
{ echo "Checkov.io version:" } 2>/dev/null
checkov --version

{ echo "" } 2>/dev/null
{ echo "Yor.io version:" } 2>/dev/null
docker run --tty --volume /root:/root bridgecrew/yor --version

