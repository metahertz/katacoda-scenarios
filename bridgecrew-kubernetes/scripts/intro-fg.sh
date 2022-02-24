set +x

echo "Waiting for initial workshop setup to complete..."; 

while [ ! -f /opt/.signals-intro-bg-finished ] ; do tail /opt/.signals-intro-bg-status; sleep 2; done; 

echo "Bridgecrew Workshop Environment Ready!"
echo "--------------------------------------"
echo ""
echo "KIND Kubernetes cluster info:"
kubectl cluster-info --context kind-kind

echo ""
echo "Checkov.io version:"
checkov --version

echo ""
echo "Yor.io version:"
docker run --tty --volume /root:/root bridgecrew/yor --version

