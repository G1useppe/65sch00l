# Lesson 1 — Arkime Fundamentals (Static PCAP Exploration)

## Summary

Arkime is a large-scale, open-source packet capture indexing and search system. Unlike Wireshark, which works best for inspecting individual packets, Arkime excels at navigating thousands of sessions across large datasets. It indexes PCAP metadata (Session Profile Information — SPI) into OpenSearch/Elasticsearch, making network-wide pattern hunting fast and intuitive. In this lesson you will explore the Arkime demo server to learn the interface, then ingest a PCAP locally and practice targeted search queries.

---

## Prepare

### Part A — Explore the Arkime Demo Server

No local setup needed. The Arkime project hosts a public demo instance with pre-loaded data:

```bash
firefox https://demo5.arkime.com/auth
# Credentials: arkime / arkime
```

Spend 10–15 minutes clicking through the interface before proceeding. Get familiar with the layout — Sessions, SPI View, SPI Graph, Connections, and the search bar.

### Part B — Local PCAP Ingest

Download the dataset for local analysis:

```bash
cd ~/65sch00l/net/suricata_arkime/arkime_a1
mkdir -p .rsrc

PCAP_ZIP=".rsrc/2024-09-04-traffic-analysis-exercise.pcap.zip"
PCAP_FILE=".rsrc/2024-09-04-traffic-analysis-exercise.pcap"

if [ ! -f "$PCAP_FILE" ]; then
  curl -L -o "$PCAP_ZIP" \
    "https://www.malware-traffic-analysis.net/2024/09/04/2024-09-04-traffic-analysis-exercise.pcap.zip"
  unzip -P "$MTA_PASS" "$PCAP_ZIP" -d .rsrc/
else
  echo "PCAP already exists, skipping download."
fi
```

Verify tools:

```bash
which arkime-capture || echo "arkime-capture not found — install Arkime or use the Docker setup in Lesson 5"
which jq
```

---

## Brief

This lesson covers three areas:

1. **Navigating the Arkime UI** — Sessions, SPI View, SPI Graph, Connections, and Hunt
2. **Search query syntax** — building targeted queries to isolate suspicious activity
3. **MITRE ATT&CK mapping** — relating network observations to adversary techniques

---

## Demonstration — The Arkime Interface

### Sessions Page

The Sessions page is your primary workspace. Each row represents a **session** (a bidirectional network conversation), not an individual packet. Key things to notice:

- **Timeline** — click and drag to filter by time range
- **Column headers** — Start Time, Source IP, Source Port, Destination IP, Destination Port, Packets, Bytes, Protocol
- **Expand a session (+)** — reveals metadata, packet hex/ASCII, and decoded protocol fields
- **Actions dropdown** — export matching sessions as PCAP or CSV

### SPI View

The SPI (Session Profile Information) View aggregates unique values across all sessions for any indexed field. Use it to quickly answer questions like "what are the top destination IPs?" or "which HTTP user-agents appear in this dataset?" without writing queries.

- Open a category (e.g., HTTP) and click **Load All**
- Hover over any value to add it as a filter (AND or AND NOT)
- Use this to build queries interactively

### SPI Graph

Temporal view of top unique values for any field. Useful for spotting bursts of activity — a sudden spike in DNS queries to a single domain, or a burst of connections to an unusual port.

### Connections

Force-directed graph showing relationships between hosts. Adjust the source/destination fields and the connection weight to visualize different relationship types (IP-to-IP, IP-to-domain, etc.).

---

## Arkime Search Query Reference

The search bar uses Arkime's expression syntax. Here are essential queries to practice:

### Basic Field Searches

```
ip.src == 172.17.0.101
ip.dst == 8.8.8.8
port.dst == 443
ip.protocol == tcp
ip.protocol == udp
```

### Existence Checks

```
http.uri == EXISTS!
dns.host == EXISTS!
tls.ja3 == EXISTS!
suricata.signature == EXISTS!
```

### Wildcards and Contains

```
http.uri == *login*
dns.host == *.ru
http.user-agent == *curl*
host.http == *malware*
```

### Compound Queries (AND / OR / NOT)

