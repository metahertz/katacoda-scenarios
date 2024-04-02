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
    "apple": "1",
    "banana": "2",
    "orange": "3"
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
    app.run(debug=True)
