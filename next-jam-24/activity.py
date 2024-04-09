from flask import Flask, request, jsonify
from google.cloud import bigtable
from google.cloud.bigtable import column_family
from google.cloud.bigtable.row_filters import RowKeyRegexFilter

app = Flask(__name__)

# Google Cloud Bigtable configuration
instance_id = 'ctf-status'
table_id = 'progress'
column_family_id = 'fam1'
column_id = 'success'

# Initialize Bigtable client
client = bigtable.Client(admin=True)
instance = client.instance(instance_id)
table = instance.table(table_id)

# Dict lookup for simple CTF flag responder.
flagdata = {
    "ipchange": "1",
    "The username/password you entered was invalid. We have logged your information for security purposes": "2",
    "${jndx:ldxp://": "3",
    "TmV2ZXIgZ29ubmEgZ2l2ZSB5b3UgdXAsIG5ldmVyIGdvbm5hIGxldCB5b3UgZG93bg==": "4",
    "Never gonna give you up, never gonna let you down":"4",
    "TmV2ZXIgZ29ubmEgcnVuIGFyb3VuZCBhbmQsIGRlc2VydCB5b3U=": "5",
    "- checkov -d . -o junitxml --bc-api-key $BC_API_KEY --repo-id $CODEBUILD_ACCOUNT_ID/$CODEBUILD_PROJECT --framework kubernetes sca_package -c 'CKV_K8S_16,CKV_CVE_2021*' > test_results.xml": "6",
    "winning": "7"
}

# Function to look up input string in the dictionary
def lookup(input_string):
    if input_string in data:
        return data[input_string]
    else:
        return False

@app.route('/flag', methods=['POST'])
def update_record():
    data = request.get_json()
    user_input = data.get('flag')
    # Look up input string in the dictionary
    if user_input in flagdata:
        # Extract task row ID
        row_key = flagdata[user_input]
        # Update successful record in Bigtable
        row = table.read_row(row_key.encode())
        row.set_cell(column_family_id, column_id, 'True'.encode())
        row.commit()

        return jsonify({'message': f'Well done!!! Flag received for task {flagdata[user_input]}!'})
    else:
        return jsonify({'message': 'That doesnt look like a flag! Sorry! Ask a proctor if you need a hint!'})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8080)