```
ip.src == 172.17.0.101 && port.dst == 80
ip.src == 172.17.0.101 && http.uri == EXISTS!
dns.host == *.com || dns.host == *.net
ip.dst != 172.17.0.1 && port.dst == 53
```

### Protocol-Specific Searches

```
# HTTP — find POST requests (potential exfiltration)
http.method == POST

# HTTP — find executable downloads
http.uri == *.exe || http.uri == *.dll || http.uri == *.scr

# DNS — find long subdomain queries (possible C2 tunneling)
dns.host == /.*\..{30,}\..*/

# TLS — find sessions without a valid certificate
tls.notAfter == EXISTS! && tls.ja3 == EXISTS!

# Find large data transfers (bytes > threshold)
bytes > 1000000
```

### Hunting for Suspicious Patterns

```
# Internal host talking to multiple external IPs on uncommon ports
ip.src == 172.17.0.0/24 && port.dst != 80 && port.dst != 443 && port.dst != 53

# DNS queries to recently registered or unusual TLDs
dns.host == *.xyz || dns.host == *.top || dns.host == *.buzz

# HTTP to raw IP addresses (no hostname — possible C2)
ip.dst != 10.0.0.0/8 && ip.dst != 172.16.0.0/12 && ip.dst != 192.168.0.0/16 && http.uri == EXISTS! && host.http != EXISTS!

# Sessions with Suricata alerts
suricata.signature == EXISTS!

# Suricata alerts by severity
suricata.severity == 1
```

### Useful Views to Save

Create saved views (Views dropdown > New View) for searches you run regularly:

- **All HTTP** — `http.uri == EXISTS!`
- **All DNS** — `dns.host == EXISTS!`
- **Suricata Alerts** — `suricata.signature == EXISTS!`
- **Large Transfers** — `bytes > 500000`
- **Executable Downloads** — `http.uri == *.exe || http.uri == *.dll`

---

## Execute — Fights On

**Narrative:** Our Active Directory environment is under attack. We need to triage the network data to identify compromised hosts and map the adversary's behavior.

### Dataset Context (2024-09-04 — "Big Fish in a Little Pond")

- **LAN segment:** 172.17.0.0/24
- **Domain:** bepositive.com
- **Domain Controller:** 172.17.0.17 (WIN-CTL9XBQ9Y19)
- **Gateway:** 172.17.0.1

### Tasks

1. **Ingest the PCAP into Arkime:**

   ```bash
   arkime-capture -r .rsrc/2024-09-04-traffic-analysis-exercise.pcap \
     -c /opt/arkime/etc/config.ini
   ```

2. **Open Arkime Viewer** and set the time range to cover the PCAP's timespan.

3. **Triage using the search queries above:**
   - Identify which internal host(s) generated suspicious outbound traffic
   - Use SPI View > HTTP to find unusual user-agents
   - Use SPI View > DNS to find domains associated with known malware infrastructure
   - Check for executable file downloads: `http.uri == *.exe || http.uri == *.dll`
   - Look for POST requests to external IPs: `http.method == POST && ip.dst != 172.17.0.0/24`

4. **Use the Connections page** with Source = `ip.src` and Destination = `ip.dst` to visualize the communication graph. Identify the infected host by its number of external connections.

5. **Export suspicious sessions as PCAP** (Actions > Export PCAP) for deeper inspection in Wireshark if needed.

6. **Map findings to MITRE ATT&CK** — consider these techniques as starting points:
   - `T1071.001` — Application Layer Protocol: Web Protocols
   - `T1071.004` — Application Layer Protocol: DNS
   - `T1105` — Ingress Tool Transfer
   - `T1041` — Exfiltration Over C2 Channel

---

## Debrief

After this lesson you should be able to:

- Navigate all major Arkime interface pages (Sessions, SPI View, SPI Graph, Connections)
- Write targeted search queries using Arkime's expression syntax
- Use SPI View to rapidly profile traffic without writing queries
- Identify suspicious network behavior patterns in indexed session data
- Map observed network activity to MITRE ATT&CK techniques
- Export filtered sessions as PCAP for further analysis
