#!/usr/bin/bash
WORKSHOP_HOMEDIR=/home/ubuntu
WORKSHOP_AUTOMATION_DIR=${WORKSHOP_HOMEDIR}/.bcworkshop

mkdir ${WORKSHOP_AUTOMATION_DIR} || true

# "Welcome to the Palo Alto CTF Jam!

echo "Configuring git.."
git config --global user.email "jam-attendee@bridgecrew.local"
git config --global user.name "Palo CTF DevJam Automation"

echo "Pulling IAM EC2 Instance role credentials to ENV... "
CREDS=$(python3 /kubernetes-devsecops-workshop/aws-reinvent-jam-22/pull-iam-role-creds.py)
AWS_ACCESS_KEY_ID=$(echo ${CREDS} | awk -F" " '{ print $1 }')
AWS_SECRET_ACCESS_KEY=$(echo ${CREDS} | awk -F" " '{ print $2 }')
AWS_SESSION_TOKEN=$(echo ${CREDS} | awk -F" " '{ print $3 }')
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN

cp /var/log/cloud-init-output.log ${WORKSHOP_HOMEDIR}/AUTOMATION_COMPLETE
chown ubuntu ${WORKSHOP_HOMEDIR}/AUTOMATION_COMPLETE