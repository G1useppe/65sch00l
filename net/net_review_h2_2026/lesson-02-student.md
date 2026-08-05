# 65sch00l — Lesson 2: Zeek Deep Dive — Protocol Analysis and Anomaly Detection

## Learning Objectives

By the end of this lesson you will be able to:

- Analyse HTTP, TLS, SMB, and file transfer logs to reconstruct network activity
- Identify indicators of compromise from Zeek protocol logs
- Correlate activity across multiple log types to build an attack timeline
- Extract IOCs (indicators of compromise) from Zeek output
- Explain what JA3 fingerprinting is and why it matters

---

## Theory

### Beyond conn.log and dns.log

In Lesson 1 you learned to map a network using connection and DNS data. Now we go deeper — into the protocol logs that tell you *what* happened inside those connections, not just *that* they happened.

### HTTP analysis

`http.log` captures the details of every HTTP request and response: the method (GET, POST), the host, the URI path, the user agent string, response codes, and references to any files transferred. For unencrypted traffic, this is the most revealing log Zeek produces.

Key fields:
- `host` — the target server (from the Host header)
- `uri` — the URL path requested
- `method` — GET (fetching data) or POST (sending data)
- `user_agent` — the software making the request
- `status_code` — 200 (success), 404 (not found), etc.
- `resp_fuids` — links to entries in `files.log` for any files in the response

### TLS/SSL analysis

Most modern traffic is encrypted. Zeek can't see inside TLS, but it can see the handshake metadata:

- **SNI (Server Name Indication)** — the hostname the client requested, sent in plaintext during the TLS handshake
- **JA3 / JA3S** — cryptographic fingerprints of the TLS client and server configurations. The same software (e.g. a specific malware family) will produce the same JA3 hash regardless of what domain it connects to. This makes JA3 a powerful indicator.
- **Certificate details** — issuer, subject, validity dates

### SMB and Windows protocol analysis

In a Windows network, Zeek logs SMB file sharing (`smb_files.log`, `smb_mapping.log`), remote procedure calls (`dce_rpc.log`), and authentication (`kerberos.log`, `ntlm.log`). These are critical for detecting lateral movement — when an attacker moves from one compromised machine to another.

Key indicators in SMB:
- Access to `C$` or `ADMIN$` shares — administrative access to remote machines
- Files with randomised names being written to remote systems
- `svcctl` operations (CreateServiceW, StartServiceW) — remote service creation/execution

### files.log — tracking file transfers

Every file Zeek observes being transferred gets an entry in `files.log`, regardless of protocol (HTTP, SMB, FTP, etc.). Key fields:
- `mime_type` — what kind of file (e.g. `application/x-dosexec` = Windows executable)
- `seen_bytes` / `total_bytes` — file size
- `source` — which protocol carried the file (HTTP, SMB, etc.)
- `analyzers` — what Zeek ran against it (e.g. `PE` for portable executable analysis)

### weird.log — protocol anomalies

`weird.log` records things that don't conform to protocol standards. These aren't necessarily malicious — but unusual protocol behaviour is often a signal worth investigating. Common entries include malformed HTTP requests, DNS response anomalies, and unexpected protocol states.

---

## Practical

This practical uses `demo.pcap` — a capture from a corporate Windows network. Something has gone wrong. Your job is to figure out what.

### Setup

```bash
mkdir -p /tmp/lesson2 && cd /tmp/lesson2
/opt/zeek/bin/zeek -r ~/st0ne_buntu/samples/demo.pcap LogAscii::use_json=T policy/protocols/conn/community-id-logging
```

### Exercise 1: Orientation — map the network

Before investigating anomalies, understand the environment. Use the skills from Lesson 1.

```bash
cat conn.log | jq -r '.["id.orig_h"]' | sort | uniq -c | sort -rn | head -5
```

```bash
cat dns.log | jq -r 'select(.answers != null) | [.query, (.answers | join(","))] | @tsv' | head -10
```

**Q1.1:** What are the internal hosts and what are their roles? (Hint: look at DNS queries for infrastructure records like LDAP SRV, domain names, and the hostname pattern.)

**Q1.2:** What is the internal domain name?

---

### Exercise 2: DNS — what were the hosts looking for?

```bash
cat dns.log | jq -r '.query' | sort -u
```

**Q2.1:** List every domain that isn't part of the internal infrastructure. Categorise each as "expected", "unusual", or "suspicious" and explain your reasoning.

```bash
cat dns.log | jq -r 'select(.rcode_name == "NXDOMAIN") | .query' | sort -u
```

**Q2.2:** What queries returned NXDOMAIN (domain not found)? Is any of them significant?

```bash
cat dns.log | jq -r 'select(.query != null) | .query' | grep -viE 'globalnets|jackson|arpa|local|_ldap|_kerberos|wpad' | sort -u
```

**Q2.3:** Filtering out internal infrastructure queries, what external domains remain? What pattern do you notice?

