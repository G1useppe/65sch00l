# 65sch00l — Lesson 1: Zeek Foundations — What Zeek Sees

## Learning Objectives

By the end of this lesson you will be able to:

- Explain what Zeek is and how it differs from signature-based detection tools
- Run Zeek against a PCAP file in offline analysis mode
- Identify the different log types Zeek produces and what each captures
- Use `jq` to query and filter Zeek's JSON log output
- Extract basic network intelligence from connection and DNS logs

---

## Theory

### What is Zeek?

Zeek (formerly Bro) is a network analysis framework. Unlike tools such as Suricata or Snort that match traffic against signatures to generate alerts, Zeek watches network traffic and produces detailed, structured logs describing what it observes. It doesn't tell you something is "bad" — it tells you what happened, and you decide what matters.

Think of it this way: Suricata is a security guard with a list of known criminals. It alerts when it recognises someone on the list. Zeek is a CCTV system that records everyone who walks through the door — what they did, who they talked to, what they were carrying, and when they left. The CCTV footage doesn't tell you who the criminals are, but it gives you the evidence to figure it out.

### How Zeek processes traffic

When Zeek reads network traffic (either live or from a PCAP file), it goes through three stages:

1. **Event engine** — parses raw packets and generates events (e.g. "a TCP connection was established", "a DNS query was made", "an HTTP request was sent")
2. **Script layer** — Zeek scripts process these events and decide what to log
3. **Log output** — structured logs are written to disk, one file per protocol/activity type

### The Zeek log ecosystem

Zeek doesn't produce a single log file. It produces many, each covering a different aspect of network activity:

| Log file | What it records |
|----------|----------------|
| `conn.log` | Every connection — source, destination, ports, protocol, duration, bytes transferred, connection state |
| `dns.log` | DNS queries and responses — who asked for what domain, what answer came back |
| `http.log` | HTTP requests — method, host, URI, user agent, response codes, file references |
| `ssl.log` | TLS/SSL connections — server name (SNI), JA3 fingerprint, certificate details |
| `files.log` | File transfers — MIME type, size, hash, which connection carried them |
| `weird.log` | Protocol anomalies and violations — things that don't conform to standards |

Not every log file will be generated for every PCAP. Zeek only creates a log file when it observes the relevant protocol. A PCAP with only DNS and HTTP traffic won't produce an `smb_files.log`.

### JSON output

Zeek can output logs in two formats: TSV (tab-separated values, the traditional default) and JSON. We use JSON because it's easier to query with tools like `jq`, integrates directly with Elasticsearch and other analysis platforms, and is self-describing — every field has a name.

To tell Zeek to output JSON:

```bash
zeek -r <pcap> LogAscii::use_json=T
```

### Community ID

Community ID is a standardised hash that uniquely identifies a network flow (based on the 5-tuple: source IP, destination IP, source port, destination port, and protocol). The same connection will produce the same community ID regardless of which tool generates it. This is the key that lets you correlate a Zeek connection with a Suricata alert or an Arkime session for the same traffic.

To enable community ID in Zeek:

```bash
zeek -r <pcap> LogAscii::use_json=T policy/protocols/conn/community-id-logging
```

### Key tool: jq

`jq` is a command-line JSON processor. Since Zeek outputs one JSON object per line (one per log entry), `jq` is the primary tool for reading, filtering, and extracting data from Zeek logs. You'll use it extensively throughout this course.

Basic `jq` patterns:

```bash
# Pretty-print a JSON file
cat conn.log | jq '.'

# Extract a single field from every entry
cat conn.log | jq -r '.["id.resp_h"]'

# The -r flag outputs raw strings (no quotes)

# Select entries matching a condition
cat conn.log | jq 'select(.proto == "tcp")'

# Extract multiple fields as tab-separated values
cat conn.log | jq -r '[.["id.orig_h"], .["id.resp_h"], .["id.resp_p"]] | @tsv'
```

