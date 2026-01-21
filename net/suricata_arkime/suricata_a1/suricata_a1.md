# Lesson 1 — Arkime Fundamentals (Static PCAP Exploration)

## Summary
Introduces Arkime for static PCAP indexing and session analysis. Arkime is a lot better at handling large datasets than

## Prepare
```bash
firefox 
```

Dataset:
Use the tagged data on the Arkime Demo Server that can be found using the query:
```

```

## Brief
Demonstrate Arkime’s ability to index, visualize, and tag large PCAP data. 
Show navigation through Sessions, SPI View, and Packet Details. Discuss tagging and collaboration.

## Execute — Fights On
Narrative: Our AD is under attack! We need to start looking through the network data so we can start deployment of countermeasures and protect our servers going forward. 

1. Ingest the sample PCAP:
   ```bash
   arkime-capture -r ./.rsrc/suspicious-dns.pcap -c /opt/arkime/etc/config.ini
   ```
2. Open Arkime viewer and investigate HTTP/DNS activity.
3. Annotate screenshots showing session timeline and suspicious behavior.
4. Map findings to MITRE ATT&CK (e.g., `T1071.001 – Web Protocols`).

## Debrief
- Navigating Arkime session data
- Reconstructing network activity from PCAPs
- Correlating behavior with MITRE ATT&CK
