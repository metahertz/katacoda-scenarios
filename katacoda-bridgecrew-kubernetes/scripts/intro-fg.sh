#!/usr/bin/bash
set +x
WORKSHOP_HOMEDIR=/root

echo "Waiting for initial workshop setup to complete..."

time while [ ! -f /opt/.signals-intro-bg-finished ] ; do tail /opt/.signals-intro-bg-status 2>/dev/null ; sleep 2; done; 

echo "Bridgecrew Workshop Environment Ready!"
echo "--------------------------------------"
echo ""
echo "KIND Kubernetes cluster info:"
kubectl cluster-info --context kind-bridgecrew-workshop

echo ""
echo "Checkov.io version:"
docker run --tty --volume /root:/root bridgecrew/checkov --version
alias checkov="docker run --tty --volume /root:/root bridgecrew/checkov"

echo ""
echo "Yor.io version:"
docker run --tty --volume /root:/root bridgecrew/yor --version

