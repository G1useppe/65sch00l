#!/usr/bin/env bash
set -euo pipefail

############################################
# NAPX Demo – PCAP → Suricata → Zeek → Splunk
# Author: Giuseppe Squinzano
############################################

### CONFIGURATION #####################################

DEMO_DIR="$HOME/napx_demo"
PCAP_NAME="demo.pcap"
RSRC_DIR="$DEMO_DIR/.rsrc"
LOG_DIR="$DEMO_DIR/logs"
SURICATA_LOG_DIR="$LOG_DIR/suricata"
ZEEK_LOG_DIR="$LOG_DIR/zeek"

SPLUNK_BIN="/opt/splunk/bin/splunk"
SPLUNK_USER="st0ne_fish"
SPLUNK_PASS="st0nefish"

SURICATA_RULES="/var/lib/suricata/rules/suricata.rules"

############################################
# SAFETY CHECKS
############################################

command -v suricata >/dev/null || { echo "Suricata not found"; exit 1; }
command -v zeek >/dev/null || { echo "Zeek not found"; exit 1; }
command -v capinfos >/dev/null || { echo "capinfos not found"; exit 1; }
command -v java >/dev/null || { echo "Java not found"; exit 1; }

############################################
# ENVIRONMENT SETUP
############################################

echo "[+] Creating directory structure"

mkdir -p "$DEMO_DIR"
mkdir -p "$RSRC_DIR"
mkdir -p "$SURICATA_LOG_DIR"
mkdir -p "$ZEEK_LOG_DIR"

cd "$DEMO_DIR"

############################################
# PCAP SETUP
############################################

if [[ ! -f "$PCAP_NAME" ]]; then
    echo "[+] Attempting to copy PCAP from ~/Documents/.rsrc"
    cp "$HOME/Documents/.rsrc/"*.pcap "$PCAP_NAME" || {
        echo "[!] PCAP not found. Please unzip and name it demo.pcap"
        exit 1
    }
fi

############################################
# SPLUNK INDEX SETUP
############################################

echo "[+] Resetting Splunk indexes"

sudo "$SPLUNK_BIN" remove index zeek || true
sudo "$SPLUNK_BIN" remove index suricata || true

sudo "$SPLUNK_BIN" add index zeek
sudo "$SPLUNK_BIN" add index suricata

############################################
# RESOURCE FILES
############################################

echo "[+] Populating .rsrc directory"

if [[ ! -f "$RSRC_DIR/plantuml-mit-1.2024.6.jar" ]]; then
    wget -P "$RSRC_DIR" \
        https://raw.githubusercontent.com/G1useppe/65sch00l/main/NAPX/.rsrc/plantuml-mit-1.2024.6.jar
fi

if [[ ! -f "$RSRC_DIR/xprint-seq-diagram-filter-high-alerts.py" ]]; then
    wget -P "$RSRC_DIR" \
        https://raw.githubusercontent.com/G1useppe/65sch00l/main/NAPX/.rsrc/xprint-seq-diagram-filter-high-alerts.py
fi

if [[ ! -f "$RSRC_DIR/zeek_oneshot.sh" ]]; then
    wget -P "$RSRC_DIR" \
        https://raw.githubusercontent.com/G1useppe/65sch00l/main/NAPX/.rsrc/zeek_oneshot.sh
fi

chmod +x "$RSRC_DIR/zeek_oneshot.sh"

############################################
# METADATA REVIEW
############################################

echo "[+] Running capinfos"

capinfos -A "$PCAP_NAME" > capinfos.txt
cat capinfos.txt

############################################
# SURICATA OFFLINE MODE
############################################

echo "[+] Running Suricata in offline mode"

suricata \
    -r "$PCAP_NAME" \
    -k none \
    --runmode single \
    -l "$SURICATA_LOG_DIR" \
    -vvv \
    -S "$SURICATA_RULES"

############################################
# SEQUENCE DIAGRAM GENERATION
############################################

echo "[+] Generating Suricata sequence diagram"

cp "$SURICATA_LOG_DIR/eve.json" "$RSRC_DIR/"
cd "$RSRC_DIR"

python3 ./xprint-seq-diagram-filter-high-alerts.py \
    | java -Djava.awt.headless=true \
        -jar ./plantuml-mit-1.2024.6.jar \
        -p -Tpng \
        > "$DEMO_DIR/seqdiag.png"

rm -f eve.json
cd "$DEMO_DIR"

############################################
# ZEEK OFFLINE MODE
############################################

echo "[+] Running Zeek in offline mode"

cd "$ZEEK_LOG_DIR"
zeek -C -r ../../"$PCAP_NAME" LogAscii::use_json=T
ls -lah
cd "$DEMO_DIR"

############################################
# SPLUNK IMPORT
############################################

echo "[+] Importing Suricata logs into Splunk"

sudo "$SPLUNK_BIN" add oneshot \
    "$SURICATA_LOG_DIR/eve.json" \
    -index suricata \
    -sourcetype _json

echo "[+] Importing Zeek logs into Splunk"

sudo "$RSRC_DIR/zeek_oneshot.sh"

############################################
# FINAL INSTRUCTIONS
############################################

cat <<EOF

=====================================================
NAPX SETUP COMPLETE
=====================================================

Splunk UI:
  http://127.0.0.1:8000

Credentials:
  Username: $SPLUNK_USER
  Password: $SPLUNK_PASS

Artifacts:
  - capinfos.txt
  - logs/suricata/eve.json
  - logs/zeek/*.log
  - seqdiag.png

Next step:
  Perform alert-driven and metadata-driven analysis in Splunk.
=====================================================

EOF
