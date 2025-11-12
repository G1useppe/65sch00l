# Lesson 6 — Static Investigation with Suricata Logs in Splunk

## Summary
Index Suricata EVE JSON logs into Splunk and analyze alert data from a static investigation.

## Prepare
```bash
# cd ~/65sch00l/net/suricata_arkime/suricata_a6
which suricata
which splunk
which jq

# git clone https://github.com/65sch00l/network-tradecraft.git ~/65sch00l
```

Dataset:
Use Suricata output logs from previous exercises in `./logs/eve.json`.

## Brief
Show how to parse and visualize Suricata events using Splunk’s search and dashboard capabilities.

## Execute — Fights On
1. Import EVE JSON into Splunk using the TA-Suricata or JSON sourcetype.
2. Query for alerts by signature, source IP, and event type.
3. Create dashboards for timeline and frequency analysis.
4. Annotate screenshots and map to MITRE ATT&CK techniques.

## Debrief
- Importing and visualizing Suricata logs in Splunk
- Querying IDS alerts effectively
- Mapping results to ATT&CK framework
