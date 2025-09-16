To conduct this demonstration, please grab the PCAP file from [https://www.malware-traffic-analysis.net/2020/05/08/index.html](), however it can also be found on the st0ne_fish virtual disk at ~/Documents/.rsrc

To conduct a NAPX, please conduct the following steps:
### Environment Setup
```
cd ~
mkdir napx_demo
cd napx_demo
#unzip the pcap here and call it demo.pcap
mkdir logs .rsrc
cd logs
mkdir suricata zeek
cd ..
cp ~/Documents/.rsrc/* ./.rsrc
sudo /opt/splunk/bin/splunk remove index zeek
sudo /opt/splunk/bin/splunk remove index suricata
sudo /opt/splunk/bin/splunk add index zeek
sudo /opt/splunk/bin/splunk add index suricata

# Run the following 3 commands to populate the .rsrc folder
wget https://raw.githubusercontent.com/G1useppe/65sch00l/main/NAPX/.rsrc/plantuml-mit-1.2024.6.jar -P ~/napx_demo/.rsrc

wget https://raw.githubusercontent.com/G1useppe/65sch00l/main/NAPX/.rsrc/xprint-seq-diagram-filter-high-alerts.py -P ~/napx_demo/.rsrc

wget https://raw.githubusercontent.com/G1useppe/65sch00l/main/NAPX/.rsrc/zeek_oneshot.sh -P ~/napx_demo/.rsrc
```
### Metadata Review
To grab the essential metadata from the PCAP, we can use the inbuilt Wireshark CLI program *capinfos*.

```
cd ~/napx_demo
capinfos -A ./demo.pcap > ./capinfos_20200508.txt
cat ./capinfos_20200508.txt
```

The output from *capinfos* is a powerful means of gaining an overview of the dataset.

```
File name:           ./2020-05-08-Trickbot-infection-in-AD-environment.pcap
File type:           Wireshark/tcpdump/... - pcap
File encapsulation:  Ethernet
File timestamp precision:  microseconds (6)
Packet size limit:   file hdr: 65535 bytes
Number of packets:   51 k
File size:           43 MB
Data size:           42 MB
Capture duration:    3098.787716 seconds
First packet time:   2020-05-09 06:46:17.014345
Last packet time:    2020-05-09 07:37:55.802061
Data byte rate:      13 kBps
Data bit rate:       110 kbps
Average packet size: 829.54 bytes
Average packet rate: 16 packets/s
SHA256:              ad66158f88c4b7b652649463d58fbcb169b32a82d57c89a438b8c9cecc981cc3
RIPEMD160:           52d9a4a2e343887e258234552f34168c254f899b
SHA1:                6fad67da442f99a5c2febbab860d2c68128d27d3
Strict time order:   True
Number of interfaces in file: 1
Interface #0 info:
                     Encapsulation = Ethernet (1 - ether)
                     Capture length = 65535
                     Time precision = microseconds (6)
                     Time ticks per second = 1000000
                     Number of stat entries = 0
                     Number of packets = 51370

```
### Suricata Offline Mode

To begin rules based detection for the PCAP, run Suricata in offline mode. 

```
cd ~/napx_demo/
suricata -r demo.pcap -k none --runmode single -l ./logs/suricata/ -vvv -S /var/lib/suricata/rules/suricata.rules
```

The flags in the command ask Suricata to act in the following ways:
- -r specifies offline mode
- -k none asks Suricata to bypass checksums
- --runmode single ensures Suricata uses only one thread - this is important for having chronologically ordered logs
- -l specifies the directory in which Suricata writes the logs it is configured to write
- -v(vv) specifies the degree of verbosity in the terminal
- -S specifies the rule file (which was found by running suricata --dump-config)

### Sequence Diagram

With the Suricata logs produced, a sequence diagram can be produced.

```
cd ~/napx_demo/
cp ~/napx_demo/logs/suricata/eve.json ./.rsrc/
python3 ./.rsrc/seqdiag.py | java -Djava.awt.headless=true -jar ./.rsrc/plantuml-mit-1.2024.6.jar -p -Tpng > seqdiag.png
```

### Zeek Offline Mode

```
cd ~/napx_demo/logs
zeek -C -r ../demo.pcap LogAscii::use_json=T
ls -lah
#should see all zeek logs
```
### Splunk Import

To import the Suricata eve.json into Splunk:

```
cd /opt/splunk/bin/
sudo ./splunk add index suricata
sudo ./splunk add oneshot ~/napx_demo/logs/suricata/eve.json -index suricata -sourcetype _json
```

To import the Zeek logs into Splunk:

```
cd ~/napx_demo/.rsrc
sudo chmod +x ./zeek_oneshot.sh
sudo ./zeek_oneshot.sh
```

To login in to Splunk
```
firefox http://127.0.0.1:8000
#credentials st0ne_fish/st0nefish
```
### Annotated Screenshots

Welcome to the analysis phase. It's now time to prove your mettle as a network analyst. Using Splunk to investigate the alerts and logs, investigate the alerts and characterize the intrusion!
