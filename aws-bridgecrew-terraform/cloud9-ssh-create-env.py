## API Creation of AWS Cloud9 "SSH" instances.
## Matt Johnson <matt@metahertz.co.uk>
### SSH Instances allow Cloud9 to be run ontop of existing systems, rather than a cloud9-managed EC2 Instance.
### They are useful as Cloud9 does not allow pre-customization of a Cloud9-managed instance.
### The API is undocumented, allowing creation only via the AWS console. Hence this script.

import sys, os, datetime, json
import requests 
from requests_aws4auth import AWS4Auth
from time import sleep

# Cloud9 Environment Details
cloud9InstanceName = "bridgecrew-workshop"
cloud9SshPort = "22"
cloud9SshLoginName = "ubuntu"

# EC2 Credentials role name
ec2MetaIamRoleName = 'demo-ec2-instance-role'

# Read in the AWS Account ID and user details so we can add the end user to the Cloud9 env
awsOrgID = sys.argv[1]
awsRoleID = sys.argv[2]
awsAssumedUser = sys.argv[3]

# Read EC2 IAM profile for creds, fallback to ENV
try:
        iamMetaResponse = requests.get(f"http://169.254.169.254/latest/meta-data/iam/security-credentials/{ec2MetaIamRoleName}")
        iamCredentialsJson= json.loads(iamMetaResponse.text)
        access_key = iamCredentialsJson['AccessKeyId']
        secret_key = iamCredentialsJson['SecretAccessKey']
        session_token = iamCredentialsJson['Token']
except:
    # Read AWS access key from env. variables or configuration file. Best practice is NOT
    # to embed credentials in code.
    access_key = os.environ.get('AWS_ACCESS_KEY_ID')
    secret_key = os.environ.get('AWS_SECRET_ACCESS_KEY')
    session_token = os.environ.get('AWS_SESSION_TOKEN')
    if access_key is None or secret_key is None:
        print('No access key is available. Exiting')
        sys.exit()

# Read public IPv4 address for use with Cloud9
try:
    publicIpv4Response = requests.get("http://169.254.169.254/latest/meta-data/public-ipv4")
    cloud9SshHost = publicIpv4Response.text
    #Append IP to workshop name for uniqueness (proctor account will see all C9 Env's)
    cloud9InstanceName = f"bridgecrew-workshop-{cloud9SshHost}"

except:
   print('No public IP available from metadata. Exiting')
   sys.exit()

method = 'POST'
service = 'cloud9'
region = 'us-west-2'
host = f'{service}.{region}.amazonaws.com'
endpoint = f'https://{service}.{region}.amazonaws.com/'
content_type = 'application/x-amz-json-1.1'
amz_target = 'AWSCloud9WorkspaceManagementService.GetUserPublicKey'
request_parameters = '''{"name":"f'{cloud9InstanceName}'"}'''


auth = AWS4Auth(access_key, secret_key, region, service, session_token=session_token)

# Create a date for headers
t = datetime.datetime.utcnow()
amz_date = t.strftime('%Y%m%dT%H%M%SZ')
date_stamp = t.strftime('%Y%m%d') # Date w/o time, used in credential scope

headers = {'Content-Type':content_type,
           'Accept-Encoding':'identity',
           'User-Agent':'aws-cli/2.4.25 Python/3.9.12 Darwin/20.6.0 source/x86_64 prompt/off command/cloud9.get-user-public-key',
           'X-Amz-Target':amz_target,
           'X-Amz-Date':amz_date,
           'X-Amz-Security-Token': session_token,
           'Connection': None,
           'Accept': None
           }


#Get SSH Key for Instance Cloud9 Access 
print('\nSSH PubKey Request...')
try:
    r = requests.post(endpoint, data=request_parameters, headers=headers, verify=False, auth=auth )

    print('SSH PubKey Request, Response code: %d\n' % r.status_code)
    print(r.text)
    sshKeyforAuthorizedHosts = json.loads(r.text)
    sshKeyforAuthorizedHosts = sshKeyforAuthorizedHosts['publicKey']


    # Add SSH key to our authorized_keys ready for SSH Cloud9 Connection
    with open(f'/home/{cloud9SshLoginName}/.ssh/authorized_keys', 'a') as fd:
        fd.write(f'{sshKeyforAuthorizedHosts}')

