# Lesson 7 — Live Suricata–Splunk Integration (Capstone)

## Summary

This is the capstone. You will build a **complete live detection pipeline**: tcpreplay injects traffic onto a loopback interface, Suricata detects threats in real time, and Splunk indexes the alerts as they arrive — giving you a live-updating dashboard of detections. This mirrors how production SOC environments operate, where analysts observe alerts arriving in near-real-time and triage as events unfold. Good luck!

---

## Prepare

### Download the Dataset

```bash
cd ~/65sch00l/net/suricata_arkime/suricata_a7
mkdir -p .rsrc

FIGHT_PCAP=".rsrc/fights_on.pcap"
if [ ! -f "$FIGHT_PCAP" ]; then
  FIGHT_ZIP=".rsrc/2024-04-18-SSLoad-with-follow-up-Cobalt-Strike-DLL.pcap.zip"
  curl -L -o "$FIGHT_ZIP" \
    "https://www.malware-traffic-analysis.net/2024/04/18/2024-04-18-SSLoad-with-follow-up-Cobalt-Strike-DLL.pcap.zip"
  unzip -P "$MTA_PASS" "$FIGHT_ZIP" -d .rsrc/
  mv .rsrc/2024-04-18-SSLoad-with-follow-up-Cobalt-Strike-DLL.pcap "$FIGHT_PCAP"
else
  echo "Fights On PCAP exists."
fi
```

### Verify Tools

```bash
docker --version         || echo "ERROR: docker not found"
docker compose version   || echo "ERROR: docker compose not found"
```

---

## Brief

This lesson brings together everything from the course:

1. **Docker Compose** to orchestrate Suricata, Splunk, and tcpreplay
2. **Live detection** — Suricata monitors the loopback interface in real time
3. **Live indexing** — Splunk monitors `eve.json` and ingests alerts as they are written
4. **Live triage** — you watch alerts populate in Splunk and investigate as they arrive
5. **MITRE ATT&CK Navigator** — map all detections to a visual ATT&CK layer

---

## Docker Compose Stack

This stack runs everything in containers with shared volumes:

```bash
mkdir -p logs rules

cat > docker-compose.yml << 'EOF'
services:
  splunk:
    image: splunk/splunk:latest
    container_name: splunk-live
    ports:
      - "8000:8000"
      - "8089:8089"
    environment:
      - SPLUNK_START_ARGS=--accept-license
      - SPLUNK_PASSWORD=Changeme1!
    volumes:
      - splunk-data:/opt/splunk/var
      - ./logs:/opt/splunk/etc/suricata-logs
    restart: unless-stopped

  suricata:
    image: jasonish/suricata:latest
    container_name: suricata-live-splunk
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
      - SYS_NICE
    volumes:
      - ./logs:/var/log/suricata
      - ./rules:/var/lib/suricata/rules
    command: >
      suricata
        --pcap=lo
        --runmode auto
        -k none
        --set pcap.checksum-checks=no
        -v
        -S /var/lib/suricata/rules/suricata.rules
    restart: "no"

  tcpreplay:
    image: alpine:latest
    container_name: tcpreplay-live
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    volumes:
      - ./.rsrc:/pcap:ro
    entrypoint: /bin/sh
    command: >
      -c "apk add --no-cache tcpreplay &&
          echo 'Waiting 15s for Suricata to initialize...' && sleep 15 &&
          echo 'Starting replay at 25 pps...' &&
          tcpreplay -i lo --pps=25 /pcap/fights_on.pcap &&
          echo 'Replay complete.'"
    depends_on:
      - suricata
    restart: "no"

volumes:
  splunk-data:

EOF
```

### Update Suricata Rules

```bash
docker run --rm -v ./rules:/var/lib/suricata/rules jasonish/suricata:latest suricata-update -f
```

---

## Execute — Fights On

**Narrative:** We've noticed an uptick in malicious scans and probes inbound on our server. Your job is to stand up the full detection pipeline, watch the alerts roll in live, and document every technique you observe.

### Step 1: Start Splunk

