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

echo "Logging into GH CLI..."
echo ${GHTOKEN} | gh auth login -h github.com -p https --with-token
echo "Creating fork of terragoat & cloning..."
cd ${WORKSHOP_HOMEDIR}; gh repo fork bridgecrewio/terragoat --clone

echo "Configuring git with GH token auth..."
git config --global user.email "workshop-automation@bridgecrew.local"
git config --global user.name "Bridgecrew Workshop Automation"
gh auth setup-git
gh auth status

echo "Adding sentinel policy files to Terragoat fork..."
cd ${WORKSHOP_HOMEDIR}/terragoat; tar -xzvf /kubernetes-devsecops-workshop/aws-bridgecrew-terraform/tfc-setup/tfc-policy-files.tgz
cd ${WORKSHOP_HOMEDIR}/terragoat; git add -A ; git commit -m "Terraform Cloud Bridgecrew Policy Configuration [BC Workshop]" ; git push

echo "Re-ownering the repo to workshop user ubuntu..."
chown -R ubuntu:ubuntu ${WORKSHOP_HOMEDIR}/terragoat

echo "Pulling IAM EC2 Instance role credentials to ENV for terraform cloud setup... "
CREDS=$(python3 /kubernetes-devsecops-workshop/aws-bridgecrew-terraform/pull-iam-role-creds.py)
AWS_ACCESS_KEY_ID=$(echo ${CREDS} | awk -F" " '{ print $1 }')
AWS_SECRET_ACCESS_KEY=$(echo ${CREDS} | awk -F" " '{ print $2 }')
AWS_SESSION_TOKEN=$(echo ${CREDS} | awk -F" " '{ print $3 }')
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN

echo "Configuring Terraform Cloud..."
# TFC ORG's need to be globally unique, TF apply will fail if not. 
# We add the last 4 digits of the current unix epoch to try and help this!
TFUNIQUETIMESTAMP=`date +%s |tail -c 5 |tr -d '\n'`
cd /kubernetes-devsecops-workshop/aws-bridgecrew-terraform/tfc-setup ; until terraform init ; do sleep 2 ; echo "Retrying terraform init..." ; done
cd /kubernetes-devsecops-workshop/aws-bridgecrew-terraform/tfc-setup ; until terraform apply -auto-approve -var="tfc_token=${TFCTOKEN}" -var="tfc_org_name=bc-${GHUSERNAME}-${TFUNIQUETIMESTAMP}" -var="github_pat=${GHTOKEN}" -var="terragoat_fork_name=${TERRAGOATFORKNAME}" -var="bc_api_key=${BRIDGECREWTOKEN}" -var="awsAccessKeyId=${AWS_ACCESS_KEY_ID}" -var="awsSecretAccessKey=${AWS_SECRET_ACCESS_KEY}" -var="awsSessionToken=${AWS_SESSION_TOKEN}" ; do sleep 2 ; echo "Retrying terraform apply..." ; done
terraform output -json | jq -r '@sh "export TFEWORKSPACEID=\(.tfe_workspace_id.value)"'

echo "Create TFC BC Integration..."

until curl -v "https://www.bridgecrew.cloud/api/v1/integrations" \
-X POST \
-H 'Host: www.bridgecrew.cloud' \
-H "Authorization: Bearer ${BRIDGECREWTOKEN}" \
-H 'Connection: keep-alive' \
-H 'Accept: application/json, text/plain, */*' \
-H 'content-type: application/json; charset=UTF-8' \
-d '{"type":"terraformCloud","alias":"tfCloud","params":{"active":true,"workspace_id":"${TFEWORKSPACEID}","description":"Terraform Cloud integration via Bridgecrew Workshop","workspace_name":"bridgecrew-workshop","token":"${TFCTOKEN}"}}' \
 ; do sleep 5 ; echo "Retrying BC Integration API for TFC..." ; done


cp /var/log/cloud-init-output.log ${WORKSHOP_HOMEDIR}/AUTOMATION_COMPLETE