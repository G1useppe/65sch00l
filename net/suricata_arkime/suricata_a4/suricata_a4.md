# Lesson 4 — Live Capture Using Tcpreplay and Wireshark

## Summary
Replay packet captures onto a loopback interface and analyze the live traffic in Wireshark.

## Prepare

Set up your workspace and verify required tools.

```bash - st0ne_fish
cd ~/65sch00l/net/suricata_arkime/suricata_a4
cp ../suricata_a2/.rsrc/demo.pcap ./.rsrc
mkdir demo_logs
mkdir fight_logs
which tcpreplay
which wireshark
```

Dataset:  
Use the provided `./.rsrc/demo.pcap` and `./.rsrc/fightson.pcap` files.

## Brief

Demonstrate how to safely replay traffic on a loopback interface for observation.  
Wireshark can be used to validate timing, payloads, and reconstruction of sessions.
The below commands will require their own individual terminal window.

```bash - st0ne_fish
sudo wireshark -k -i lo
sudo suricata --pcap=lo --runmode single -k none --set pcap.checksum-checks=no -v -l ./demo_logs -S /var/lib/suricata/rules/suricata.rules
#wait for <Notice> -- all 1 packet processing threads...
sudo tcpreplay -i lo -K --pps=100 ./.rsrc/demo.pcap
tail -f ./demo_logs/fast.log
```

Discuss replay speed, isolation, and capture fidelity.  
Observe how timestamps differ from static inspection.

## Execute — Fights On

Repeat the exercise using `fightson.pcap` while monitoring in Wireshark.

```bash - st0ne_fish
sudo wireshark -k -i lo
sudo suricata -i lo -k none -vvv -l ./fight_logs/
sudo tcpreplay -i lo ./.rsrc/fightson.pcap
```

Capture screenshots showing live packets, filters, and reconstructed conversations.  
Highlight suspicious flows and relate them to MITRE ATT&CK techniques.

## Debrief

- Configuring safe local replay environments  
- Observing live packet streams  
- Comparing static vs live packet behavior

Dataset: 2022-03-21
