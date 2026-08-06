# 65sch00l — Lesson 1: Instructor Guide

## Lesson Overview

**Duration:** 90 minutes (20 theory, 70 practical)

**Prerequisites:** Basic Linux CLI familiarity, understanding of TCP/IP (ports, protocols, IP addresses). Students should have a running st0ne_buntu VM with internet access.

**PCAP:** Students generate their own. No pre-provided PCAP needed.

**Key advantage of self-generated traffic:** Students know exactly what they did, so they can validate Zeek's output against their own actions. "I visited google.com — is it in dns.log? Yes. Is the connection in conn.log? Yes. Why does it appear in ssl.log but not http.log? Because HTTPS." This builds trust in the tool and teaches the relationship between protocols.

---

## Theory Notes

### CCTV analogy
The guard (Suricata) vs CCTV (Zeek) analogy works well. Emphasise that both are valuable — this isn't about one being better. Later lessons will show how they complement each other.

### Common student questions
- "Why would I use Zeek if it doesn't tell me what's bad?" — Because signatures miss novel threats, and Zeek's structured data enables hunting for things you don't have signatures for.
- "Isn't Wireshark better?" — Wireshark is for looking at individual packets. Zeek is for understanding thousands of connections at scale.
- "What's the difference between JSON and TSV?" — Show both briefly. JSON is self-describing, TSV requires a header line.

---

## Setup Notes

### Internet access
Students need working internet on the VM to generate traffic. Ensure DNS is working:

```bash
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

### Interface names
Most VMs use `ens33` (VMware) or `enp0s3` (VirtualBox). Walk through `ip -br link show up` together if students can't find theirs.

### Two terminals
Students need two terminals open simultaneously — one for tcpdump, one for generating traffic. Show them how to open a second terminal before starting Part 1.

---

## Practical Notes

### Part 1: Capture

**Q1.1:** Packet count varies — expect 500–5000 depending on how much browsing they did. If someone has <100, they probably didn't generate enough traffic. If >10000, they browsed a lot or a background process is chatty.

**Q1.2:** File size typically 500KB–5MB for 2–3 minutes of mixed browsing.

**Common issue:** tcpdump says "permission denied" — they forgot `sudo`. Also, if they put tcpdump in the background with `&`, killing it cleanly can be tricky. Recommend using two terminals instead.

### Part 2: Zeek analysis

**Q2.1–Q2.3:** Log file count depends on traffic generated. Minimum expected: `conn.log`, `dns.log`, `ssl.log`, `packet_filter.log`. If they visited HTTP sites: `http.log`, `files.log`. If they pinged: no separate log (ICMP appears in conn.log). Largest log is usually `conn.log` or `dns.log`.

**Q3.2:** Connection count is always higher than students expect. A single webpage load generates 20–50 connections (the page itself, CSS, JS, images, fonts, analytics, CDN resources, OCSP checks). This is a good teaching moment about modern web architecture.

**Q3.3:** Unique destination IPs — typically 15–50 even from a few websites. CDNs, analytics, ad networks, certificate authorities, NTP servers.

**Q3.4:** UDP is dominated by DNS (port 53) and possibly QUIC (port 443). Students may be surprised how much DNS traffic exists — every hostname in every webpage triggers a lookup.

**Q3.5:** Expected top ports:
- 443 (HTTPS) — dominant
- 53 (DNS) — second
- 80 (HTTP) — if they visited HTTP sites
- 123 (NTP) — time sync
- Possibly QUIC on 443/UDP

### Exercise 3: dns.log

**Q4.1:** Students will find domains they didn't explicitly visit. Common sources:
- CDN domains (cloudfront.net, akamaiedge.net, fastly.net)
- Certificate validation (ocsp.digicert.com, r3.o.lencr.org)
- Analytics (google-analytics.com, doubleclick.net)
- OS telemetry (msftconnecttest.com, settings-win.data.microsoft.com)
- Browser services (safebrowsing.googleapis.com)

This is a key learning moment. Ask: "Who generated this traffic — you, your browser, or your operating system?"

**Q4.3:** The DNS→connection relationship: first a DNS query resolves a hostname to an IP, then a TCP connection is made to that IP. Zeek logs both independently. In later lessons, this correlation becomes critical for tracking malware that uses domain generation algorithms (DGAs).

### Exercise 4: http.log

**Q5.1:** curl's user agent is typically `curl/7.x.x` or `curl/8.x.x`.

**Q5.2:** Unexpected HTTP requests often come from OCSP responders, Windows update checks, or browser background requests.

**Q5.3:** HTTPS traffic doesn't appear in http.log because the HTTP content is encrypted inside TLS. Zeek can't see the HTTP request/response — only the TLS handshake metadata (which goes in ssl.log). This is a fundamental concept students need to internalise before Lesson 2.

### Exercise 5: ssl.log

**Q6.2:** TLS encrypts the application data (the HTTP request/response, page content, cookies, etc.). The TLS handshake, including SNI and the server certificate, is NOT encrypted (in TLS 1.2; TLS 1.3 encrypts some but SNI typically remains visible via ECH). So Zeek can see WHERE you connected but not WHAT you sent or received.

### Exercise 6: Connection statistics

**Q7.2:** `S0` connections (SYN sent, no reply) may appear if a service was unavailable, a firewall blocked the connection, or the host tried to connect to a dead IP. In an investigation, many S0 connections to the same destination could indicate scanning or a dead C2 server.

### Exercise 7: Unexpected traffic

**Q8.1:** Common unexpected connections:
- NTP (port 123) — time synchronisation
- OCSP (port 80 to certificate authorities) — certificate revocation checks
- Windows telemetry / update checks
- Browser safe browsing checks
- IPv6 link-local traffic
- LLMNR/mDNS multicast

**Q8.2:** Distinguishing normal from suspicious:
- Known infrastructure IPs (Microsoft, Google, Akamai CDN) are usually benign
- Connections to raw IPs (no DNS resolution first) are more suspicious
- Regular timed connections (beaconing) are suspicious
- Unusual ports, unusual user agents, unusual data volumes
- This question foreshadows Lesson 2 where they see actual malicious traffic

### Part 3: Filtered capture

**Q9.1:** The custom user agent "SuspiciousBot/1.0" is clearly visible in http.log. In a real investigation, unusual or custom user agents are one of the first things analysts look for — malware often uses distinctive or spoofed user agents.

**Q9.2:** Filtered capture advantages: smaller file, less noise, easier analysis. Disadvantages: you might miss relevant traffic on other ports (DNS, TLS connections, lateral movement). In general, capture everything and filter at analysis time unless storage is a constraint.

---

## Discussion Points

1. **"How much traffic did your OS generate without you doing anything?"** — Students are usually surprised. Modern operating systems are constantly chatting — telemetry, updates, certificate checks, time sync. This is the baseline you need to understand before you can spot anomalies.

2. **"If you were monitoring a corporate network, how many connections per hour would you expect?"** — Hundreds to thousands per host. This is why Zeek's structured logs matter — you can't read packets at that scale.

3. **"What would look different if malware was running on your VM?"** — Sets up Lesson 2. Expected answers: connections to unusual IPs, strange DNS queries, regular beaconing, unusual user agents.

---

## Bridge to Lesson 2

"You've captured your own traffic and seen what normal looks like through Zeek's lens. In the next lesson, you'll analyse a PCAP where something has gone very wrong. The same skills — reading conn.log, checking dns.log, finding unexpected connections — will reveal a full malware infection. The difference is: in this lesson you knew what was normal because you generated it. In Lesson 2, you'll have to figure it out."
