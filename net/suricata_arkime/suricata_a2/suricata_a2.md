# Lesson 2 — Suricata Read Mode and Wireshark

## Summary

Suricata can run in **offline (read) mode** against a PCAP file, applying its ruleset exactly as it would on live traffic. This produces the same alert outputs — `eve.json` and `fast.log` — which you can then correlate back to specific packets in Wireshark. This lesson teaches you to run Suricata offline, inspect its output, and cross-reference alerts with packet-level evidence.

---

## Prepare

### Update Suricata Rules

Pull the latest Emerging Threats ruleset before every analysis session:

```bash
sudo suricata-update
```

### Download the Dataset

Set the malware-traffic-analysis.net zip password (see the [about page](https://www.malware-traffic-analysis.net/about.html) for the current password):

```bash
export MTA_PASS="infected"
```

Then run the download script:

```bash
cd ~/65sch00l/net/suricata_arkime/suricata_a2
chmod +x .rsrc/download_datasets.sh
./.rsrc/download_datasets.sh
```

The script downloads two PCAPs into `.rsrc/`, creates the `demo_logs/` and `fight_logs/` directories, and skips any files that already exist. See `.rsrc/download_datasets.sh` for full details.

### Verify Tools

```bash
which suricata   || echo "ERROR: suricata not found"
which wireshark  || echo "ERROR: wireshark not found"
which jq         || echo "ERROR: jq not found"
```

---

## Brief

In this lesson you will:

- Run Suricata in **read mode** against a PCAP file
- Inspect the **eve.json** (structured JSON log) and **fast.log** (one-line-per-alert) output
- Correlate Suricata alerts with packet-level data in Wireshark

---

## Demonstration — Suricata Read Mode

Run Suricata in offline mode against the demo PCAP:

```bash
suricata -r .rsrc/demo.pcap \
  -k none \
  --runmode single \
  -l ./demo_logs/ \
  -vvv \
  -S /var/lib/suricata/rules/suricata.rules
```

### Command Flags Explained

| Flag | Purpose |
|------|---------|
| `-r <file>` | Read packets from a PCAP file (offline mode) |
| `-k none` | Skip checksum validation — essential for PCAP analysis where checksums are often invalid |
| `--runmode single` | Single-threaded execution — ensures ordered logs, good for learning |
| `-l <dir>` | Output directory for logs |
| `-v` / `-vvv` | Increase verbosity — helpful for troubleshooting rule loading issues |
| `-S <rules>` | Explicitly specify the ruleset to use |

---

## Inspecting Suricata Logs

### eve.json — The Primary Log

`eve.json` is Suricata's structured JSON log. Each line is a standalone JSON object representing an event. Event types include `alert`, `dns`, `http`, `tls`, `flow`, `fileinfo`, and more.

View which event types were generated:

```bash
jq -r '.event_type' ./demo_logs/eve.json | sort | uniq -c | sort -rn
```

### Filtering Alerts

Extract only alert events:

```bash
jq 'select(.event_type == "alert")' ./demo_logs/eve.json
```

Get a concise summary of each alert:

```bash
jq -r 'select(.event_type == "alert") |
  "\(.timestamp) | \(.src_ip):\(.src_port) -> \(.dest_ip):\(.dest_port) | [\(.alert.signature_id)] \(.alert.signature)"' \
  ./demo_logs/eve.json
```

Count alerts by signature:

```bash
jq -r 'select(.event_type == "alert") | .alert.signature' ./demo_logs/eve.json | sort | uniq -c | sort -rn
```

Count alerts by severity:

```bash
jq -r 'select(.event_type == "alert") | "sev-\(.alert.severity)"' ./demo_logs/eve.json | sort | uniq -c | sort -rn
```

### fast.log — Quick Reference

`fast.log` provides a one-line-per-alert summary, useful for a rapid overview:

```bash
cat ./demo_logs/fast.log
```

---

## Packet Correlation with Wireshark

The real power of offline analysis is correlating Suricata alerts back to their source packets. Each alert in `eve.json` includes source/destination IPs, ports, and a timestamp — use these to build Wireshark display filters.

Open the PCAP in Wireshark:

```bash
wireshark .rsrc/demo.pcap &
```

### Building Wireshark Filters from Alerts

If an alert shows `src_ip: 172.17.0.101`, `dest_ip: 45.33.32.156`, `dest_port: 80`:

```
ip.addr == 172.17.0.101 && ip.addr == 45.33.32.156 && tcp.port == 80
```

For a specific Suricata flow_id (if you need to be precise), filter by the 5-tuple and narrow by time.

### Workflow

1. Run the `jq` summary command above to list all alerts
2. Pick an alert of interest
3. Build a Wireshark display filter from its 5-tuple
4. Follow the TCP stream to see the full conversation
5. Note what the alert detected vs. what the payload actually shows

---

## Execute — Fights On

Run Suricata against the second dataset:

```bash
suricata -r .rsrc/fights_on.pcap \
  -k none \
  --runmode single \
  -l ./fight_logs/ \
  -vvv \
  -S /var/lib/suricata/rules/suricata.rules
```

Open the PCAP in Wireshark alongside the logs:

```bash
wireshark .rsrc/fights_on.pcap &
```

### Analyst Tasks

1. Run the `jq` summary commands to profile the alerts — how many unique signatures fired? What are the top talkers?
2. Pick the three highest-severity alerts and locate their corresponding packets in Wireshark
3. For each alert, follow the TCP/UDP stream and note what triggered the signature
4. Identify any false positives — alerts that look benign on packet inspection
5. Map confirmed detections to **MITRE ATT&CK** techniques (consider `T1071` — Application Layer Protocol, `T1040` — Network Sniffing, `T1059` — Command and Scripting Interpreter)

---

## Debrief

After this lesson you should be able to:

- Run Suricata in read mode against any PCAP file
- Parse and filter `eve.json` using `jq` to extract alert summaries
- Cross-reference Suricata alerts with packet-level data in Wireshark
- Distinguish between true positive alerts and noise
- Validate detection coverage against observed traffic
