# 65sch00l — Lesson 3: Arkime Foundations — Indexed Packet Capture

## Learning Objectives

By the end of this lesson you will be able to:

- Explain what Arkime is and how it differs from Zeek
- Import a PCAP into Arkime for indexed session analysis
- Navigate the Arkime viewer: sessions list, session detail, and packet view
- Use the Arkime search bar to filter sessions by IP, port, protocol, and other fields
- Drill into individual sessions to inspect payloads and reassembled streams

---

## Theory

### What is Arkime?

Arkime (formerly Moloch) is a full packet capture and session analysis system. Where Zeek produces structured logs *about* traffic, Arkime stores the actual packets and indexes metadata about every session in Elasticsearch. This means you can search across millions of sessions, find the one you care about, and then inspect the raw packet payload — the actual bytes that crossed the wire.

### How Arkime differs from Zeek

| | Zeek | Arkime |
|---|---|---|
| **Output** | Structured protocol logs (JSON) | Indexed session metadata + full packet access |
| **Storage** | Log files (small) | PCAP files + ES index (large) |
| **Query tool** | `jq` on the command line | Web-based viewer with search bar |
| **Strength** | Fast structured queries across protocol fields | Deep packet inspection, payload viewing, file extraction |
| **Weakness** | Can't show you the raw packets | Heavier storage and resource requirements |

The key distinction: Zeek answers "what connections happened and what protocols were used?" Arkime answers "show me exactly what was sent and received in that connection."

### When to use which

- "How many connections went to port 443?" → Zeek (faster, structured data)
- "What was the actual content of that HTTP response?" → Arkime (packet-level access)
- "What domains were resolved?" → Zeek dns.log (purpose-built for this)
- "Show me the TLS certificate the server presented" → Arkime (can decode and display it)
- "I found a suspicious connection — what was transferred?" → Arkime (full payload)

In practice, you use Zeek to find what's interesting, then Arkime to examine it in detail. Lesson 5 will teach this workflow explicitly.

### The Arkime data model

Arkime organises traffic into **sessions**. A session is roughly equivalent to a connection — a bidirectional flow between two endpoints. For each session, Arkime stores:

- **SPI (Session Profile Information)** — metadata fields: IPs, ports, protocol, timestamps, data volumes, detected application protocol, and extracted fields (HTTP hosts, URIs, TLS SNI, etc.)
- **Packets** — the raw packet data, stored in PCAP files on disk
- **Linked data** — decoded content like HTTP request/response bodies, file transfers, certificates

### PCAP import vs live capture

Arkime can capture live traffic (like Suricata or Zeek), but on st0ne_buntu we primarily use it for offline analysis. You import a PCAP file using the `capture --copy` command, which reads the PCAP, indexes the session metadata into Elasticsearch, and stores a copy of the packets for later retrieval.

---

## Practical

### Setup — Import the PCAP into Arkime

This is the same PCAP you analysed with Zeek in Lesson 2. Now you'll see the same traffic from a different angle.

```bash
sudo /opt/arkime/bin/capture --copy -r ~/st0ne_buntu/samples/demo.pcap -c /opt/arkime/etc/config.ini
```

