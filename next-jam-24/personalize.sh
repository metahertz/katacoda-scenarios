#!/usr/bin/bash
WORKSHOP_HOMEDIR=/home/ubuntu
WORKSHOP_AUTOMATION_DIR=${WORKSHOP_HOMEDIR}/.bcworkshop

mkdir ${WORKSHOP_AUTOMATION_DIR} || true

# "Welcome to the Palo Alto CTF Jam!

echo "Configuring git.."
git config --global user.email "jam-attendee@pan.dev"
git config --global user.name "Palo CTF DevJam Automation"


cp /var/log/cloud-init-output.log ${WORKSHOP_HOMEDIR}/AUTOMATION_COMPLETE
chown ubuntu ${WORKSHOP_HOMEDIR}/AUTOMATION_COMPLETE