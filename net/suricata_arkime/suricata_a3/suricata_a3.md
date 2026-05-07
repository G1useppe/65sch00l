# Lesson 3 — Capinfos and Sequence Diagramming

## Summary

Before diving into packet-level analysis, experienced analysts start with the big picture: how long is this capture? How much data? How many packets? `capinfos` answers these questions in seconds. This lesson pairs that metadata summary with **sequence diagramming** — a technique for visualizing the order and direction of network exchanges between hosts, overlaid with Suricata alert data. Together, these tools let you brief teammates and document findings efficiently.

---

## Prepare

### Download the Dataset

```bash
cd ~/65sch00l/net/suricata_arkime/suricata_a3
mkdir -p .rsrc demo_logs fight_logs

# Demo PCAP — reuse from Lesson 2 or re-download
DEMO_PCAP=".rsrc/demo.pcap"
if [ ! -f "$DEMO_PCAP" ]; then
  if [ -f "../suricata_a2/.rsrc/demo.pcap" ]; then
    cp ../suricata_a2/.rsrc/demo.pcap "$DEMO_PCAP"
  else
    DEMO_ZIP=".rsrc/2024-09-04-traffic-analysis-exercise.pcap.zip"
    curl -L -o "$DEMO_ZIP" \
      "https://www.malware-traffic-analysis.net/2024/09/04/2024-09-04-traffic-analysis-exercise.pcap.zip"
    unzip -P "$MTA_PASS" "$DEMO_ZIP" -d .rsrc/
    mv .rsrc/2024-09-04-traffic-analysis-exercise.pcap "$DEMO_PCAP"
  fi
else
  echo "Demo PCAP already exists."
fi

# Fights On PCAP — different exercise from the previous lesson
FIGHT_PCAP=".rsrc/fights_on.pcap"
if [ ! -f "$FIGHT_PCAP" ]; then
  FIGHT_ZIP=".rsrc/2025-01-22-traffic-analysis-exercise.pcap.zip"
  curl -L -o "$FIGHT_ZIP" \
    "https://www.malware-traffic-analysis.net/2025/01/22/2025-01-22-traffic-analysis-exercise.pcap.zip"
  unzip -P "$MTA_PASS" "$FIGHT_ZIP" -d .rsrc/
  mv .rsrc/2025-01-22-traffic-analysis-exercise.pcap "$FIGHT_PCAP"
else
  echo "Fights On PCAP already exists."
fi

# Copy Suricata logs from Lesson 2 demo run (or regenerate)
if [ -f "../suricata_a2/demo_logs/eve.json" ]; then
  cp ../suricata_a2/demo_logs/* ./demo_logs/
else
  echo "No Lesson 2 logs found — run Suricata against demo.pcap first:"
  echo "  suricata -r .rsrc/demo.pcap -k none --runmode single -l ./demo_logs/ -S /var/lib/suricata/rules/suricata.rules"
fi
```

### Verify Tools

```bash
which capinfos   || echo "ERROR: capinfos not found (install wireshark-common)"
which suricata   || echo "ERROR: suricata not found"
which wireshark  || echo "ERROR: wireshark not found"
which jq         || echo "ERROR: jq not found"
which tshark     || echo "WARNING: tshark not found (optional, for automated diagramming)"
```

### Sequence Diagram Tooling

The `seqdiag.py` script in `.rsrc/` reads `eve.json` alerts and outputs PlantUML markup. You need Java and the PlantUML jar to render it:

```bash
# Check for PlantUML jar
if [ ! -f ".rsrc/plantuml.jar" ]; then
  curl -L -o .rsrc/plantuml.jar \
    "https://github.com/plantuml/plantuml/releases/download/v1.2024.6/plantuml-mit-1.2024.6.jar"
fi

java -version 2>/dev/null || echo "ERROR: Java not found — install openjdk-17-jre or similar"
```

> **Alternative:** If you don't have Java/PlantUML, you can paste the PlantUML output into [plantuml.com](https://www.plantuml.com/plantuml/uml) to render online.

---

## Brief

This lesson covers:

