# 65sch00l — Lesson 7: Instructor Guide

## Lesson Overview

**Duration:** 120 minutes (15 theory, 105 practical)

**Prerequisites:** Lesson 6 complete. Students should understand fast.log, eve.json, and SID lookups.

**PCAPs:** Both `easy123.pcap` and `demo.pcap`. This lesson crosses between them to demonstrate rule portability.

**Key shift:** Students move from consuming rules to writing them, and from single-tool analysis to integrated three-tool investigation.

---

## Practical Answer Key

### Exercise 1: Rules for known patterns

**Q1.1:** Rule 9000001 (NetSupport user agent) should fire ~260 times — once for each C2 POST.

**Q1.2:** Both rules fire a similar number of times since every C2 request has both the user agent and the URI. Minor differences may occur if some requests are partial or malformed.

---

### Exercise 2: Rules for demo.pcap

**Q2.1:**
- 9000003 (HTTP to raw IP) — **fires** on demo.pcap. Multiple C2 destinations are raw IPs (36.89.106.69, 23.95.227.159, 203.176.135.102).
- 9000004 (IE7 user agent) — **fires** on demo.pcap. The Ursnif C2 uses a spoofed MSIE 7.0 user agent.
- 9000005 (WinHTTP loader) — **fires** on demo.pcap. The dropper component uses `WinHTTP loader/1.0`.
- 9000001 (NetSupport user agent) — **does not fire** on demo.pcap (different malware family).
- 9000002 (fakeurl.htm) — **does not fire** on demo.pcap.

**Q2.2:** Rule 9000003 also fires on easy123.pcap — the NetSupport C2 also uses a raw IP (45.131.214.85). This demonstrates that broad behavioural rules (HTTP to raw IPs) catch more malware families than narrow signature rules (specific user agent). The trade-off: broader rules have higher false positive risk.

**Instructor note:** This is the key insight of the exercise. Ask: "Which type of rule would you want in production — the broad one or the narrow one? What if you could have both?" The answer is layered detection: broad rules for hunting, narrow rules for high-confidence alerting.

---

### Exercise 3: Custom rule

**Option A (DNS .onion):**
```
alert dns any any -> any any (msg:"CUSTOM DNS Query for .onion Domain"; dns.query; content:".onion"; nocase; endswith; sid:9000010; rev:1;)
```
Fires once on demo.pcap (the 5efxqhk2zhgnc24l.onion query). Zero false positive risk — .onion queries should never appear in standard DNS.

**Option B (HTTP POST on 443):**
```
alert http any any -> any 443 (msg:"CUSTOM HTTP POST on Port 443"; flow:established,to_server; http.method; content:"POST"; sid:9000011; rev:1;)
```
Fires ~260 times on easy123.pcap. Could false-positive on legitimate HTTP-over-443 configurations (rare but possible).

**Option C (Beaconing threshold):**
```
alert http any any -> any any (msg:"CUSTOM Possible Beaconing - High Frequency HTTP"; flow:established,to_server; http.method; content:"POST"; threshold: type threshold, track by_dst, count 10, seconds 60; sid:9000012; rev:1;)
```
Fires fewer times (once per threshold window). Higher false positive risk on busy web applications.

---

### Exercise 4: Threshold

**Q4.1:** Unthrottled fires ~260 times; throttled fires approximately 5–10 times (once per destination per 5-minute window across the ~4.5 hour capture).

**Q4.2:** Deploy the throttled version in live monitoring. 260 identical alerts create alert fatigue and SOC ticket overload. The throttled version tells you the same thing — "this host is beaconing to this IP" — without generating hundreds of duplicate tickets.

---

### Exercise 5: Full stack integration

**Q5.1:** Complete picture:

| Field | Value | Source |
|-------|-------|--------|
| Infected host hostname | DESKTOP-TEYQ2NR | Zeek dhcp.log, kerberos.log |
| Infected host IP | 10.2.28.88 | All three tools |
| Domain | easyas123.tech | Zeek kerberos.log |
| Username | brolf | Zeek kerberos.log |
| C2 server | 45.131.214.85:443 | Suricata alerts + Zeek http.log |
| Protocol | HTTP (on port 443) | Suricata (HTTP-on-443 alert) + Zeek http.log |
| RAT tool | NetSupport Manager 1.3 | Suricata (signature name) + Zeek http.log (user agent) |
| URI pattern | `http://45.131.214.85/fakeurl.htm` | Zeek http.log |
| Beaconing interval | ~60 seconds | Suricata alert timestamps + Zeek conn.log |
| First alert | ~19:55:06 2026-02-28 | Suricata fast.log |
| Active C2 response | Yes — server returns 200 OK with 69-byte response | Zeek http.log + Arkime session detail |

**Q5.2:** Look for:
- Paragraph 1: what happened (Suricata alerts identified NetSupport RAT)
- Paragraph 2: who and how (Zeek provided host identity, C2 protocol details)
- Paragraph 3: evidence (Arkime session shows actual HTTP exchange, community ID links all three)

**Q5.3:** IOCs:

| Type | Value | Source |
|------|-------|--------|
| IP | 45.131.214.85 | Suricata + Zeek + Arkime |
| Port | 443 (HTTP, not TLS) | Suricata |
| User Agent | NetSupport Manager/1.3 | Zeek http.log |
| URI | /fakeurl.htm | Zeek http.log |
| Hostname | DESKTOP-TEYQ2NR | Zeek dhcp.log |
| Username | brolf | Zeek kerberos.log |
| Domain | easyas123.tech | Zeek kerberos.log |
| Suricata SID | 2035892 | Suricata |

---

### Extension: Resilient rules

**E1:** Beyond user agent, distinctive characteristics:
- HTTP on port 443 (protocol/port mismatch)
- POST to `/fakeurl.htm` (static URI)
- 60-second beaconing interval
- POST body size consistently 22 or 36 bytes
- Single persistent TCP connection (no new connections per request)

**E2:** Example resilient rule:
```
alert http any any -> any 443 (msg:"CUSTOM Possible RAT - HTTP POST to fakeurl on port 443"; flow:established,to_server; http.method; content:"POST"; http.uri; content:"fakeurl"; sid:9000020; rev:1;)
```
This matches on the URI pattern + port mismatch rather than user agent. The attacker would need to change both the URI and the port, which is harder than changing a user agent string.

---

## Discussion Points

1. **"If you were the attacker, how would you evade these rules?"** — Change the user agent, use a real domain instead of an IP, use actual TLS on 443, randomise the URI, add jitter to the beaconing interval. Each evasion has a cost (complexity, infrastructure) which is the point of detection engineering — raising the attacker's cost.

2. **"When should you write a custom rule vs use the ET ruleset?"** — Custom rules for threats specific to your environment, internal IOCs, or patterns the ET set doesn't cover. ET rules for broad coverage. Both together is best.

3. **"How did community ID change the way you investigated?"** — It should have eliminated the manual work of matching IPs, ports, and timestamps between tools. One hash = one connection across all three tools.

---

## Bridge to Lesson 8

"You've now used all three tools individually and together. In the final lesson, you'll face an unknown PCAP with no hints. You'll decide which tools to use, in what order, and produce a complete investigation report. Everything you've learned comes together."
