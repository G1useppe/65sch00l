# Lesson 2 — Suricata Read Mode and Wireshark

## Summary
Use **Suricata in offline (read) mode** to generate alerts from a PCAP file and **correlate those alerts with packets in Wireshark**.

---

## Prepare

Update Suricata rules (Emerging Threats):

```bash
sudo pipx run suricata-update
```

Prepare the working directory and dataset:

```bash
cd ~/65sch00l/net/suricata_arkime/suricata_a2
cp ../.rsrc/demo.pcap ./.rsrc/
mkdir demo_logs
mkdir fight_logs
```

Verify required tools are installed:

```bash
which suricata
which wireshark
which jq
```

### Dataset
Use the provided PCAP file:

```
#./.rsrc/demo.pcap
```

---

## Brief

In this lesson you will:

- Run Suricata in **read mode** against an existing PCAP
- Inspect **EVE JSON** output
- Correlate Suricata alerts with packet-level data in Wireshark

---

## Demonstration — Suricata Read Mode

Run Suricata in offline mode against the demo PCAP:

```bash
suricata -r .rsrc/demo.pcap   -k none   --runmode auto   -l ./demo_logs/   -vvv   -S /var/lib/suricata/rules/suricata.rules
```

### Command Flags Explained

- `-r` — Read packets from a PCAP file (offline mode)
- `-k none` — Ignore checksum validation (common for PCAP analysis)
- `--runmode single` — Single-threaded execution  
  - Ensures **ordered logs**
  - Useful for learning and analysis (not recommended for production)
- `-l` — Directory to write logs
- `-v / -vvv` — Increase verbosity (helpful for troubleshooting)
- `-S` — Explicitly specify the ruleset being used

---

## Inspecting Suricata Logs

View event types being written to `eve.json`:

```bash
tail ./demo_logs/eve.json | grep event_type
```

Filter only alert events using `jq`:

```bash
jq 'select(.event_type == "alert")' ./demo_logs/eve.json
```

View the fast alert log:

```bash
cat ./demo_logs/fast.log
```

---

## Packet Correlation with Wireshark

Open the same PCAP in Wireshark:

```bash
wireshark ./.rsrc/demo.pcap
```

---

## Execute — Fights On

Run Suricata against the second dataset:

```bash
mkdir fight_logs

suricata -r .rsrc/fights_on.pcap   -k none   --runmode single   -l ./fight_logs/   -vvv   -S /var/lib/suricata/rules/suricata.rules
sudo wireshark ./.rsrc/fights_on.pcap
```

### Analyst Tasks

- Open `fights_on.pcap` in Wireshark
- Identify packets referenced in Suricata alerts
- Annotate screenshots linking alerts and packet payloads
- Map detections to **MITRE ATT&CK** (e.g., T1040 — Network Sniffing)

---

## Debrief

Students should now understand:

- Operating Suricata in **read mode**
- Cross-referencing alerts with packet data
- Validating detection coverage

Dataset: 2024-09-04
