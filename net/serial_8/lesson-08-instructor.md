# 65sch00l — Lesson 8: Instructor Guide (Capstone)

## Lesson Overview

**Duration:** 120 minutes (no theory — fully independent practical)

**Prerequisites:** All previous lessons complete.

**PCAP:** `nemotodes.pcap` — NetSupport Manager RAT infection from 2024-11-26. Students are NOT told this. They should recognise the pattern from Lessons 6–7 (easy123.pcap was also NetSupport Manager) but must prove it independently.

**Instructor role:** Observe, answer clarifying questions about tool usage (not about the traffic), and assess the deliverables.

---

## Network Environment

| Host | IP | Role |
|------|-----|------|
| DESKTOP-B8TQK49 | 10.11.26.183 | Workstation (infected) |
| NEMOTODES-DC | 10.11.26.3 | Domain controller |
| Domain | nemotodes.health | Internal AD domain |
| User | oboomwald (Oliver Q.. Boomwald) | Authenticated user |

## Attack Summary

- NetSupport Manager RAT on DESKTOP-B8TQK49
- **C2:** 194.180.191.64:443 (HTTP over port 443 — same technique as easy123.pcap but different IP)
- User agent: `NetSupport Manager/1.3`
- URI: `http://194.180.191.64/fakeurl.htm`
- Beaconing every ~60 seconds
- **GeoLocation lookup:** geo.netsupportsoftware.com/location/loca.asp (Priority 1 alert — highest severity in this PCAP)
- Connection re-establishment: C2 session drops and reconnects on new source port (53362 → 53500) around 05:38–05:40
- No lateral movement observed
- Legitimate traffic: Bing browsing (QUIC), OCSP, Adobe update check, Windows CTL update, SMB group policy updates, NTLM auth to DC on port 139

---

## Expected Findings by Deliverable

### 1. Network Map

| Item | Expected Answer | Source |
|------|----------------|--------|
| Infected host IP | 10.11.26.183 | conn.log, Suricata alerts |
| Infected host hostname | DESKTOP-B8TQK49 | Zeek ldap_search.log, ntlm.log |
| DC IP | 10.11.26.3 | conn.log (most internal connections) |
| DC hostname | NEMOTODES-DC | ntlm.log, smb_mapping.log, kerberos.log |
| Domain | nemotodes.health | kerberos.log, ldap_search.log |
| DNS server | 10.11.26.3 | conn.log port 53 |
| User | oboomwald (Oliver Q.. Boomwald) | kerberos.log, ldap_search.log |

**Strong students** will also note: the FQDN from LDAP (DESKTOP-B8TQK49.nemotodes.health), the domain SID from ldap_search.log, and the DHCP/DNS infrastructure.

### 2. Timeline

Expected minimum 10 events:

| # | Time (approx) | Event | Tool |
|---|---|---|---|
| 1 | 04:49:38 | Microsoft Connection Test (internet access confirmed) | Suricata |
| 2 | 04:49:38 | NetSupport C2 check-in begins (194.180.191.64:443) | Suricata + Zeek http.log |
| 3 | 04:49:55 | Kerberos AS-REQ for oboomwald (user authentication) | Zeek kerberos.log |
| 4 | 04:49:55 | SAMr user enumeration against DC | Zeek dce_rpc.log |
| 5 | 04:49:57 | DRSBind/DRSCrackNames against DC (AD replication queries) | Zeek dce_rpc.log |
| 6 | 04:50:10 | SMB IPC$ access to DC via port 139 | Suricata + Zeek smb_mapping.log |
| 7 | 04:50:27 | LDAP queries for user Oliver Q.. Boomwald | Zeek ldap_search.log |
| 8 | 04:50:46 | NetSupport GeoLocation Lookup (geo.netsupportsoftware.com) | Suricata (Priority 1) + Zeek http.log |
| 9 | 04:50:46–05:38 | Continuous C2 beaconing every ~60 seconds | Suricata + Zeek http.log |
| 10 | 05:38–05:40 | C2 connection drops and re-establishes on port 53500 | Zeek conn.log + Suricata |
| 11 | 05:40:29 | C2 beaconing resumes on new connection | Suricata |
| 12 | 05:44 | Capture ends | conn.log |

### 3. Threat Assessment

| Question | Expected Answer |
|----------|----------------|
| Nature of threat | NetSupport Manager RAT — legitimate RMM tool abused as a RAT |
| Compromised host(s) | DESKTOP-B8TQK49 (10.11.26.183) only |
| C2 infrastructure | 194.180.191.64:443, HTTP on TLS port |
| Lateral movement | No evidence — SMB/IPC$ activity to DC is standard domain operations (group policy, LDAP, Kerberos), not C2-related |
| Data exfiltration | Not conclusively visible — POST bodies are small (22–250 bytes), likely C2 protocol overhead not bulk data theft |
| Beaconing interval | ~60 seconds |

**Key differentiation from easy123.pcap:** Different C2 IP (194.180.191.64 vs 45.131.214.85), additional GeoLocation alert (SID 2034559, Priority 1), connection drop/reconnect behaviour, different network environment (nemotodes.health vs easyas123.tech).

