# Lesson 7 — Live Suricata–Splunk Integration with Tcpreplay

## Summary
This is the big one. Demonstrate your skills in a challenging environment. Good luck! Replay traffic while Suricata detects events in real time and Splunk indexes them live.

## Prepare
```bash
cd ~/65sch00l/net/suricata_arkime/suricata_a7
mkdir fight_logs
which suricata
which splunk
which tcpreplay
```

Dataset:
Use `./.rsrc/fights_on.pcap`.

## Brief
Demonstrate the complete live detection pipeline from packet replay to indexed alerts in Splunk.

## Execute — Fights On
1. Start Suricata in live capture mode on loopback:
   ```bash
   sudo suricata -i lo -l ./fight_logs/
   ```
2. Replay traffic:
   ```bash
   sudo tcpreplay -i lo ./.rsrc/fights_on.pcap
   ```
3. Verify alerts populate in Splunk in real time.
``` bash
sudo /opt/splunk/bin/splunk add monitor ./fight_logs/eve.json -index suricata -sourcetype _json
```
4. Map live detections to MITRE ATT&CK mapper.
``` bash
firefox https://mitre-attack.github.io/attack-navigator/
```

## Debrief
- Running Suricata live while feeding Splunk
- Observing end-to-end detection and indexing
- Confirming detection timeliness and fidelity

Dataset: 