---

### Exercise 3: HTTP — what was requested?

```bash
cat http.log | jq -r '[.ts, .["id.orig_h"], .host, .method, .uri, .user_agent] | @tsv'
```

**Q3.1:** List all the HTTP hosts contacted and the URIs requested.

**Q3.2:** Identify any requests made to raw IP addresses (no hostname). Why is this notable?

```bash
cat http.log | jq -r '.user_agent' | sort -u
```

**Q3.3:** List all unique user agent strings. Which look like standard browser traffic? Which look unusual? Explain why.

**Q3.4:** Look at the POST requests specifically. What data is being sent, and where?

```bash
cat http.log | jq -r 'select(.method == "POST") | [.["id.orig_h"], .host, .uri, .request_body_len] | @tsv'
```

**Q3.5:** Examine the URI paths in the POST requests to `36.89.106.69`. What information is encoded in the path?

---

### Exercise 4: File transfers — what was downloaded?

```bash
cat files.log | jq -r '[.source, .mime_type, .seen_bytes, .filename] | @tsv' | sort
```

**Q4.1:** What file types were transferred? Identify any executable files.

```bash
cat files.log | jq -r 'select(.mime_type == "application/x-dosexec") | [.ts, .source, .seen_bytes, .filename, .["id.orig_h"], .["id.resp_h"]] | @tsv'
```

**Q4.2:** How many executable files were transferred? Over which protocol(s)? What are their sizes?

**Q4.3:** Looking at the executables transferred over SMB — what are the filenames? What do you notice about the naming pattern?

---

### Exercise 5: SMB — lateral movement

```bash
cat smb_mapping.log | jq -r '[.ts, .["id.orig_h"], .["id.resp_h"], .path, .share_type] | @tsv'
```

**Q5.1:** Which shares were accessed? Is access to `C$` normal?

```bash
cat smb_files.log | jq -r '[.ts, .["id.orig_h"], .["id.resp_h"], .action, .name] | @tsv'
```

**Q5.2:** What files were opened or created on the remote system? Which are named pipes (Windows internal) and which are actual files?

```bash
cat dce_rpc.log | jq -r 'select(.endpoint == "svcctl") | [.ts, .operation] | @tsv'
```

**Q5.3:** What `svcctl` operations occurred? What does the sequence `OpenSCManagerW → OpenServiceW → CreateServiceW → StartServiceW → DeleteService` represent?

---

### Exercise 6: Authentication

```bash
cat ntlm.log | jq -r '[.ts, .["id.orig_h"], .username, .domainname, .server_dns_computer_name, .success] | @tsv'
```

**Q6.1:** What user account authenticated via NTLM? From which host to which host?

```bash
cat kerberos.log | jq -r '[.ts, .client, .service, .success] | @tsv'
```

**Q6.2:** What Kerberos authentication occurred? What machine account is authenticating?

---

### Exercise 7: TLS connections

```bash
cat ssl.log | jq -r '[.ts, .["id.orig_h"], .["id.resp_h"], .server_name, .ja3] | @tsv'
```

**Q7.1:** Which hosts made TLS connections to external servers? What SNI values are present?

**Q7.2:** Are there any TLS connections with no SNI (null or missing server_name)? Why is this significant?

---

### Exercise 8: Build the timeline

Using your findings from all exercises, construct a chronological timeline of events. For each entry include the timestamp, what happened, what evidence supports it, and which log file you found it in.

**Q8.1:** Write a timeline with at least 8 events that tells the story of what happened on this network.

**Q8.2:** Which host was compromised first?

**Q8.3:** Did the compromise spread to other hosts? What evidence supports this?

---

### Exercise 9: Extract IOCs

Compile a list of indicators of compromise from your analysis:

```bash
# External IPs contacted
cat conn.log | jq -r 'select(.local_resp == false) | .["id.resp_h"]' | sort -u

# Domains queried
cat dns.log | jq -r '.query' | grep -viE 'globalnets|jackson|arpa|local|_ldap|_kerberos|wpad' | sort -u

# User agents
cat http.log | jq -r '.user_agent' | sort -u

# JA3 hashes
cat ssl.log | jq -r '.ja3' | sort -u | grep -v null

# File hashes (if available)
cat files.log | jq -r 'select(.md5 != null) | .md5' | sort -u
```

**Q9.1:** Compile your IOC list under these categories: IP addresses, domains, user agents, JA3 hashes.

---

### Cleanup

```bash
cd ~ && rm -rf /tmp/lesson2
```

---

## Key Takeaways

- HTTP logs reveal C2 communication patterns: URI structure, user agents, and POST data exfiltration
- DNS queries for IP lookup services and .onion domains are strong indicators of malware
- files.log tracks executables crossing the network regardless of protocol
- SMB share access to C$ combined with remote service creation is a classic lateral movement pattern
- Multiple log types correlated together tell a story that no single log can
- Building a timeline from structured logs is the core skill of network forensics
