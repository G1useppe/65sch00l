# 65sch00l — Lesson 7: Suricata Advanced — Rule Writing and Full Stack Integration

## Learning Objectives

By the end of this lesson you will be able to:

- Write custom Suricata rules to detect specific traffic patterns
- Use protocol-aware keywords (http.uri, http.user_agent, tls.sni, dns.query)
- Test rules against PCAPs and verify they fire correctly
- Integrate Suricata alerts with Zeek logs and Arkime sessions using community ID
- Execute a full three-tool investigation: alert → context → evidence

---

## Theory

### Writing custom rules

When the ET ruleset doesn't cover a specific threat, you write your own rules. The process is: identify the pattern in the traffic, write a rule to match it, test it against a PCAP, and refine.

### Protocol-aware keywords

Suricata understands protocols. Instead of matching raw bytes anywhere in a packet, you can target specific protocol fields:

| Keyword | Matches on |
|---------|-----------|
| `http.uri` | The HTTP request URI |
| `http.host` | The HTTP Host header |
| `http.user_agent` | The HTTP User-Agent header |
| `http.method` | GET, POST, etc. |
| `tls.sni` | TLS Server Name Indication |
| `dns.query` | DNS query name |
| `content` | Raw byte pattern anywhere in the payload |

### Content matching options

```
content:"pattern";           # match this string
nocase;                      # case-insensitive
startswith;                  # must be at the start of the field
endswith;                    # must be at the end of the field
fast_pattern;                # use this content as the primary search pattern
depth:N;                     # only search the first N bytes
offset:N;                    # start searching after N bytes
```

### Flow keywords

```
flow:established,to_server;   # established connection, client → server
flow:established,to_client;   # established connection, server → client
flow:to_server;               # any connection, client → server
```

### Threshold and suppression

To reduce noise from repetitive alerts:

```
# Alert at most once per source IP per 60 seconds
threshold: type limit, track by_src, count 1, seconds 60;

# Alert only after 10 matches in 60 seconds (detect flooding/beaconing)
threshold: type threshold, track by_src, count 10, seconds 60;
```

---

## Practical

This lesson uses both `easy123.pcap` and `demo.pcap`.

### Exercise 1: Write rules for known patterns

Based on what you learned about the easy123.pcap traffic in Lesson 6, write custom rules to detect the NetSupport Manager RAT. Create a rules file:

```bash
mkdir -p /tmp/lesson7
```

Write a rule matching the NetSupport user agent:

```bash
cat > /tmp/lesson7/custom.rules << 'EOF'
# Rule 1: Match the NetSupport Manager user agent
alert http any any -> any any (msg:"CUSTOM NetSupport Manager User Agent"; flow:established,to_server; http.user_agent; content:"NetSupport Manager"; nocase; sid:9000001; rev:1;)
EOF
```

Test it:

```bash
mkdir -p /tmp/lesson7/test1
sudo suricata -r ~/st0ne_buntu/samples/easy123.pcap -S /tmp/lesson7/custom.rules -l /tmp/lesson7/test1/ -k none
cat /tmp/lesson7/test1/fast.log | head -5
wc -l /tmp/lesson7/test1/fast.log
```

**Q1.1:** Did your rule fire? How many times?

Now add a rule matching the `fakeurl.htm` URI:

```bash
cat >> /tmp/lesson7/custom.rules << 'EOF'

# Rule 2: Match the fakeurl.htm URI pattern
alert http any any -> any any (msg:"CUSTOM Suspicious fakeurl.htm Request"; flow:established,to_server; http.uri; content:"fakeurl.htm"; nocase; sid:9000002; rev:1;)
EOF
```

Test both rules together:

```bash
mkdir -p /tmp/lesson7/test2
sudo suricata -r ~/st0ne_buntu/samples/easy123.pcap -S /tmp/lesson7/custom.rules -l /tmp/lesson7/test2/ -k none
grep -c 'CUSTOM' /tmp/lesson7/test2/fast.log
```

**Q1.2:** How do the hit counts for your two rules compare? Why might they differ?

---

### Exercise 2: Write rules for the demo.pcap

Now write rules to detect patterns from the Ursnif/Gozi infection (demo.pcap):

Add these rules to your custom rules file:

```bash
cat >> /tmp/lesson7/custom.rules << 'EOF'

# Rule 3: Detect HTTP requests to raw IPs (no hostname, just an IP in the Host header)
alert http any any -> any any (msg:"CUSTOM HTTP Request to Raw IP Address"; flow:established,to_server; http.host; pcre:"/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/"; sid:9000003; rev:1;)

# Rule 4: Detect the spoofed IE7 user agent (Ursnif pattern)
alert http any any -> any any (msg:"CUSTOM Suspicious Legacy IE7 User Agent"; flow:established,to_server; http.user_agent; content:"MSIE 7.0"; sid:9000004; rev:1;)

# Rule 5: Detect WinHTTP loader user agent
alert http any any -> any any (msg:"CUSTOM WinHTTP Loader User Agent"; flow:established,to_server; http.user_agent; content:"WinHTTP loader"; nocase; sid:9000005; rev:1;)
EOF
```

Test against demo.pcap:

```bash
mkdir -p /tmp/lesson7/test3
sudo suricata -r ~/st0ne_buntu/samples/demo.pcap -S /tmp/lesson7/custom.rules -l /tmp/lesson7/test3/ -k none
cat /tmp/lesson7/test3/fast.log
```

**Q2.1:** Which of your rules fired? Which didn't? Why?

**Q2.2:** Does rule 9000003 (HTTP to raw IP) fire on the easy123.pcap too? Test it:

