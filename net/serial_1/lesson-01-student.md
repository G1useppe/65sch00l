# 65sch00l — Lesson 1: Zeek Foundations — What Zeek Sees

## Learning Objectives

By the end of this lesson you will be able to:

- Capture network traffic using tcpdump
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

### Community ID

Community ID is a standardised hash that uniquely identifies a network flow. The same connection produces the same community ID regardless of which tool generates it. This is the key that lets you correlate a Zeek connection with a Suricata alert or an Arkime session for the same traffic. We'll use this extensively in later lessons.

### Capturing traffic with tcpdump

Before you can analyse traffic, you need to capture it. `tcpdump` is the standard command-line packet capture tool on Linux:

```bash
# Capture all traffic on an interface, write to a file
sudo tcpdump -i <interface> -w output.pcap

# Capture only the first 1000 packets
sudo tcpdump -i <interface> -w output.pcap -c 1000

# Capture only traffic on port 80 and 443
sudo tcpdump -i <interface> -w output.pcap port 80 or port 443

# Stop capture with Ctrl+C
```

### Key tool: jq

`jq` is a command-line JSON processor. Since Zeek outputs one JSON object per line, `jq` is the primary tool for reading, filtering, and extracting data from Zeek logs.

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

# Count unique values
cat conn.log | jq -r '.["id.resp_h"]' | sort | uniq -c | sort -rn
```

---

## Practical

### Part 1: Capture your own traffic

You will generate and capture your own network traffic, then analyse it with Zeek. This way you know exactly what should be in the logs — because you created it.

#### Step 1: Find your network interface

```bash
ip -br link show up | grep -v lo
```

Note your interface name (e.g. `ens33`, `eth0`).

#### Step 2: Start the capture

Open **Terminal 1** and start tcpdump:

```bash
mkdir -p /tmp/lesson1
sudo tcpdump -i <your-interface> -w /tmp/lesson1/my-traffic.pcap
```

Leave this running.

#### Step 3: Generate traffic

Open **Terminal 2** (or use the Firefox browser on the VM) and generate a variety of traffic. Do each of these and **write down what you did** — you'll compare your notes to what Zeek finds:

**HTTP traffic:**
```bash
curl -s http://example.com > /dev/null
curl -s http://neverssl.com > /dev/null
```

**HTTPS traffic:**
```bash
curl -s https://www.google.com > /dev/null
curl -s https://www.wikipedia.org > /dev/null
curl -s https://www.github.com > /dev/null
```

**DNS lookups:**
```bash
nslookup cloudflare.com
nslookup bbc.co.uk
nslookup amazon.com
```

**ICMP (ping):**
```bash
ping -c 3 8.8.8.8
ping -c 3 1.1.1.1
```

**Web browsing (open Firefox on the VM):**
- Visit `https://www.bing.com` and search for something
- Visit a news website
- Visit any other website of your choice

Spend 2–3 minutes browsing to generate a reasonable volume of traffic.

#### Step 4: Stop the capture

Go back to **Terminal 1** and press `Ctrl+C` to stop tcpdump.

**Q1.1:** How many packets did tcpdump capture? (It prints the count when you stop it.)

#### Step 5: Verify the PCAP

```bash
file /tmp/lesson1/my-traffic.pcap
ls -lh /tmp/lesson1/my-traffic.pcap
```

**Q1.2:** How large is your PCAP file?

---

### Part 2: Run Zeek against your capture

```bash
cd /tmp/lesson1
/opt/zeek/bin/zeek -r my-traffic.pcap LogAscii::use_json=T policy/protocols/conn/community-id-logging
```

#### Exercise 1: Discover what Zeek produced

```bash
ls -lh *.log
```

**Q2.1:** How many log files did Zeek create?

**Q2.2:** Based on the log file names, what protocols did Zeek detect in your traffic?

**Q2.3:** Which log file is the largest? Does that match the type of traffic you generated the most of?

---

#### Exercise 2: Explore conn.log

Look at the first entry:

```bash
cat conn.log | jq '.' | head -30
```

**Q3.1:** List five fields from a conn.log entry and describe what each records.

Count total connections:

```bash
cat conn.log | wc -l
```

**Q3.2:** How many connections did your browsing session generate? Is this more or fewer than you expected?

Find all unique destination IPs:

```bash
cat conn.log | jq -r '.["id.resp_h"]' | sort -u
```

**Q3.3:** How many unique destination IPs are there? Can you identify what some of them are?

Count connections per protocol:

```bash
cat conn.log | jq -r '.proto' | sort | uniq -c | sort -rn
```

**Q3.4:** What is the split between TCP and UDP? Why is there so much UDP? (Hint: what protocol uses UDP on port 53?)

Find the top destination ports:

```bash
cat conn.log | jq -r '.["id.resp_p"]' | sort | uniq -c | sort -rn | head -10
```

**Q3.5:** What are the most common destination ports? Match each to the service it represents (53=DNS, 80=HTTP, 443=HTTPS, etc.)

---

