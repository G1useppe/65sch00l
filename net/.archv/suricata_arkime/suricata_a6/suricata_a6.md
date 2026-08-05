# Lesson 6 — Static Investigation with Suricata Logs in Splunk

## Summary

Splunk transforms raw Suricata logs into searchable, dashboardable intelligence. While Arkime excels at session-level PCAP investigation, Splunk shines when you need to aggregate, visualize, and correlate alert data across time — counting alert frequencies, building timelines, and identifying patterns that aren't obvious from individual sessions. This lesson ingests Suricata EVE JSON logs into a Dockerized Splunk instance and walks through alert analysis using SPL queries and a pre-built dashboard.

---

## Prepare

### Generate Suricata Logs

If you don't have Suricata logs from a previous lesson, generate them now:

```bash
cd ~/65sch00l/net/suricata_arkime/suricata_a6
mkdir -p .rsrc demo_logs

# Get the demo PCAP
DEMO_PCAP=".rsrc/demo.pcap"
if [ ! -f "$DEMO_PCAP" ]; then
  if [ -f "../suricata_a2/.rsrc/demo.pcap" ]; then
    cp ../suricata_a2/.rsrc/demo.pcap "$DEMO_PCAP"
  else
    DEMO_ZIP=".rsrc/2024-09-04-traffic-analysis-exercise.pcap.zip"
    curl -L -o "$DEMO_ZIP" \
      "https://www.malware-traffic-analysis.net/2024/09/04/2024-09-04-traffic-analysis-exercise.pcap.zip"
    unzip -P "$MTA_PASS" "$DEMO_ZIP" -d .rsrc/
    mv .rsrc/2024-09-04-traffic-analysis-exercise.pcap "$DEMO_PCAP"
  fi
fi

# Generate Suricata logs if not already present
if [ ! -f "./demo_logs/eve.json" ]; then
  suricata -r "$DEMO_PCAP" \
    -k none --runmode single \
    -l ./demo_logs/ \
    -S /var/lib/suricata/rules/suricata.rules
else
  echo "Suricata logs already exist."
fi
```

### Verify Tools

```bash
docker --version         || echo "ERROR: docker not found"
docker compose version   || echo "ERROR: docker compose not found"
```

---

## Brief

This lesson covers:

1. Standing up Splunk in Docker for log analysis
2. Ingesting Suricata `eve.json` as a one-shot data load
3. Writing SPL queries to investigate alerts by signature, source IP, severity, and timeline
4. Loading a pre-built Suricata dashboard for at-a-glance overview

---

## Docker Compose Stack

```bash
cat > docker-compose.yml << 'EOF'
services:
  splunk:
    image: splunk/splunk:latest
    container_name: splunk
    ports:
      - "8000:8000"    # Web UI
      - "8088:8088"    # HEC (optional)
      - "8089:8089"    # Management
    environment:
      - SPLUNK_START_ARGS=--accept-license
      - SPLUNK_PASSWORD=Changeme1!
    volumes:
      - ./demo_logs:/opt/splunk/etc/ingest:ro
      - splunk-data:/opt/splunk/var
    restart: unless-stopped

volumes:
  splunk-data:

EOF
```

---

## Demonstration — Splunk Setup and Ingest

### Step 1: Start Splunk

```bash
docker compose up -d
echo "Waiting for Splunk to start (this takes 1-2 minutes)..."
until docker logs splunk 2>&1 | grep -q "Ansible playbook complete"; do
  sleep 5
done
echo "Splunk is ready: http://localhost:8000"
echo "Login: admin / Changeme1!"
```

```bash
firefox http://localhost:8000 &
```

### Step 2: Create the Suricata Index

Via the Splunk CLI inside the container:

```bash
docker exec splunk /opt/splunk/bin/splunk add index suricata \
  -auth admin:Changeme1!
```

### Step 3: Ingest the EVE JSON

Load the `eve.json` file as a one-shot ingest:

```bash
docker exec splunk /opt/splunk/bin/splunk add oneshot \
  /opt/splunk/etc/ingest/eve.json \
  -index suricata \
  -sourcetype _json \
  -auth admin:Changeme1!
```

### Step 4: Verify Data

In the Splunk web UI, go to **Search & Reporting** and run:

```spl
index=suricata | head 10
```

You should see JSON events from Suricata. Now filter to just alerts:

```spl
index=suricata event_type=alert | head 10
```

---

## SPL Queries for Suricata Analysis

### Alert Overview

```spl
index=suricata event_type=alert
| stats count by alert.signature
| sort - count
```

### Timeline of Alerts

```spl
index=suricata event_type=alert
| timechart count by alert.signature
```

### Top Source IPs Generating Alerts

```spl
index=suricata event_type=alert
| stats count by src_ip
| sort - count
```

### Alerts by Severity

```spl
index=suricata event_type=alert
| stats count by alert.severity
| sort alert.severity
```

### Pivot: Specific Source IP to All Signatures

```spl
index=suricata event_type=alert src_ip="172.17.0.101"
| stats count by alert.signature, dest_ip, dest_port
| sort - count
```

### Hunt: Unique Destination IPs per Source

```spl
index=suricata event_type=alert
| stats dc(dest_ip) as unique_targets by src_ip
| sort - unique_targets
```

### Protocol Breakdown

```spl
index=suricata event_type=alert
| stats count by proto
| sort - count
```

---

## Loading the Dashboard

A pre-built Splunk dashboard XML is included in `.rsrc/`. To install it:

1. In Splunk web UI, go to **Dashboards** > **Create New Dashboard**
2. Name it "Suricata Network Overview"
3. Switch to **Source** (XML) editing mode
4. Paste the contents of `.rsrc/Truvis-Suricata Network Overview [MAIN].txt`
5. Save the dashboard

The dashboard provides:

- Time-range picker for filtering
- Source and destination IP search fields
- Configurable event table columns
- Alert counts by signature, severity, and protocol
- Timeline visualizations

---

## Execute — Fights On

1. Generate Suricata logs for a new PCAP (use a fights_on PCAP from a previous lesson)
2. Ingest the new `eve.json` into the existing Splunk instance:

   ```bash
   docker exec splunk /opt/splunk/bin/splunk remove index suricata \
     -auth admin:Changeme1!
   docker exec splunk /opt/splunk/bin/splunk add index suricata \
     -auth admin:Changeme1!
   docker exec splunk /opt/splunk/bin/splunk add oneshot \
     /opt/splunk/etc/ingest/eve.json \
     -index suricata -sourcetype _json \
     -auth admin:Changeme1!
   ```

3. Use the SPL queries above to profile the new dataset
4. Identify the top 5 most interesting alerts and investigate them
5. Build a custom SPL search that answers a specific question about the dataset
6. Map findings to **MITRE ATT&CK** techniques

### Tear Down

```bash
docker compose down
# To reset Splunk data:
# docker compose down -v
```

---

## Debrief

After this lesson you should be able to:

- Deploy Splunk in Docker and ingest Suricata logs
- Write SPL queries to aggregate, filter, and visualize IDS alert data
- Use dashboards for rapid overview of alert landscapes
- Correlate alert patterns across time, source, destination, and signature
- Map aggregated alert data to MITRE ATT&CK techniques
