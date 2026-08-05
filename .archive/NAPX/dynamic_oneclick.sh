#!/usr/bin/env bash
set -euo pipefail

############################################
# NAPX Demo – PCAP → Replay → Suricata → Zeek → Wireshark → Splunk
# Interface: lo
# Author: Giuseppe Squinzano
############################################

### CONFIGURATION #####################################

DEMO_DIR="$HOME/napx_demo"
PCAP_NAME="demo.pcap"
REPLAY_PCAP="$DEMO_DIR/replay_lo.pcap"

RSRC_DIR="$DEMO_DIR/.rsrc"
LOG_DIR="$DEMO_DIR/logs"
SURICATA_LOG_DIR="$LOG_DIR/suricata"
ZEEK_LOG_DIR="$LOG_DIR/zeek"

INTERFACE="lo"

SPLUNK_BIN="/opt/splunk/bin/splunk"
SPLUNK_USER="st0ne_fish"
SPLUNK_PASS="st0nefish"

SURICATA_RULES="/var/lib/suricata/rules/suricata.rules"

############################################
# SAFETY CHECKS
############################################

echo "[+] Running safety checks"

for bin in suricata zeek capinfos java tcpreplay wireshark; do
    command -v "$bin" >/dev/null || {
        echo "[!] Required binary not found: $bin"
        exit 1
    }
done

############################################
# ENVIRONMENT SETUP
############################################

echo "[+] Creating directory structure"

mkdir -p "$SURICATA_LOG_DIR" "$ZEEK_LOG_DIR" "$RSRC_DIR"
cd "$DEMO_DIR"

############################################
# PCAP SETUP (INTERACTIVE)
############################################

echo
echo "[+] PCAP setup"
echo "Enter a PCAP file OR directory containing a PCAP"
echo "Press Enter to use default: $HOME/Documents/.rsrc"
echo

read -rp "PCAP path: " PCAP_INPUT
[[ -z "$PCAP_INPUT" ]] && PCAP_INPUT="$HOME/Documents/.rsrc"

if [[ -d "$PCAP_INPUT" ]]; then
    PCAP_INPUT=$(ls "$PCAP_INPUT"/*.pcap 2>/dev/null | head -n 1 || true)
fi

if [[ ! -f "$PCAP_INPUT" ]]; then
    echo "[!] PCAP file not found"
    exit 1
fi

cp "$PCAP_INPUT" "$PCAP_NAME"
echo "[+] Using PCAP: $PCAP_INPUT"

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

echo "[+] Fetching resource files"

wget -nc -P "$RSRC_DIR" \
  https://raw.githubusercontent.com/G1useppe/65sch00l/main/NAPX/.rsrc/plantuml-mit-1.2024.6.jar \
  https://raw.githubusercontent.com/G1useppe/65sch00l/main/NAPX/.rsrc/xprint-seq-diagram-filter-high-alerts.py \
  https://raw.githubusercontent.com/G1useppe/65sch00l/main/NAPX/.rsrc/zeek_monitor.sh

chmod +x "$RSRC_DIR/zeek_monitor.sh"

############################################
# METADATA REVIEW
############################################

echo "[+] Running capinfos"
capinfos -A "$PCAP_NAME" > capinfos.txt

############################################
# START SURICATA (LIVE)
############################################

echo "[+] Starting Suricata on $INTERFACE"

sudo suricata \
    -i "$INTERFACE" \
    --runmode auto \
    -l "$SURICATA_LOG_DIR" \
    -S "$SURICATA_RULES" &

SURICATA_PID=$!
sleep 3

############################################
# START ZEEK (LIVE)
############################################

echo "[+] Starting Zeek on $INTERFACE"

cd "$ZEEK_LOG_DIR"
sudo zeek -i "$INTERFACE" &
ZEEK_PID=$!
sleep 3
cd "$DEMO_DIR"

############################################
# START WIRESHARK (LIVE)
############################################

echo "[+] Starting Wireshark capture on $INTERFACE"

sudo wireshark \
    -i "$INTERFACE" \
    -k \
    -w "$REPLAY_PCAP" \
    >/dev/null 2>&1 &

WIRESHARK_PID=$!
sleep 3

############################################
# REPLAY PCAP
############################################

echo "[+] Replaying PCAP onto $INTERFACE"

sudo tcpreplay --intf1="$INTERFACE" "$PCAP_NAME"
sleep 5

############################################
# STOP SENSORS
############################################

echo "[+] Stopping sensors"

sudo kill "$SURICATA_PID" || true
sudo kill "$ZEEK_PID" || true
sudo kill "$WIRESHARK_PID" || true

############################################
# SPLUNK INGEST (MONITOR MODE)
############################################

echo "[+] Monitoring Suricata logs"

sudo "$SPLUNK_BIN" add monitor \
    "$SURICATA_LOG_DIR/eve.json" \
    -index suricata \
    -sourcetype suricata:json \
    2>/dev/null || true

echo "[+] Monitoring Zeek logs"

sudo "$RSRC_DIR/zeek_monitor.sh"

############################################
# SEQUENCE DIAGRAM
############################################

echo "[+] Generating sequence diagram"

cp "$SURICATA_LOG_DIR/eve.json" "$RSRC_DIR/"
cd "$RSRC_DIR"

python3 ./xprint-seq-diagram-filter-high-alerts.py \
  | java -Djava.awt.headless=true \
    -jar plantuml-mit-1.2024.6.jar \
    -p -Tpng > "$DEMO_DIR/seqdiag.png"

cd "$DEMO_DIR"

############################################
# FINAL INSTRUCTIONS
############################################

cat <<EOF

=====================================================
NAPX LIVE REPLAY COMPLETE
=====================================================

Interface:
  $INTERFACE

Splunk:
  http://127.0.0.1:8000
  Indexes: suricata, zeek

Artifacts:
  - demo.pcap            (original evidence)
  - replay_lo.pcap       (Wireshark replay capture)
  - logs/suricata/eve.json
  - logs/zeek/*.log
  - seqdiag.png

Analysis Flow:
  1. Alert-first (Suricata)
  2. Metadata pivot (Zeek)
  3. Packet validation (Wireshark)

=====================================================

EOF