```bash
mkdir -p /tmp/lesson7/test4
sudo suricata -r ~/st0ne_buntu/samples/easy123.pcap -S /tmp/lesson7/custom.rules -l /tmp/lesson7/test4/ -k none
grep '9000003' /tmp/lesson7/test4/fast.log | head -3
```

What does this tell you about how broadly the rule matches?

---

### Exercise 3: Write your own detection rule

Now write a rule from scratch. Choose one of these challenges:

**Option A:** Write a rule that detects DNS queries for `.onion` domains (present in demo.pcap).

**Option B:** Write a rule that detects HTTP POST requests on port 443 (present in easy123.pcap).

**Option C:** Write a rule that detects beaconing — specifically, the same HTTP request occurring more than 10 times in 60 seconds to the same destination.

Add your rule to `custom.rules` and test it against the appropriate PCAP.

**Q3.1:** Write your rule and paste it here.

**Q3.2:** How many times does it fire? Is there a false positive risk?

---

### Exercise 4: Threshold and suppression

Your "HTTP to Raw IP" rule (9000003) fires many times. Add a threshold to limit it:

```bash
cat >> /tmp/lesson7/custom.rules << 'EOF'

# Rule 6: Same as Rule 3 but with threshold — alert once per dest IP per 5 minutes
alert http any any -> any any (msg:"CUSTOM HTTP to Raw IP (throttled)"; flow:established,to_server; http.host; pcre:"/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/"; threshold: type limit, track by_dst, count 1, seconds 300; sid:9000006; rev:1;)
EOF
```

Test and compare:

```bash
mkdir -p /tmp/lesson7/test5
sudo suricata -r ~/st0ne_buntu/samples/easy123.pcap -S /tmp/lesson7/custom.rules -l /tmp/lesson7/test5/ -k none
echo "=== Unthrottled ==="
grep -c '9000003' /tmp/lesson7/test5/fast.log
echo "=== Throttled ==="
grep -c '9000006' /tmp/lesson7/test5/fast.log
```

**Q4.1:** How many times does the throttled version fire vs the unthrottled version?

**Q4.2:** In a live monitoring scenario, which version would you deploy? Why?

---

### Exercise 5: Full stack integration — Suricata + Zeek + Arkime

This is the capstone exercise for the Suricata block. Use all three tools together on `easy123.pcap`.

**Step 1: Suricata — get the alerts**

```bash
mkdir -p /tmp/lesson7/fullstack/suricata
sudo suricata -r ~/st0ne_buntu/samples/easy123.pcap -c /etc/suricata/suricata.yaml -l /tmp/lesson7/fullstack/suricata/ -k none
```

Identify the primary alert and extract the community ID:

```bash
cat /tmp/lesson7/fullstack/suricata/eve.json | jq -r 'select(.event_type == "alert" and .alert.signature_id == 2035892) | [.timestamp, .community_id, .src_ip, .dest_ip] | @tsv' | head -3
```

**Step 2: Zeek — get the context**

```bash
mkdir -p /tmp/lesson7/fullstack/zeek && cd /tmp/lesson7/fullstack/zeek
/opt/zeek/bin/zeek -r ~/st0ne_buntu/samples/easy123.pcap LogAscii::use_json=T policy/protocols/conn/community-id-logging
```

Use the community ID from Step 1 to find the connection in Zeek:

```bash
cat conn.log | jq 'select(.community_id == "<paste>")' 
```

Find the HTTP details:

```bash
cat http.log | jq -r 'select(.["id.resp_h"] == "45.131.214.85") | [.ts, .method, .host, .uri, .user_agent, .request_body_len, .response_body_len] | @tsv' | head -5
```

Identify the infected host from DHCP and Kerberos:

```bash
cat dhcp.log | jq -r '[.host_name, .client_addr, .client_fqdn, .domain] | @tsv'
cat kerberos.log | jq -r 'select(.success == true) | [.client, .service] | @tsv' | head -5
```

**Step 3: Arkime — get the evidence**

```bash
sudo /opt/arkime/bin/capture --copy -r ~/st0ne_buntu/samples/easy123.pcap -c /opt/arkime/etc/config.ini 2>/dev/null
```

Open Arkime (`http://localhost:8005`), adjust the time range, and search:

```
communityId == "<paste from Step 1>"
```

**Q5.1:** Build a complete picture of the incident using all three tools. Fill in:

- **Infected host:** hostname, IP, domain, username (source: _____)
- **C2 server:** IP, port, protocol (source: _____)
- **RAT tool:** name, user agent, URI pattern (source: _____)
- **Beaconing interval:** approximately _____ seconds (source: _____)
- **First alert timestamp:** _____ (source: _____)
- **Evidence of active C2 response:** yes/no, evidence: _____ (source: _____)

**Q5.2:** Write a three-paragraph incident summary that references findings from all three tools.

**Q5.3:** Compile an IOC list with at least 5 indicators from across all three tools.

---

### Extension: Fast Finishers

Write a detection rule that would catch this RAT even if the attacker changed the user agent string. Think about what other characteristics of the traffic are distinctive beyond the user agent.

**E1:** What aspects of the C2 communication could you write a rule for that would be harder to change?

**E2:** Write the rule, test it, and explain why it's more resilient than a user-agent match.

---

### Cleanup

```bash
cd ~ && rm -rf /tmp/lesson7
```

---

## Key Takeaways

- Custom Suricata rules let you detect threats the existing ruleset doesn't cover
- Protocol-aware keywords (http.uri, http.user_agent) are more precise than raw content matching
- Thresholds prevent alert fatigue from repetitive beaconing
- The three-tool workflow — Suricata (alert) → Zeek (context) → Arkime (evidence) — is greater than the sum of its parts
- Community ID is the universal join key across all three tools
- Writing detection rules requires understanding what makes malicious traffic distinctive
