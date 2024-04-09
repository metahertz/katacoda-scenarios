#!/usr/bin/bash
echo 'APT::Periodic::Update-Package-Lists "0";' > /etc/apt/apt.conf.d/20auto-upgrades
echo 'APT::Periodic::Unattended-Upgrade "0";' >>  /etc/apt/apt.conf.d/20auto-upgrades

WORKSHOP_USER=ubuntu
WORKSHOP_HOMEDIR=/home/${WORKSHOP_USER}
WORKSHOP_AUTOMATION_DIR=${WORKSHOP_HOMEDIR}/.panwctf

mkdir -p ${WORKSHOP_AUTOMATION_DIR} || true
sudo apt-get update

sudo apt install python3
sudo python3 -m pip install requests
sudo cp /kubernetes-devsecops-workshop/next-jam-24/submitflag.py /usr/bin/submitflag
sudo chmod +x /usr/bin/submitflag
sudo python3 -m pip install google-cloud
sudo python3 -m pip install google-cloud-vision
sudo python3 -m pip install google.cloud.storage

echo "Cloning CTF attack tools..."
cd ${WORKSHOP_HOMEDIR}; git clone https://github.com/eurogig/log4sheller.git
chmod -R 777 ${WORKSHOP_HOMEDIR}/log4sheller
cd ${WORKSHOP_HOMEDIR}/log4sheller ; sudo bash init.sh   


cd ${WORKSHOP_AUTOMATION_DIR}; curl -fsSL https://code-server.dev/install.sh | sh
sudo apt
cat > '/usr/lib/systemd/system/code-server@.service' << EOF
[Unit]
Description=code-server
After=network.target

[Service]
Type=exec
ExecStart=/usr/bin/code-server --auth none --host 0.0.0.0
Restart=always
User=%i

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
cd ${WORKSHOP_AUTOMATION_DIR}; sudo systemctl enable --now code-server@${WORKSHOP_USER}

git config --global user.email “ctf-user@pan.dev"
git config --global user.name "PaloCTF User”
cd ${WORKSHOP_HOMEDIR}; gcloud source repos clone jankybank
chmod -R 777 ${WORKSHOP_HOMEDIR}/jankybank
