# Lesson 5 — Static Workflow with Arkime

## Summary
Use Arkime in conjunction with Suricata to rehearse investigation workflows for larger datasets.

## Prepare
```bash
# cd ~/65sch00l/net/suricata_arkime/suricata_a5
which arkimecapture
which arkimeviewer
which tcpreplay

# git clone https://github.com/65sch00l/network-tradecraft.git ~/65sch00l
```

Dataset:
Use `./.rsrc/sample-http.pcap`.

## Brief
Demonstrate Arkime’s live capture mode and real-time session indexing workflow.

## Execute — Fights On
1. Start Arkime capture on loopback interface.
2. Replay traffic:
   ```bash
   sudo tcpreplay -i lo ./.rsrc/sample-http.pcap
   ```
3. Confirm sessions appear in the Arkime viewer.
4. Annotate suspicious behavior and map to MITRE ATT&CK.

## Debrief
- Using Arkime for live capture
- Comparing static vs live indexing
- Tagging and documenting evidence in real time