1. Using `capinfos` to quickly summarize PCAP metadata
2. Generating sequence diagrams from Suricata alerts to visualize attack flow
3. Combining metadata summaries, sequence diagrams, and Wireshark packet inspection into a coherent analysis workflow

---

## Demonstration — Capinfos

`capinfos` extracts metadata from a PCAP file without parsing every packet:

```bash
capinfos .rsrc/demo.pcap
```

Key fields to note in the output:

| Field | Why It Matters |
|-------|---------------|
| **File size** | Helps estimate processing time and storage needs |
| **Packet count** | Scale of the capture |
| **Capture duration** | How long the window covers — seconds, minutes, or hours? |
| **Start / End time** | When did this traffic occur? Set your Arkime/Wireshark time filters accordingly |
| **Data rate** | Average throughput — unusually high rates may indicate exfiltration or scanning |
| **Interface / encapsulation** | Confirms the capture source and link layer type |

For a concise one-liner summary:

```bash
capinfos -T .rsrc/demo.pcap
```

---

## Demonstration — Sequence Diagramming

### Generating the Diagram from Suricata Alerts

The `seqdiag.py` script reads `eve.json`, deduplicates alerts by 5-tuple + signature, and outputs PlantUML syntax showing the alert flow between hosts:

```bash
# Copy eve.json to the .rsrc directory (script expects it there)
cp ./demo_logs/eve.json .rsrc/
cd .rsrc

# Generate the PlantUML source and render to PNG
python3 ./seqdiag.py | java -Djava.awt.headless=true \
  -jar ./plantuml.jar -p -Tpng > ../demo_seqdiag.png

# Clean up
rm eve.json
cd ..

# View the diagram
xdg-open ./demo_seqdiag.png 2>/dev/null || eog ./demo_seqdiag.png 2>/dev/null || echo "Open demo_seqdiag.png manually"
```

### Reading the Diagram

The sequence diagram shows:

- **Participants** (vertical lines) — each unique IP address involved in severity-1 alerts
- **Arrows** — direction of the alert (source → destination)
- **Labels** — timestamp, SID (signature ID), and signature name

Look for patterns: repeated alerts between the same hosts suggest persistent C2 communication, while fan-out patterns (one source → many destinations) suggest scanning.

### Correlating with Wireshark

After reviewing the diagram, open the same PCAP in Wireshark to drill into specific exchanges:

```bash
wireshark .rsrc/demo.pcap &
```

Use Wireshark's **Follow TCP Stream** feature on sessions identified in the diagram. Compare what the diagram shows (alert-level view) with what the packets reveal (payload-level view).

---

## Execute — Fights On

Repeat the full workflow with a fresh dataset:

```bash
cd ~/65sch00l/net/suricata_arkime/suricata_a3

# 1. Summarize the PCAP
capinfos .rsrc/fights_on.pcap

# 2. Run Suricata
suricata -r .rsrc/fights_on.pcap \
  -k none \
  --runmode single \
  -l ./fight_logs/ \
  -v \
  -S /var/lib/suricata/rules/suricata.rules

# 3. Generate sequence diagram
cp ./fight_logs/eve.json .rsrc/
cd .rsrc
python3 ./seqdiag.py | java -Djava.awt.headless=true \
  -jar ./plantuml.jar -p -Tpng > ../fights_on_seqdiag.png
rm eve.json
cd ..
xdg-open ./fights_on_seqdiag.png 2>/dev/null || echo "Open fights_on_seqdiag.png manually"

# 4. Open in Wireshark
wireshark .rsrc/fights_on.pcap &
```

### Analyst Tasks

1. What is the total capture duration and packet count? Does this suggest a targeted capture or broad monitoring?
2. Review the sequence diagram — identify the primary attacker and victim IPs
3. In Wireshark, follow TCP streams for the most interesting alert sequences
4. Overlay your findings: annotate the sequence diagram (screenshot + notes) with what the packets actually contained
5. Map observed behaviors to **MITRE ATT&CK** techniques

---

## Debrief

After this lesson you should be able to:

- Use `capinfos` to quickly profile any PCAP before analysis
- Generate sequence diagrams from Suricata alert data
- Read sequence diagrams to identify attack patterns and communication flow
- Integrate metadata summaries, IDS alerts, and packet inspection into a structured workflow