#### Exercise 3: Explore dns.log

List all queried domains:

```bash
cat dns.log | jq -r '.query' | sort -u
```

**Q4.1:** Compare this list to the websites you visited and the nslookup commands you ran. Are they all present? Are there any domains you didn't explicitly request? Where did those come from?

Find DNS queries with their answers:

```bash
cat dns.log | jq -r 'select(.answers != null) | [.query, (.answers | join(","))] | @tsv'
```

**Q4.2:** Pick two domains and note their resolved IP addresses. Do these IPs appear in conn.log?

Verify by checking conn.log:

```bash
cat conn.log | jq -r 'select(.["id.resp_h"] == "<paste an IP from above>") | [.ts, .["id.resp_p"], .proto] | @tsv'
```

**Q4.3:** What does this tell you about the relationship between DNS lookups and subsequent connections?

---

#### Exercise 4: Explore http.log (if present)

If you generated HTTP traffic (the `curl` to example.com and neverssl.com), you should have an http.log:

```bash
cat http.log | jq -r '[.ts, .method, .host, .uri, .user_agent, .status_code] | @tsv'
```

**Q5.1:** Can you see your curl requests? What user agent did curl use?

**Q5.2:** Are there any HTTP requests you didn't expect? Where did they come from?

**Q5.3:** Why don't your HTTPS visits (google.com, wikipedia.org) appear in http.log? (Hint: what happens to HTTP inside TLS?)

---

#### Exercise 5: Explore ssl.log (if present)

Your HTTPS connections should appear here:

```bash
cat ssl.log | jq -r '[.["id.resp_h"], .server_name] | @tsv' | sort -u
```

**Q6.1:** Can you see the SNI (Server Name Indication) for your HTTPS visits? Match each SNI to a website you visited.

**Q6.2:** Zeek can see the SNI but not the page content. Explain why — what does TLS encrypt vs what stays in plaintext?

---

#### Exercise 6: Connection statistics

Find the top talkers by connection count:

```bash
cat conn.log | jq -r '.["id.resp_h"]' | sort | uniq -c | sort -rn | head -10
```

**Q7.1:** Which destination IP has the most connections? Can you figure out what service it is?

Find connection states:

```bash
cat conn.log | jq -r '.conn_state' | sort | uniq -c | sort -rn
```

**Q7.2:** What are the most common connection states? Look up what `SF`, `S0`, and `S1` mean:
- `SF` — Normal established and terminated
- `S0` — SYN sent, no reply (connection attempt failed)
- `S1` — Connection established but not terminated
- `RSTO` — Reset by originator
- `RSTR` — Reset by responder

Do any of your connections show `S0`? What might that mean?

---

#### Exercise 7: Find something unexpected

Every network capture contains traffic you didn't explicitly generate. Your OS, browser, and installed applications produce background traffic — NTP time sync, OCSP certificate validation, update checks, telemetry.

```bash
cat conn.log | jq -r '[.["id.resp_h"], .["id.resp_p"], .proto] | @tsv' | sort -u
```

**Q8.1:** Identify at least three connections that you did NOT explicitly generate. For each one, try to determine what produced it and why.

**Q8.2:** If you were an analyst looking at someone else's capture, how would you distinguish "normal background traffic" from "something suspicious"?

---

### Part 3: Capture targeted traffic

Now that you understand the basics, capture something specific.

#### Step 1: Start a new capture filtered to port 80 only

```bash
sudo tcpdump -i <your-interface> -w /tmp/lesson1/http-only.pcap port 80
```

#### Step 2: Generate HTTP traffic

```bash
curl -s http://example.com > /dev/null
curl -s http://neverssl.com > /dev/null
curl -A "SuspiciousBot/1.0" http://example.com > /dev/null
```

Stop the capture (`Ctrl+C`).

#### Step 3: Analyse with Zeek

```bash
cd /tmp/lesson1
mkdir http-analysis && cd http-analysis
/opt/zeek/bin/zeek -r ../http-only.pcap LogAscii::use_json=T
```

```bash
cat http.log | jq -r '[.host, .uri, .user_agent] | @tsv'
```

**Q9.1:** Can you see the custom "SuspiciousBot/1.0" user agent? How would this stand out in a real investigation?

**Q9.2:** How does the filtered capture (port 80 only) compare to your full capture? What are the advantages and disadvantages of filtering at capture time?

---

### Cleanup

```bash
cd ~ && rm -rf /tmp/lesson1
```

---

## Key Takeaways

- `tcpdump` captures raw packets; Zeek turns them into structured, queryable logs
- Zeek produces separate log files per protocol — conn.log is always the starting point
- `jq` is your primary tool for querying Zeek's JSON output
- DNS queries reveal intent; connection logs reveal action; HTTP/TLS logs reveal detail
- Your network produces far more traffic than you think — background OS activity, certificate checks, update polling
- Community ID (introduced here, used heavily in later lessons) is the cross-tool correlation key
- Filtering at capture time (tcpdump filters) reduces noise but risks missing relevant traffic