---

## Practical

> **Note:** This practical uses a benign traffic PCAP to build foundational skills. Lesson 2 introduces a more complex scenario.

### Setup

Run Zeek against the provided PCAP:

```bash
mkdir -p /tmp/lesson1 && cd /tmp/lesson1
/opt/zeek/bin/zeek -r ~/st0ne_buntu/samples/lesson1.pcap LogAscii::use_json=T policy/protocols/conn/community-id-logging
```

### Exercise 1: Discover what Zeek produced

List all the log files Zeek generated and their sizes:

```bash
ls -lh *.log
```

**Q1.1:** How many different log files did Zeek create?

**Q1.2:** Based on the log file names, what protocols are present in this PCAP?

---

### Exercise 2: Reading conn.log

`conn.log` is the foundation — every network connection gets an entry here. Look at the first entry:

```bash
cat conn.log | jq '.' | head -30
```

**Q2.1:** Looking at the fields in a single conn.log entry, list five fields and describe what each records.

Count the total connections:

```bash
cat conn.log | wc -l
```

**Q2.2:** How many connections are in this PCAP?

Find all unique source IPs:

```bash
cat conn.log | jq -r '.["id.orig_h"]' | sort -u
```

**Q2.3:** How many unique source IPs are there?

Find all unique destination IPs:

```bash
cat conn.log | jq -r '.["id.resp_h"]' | sort -u
```

**Q2.4:** How many unique destination IPs are there?

Count connections per protocol:

```bash
cat conn.log | jq -r '.proto' | sort | uniq -c | sort -rn
```

**Q2.5:** What is the split between TCP and UDP?

Find the top destination ports:

```bash
cat conn.log | jq -r '.["id.resp_p"]' | sort | uniq -c | sort -rn | head -10
```

**Q2.6:** What are the most common destination ports? What services do they correspond to?

---

### Exercise 3: Reading dns.log

DNS lookups reveal what hosts are communicating with. List all queried domains:

```bash
cat dns.log | jq -r '.query' | sort -u
```

**Q3.1:** List the domains that were queried.

Find DNS queries with answers:

```bash
cat dns.log | jq -r 'select(.answers != null) | [.query, (.answers | join(","))] | @tsv'
```

**Q3.2:** Which queries returned answers, and what were the resolved IPs?

Find the DNS server (most common responder on port 53):

```bash
cat conn.log | jq -r 'select(.["id.resp_p"] == 53) | .["id.resp_h"]' | sort | uniq -c | sort -rn
```

**Q3.3:** What is the DNS server IP?

---

### Exercise 4: Basic statistics

Find the top talkers by bytes sent:

```bash
cat conn.log | jq -r 'select(.orig_bytes != null) | [.orig_bytes, .["id.orig_h"], .["id.resp_h"]] | @tsv' | sort -rn | head -10
```

**Q4.1:** Which host sent the most data, and to where?

Find connection states:

```bash
cat conn.log | jq -r '.conn_state' | sort | uniq -c | sort -rn
```

**Q4.2:** What are the most common connection states? Look up what `SF`, `S0`, and `S1` mean in the Zeek documentation.

---

### Exercise 5: Putting it together

**Q5.1:** Based on your analysis, describe the network in one paragraph: how many hosts, what the DNS server is, what protocols are in use, and what the traffic appears to be doing.

**Q5.2:** Is there anything in the traffic that you would want to investigate further? Why?

---

### Cleanup

```bash
cd ~ && rm -rf /tmp/lesson1
```

---

## Key Takeaways

- Zeek produces structured logs describing network activity — it observes, it doesn't judge
- `conn.log` records every connection and is the starting point for any investigation
- `dns.log` reveals what domains hosts are communicating with
- `jq` is your primary tool for querying Zeek's JSON output
- Community ID is the cross-tool correlation key you'll use in later lessons
- Even basic connection statistics (top talkers, port distribution, connection states) tell a story about a network
