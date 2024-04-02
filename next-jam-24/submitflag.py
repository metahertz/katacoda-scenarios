import sys
import requests
from google.cloud import storage

# Check if the input is provided as a command-line argument
if len(sys.argv) < 2:
    print("Usage: python submitflag.py <flag>")
    sys.exit(1)

def get_project_id():
    # Create a client to interact with Cloud Storage (you can use any service, such as BigQuery or Compute Engine)
    client = storage.Client()
    # Retrieve the current project ID from the client
    project_id = client.project
    return project_id

# Get the project ID
project_id = get_project_id()

if project_id:
    print("Project ID:", project_id)
else:
    print("Failed to retrieve project ID. Please inform your challenge proctor!")

# URL of the API endpoint
url = f'http://panw-ctf-bank.c.{project_id}.internal:8080/flag'  

# Extract input from command-line arguments
input_data = sys.argv[1]

# Data to be sent in the request body
data = {
    'input': input_data  # Input data to be sent to the API
}

# Send POST request to the API
response = requests.post(url, json=data)

# Check if request was successful (status code 200)
if response.status_code == 200:
    print(response.json()) 
else:
    print(f"Request failed! Status code:{response.status_code}. Response: {response.json()}" )