**Strong students** will note: the SMB IPC$ access via port 139 (not 445) with NTLM auth is unusual but appears to be legitimate domain operations (repeating every ~30 seconds for 5 iterations, consistent with a scheduled task or group policy check, not manual lateral movement). The samr and lsarpc operations in dce_rpc.log are user enumeration — this COULD be the RAT performing reconnaissance, but could also be normal domain logon activity. The DRSBind/DRSCrackNames operations are AD replication queries — notable if unexpected from a workstation.

### 4. IOC List

| Type | Value |
|------|-------|
| IP | 194.180.191.64 (C2) |
| Port | 443 (HTTP, not TLS) |
| User Agent | NetSupport Manager/1.3 |
| URI | /fakeurl.htm |
| Domain | geo.netsupportsoftware.com (geolocation) |
| URI | /location/loca.asp |
| Hostname (victim) | DESKTOP-B8TQK49 |
| User (victim) | oboomwald |
| Suricata SIDs | 2035892, 2035895, 2013926, 2034559 |

### 5. Tool Comparison

**Suricata:** Immediately identified the threat by name (NetSupport Manager). The Priority 1 GeoLocation alert was the most actionable single finding. Suricata also flagged the HTTP-on-443 anomaly. Without Suricata, identifying this as NetSupport Manager specifically would require manual research.

**Zeek:** Provided the network context Suricata couldn't: hostname (DESKTOP-B8TQK49), user (oboomwald), domain (nemotodes.health), and the full HTTP details (URI, user agent, response codes). Also revealed the AD enumeration activity (samr, DRSCrackNames) that Suricata had no rules for.

**Arkime:** Packet-level evidence — the actual HTTP POST/response bodies, the timing of the connection drop and re-establishment, ability to export the C2 traffic as a standalone PCAP for further analysis.

### 6. Recommendations

Expected at minimum:
1. Isolate DESKTOP-B8TQK49 from the network immediately
2. Block 194.180.191.64 at the perimeter firewall
3. Block geo.netsupportsoftware.com at DNS/proxy
4. Forensic investigation of DESKTOP-B8TQK49 (how was NetSupport installed? — answer not in this PCAP)
5. Verify whether oboomwald's credentials have been compromised (the samr/lsarpc activity is concerning)
6. Hunt across the environment for other NetSupport installations (check for the user agent or /fakeurl.htm URI)
7. Deploy detection rules for the IOCs to catch re-infection

---

## Assessment Rubric

### Excellent (90–100%)
- Correctly identified NetSupport Manager RAT, possibly by name
- Connected it to the easy123.pcap pattern from Lessons 6–7
- Complete timeline with 12+ events
- Cross-tool correlation using community ID
- Noted the GeoLocation lookup as significant
- Differentiated legitimate SMB/domain activity from malicious C2
- Professional report structure

### Good (70–89%)
- Identified a RAT/remote access tool on the infected host
- Correct C2 IP, port, and beaconing interval
- Timeline with 8–11 events
- Used all three tools but may not have used community ID explicitly
- IOC list mostly complete
- Some analysis of whether SMB activity is malicious or benign

### Adequate (50–69%)
- Identified the infected host and C2 destination
- Basic alert triage (recognised NetSupport alerts as malicious)
- Timeline with 5–7 events
- May have relied heavily on one tool
- Missing some IOCs or context (hostname, user)

### Below Expectations (<50%)
- Could not identify the compromised host or C2
- Listed alerts without analysis or triage
- No timeline or severely incomplete
- Used only one tool
- No cross-tool correlation

---

## Common Student Issues

- **"This looks just like easy123"** — Correct! But they need to prove it with evidence, not just assert it. The network is different, the C2 IP is different, and there are new findings (GeoLocation, port 139 SMB).

- **Time picker in Arkime** — The PCAP is from 2024-11-26. Students will forget to adjust the time range. This is expected by now but still catches people.

- **Mistaking legitimate domain activity for lateral movement** — The SMB IPC$ on port 139, samr enumeration, and DRSCrackNames look suspicious on the surface. Students need to distinguish this from the clearly malicious C2 traffic. If they flag it as "possible reconnaissance by the RAT," that's a reasonable assessment.

- **Missing the GeoLocation alert** — It only fires once and is buried among the repeating NetSupport check-in alerts. Students who only look at alert counts may miss that SID 2034559 is Priority 1 (the highest priority alert in this PCAP).

---

## Post-Lesson Discussion

1. **"You saw NetSupport Manager in Lesson 6. Did that help or bias your analysis?"** — Both. Pattern recognition accelerated identification, but they should have still proven it from the evidence rather than assuming.

2. **"What was different about this PCAP compared to easy123?"** — Different C2 IP, GeoLocation lookup present, SMB/domain activity more prominent, connection drop/reconnect, and AD enumeration queries (samr, DRSCrackNames) that weren't in easy123.

3. **"If this was a real incident, what's the most important thing you still don't know?"** — How NetSupport Manager was installed. The initial access vector isn't in this PCAP. That's the next investigation step.

4. **"Course reflection: which tool did you find most valuable? When would you use each?"** — Open-ended. Most students land on "Suricata for the first alert, Zeek for context, Arkime for evidence" which is exactly the workflow this course teaches.
