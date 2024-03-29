#!/usr/bin/bash
echo 'APT::Periodic::Update-Package-Lists "0";' > /etc/apt/apt.conf.d/20auto-upgrades
echo 'APT::Periodic::Unattended-Upgrade "0";' >>  /etc/apt/apt.conf.d/20auto-upgrades

WORKSHOP_USER=ubuntu
WORKSHOP_HOMEDIR=/home/${WORKSHOP_USER}
WORKSHOP_AUTOMATION_DIR=${WORKSHOP_HOMEDIR}/.panwctf

mkdir -p ${WORKSHOP_AUTOMATION_DIR} || true
sudo apt-get update

sudo apt install python3

echo "Cloning CTF attack tools..."
cd ${WORKSHOP_HOMEDIR}; git clone https://github.com/eurogig/log4sheller.git
chmod -R 777 ${WORKSHOP_HOMEDIR}/log4sheller
cd ${WORKSHOP_HOMEDIR}/log4sheller ; sudo bash init.sh   


cd ${WORKSHOP_AUTOMATION_DIR}; curl -fsSL https://code-server.dev/install.sh | sh
cd ${WORKSHOP_AUTOMATION_DIR}; nohup code-server --auth none --bin-addr 0.0.0.0:8081 &

