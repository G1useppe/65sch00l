# 65sch00l — Lesson 6: Instructor Guide

## Lesson Overview

**Duration:** 90 minutes (25 theory, 65 practical)

**Prerequisites:** Lessons 1–5 complete.

**PCAP:** `easy123.pcap` — NetSupport Manager RAT infection from 2026-02-28. Contains a single infected host (10.2.28.88 / DESKTOP-TEYQ2NR) on the easyas123.tech domain, beaconing to a C2 server at 45.131.214.85:443 via HTTP (not TLS). Legitimate traffic includes Bing browsing, Microsoft Edge updates, Adobe update checks, and group policy refreshes.

---

## Network Environment

| Host | IP | Role |
|------|-----|------|
| DESKTOP-TEYQ2NR | 10.2.28.88 | Workstation (infected) |
| EASYAS123-DC | 10.2.28.2 | Domain controller |
| Domain | easyas123.tech | Internal AD domain |
| User | brolf | Authenticated user |

## Attack Summary

- NetSupport Manager RAT installed on DESKTOP-TEYQ2NR
- C2 at 45.131.214.85:443 using HTTP (not TLS) — unusual: HTTP protocol on a TLS port
- User agent: `NetSupport Manager/1.3`
- URI: `http://45.131.214.85/fakeurl.htm`
- Beaconing every ~60 seconds for the entire capture (~4.5 hours)
- ~260 check-in POST requests
- No lateral movement observed (simpler than demo.pcap)
- Legitimate traffic mixed in: Bing, Edge updates, Adobe, OCSP, Group Policy

---

## Practical Answer Key

### Exercise 1: First look

**Q1.1:** Approximately 530 alerts (exact count may vary slightly).

**Q1.2:** Three signature types appear:
- `ET REMOTE_ACCESS NetSupport Remote Admin Checkin` (Priority 3)
- `ET REMOTE_ACCESS NetSupport Remote Admin Response` (Priority 3)
- `ET INFO HTTP traffic on port 443 (POST)` (Priority 2)
- `ET INFO Microsoft Connection Test` (Priority 3) — appears once

---

### Exercise 2: Counting and grouping

**Q2.1:** Four unique signatures:

| Count | Signature |
|-------|-----------|
| ~260 | ET REMOTE_ACCESS NetSupport Remote Admin Checkin |
| ~260 | ET INFO HTTP traffic on port 443 (POST) |
| ~3 | ET REMOTE_ACCESS NetSupport Remote Admin Response |
| 1 | ET INFO Microsoft Connection Test |

**Q2.2:** The NetSupport Checkin and HTTP-on-443 fire equally often because they trigger on the same sessions. The name directly identifies NetSupport Manager, a legitimate remote administration tool frequently abused by attackers.

**Q2.3:** The Microsoft Connection Test fires once — it's benign (Windows checking internet connectivity). Rare alerts deserve attention because they might indicate a one-time event (initial access, data exfiltration) rather than ongoing automated activity. However, in this case the rare alert is the least interesting.

**Instructor note:** The NetSupport Response only fires 3 times despite 260+ check-ins because the response signature only matches certain response patterns, not every server reply. This is a good teaching moment about rule specificity.

---

### Exercise 3: Working with eve.json

**Q3.1:** Fields in EVE not in fast.log:
- `flow_id` — unique flow identifier
- `alert.category` — classification category
- `alert.metadata` — rule metadata (created date, confidence, etc.)
- `http.hostname`, `http.url`, `http.http_user_agent` — protocol-specific fields
- `community_id` — cross-tool correlation hash
- `app_proto` — detected application protocol

**Q3.2:** Source IP: `10.2.28.88` (the infected workstation). Destination: `45.131.214.85:443`. All malicious alerts target the same C2 server.

---

### Exercise 4: Understanding the alerts

**Q4.1:** SID 2035892 (NetSupport Checkin) — matches HTTP POST requests with specific content patterns associated with NetSupport Manager's C2 protocol. Key content matches include the user agent string and POST body patterns.

**Q4.2:** SID 2013926 (HTTP on port 443) — port 443 normally carries TLS/HTTPS traffic. This rule fires when it detects unencrypted HTTP on port 443, which is anomalous. In this case, NetSupport Manager is using HTTP (not HTTPS) on port 443 to blend in with normal HTTPS traffic at the port level while avoiding TLS overhead.

**Instructor note:** This is a great teaching point. The attacker uses port 443 to avoid port-based firewall blocking (most firewalls allow 443 outbound). But they use plain HTTP instead of TLS, which is detectable both by Suricata (this rule) and by any tool that inspects protocol vs port (Zeek would log it as HTTP on port 443 too).

**Q4.3:** SID 2031071 (Microsoft Connection Test) — this is NOT malicious. Windows periodically checks `www.msftconnecttest.com/connecttest.txt` to verify internet connectivity. The rule is informational — it exists so analysts know the host has internet access. This is a benign true positive.

