import sys, os, datetime, json
import requests 

# EC2 Credentials role name
ec2MetaIamRoleName = 'demo-ec2-instance-role'

# Read EC2 IAM profile for creds. Fallback to ENV
try:
        iamMetaResponse = requests.get(f"http://169.254.169.254/latest/meta-data/iam/security-credentials/{ec2MetaIamRoleName}")
        iamCredentialsJson= json.loads(iamMetaResponse.text)
        access_key = iamCredentialsJson['AccessKeyId']
        secret_key = iamCredentialsJson['SecretAccessKey']
        session_token = iamCredentialsJson['Token']
except:
        print('No access key is available. Exiting')
        sys.exit()

# Set ENV's
os.environ["AWS_ACCESS_KEY_ID"] = access_key
os.environ["AWS_SECRET_ACCESS_KEY"] = secret_key
os.environ["AWS_SESSION_TOKEN"] = session_token