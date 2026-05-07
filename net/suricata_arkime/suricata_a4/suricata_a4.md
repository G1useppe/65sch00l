# Lesson 4 — Live Capture with Docker (Tcpreplay + Suricata)

## Summary

Moving from static PCAP analysis to **live traffic detection** is a critical skill transition. In a live environment, Suricata processes packets in real time, generating alerts as events unfold rather than after the fact. This lesson uses **Docker Compose** to create an isolated lab where you replay PCAP traffic onto a virtual interface and watch Suricata detect threats in real time. This eliminates the need for complex local Suricata + Wireshark configuration and ensures a reproducible environment.

---

## Prepare

### Download the Dataset

```bash
cd ~/65sch00l/net/suricata_arkime/suricata_a4
mkdir -p .rsrc

# Demo PCAP
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
else
  echo "Demo PCAP exists."
fi

# Fights On PCAP
FIGHT_PCAP=".rsrc/fights_on.pcap"
if [ ! -f "$FIGHT_PCAP" ]; then
  FIGHT_ZIP=".rsrc/2024-08-15-traffic-analysis-exercise.pcap.zip"
  curl -L -o "$FIGHT_ZIP" \
    "https://www.malware-traffic-analysis.net/2024/08/15/2024-08-15-traffic-analysis-exercise.pcap.zip"
  unzip -P "$MTA_PASS" "$FIGHT_ZIP" -d .rsrc/
  mv .rsrc/2024-08-15-traffic-analysis-exercise.pcap "$FIGHT_PCAP"
else
  echo "Fights On PCAP exists."
fi
```

### Verify Tools

```bash
docker --version   || echo "ERROR: docker not found"
docker compose version || echo "ERROR: docker compose not found"
which tcpreplay    || echo "WARNING: tcpreplay not found locally — it's included in the Docker stack"
```

---

## Brief

This lesson covers:

1. Using Docker Compose to stand up a Suricata live-capture environment
2. Replaying PCAP traffic onto a container network interface using `tcpreplay`
3. Monitoring Suricata alerts in real time via `fast.log` and `eve.json`
4. Comparing live detection behavior to static analysis results

---

## Docker Compose Stack

The following `docker-compose.yml` creates three services: a Suricata IDS container, a tcpreplay container for injecting traffic, and a shared network they communicate over.

Create the compose file:

```bash
cat > docker-compose.yml << 'EOF'
services:
  suricata:
    image: jasonish/suricata:latest
    container_name: suricata-live
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
        --runmode single
        -k none
        --set pcap.checksum-checks=no
        -v
        -S /var/lib/suricata/rules/suricata.rules
    restart: "no"

  tcpreplay:
    image: alpine:latest
    container_name: tcpreplay
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    volumes:
      - ./.rsrc:/pcap:ro
    entrypoint: /bin/sh
    command: >
      -c "apk add --no-cache tcpreplay && echo 'Ready. Waiting 10s for Suricata...' && sleep 10 && tcpreplay -i lo --pps=100 /pcap/demo.pcap && echo 'Replay complete.'"
    depends_on:
      - suricata
    restart: "no"

EOF

mkdir -p logs rules
```

### Update Rules Before Starting

```bash
# Download the ET Open ruleset for the Suricata container
docker run --rm -v ./rules:/var/lib/suricata/rules jasonish/suricata:latest suricata-update -f
```

---

## Demonstration — Live Capture

### Start the Stack

```bash
docker compose up -d suricata
```

Wait for Suricata to initialize (watch for the "all packet processing threads running" message):

```bash
docker logs -f suricata-live 2>&1 | grep -m1 "packet processing threads"
```

### Start the Replay

```bash
docker compose up tcpreplay
```

### Monitor Alerts in Real Time

In a separate terminal, tail the fast log:

```bash
tail -f ./logs/fast.log
```

Or stream structured alerts with `jq`:

```bash
tail -f ./logs/eve.json | jq -r 'select(.event_type == "alert") |
  "\(.timestamp) [\(.alert.severity)] \(.src_ip) -> \(.dest_ip) | \(.alert.signature)"'
```

### Key Observations

Compare what you see in real-time alerts vs. the static analysis from Lesson 2:

- **Timing** — alerts arrive as packets are replayed, not all at once
- **Alert ordering** — reflects the actual chronological order of events
- **`--pps` flag** — the packets-per-second rate in tcpreplay controls how fast the scenario unfolds. Lower values (e.g., `--pps=25`) give you more time to observe; higher values finish faster

### Tear Down

```bash
docker compose down
```

---

## Execute — Fights On

Replay the second dataset through the same stack:

```bash
# Update compose to use the fights_on PCAP
sed -i 's|/pcap/demo.pcap|/pcap/fights_on.pcap|' docker-compose.yml

# Clear previous logs
rm -f ./logs/fast.log ./logs/eve.json

# Run the stack
docker compose up -d suricata
docker logs -f suricata-live 2>&1 | grep -m1 "packet processing threads"
docker compose up tcpreplay

# Monitor in another terminal
tail -f ./logs/fast.log
```

### Analyst Tasks

1. Monitor `fast.log` in real time — note which alerts fire first and which come later in the kill chain
2. After replay completes, use `jq` to count unique signatures and identify the most-fired rules
3. Compare the live detection timeline to what you would see running Suricata in read mode
4. Note any alerts that arrive with significant delay after the triggering packet — this shows Suricata's reassembly/detection latency
5. Map live detections to **MITRE ATT&CK** techniques

### Reset for Next Run

```bash
# Restore the original PCAP reference
sed -i 's|/pcap/fights_on.pcap|/pcap/demo.pcap|' docker-compose.yml
docker compose down
```

---

## Debrief

After this lesson you should be able to:

- Use Docker Compose to create reproducible Suricata live-capture environments
- Replay PCAP traffic safely using tcpreplay on a loopback interface
- Monitor Suricata alerts in real time using `fast.log` and `eve.json`
- Understand the behavioral differences between static and live IDS analysis
- Control replay speed to simulate different traffic scenarios
