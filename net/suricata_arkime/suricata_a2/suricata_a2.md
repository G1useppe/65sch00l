# Lesson 2 — Suricata Read Mode and Wireshark

## Summary
Use Suricata in offline mode to generate alerts and correlate them with packets in Wireshark.

## Prepare
```bash
# cd ~/65sch00l/net/suricata_arkime/suricata_a2
which suricata
which wireshark
which jq

# git clone https://github.com/65sch00l/network-tradecraft.git ~/65sch00l
```

Dataset:
Use the provided `./.rsrc/suspicious-dns.pcap` file.

## Brief
Demonstrate Suricata’s read mode and how to inspect EVE JSON logs. 
Show correlation of alerts with packets in Wireshark.

## Execute — Fights On
1. Run Suricata in read mode:
   ```bash
   suricata -r ./.rsrc/suspicious-dns.pcap -l ./logs/
   ```
2. Open the same PCAP in Wireshark to locate packets referenced in alerts.
3. Annotate screenshots linking alerts and packet payloads.
4. Map detections to MITRE ATT&CK (e.g., `T1040 – Network Sniffing`).

## Debrief
- Operating Suricata in read mode
- Cross-referencing alerts with packet data
- Validating detection coverage
