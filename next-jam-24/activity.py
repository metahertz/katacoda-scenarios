from flask import Flask, request, jsonify
from google.cloud import bigtable
from google.cloud.bigtable import column_family
from google.cloud.bigtable.row_filters import RowKeyRegexFilter

app = Flask(__name__)

# Google Cloud Bigtable configuration
#project_id = 'your-project-id'
instance_id = 'ctf-status'
table_id = 'progress'
column_family_id = 'fam1'
column_id = 'success'

# Initialize Bigtable client
client = bigtable.Client(admin=True)
instance = client.instance(instance_id)
table = instance.table(table_id)

# Hardcoded string to match
target_string = "example"

@app.route('/flag', methods=['POST'])
def update_record():
    data = request.get_json()
    user_input = data.get('flag')

    if user_input == target_string:
        # Update record in Bigtable
        row_key = '1'  # Example row key
        row = table.read_row(row_key.encode())
        row.set_cell(column_family_id, column_id, 'True'.encode())
        row.commit()

        return jsonify({'message': 'Well done!!! Flag received!'})
    else:
        return jsonify({'message': 'That doesnt look like a flag! Sorry'})

if __name__ == '__main__':
    app.run(debug=True)
