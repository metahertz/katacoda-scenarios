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

echo "Installing Checkov..."
#sudo docker pull bridgecrew/checkov

echo "Installing Yor..." 
sudo docker pull bridgecrew/yor

echo "Installing Terraform..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install -y terraform

echo "Installing JQ..."
sudo apt install -y jq

echo "Fixing up botocore dep version for checkov see https://github.com/aws/aws-cli/issues/3092..."
sudo apt -y remove python3-botocore
pip3 install botocore

echo "done"