#!/usr/bin/bash
WORKSHOP_USER=ubuntu
WORKSHOP_HOMEDIR=/home/${WORKSHOP_USER}
WORKSHOP_AUTOMATION_DIR=${WORKSHOP_HOMEDIR}/.bcworkshop

mkdir -p ${WORKSHOP_AUTOMATION_DIR} || true

echo "Extracting TGZ of Cloud9 compile/setup dir to save time..."
#apt install -y python2 
#curl -L https://raw.githubusercontent.com/c9/install/master/install.sh | bash &
#curl -L -o cloud9.tgz https://github.com/metahertz/kubernetes-devsecops-workshop/blob/main/aws-bridgecrew-kubernetes/c9-installed.tgz?raw=true
#tar -xzf cloud9.tgz
cp -Rf /.c9 ${WORKSHOP_HOMEDIR}/.
chown -Rf ubuntu:ubuntu ${WORKSHOP_HOMEDIR}/.c9
#Unmess pre-installed symlinks that wanted to point to root.
sudo rm ${WORKSHOP_HOMEDIR}/.c9/node/bin/node-gyp
sudo ln -s ${WORKSHOP_HOMEDIR}/.c9/node/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js ${WORKSHOP_HOMEDIR}/.c9/node/bin/node-gyp
sudo chown ubuntu:ubuntu ${WORKSHOP_HOMEDIR}/.c9/node/bin/node-gyp
sudo rm ${WORKSHOP_HOMEDIR}/.c9/bin/tmux
sudo ln -s ${WORKSHOP_HOMEDIR}/.c9/local/bin/tmux ${WORKSHOP_HOMEDIR}/.c9/bin/tmux
sudo chown ubuntu:ubuntu ${WORKSHOP_HOMEDIR}/.c9/bin/tmux
sudo rm ${WORKSHOP_HOMEDIR}/.c9/bin/sqlite3
sudo ln -s ${WORKSHOP_HOMEDIR}/.c9/lib/sqlite3/sqlite3 ${WORKSHOP_HOMEDIR}/.c9/bin/sqlite3
sudo chown ubuntu:ubuntu ${WORKSHOP_HOMEDIR}/.c9/bin/sqlite3
#Fix issue with finding valid terminfo for C9 Terminal
mkdir -p ${WORKSHOP_HOMEDIR}/.terminfo/x
cp /lib/terminfo/x/xterm-color /home/ubuntu/.terminfo/x/xterm-color

#cd ${WORKSHOP_HOMEDIR}; pipenv --python 3.8

echo "Configuring KIND cluster environment..." 
cat > ${WORKSHOP_AUTOMATION_DIR}/kind-config.yaml << EOF
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
networking:
  apiServerAddress: "0.0.0.0"
  # By default the API server listens on a random open port.
  # You may choose a specific port but probably don't need to in most cases.
  # Using a random port makes it easier to spin up multiple clusters.
  apiServerPort: 6443
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
  - containerPort: 38080
    hostPort: 38080
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 38081
    hostPort: 38081
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 38082
    hostPort: 38082
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 38083
    hostPort: 38083
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 38084
    hostPort: 38084
    listenAddress: "0.0.0.0"
    protocol: tcp
  - containerPort: 38085
    hostPort: 38085
    listenAddress: "0.0.0.0"
    protocol: tcp
- role: worker
- role: worker
EOF

echo "Setting up KIND cluster..."
cd ${WORKSHOP_AUTOMATION_DIR}; sudo /usr/bin/kind create cluster --name bridgecrew-workshop --config=kind-config.yaml

#echo "Installing kubectl cli..."
#curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
#chmod +x ./kubectl
#sudo mv ./kubectl /usr/bin/kubectl

echo "Providing ${WORKSHOP_USER} access to KIND cluster..."
cd ${WORKSHOP_HOMEDIR}; sudo cp -rfv /root/.kube /home/${WORKSHOP_USER}/.kube
cd ${WORKSHOP_HOMEDIR}; sudo chown -R ${WORKSHOP_USER} /home/${WORKSHOP_USER}/.kube

echo "Installing ArgoCD into cluster..."
cd ${WORKSHOP_HOMEDIR}; kubectl create namespace argocd
cd ${WORKSHOP_HOMEDIR}; kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Sprinkling some magic..."
# This is NOT a real secret (i'm looking at you checkov) it's just for a CTF "Flag"
echo "YXBpVmVyc2lvbjogdjEKa2luZDogU2VjcmV0Cm1ldGFkYXRhOgogIG5hbWU6IGRic2VjcmV0CnR5\
cGU6IE9wYXF1ZQpkYXRhOgogIFBPU1RHUkVTX1VTRVI6IFlXUnRhVzQ9CiAgUE9TVEdSRVNfUEFT\
U1dPUkQ6IFZHMVdNbHBZU1dkYU1qbDFZbTFGWjFveWJESmFVMEkxWWpOVloyUllRWE5KUnpWc1pH\
MVdlVWxIWkhaaWJUVm9TVWQ0YkdSRFFqVmlNMVZuV2tjNU0ySm5QVDA9Cg==" > ./jank.txt
cd ${WORKSHOP_HOMEDIR}; kubectl apply -f ./jank.txt

echo "Setting access to Argo Web UI" 
kubectl patch svc argocd-server -n argocd --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":32080},{"op":"replace","path":"/spec/ports/1/nodePort","value":32443}]'

echo "Installing ArgoCD CLI..."
#cd ${WORKSHOP_HOMEDIR}; sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
#cd ${WORKSHOP_HOMEDIR}; sudo chmod +x /usr/local/bin/argocd

echo "Installing MetalLB for Docker Bridge L2 Subnet..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
sleep 1
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
cat > ${WORKSHOP_AUTOMATION_DIR}/kind-metallb-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.18.255.10-172.18.255.250
EOF
kubectl apply -f ${WORKSHOP_AUTOMATION_DIR}/kind-metallb-config.yaml

echo "Cloning CTF attack tools..."
git clone https://github.com/eurogig/log4sheller.git
chown -R ubuntu ./log4sheller

echo "Installing Checkov..."
#sudo docker pull bridgecrew/checkov

echo "Installing Yor..." 
sudo docker pull bridgecrew/yor

echo "Installing GitHub cli..."
wget https://github.com/cli/cli/releases/download/v2.14.2/gh_2.14.2_linux_amd64.deb
sudo dpkg -i ./gh_2.14.2_linux_amd64.deb

echo "Installing Terraform..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install -y terraform

echo "Installing JQ..."
sudo apt install -y jq

echo "Fixing up botocore dep version for checkov see https://github.com/aws/aws-cli/issues/3092..."
sudo apt -y remove python3-botocore
pip3 install botocore

echo "Fixup AWSCLI install.."
sudo apt install -y awscli
sudo pip3 install --upgrade awscli

echo "Pushing Kubeconfig to SSM for CI.."
sudo aws ssm put-parameter \
    --region $(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region) \
    --name KUBECONFIG \
    --type SecureString \
    --key-id alias/aws/ssm \
    --value "$(sudo cat /root/.kube/config | base64)" \
    --tier Advanced

echo "done"