except:
   print('Unable to request Public SSH key for Cloud9 setup. Exiting.')
   sys.exit()

print('\nCreate ENV Request...')
print('Request URL = ' + endpoint)

newEnironmentID = ""
envCreateResponse = 0
lastFourDigitsToken = 0000
while envCreateResponse != 200:
    amz_target = 'AWSCloud9WorkspaceManagementService.CreateEnvironmentSSH'
    request_parameters =  "{" + f'"name":"{cloud9InstanceName}","clientRequestToken":"cloud9-console-73d36992-9b69-413c-8035-bf0ff4dc6d4b{lastFourDigitsToken}","tags":[],"host":"{cloud9SshHost}","port":{cloud9SshPort},"loginName":"{cloud9SshLoginName}","dryRun":"false"' + "}"

    headers = {'Content-Type':content_type,
            'Accept-Encoding':'identity',
            'User-Agent':'aws-cli/2.4.25 Python/3.9.12 Darwin/20.6.0 source/x86_64 prompt/off command/cloud9.create-environment-ssh',
            'X-Amz-Target':amz_target,
            'X-Amz-Date':amz_date,
            'X-Amz-Security-Token': session_token,
            'Connection': None,
            'Accept': None,
            
            }

    r = requests.post(endpoint, data=request_parameters, headers=headers, verify=False, auth=auth )
    print('Env Creation Request, Response code: %d\n' % r.status_code)
    envCreateResponse = r.status_code
    print(r.text)
    sleep(3)
    lastFourDigitsToken = lastFourDigitsToken + 1

newEnironmentID = json.loads(r.text)
newEnironmentID = newEnironmentID['environmentId']


print('\nAdding workshop assumed role to env...')
print('Request URL = ' + endpoint)

amz_target = 'AWSCloud9WorkspaceManagementService.CreateEnvironmentMembership'
request_parameters =  "{" + f'"environmentId":"{newEnironmentID}","userArn":"arn:aws:sts::{awsOrgID}:assumed-role/{awsRoleID}/{awsAssumedUser}","permissions":"read-write"' + "}"

headers = {'Content-Type':content_type,
           'Accept-Encoding':'identity',
           'User-Agent':'aws-cli/2.4.25 Python/3.9.12 Darwin/20.6.0 source/x86_64 prompt/off command/cloud9.create-environment-membership',
           'X-Amz-Target':amz_target,
           'X-Amz-Date':amz_date,
           'X-Amz-Security-Token': session_token,
           'Connection': None,
           'Accept': None,
           
           }

r = requests.post(endpoint, data=request_parameters, headers=headers, verify=False, auth=auth )
print('Env Sharing Request, Response code: %d\n' % r.status_code)
print(r.text)


print('\nAdding workshop proctor account to env...')
print('Request URL = ' + endpoint)

amz_target = 'AWSCloud9WorkspaceManagementService.CreateEnvironmentMembership'
request_parameters =  "{" + f'"environmentId":"{newEnironmentID}","userArn":"arn:aws:iam::325714095067:user/proctor1","permissions":"read-write"' + "}"

headers = {'Content-Type':content_type,
           'Accept-Encoding':'identity',
           'User-Agent':'aws-cli/2.4.25 Python/3.9.12 Darwin/20.6.0 source/x86_64 prompt/off command/cloud9.create-environment-membership',
           'X-Amz-Target':amz_target,
           'X-Amz-Date':amz_date,
           'X-Amz-Security-Token': session_token,
           'Connection': None,
           'Accept': None,
           
           }

r = requests.post(endpoint, data=request_parameters, headers=headers, verify=False, auth=auth )
print('Add env to proctor account, Response code: %d\n' % r.status_code)
print(r.text)