```bash
docker compose up -d splunk
echo "Waiting for Splunk to start..."
until docker logs splunk-live 2>&1 | grep -q "Ansible playbook complete"; do
  sleep 5
done
echo "Splunk ready: http://localhost:8000 (admin / Changeme1!)"
```

### Step 2: Create the Suricata Index and Monitor

```bash
# Create the index
docker exec splunk-live /opt/splunk/bin/splunk add index suricata \
  -auth admin:Changeme1!

# Set up a file monitor on the eve.json output directory
docker exec splunk-live /opt/splunk/bin/splunk add monitor \
  /opt/splunk/etc/suricata-logs/eve.json \
  -index suricata \
  -sourcetype _json \
  -auth admin:Changeme1!
```

### Step 3: Start Suricata

```bash
docker compose up -d suricata

# Wait for initialization
echo "Waiting for Suricata packet processing threads..."
docker logs -f suricata-live-splunk 2>&1 | grep -m1 "packet processing threads"
echo "Suricata is running."
```

### Step 4: Start the Replay

Open **four terminal windows** (or tmux panes):

**Terminal 1 — Splunk dashboard:**
```bash
firefox http://localhost:8000 &
```
Navigate to Search & Reporting and run a real-time search:
```spl
index=suricata event_type=alert | table _time src_ip dest_ip alert.signature alert.severity
```
Set the time picker to **Real-time > 30 minute window**.

**Terminal 2 — Fast log tail:**
```bash
tail -f ./logs/fast.log
```

**Terminal 3 — Structured alert stream:**
```bash
tail -f ./logs/eve.json | jq -r 'select(.event_type == "alert") |
  "\(.timestamp) [sev:\(.alert.severity)] \(.src_ip):\(.src_port) -> \(.dest_ip):\(.dest_port) [\(.alert.signature_id)] \(.alert.signature)"'
```

**Terminal 4 — Start the replay:**
```bash
docker compose up tcpreplay
```

### Step 5: Observe and Triage

As the replay runs (at 25 pps this may take a while depending on PCAP size), watch alerts arrive in real time across all three monitoring channels:

1. **Splunk** — alerts populate the real-time search results
2. **fast.log** — one-line summaries scroll past
3. **eve.json stream** — structured alert data with full metadata

### Step 6: Post-Replay Analysis in Splunk

Once the replay completes, switch from real-time to historical search in Splunk:

```spl
index=suricata event_type=alert
| stats count by alert.signature
| sort - count
```

```spl
index=suricata event_type=alert
| timechart span=1m count by alert.severity
```

```spl
index=suricata event_type=alert
| stats dc(dest_ip) as targets, dc(alert.signature_id) as unique_sigs by src_ip
| sort - unique_sigs
```

### Step 7: MITRE ATT&CK Navigator

Map your findings to the ATT&CK framework:

```bash
firefox https://mitre-attack.github.io/attack-navigator/ &
```

Create a new layer and color-code techniques based on what you observed:

- **Red** — confirmed detections with high-severity alerts
- **Orange** — probable matches based on alert patterns
- **Yellow** — potential matches requiring further investigation

Export your layer as JSON for future reference.

---

## Tear Down

```bash
docker compose down

# Full cleanup including Splunk data:
# docker compose down -v
```

---

## Debrief

After this lesson you should be able to:

- Build a complete live detection pipeline using Docker Compose (Suricata + Splunk + tcpreplay)
- Configure Splunk to monitor and ingest Suricata logs in real time
- Triage alerts as they arrive using multiple monitoring channels simultaneously
- Write SPL queries for post-incident analysis of alert data
- Map a full exercise's detections to a MITRE ATT&CK Navigator layer
- Understand the end-to-end flow from packet capture through detection to analyst triage

---

## Course Complete

Congratulations — you've progressed from static PCAP inspection to building and operating a live detection pipeline. The skills from this course apply directly to SOC operations, incident response, and threat hunting. Continue practicing with fresh PCAPs from [malware-traffic-analysis.net](https://www.malware-traffic-analysis.net/) and challenge yourself with larger, more complex datasets.
