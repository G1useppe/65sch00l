# Lesson 3 — Capinfos and Sequence Diagramming

## Summary
Use capinfos, sequence diagramming and Wireshark to summarize network flow, visualize packet exchanges, and overlay Suricata alerts.

## Prepare

Set up your environment and ensure tools are installed and ready.

```bash - st0ne_fish
cd ~/65sch00l/net/suricata_arkime/suricata_a3
mkdir demo_logs
mkdir fight_logs
which suricata
which wireshark
which capinfos
which jq
cp ../suricata_a2/demo_logs/* ./demo_logs/
```

Dataset:  
Use the provided `./.rsrc/demo.pcap` and `./.rsrc/fightson.pcap` files.

## Brief

Demonstrate how to use `capinfos` to summarize capture metadata and how to diagram packet flow.  
Run Suricata to identify alerts, then visualize relationships and timing between endpoints.

```bash - st0ne_fish
capinfos ./.rsrc/demo.pcap
```

```
cp ./demo_logs/eve.json ./.rsrc/
cd .rsrc
python3 ./seqdiag.py | java -Djava.awt.headless=true -jar ./plantuml-mit-1.2024.6.jar -p -Tpng > ../seqdiag.png
rm eve.json
eog seqdiag.png
cd ..
wireshark ./.rsrc/demo.pcap
```

Use Wireshark’s **Follow TCP Stream** to identify dialogue sequences and note source–destination order.  
Represent the exchange as a sequence diagram (tool-based or manual).  

## Execute — Fights On

Repeat using `fightson.pcap`.

```bash - st0ne_fish
suricata -r ./.rsrc/fightson.pcap -k none --runmode single   -l ./fight_logs/ -vvv   -S /var/lib/suricata/rules/suricata.rules
capinfos ./.rsrc/fightson.pcap
```

Review the flow in Wireshark and identify notable sequences or anomalies.  
Overlay Suricata alert data on the diagram and map to MITRE ATT&CK behaviors.

## Debrief

- Using `capinfos` for quick traffic summaries  
- Translating packet capture into flow diagrams  
- Integrating IDS detections into sequence analysis

Dataset: 2021-12-08
