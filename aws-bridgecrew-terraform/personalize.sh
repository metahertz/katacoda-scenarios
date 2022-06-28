#!/usr/bin/bash
WORKSHOP_HOMEDIR=/home/ubuntu
WORKSHOP_AUTOMATION_DIR=${WORKSHOP_HOMEDIR}/.bcworkshop

mkdir ${WORKSHOP_AUTOMATION_DIR} || true

# "Welcome to the Bridgecrew Terraform AWS Workshop, lets get some quick setup details!" #Params via Cloudformation
# "Enter your forked kustomizegoat URL..." 
GITCLONEURL=$1
echo $1 > ${WORKSHOP_HOMEDIR}/.bcworkshop/gitcloneurl
# "Enter your Bridgecrew API Token..."
BRIDGECREWTOKEN=$2
echo $2 > ${WORKSHOP_HOMEDIR}/.bcworkshop/bridgecrewtoken
# "Your Terraform Cloud API Token..."
TFCTOKEN=$3
echo $3 >> ${WORKSHOP_HOMEDIR}/.bcworkshop/tfctoken
# "Your GitHub Personal Access Token..."
GHTOKEN=$4
echo $4 >> ${WORKSHOP_HOMEDIR}/.bcworkshop/ghtoken

GHUSERNAME=`echo ${GITCLONEURL} | awk -F"/" '{ print $4 }'`
TERRAGOATFORKNAME=`echo ${GITCLONEURL} | awk -F"/" '{ print $4 "/" $5}' | awk -F"." '{ print $1 }'`

echo "Cloning Terragoat..." 
cd ${WORKSHOP_HOMEDIR}; git clone ${GITCLONEURL}
chown -R ubuntu:ubuntu ${WORKSHOP_HOMEDIR}/terragoat

echo "Pulling IAM EC2 Instance role credentials to ENV for terraform cloud setup... "
python3 /kubernetes-devsecops-workshop/aws-bridgecrew-terraform/pull-iam-role-creds.py

echo "Configuring Terraform Cloud..."
cd /kubernetes-devsecops-workshop/aws-bridgecrew-terraform/tfc-setup ; terraform init 
cd /kubernetes-devsecops-workshop/aws-bridgecrew-terraform/tfc-setup ;  terraform apply -auto-approve -var="tfc_token=${TFCTOKEN}" -var="tfc_org_name=bc-${GHUSERNAME}" -var="github_pat=${GHTOKEN}" -var="terragoat_fork_name=${TERRAGOATFORKNAME}" -var="bc_api_key=${BRIDGECREWTOKEN}" -var="awsAccessKeyId=${AWS_ACCESS_KEY_ID}" -var="awsSecretAccessKey=${AWS_SECRET_ACCESS_KEY}" -var="awsSessionToken=${AWS_SESSION_TOKEN}" 


cp /var/log/cloud-init-output.log ${WORKSHOP_HOMEDIR}/AUTOMATION_COMPLETE