# Lesson 4 — Live Capture Using Tcpreplay and Wireshark

## Summary
Replay static PCAPs to a live interface and observe the traffic in real time using Wireshark.

## Prepare
```bash
# cd ~/65sch00l/net/suricata_arkime/suricata_a4
which tcpreplay
which wireshark

# git clone https://github.com/65sch00l/network-tradecraft.git ~/65sch00l
```

Dataset:
Use `./.rsrc/suspicious-dns.pcap`.

## Brief
Demonstrate how to replay packet captures safely to a loopback interface for live observation.

## Execute — Fights On
1. Start Wireshark capturing on the loopback interface.
2. Replay the traffic:
   ```bash
   sudo tcpreplay -i lo ./.rsrc/suspicious-dns.pcap
   ```
3. Observe sessions and note timestamps, retransmissions, and payloads.
4. Annotate captured evidence and map to MITRE ATT&CK.

## Debrief
- Configuring loopback captures
- Observing replayed traffic in Wireshark
- Relating live replay behavior to static analysis
