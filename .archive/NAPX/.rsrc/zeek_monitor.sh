#!/bin/bash

ZEEK_LOG_DIR="./logs/zeek"
INDEX="zeek"
SPLUNK_BIN="/opt/splunk/bin/splunk"

for file in "$ZEEK_LOG_DIR"/*.log; do
    base=$(basename "$file" .log)
    sourcetype="zeek:${base}"

    echo "Adding monitor for $file"
    echo "  index=$INDEX"
    echo "  sourcetype=$sourcetype"

    sudo "$SPLUNK_BIN" add monitor "$file" \
        -index "$INDEX" \
        -sourcetype "$sourcetype" \
        2>/dev/null || true
done
