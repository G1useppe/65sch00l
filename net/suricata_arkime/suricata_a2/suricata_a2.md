# Lesson 2 — Suricata Read Mode and Wireshark

## Summary
Use Suricata in offline mode to generate alerts and correlate them with packets in Wireshark.

## Prepare
```bash
#sudo pipx run suricata-update
### grab rules from emerging threats
cd ~/65sch00l/net/suricata_arkime/suricata_a2
cp ~/.rsrc/demo.pcap ./.rsrc/
mkdir demo_logs
mkdir fight_logs
which suricata
which wireshark
which jq

```

Dataset:
Use the provided `./.rsrc/demo.pcap` file.

## Brief
Demonstrate Suricata’s read mode and how to inspect EVE JSON logs. 

``` st0ne_fish
suricata -r .rsrc/demo.pcap -k none --runmode single -l ./demo_logs/ -vvv -S /var/lib/suricata/rules/suricata.rules
### run suricata in offline mode (-r)
### ignore checksums (-k)
### --runmode single ensure single threaded processing, resulting in ordered logs (not desirable in production)
### tell the logs where to write (-l)
### verbosity (-v to -vvvvv) is great for troubleshooting
### make sure we are hitting the right ruleset with -S
tail ./demo_logs/eve.json | grep event_type
### lets have a look at all of the logs we get - there are many different event_type values
jq 'select(.event_type == "alert")' ./demo_logs/eve.json
### lets sneak preview jq, a powerful json query utility that we'll touch on later on course
cat ./demo_logs/fast.log
### fast.log is configured to give quick, readable access to the alert event_type
wireshark ./.rsrc/demo.pcap 
### Show correlation of alerts with packets in Wireshark.
```

## Execute — Fights On
1. Run Suricata in read mode:
   ```st0ne_fish
   mkdir fight_logs
   suricata -r .rsrc/fights_on.pcap -k none --runmode single -l ./fight_logs/ -vvv -S /var/lib/suricata/rules/suricata.rules
   ```
2. Open the same PCAP in Wireshark to locate packets referenced in alerts.
3. Annotate screenshots linking alerts and packet payloads.
4. Map detections to MITRE ATT&CK (e.g., `T1040 – Network Sniffing`).

## Debrief
- Operating Suricata in read mode
- Cross-referencing alerts with packet data
- Validating detection coverage
