set +x

{ echo "Waiting for initial workshop setup to complete..."; } 2> /dev/null

time while [ ! -f /opt/.signals-intro-bg-finished ] ; do tail /opt/.signals-intro-bg-status 2>/dev/null ; sleep 2; done; 

{ echo "Bridgecrew Workshop Environment Ready!" } 2> /dev/null
{ echo "--------------------------------------" } 2> /dev/null
{ echo "" } 2> /dev/null
{ echo "KIND Kubernetes cluster info:" } 2> /dev/null
kubectl cluster-info --context kind-bridgecrew-workshop

{ echo "" } 2> /dev/null
{ echo "Checkov.io version:" } 2> /dev/null
checkov --version

{ echo "" } 2> /dev/null
{ echo "Yor.io version:" } 2> /dev/null
docker run --tty --volume /root:/root bridgecrew/yor --version

