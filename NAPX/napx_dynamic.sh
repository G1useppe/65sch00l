#!/usr/bin/env bash
#
# run_nids_with_replay.sh
# Start Suricata + Zeek on loopback, reset Splunk indexes,
# replay a pcap into lo, ingest everything freshly into Splunk,
# then cleanly shut down.

set -euo pipefail

#######################################
# INPUT VALIDATION
#######################################
PCAP="${1:-}"

if [[ -z "$PCAP" ]]; then
    echo "Usage: $0 <pcap-file>"
    exit 1
fi

if [[ ! -f "$PCAP" ]]; then
    echo "ERROR: PCAP file not found: $PCAP"
    exit 1
fi

#######################################
# CONFIG
#######################################
IFACE="lo"
BASE_DIR="/var/nids"
LOG_DIR="$BASE_DIR/logs"
PID_DIR="$BASE_DIR/pids"
SPLUNK="/opt/splunk/bin/splunk"

mkdir -p "$LOG_DIR/suricata" "$LOG_DIR/zeek" "$PID_DIR"

#######################################
# DEPENDENCY CHECK
#######################################
check_bin() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "ERROR: missing command: $1"
        exit 1
    }
}

check_bin suricata
check_bin zeek
check_bin tcpreplay
check_bin sudo

#######################################
# START SURICATA
#######################################
start_suricata() {
    echo "[+] Starting Suricata on $IFACE ..."
    suricata -i "$IFACE" -D \
        --pidfile "$PID_DIR/suricata.pid" \
        -l "$LOG_DIR/suricata" \
        >> "$LOG_DIR/suricata_console.log" 2>&1
    echo "[+] Suricata started."
}

#######################################
# START ZEEK
#######################################
start_zeek() {
    echo "[+] Starting Zeek on $IFACE ..."
    zeek -i "$IFACE" \
        >> "$LOG_DIR/zeek_console.log" 2>&1 &
    echo $! > "$PID_DIR/zeek.pid"
    echo "[+] Zeek started."
}

#######################################
# STOP ALL
#######################################
stop_all() {
    echo "[*] Stopping Suricata + Zeek ..."

    if [[ -f "$PID_DIR/suricata.pid" ]]; then
        kill "$(cat "$PID_DIR/suricata.pid")" 2>/dev/null || true
    fi

    if [[ -f "$PID_DIR/zeek.pid" ]]; then
        kill "$(cat "$PID_DIR/zeek.pid")" 2>/dev/null || true
    fi

    echo "[*] Done."
}

trap stop_all EXIT

#######################################
# RESET SPLUNK INDEXES
#######################################
reset_splunk_indexes() {
    echo "[*] Resetting Splunk indexes..."

    sudo $SPLUNK remove index zeek || true
    sudo $SPLUNK remove index suricata || true

    sudo $SPLUNK add index zeek
    sudo $SPLUNK add index suricata

    echo "[*] Re-adding Splunk monitors..."
    sudo $SPLUNK add monitor "$LOG_DIR/suricata"
    sudo $SPLUNK add monitor "$LOG_DIR/zeek"

    echo "[*] Splunk index reset complete."
}

#######################################
# MAIN FLOW
#######################################
echo "[+] Initialising NIDS + Splunk pipeline..."

start_suricata
start_zeek
reset_splunk_indexes

echo "[+] Replaying PCAP into $IFACE ..."
tcpreplay --intf1="$IFACE" "$PCAP"

echo "[+] Replay complete. Logs are in:"
echo "    $LOG_DIR/suricata"
echo "    $LOG_DIR/zeek"
echo "[+] Data should now be populating Splunk."
