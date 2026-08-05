#!/bin/bash
# Path to your Zeek logs
ZEEK_LOG_DIR="./logs/zeek"
# Index in Splunk
INDEX="zeek"

for file in "$ZEEK_LOG_DIR"/*.log; do
    # Get just the filename without path and extension
    base=$(basename "$file" .log)
    # Define sourcetype as zeek_<filename>
    sourcetype="_json"
    echo "Uploading $file as sourcetype=$sourcetype to index=$INDEX"
    /opt/splunk/bin/splunk add oneshot "$file" -index "$INDEX" -sourcetype "$sourcetype"
done