---

### Exercise 5: Alert triage

**Q5.1:** Expected verdicts:

| Signature | Verdict | Reasoning |
|-----------|---------|-----------|
| NetSupport Remote Admin Checkin | **True Positive (Malicious)** | NetSupport Manager is a legitimate RMM tool, but when present without authorisation on a corporate endpoint, it's almost certainly attacker-deployed. The beaconing pattern confirms automated C2. |
| NetSupport Remote Admin Response | **True Positive (Malicious)** | Confirms the C2 server responded — the RAT is active, not just attempting to connect. |
| HTTP traffic on port 443 (POST) | **True Positive (Malicious)** | In this context, it reinforces the C2 finding — HTTP on 443 is the RAT's evasion technique. |
| Microsoft Connection Test | **Benign True Positive** | The rule matched correctly, but the activity is standard Windows behaviour. |

**Instructor note:** Push students on the NetSupport verdict. "NetSupport Manager is a legitimate tool — how do you know this is malicious?" Expected reasoning: unsolicited installation, beaconing to an IP (not a corporate support domain), `fakeurl.htm` URI, the context of an investigation exercise. In real life, you'd check with IT whether NetSupport is an authorised tool in this environment.

**Q5.2:** Investigate the NetSupport Checkin first — it's the highest-confidence indicator of compromise, and the beaconing pattern confirms active C2.

**Q5.3:** The repetition with ~60-second intervals confirms automated beaconing. A human using remote access would produce irregular session patterns. Regular timing is a machine, not a person.

---

### Exercise 6: Timeline

**Q6.1:** First alert: `ET INFO Microsoft Connection Test` or `ET REMOTE_ACCESS NetSupport Remote Admin Checkin` (both near 19:55 on 2026-02-28). Last alert: NetSupport Checkin around 00:16 on 2026-03-01.

**Q6.2:** Alerts span approximately 4 hours 20 minutes.

**Q6.3:** Approximately 60 seconds between check-ins. This is consistent with automated C2 beaconing — a software timer, not a human clicking.

---

### Exercise 7: What Suricata tells you vs what it doesn't

**Q7.1:** Suricata confirms:
- NetSupport Manager RAT is active on 10.2.28.88
- The C2 server is 45.131.214.85:443
- The RAT has been beaconing for at least 4+ hours
- HTTP is being used on port 443 (evasion technique)

**Q7.2:** Suricata can't tell you:
- How NetSupport Manager was installed (initial access vector)
- What data the RAT is exfiltrating (content is opaque)
- What commands the C2 server sent to the RAT
- Whether the RAT has moved laterally to other hosts
- What legitimate activity the user performed during this period
- The hostname, domain, or user identity of the infected machine

**Q7.3:** Zeek would show:
- DHCP/Kerberos for hostname and user identity
- HTTP details for the C2 requests (URI, user agent, body sizes)
- DNS for any domain lookups the RAT made
- SMB/DCE-RPC for any lateral movement attempts
- conn.log for the full scope of the host's network activity

---

### Extension: Fast Finishers

**E1:** demo.pcap produces more diverse alerts — ET MALWARE, ET INFO (IP lookups), and possibly ET POLICY signatures. easy123.pcap is dominated by a single repeating signature.

**E2:** Suricata likely does NOT detect the SMB lateral movement from demo.pcap in a way that clearly identifies it. The randomly-named .exe files and service creation are visible in Zeek but not well-signatured. This demonstrates Suricata's blindspot: novel or custom attack techniques without existing signatures.

**E3:** demo.pcap would be harder — more diverse activity, lateral movement that Suricata misses, multiple C2 channels. easy123.pcap is straightforward: one host, one RAT, one C2 server, clear signatures.

---

## Discussion Points

1. **"NetSupport Manager is a legitimate tool. How is this different from your IT department using it?"** — Context matters. Authorised RMM tools connect to corporate infrastructure, not random IPs. The URI `fakeurl.htm` is a giveaway. In incident response, you verify with IT whether the tool is authorised.

2. **"The HTTP-on-443 alert fires 260 times. Would you create a ticket for each one?"** — No. This is where alert aggregation and correlation matter. 260 instances of the same alert from the same source to the same destination is one incident, not 260 incidents.

3. **"What if the attacker used HTTPS instead of HTTP on port 443?"** — The HTTP-on-443 rule wouldn't fire. The NetSupport signature might still fire if it matches on specific byte patterns visible in the TLS handshake or if the content is detectable. This leads into Lesson 7's discussion of rule writing and evasion.

---

## Bridge to Lesson 7

"You now know how to read and triage Suricata alerts. But what happens when the existing ruleset doesn't catch something? In the next lesson, you'll write your own custom Suricata rules, learn how the ET rules work under the hood, and practise triaging a mix of malicious and benign traffic where the line isn't always clear."
