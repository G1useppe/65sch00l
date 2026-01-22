# Lesson 7 — Live Suricata–Splunk Integration with Tcpreplay

## Summary
This is the big one. Demonstrate your skills in a challenging environment. Good luck! Replay traffic while Suricata detects events in real time and Splunk indexes them live.

## Prepare
```bash
cd ~/65sch00l/net/suricata_arkime/suricata_a7
mkdir fight_logs
which suricata
which tcpreplay
cd /opt/splunk/bin/
sudo ./splunk remove index suricata
sudo ./splunk add index suricata
cd ~/65sch00l/net/suricata_arkime/suricata_a6
sudo ./splunk add monitor ./fight_logs/eve.json -index suricata -sourcetype _json
```

Dataset:
Use `./.rsrc/fights_on.pcap`.

## Brief
Demonstrate the complete live detection pipeline from packet replay to indexed alerts in Splunk.

## Execute — Fights On
Narrative: We've noticed an uptick on malicious scans and probes inbound on our server (203.161.44.28). How many can you count in the window?

1. Start Suricata in live capture mode on loopback:
   ```bash
   sudo suricata --pcap=lo --runmode auto -k none --set pcap.checksum-checks=no -v -l ./fight_logs -S /var/lib/suricata/rules/suricata.rules

2. Start Wireshark in live capture mode on loopback:
   ```bash
   sudo wireshark -k -i lo

   ```

3. Replay traffic (4 hour run):
   ```bash
   sudo tcpreplay -i lo --pps=25 ./.rsrc/fights_on.pcap
   ```


4. Map live detections to MITRE ATT&CK Navigator.
``` bash
firefox https://mitre-attack.github.io/attack-navigator/
```

## Debrief
- Running Suricata live while feeding Splunk
- Observing end-to-end detection and indexing
- Confirming detection timeliness and fidelity

Dataset: 2025-11-23
