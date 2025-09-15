[NAPX.md](https://github.com/user-attachments/files/22325319/NAPX.md)
This is the splash page for the NAPX *vault*.

To conduct this demonstration, please grab the PCAP file from [https://www.malware-traffic-analysis.net/2020/05/08/index.html]()

To conduct a NAPX, please conduct the following steps:
### Environment Setup
```
mkdir <preferred working directory>
cd <preferred working directory>
touch capinfos_<yyyymmdd>.txt
mkdir logs 
mkdir ./logs/suricata ./logs/zeek
```
In our demonstration case;

```
mkdir demo_napx
cd demo_napx
touch capinfos_20200508.txt
mkdir logs 
mkdir ./logs/suricata ./logs/zeek
```
### Metadata Review
To grab the essential metadata from the PCAP, we can use the inbuilt Wireshark CLI program *capinfos*.
```
capinfos -A ./demo.pcap > ./capinfos_20200508.txt
cat ./capinfos_20200508.txt
```
