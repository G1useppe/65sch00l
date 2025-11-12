# Lesson 7 — Live Suricata–Splunk Integration with Tcpreplay

## Summary
Replay traffic while Suricata detects events in real time and Splunk indexes them live.

## Prepare
```bash
# cd ~/65sch00l/net/suricata_arkime/suricata_a7
which suricata
which splunk
which tcpreplay

# git clone https://github.com/65sch00l/network-tradecraft.git ~/65sch00l
```

Dataset:
Use `./.rsrc/suspicious-dns.pcap`.

## Brief
Demonstrate the complete live detection pipeline from packet replay to indexed alerts in Splunk.

## Execute — Fights On
1. Start Suricata in live capture mode on loopback:
   ```bash
   sudo suricata -i lo -l ./logs/
   ```
2. Replay traffic:
   ```bash
   sudo tcpreplay -i lo ./.rsrc/suspicious-dns.pcap
   ```
3. Verify alerts populate in Splunk in real time.
4. Annotate and map live detections to MITRE ATT&CK.

## Debrief
- Running Suricata live while feeding Splunk
- Observing end-to-end detection and indexing
- Confirming detection timeliness and fidelity