Wait for the import to complete (you'll see a packet count and "Signal Received" when done). Then open the Arkime viewer in Firefox:

```
http://localhost:8005
```

Log in with username `admin` and password `st0ne_buntu`.

---

### Exercise 1: Navigate the viewer

Once logged in, you should see the **Sessions** tab with a list of all sessions from the imported PCAP.

**Q1.1:** How many sessions does Arkime show? Compare this to the number of connections in Zeek's conn.log from Lesson 2. Are they the same? Why might they differ?

Explore the interface:

- **Sessions tab** — the main session list with columns for time, source, destination, protocol, and data volume
- **SPI Graph** — the bar chart at the top showing session counts over time
- **SPI View** — click the SPI View tab to see a breakdown of traffic by field (source IP, destination IP, protocol, etc.)

**Q1.2:** Using the SPI View, what are the top 5 destination IPs by session count?

**Q1.3:** Using the SPI View, what protocols does Arkime detect in this PCAP?

---

### Exercise 2: Basic searching

Arkime's search bar uses its own query language. Type queries into the search bar at the top and press Enter.

Try these searches:

```
ip.src == 10.0.0.128
```

**Q2.1:** How many sessions originate from 10.0.0.128?

```
ip.dst == 23.95.227.159
```

**Q2.2:** How many sessions go to 23.95.227.159? What ports are used?

```
port.dst == 445
```

**Q2.3:** How many sessions use destination port 445 (SMB)? Between which hosts?

```
protocols == http
```

**Q2.4:** How many sessions contain HTTP traffic?

Combine conditions with `&&` (AND) and `||` (OR):

```
ip.src == 10.0.0.128 && port.dst == 80
```

**Q2.5:** How many sessions from 10.0.0.128 go to port 80?

Use `!=` for negation:

```
ip.src == 10.0.0.128 && ip.dst != 10.0.0.10
```

**Q2.6:** How many sessions from the workstation go to hosts *other than* the domain controller? What does this represent?

---

### Exercise 3: Session detail — inspecting a connection

Find the HTTP sessions to `23.95.227.159`:

```
ip.dst == 23.95.227.159 && protocols == http
```

Click on one of these sessions to expand it. You'll see:

- **Session detail** — metadata about the connection
- **Packet payload** — the raw packet content, or click "Src/Dst" for a reassembled stream view

**Q3.1:** In the session detail, what HTTP URI was requested?

**Q3.2:** Switch to the packet view. Can you see the HTTP request and response? What content type was returned?

**Q3.3:** Looking at the response body — does the content match what the file extension suggests? (Hint: look at the magic bytes at the start of the response body.)

Now look at an HTTP session to `36.89.106.69`:

```
ip.dst == 36.89.106.69 && protocols == http
```

**Q3.4:** Expand a session and examine the HTTP request. What is in the URI path? What does it contain that identifies the infected host?

**Q3.5:** What user agent string is sent in the request? Does this match what you found in Zeek's http.log in Lesson 2?

---

### Exercise 4: SMB sessions

Search for SMB traffic:

```
port.dst == 445 && ip.src == 10.0.0.128
```

Click on one of the larger SMB sessions.

**Q4.1:** Can you see the file names in the session detail or packet view? Look for the randomly-named `.exe` files you found in Zeek's smb_files.log.

**Q4.2:** What advantage does seeing the raw SMB packets give you over Zeek's smb_files.log?

---

### Exercise 5: TLS sessions

Search for TLS connections from the workstation to external hosts:

```
ip.src == 10.0.0.128 && protocols == tls && ip.dst != 10.0.0.10
```

Click on a session to expand it.

**Q5.1:** In the session detail, can you see the TLS Server Name (SNI)? Which sessions have no SNI?

**Q5.2:** Can you see the server's TLS certificate details? What is the certificate's Common Name (CN) and issuer?

**Q5.3:** Why can't Arkime show you the payload content of TLS sessions the way it can for HTTP?

---

### Exercise 6: Connections view

Click the **Connections** tab at the top of the Arkime viewer. This shows a network graph of which hosts communicated.

**Q6.1:** Describe the network topology you see. Which host is the central node?

**Q6.2:** Identify the external hosts connected to 10.0.0.128. Do any of them also connect to 10.0.0.10? What does that imply?

---

### Exercise 7: Compare with Zeek

Think about what you learned from Zeek in Lesson 2 versus what Arkime showed you in this lesson.

**Q7.1:** Name two things Zeek told you that Arkime didn't make obvious.

**Q7.2:** Name two things Arkime showed you that Zeek couldn't.

**Q7.3:** If you had to choose only one tool to start an investigation, which would you pick and why?

---

### Extension: Fast Finishers

Import one of the additional PCAPs and explore it in Arkime independently:

```bash
sudo /opt/arkime/bin/capture --copy -r ~/st0ne_buntu/samples/easy123.pcap -c /opt/arkime/etc/config.ini
```

In the Arkime viewer, use the time picker to focus on the new PCAP's time range (separate from demo.pcap).

**E1:** Map the network — how many internal hosts? What's the domain?

**E2:** Find the infected host and describe what makes it stand out.

**E3:** What external IPs does the infected host communicate with?

---

### Cleanup

No cleanup needed — Arkime sessions persist in Elasticsearch for future lessons.

---

## Key Takeaways

- Arkime gives you packet-level access to indexed, searchable sessions
- Use Arkime's search bar to filter by IP, port, protocol, and extracted fields
- Session detail lets you inspect raw payloads, reassembled streams, and decoded content
- The Connections view provides a visual network map
- Arkime and Zeek are complementary — Zeek for structured queries, Arkime for deep inspection
- The same PCAP looks different through each tool's lens
