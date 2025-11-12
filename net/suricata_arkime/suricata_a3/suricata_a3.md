# Lesson 3 — Capinfos and Sequence Diagramming

## Summary
Use capinfos and sequence diagramming to visualize network flow and overlay Suricata alerts.

## Prepare
```bash
# cd ~/65sch00l/net/suricata_arkime/suricata_a3
which capinfos
which wireshark
which suricata

# git clone https://github.com/65sch00l/network-tradecraft.git ~/65sch00l
```

Dataset:
Use the provided `./.rsrc/sample-http.pcap`.

## Brief
Explain how to summarize traffic using capinfos and create sequence diagrams showing packet flow. 
Integrate Suricata alerts to contextualize detections.

## Execute — Fights On
1. Gather metadata:
   ```bash
   capinfos ./.rsrc/sample-http.pcap
   ```
2. Run Suricata in read mode and review alerts.
3. Use Wireshark “Follow TCP Stream” to identify communication flow.
4. Create a sequence diagram (manual or tool-based) showing packet exchange.
5. Annotate key detections and MITRE mappings.

## Debrief
- Extracting traffic statistics with capinfos
- Visualizing flows via diagrams
- Overlaying detections for context
