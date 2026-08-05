# 65sch00l — Lesson 5: Instructor Guide

## Lesson Overview

**Duration:** 120 minutes (15 theory, 105 practical)

**Prerequisites:** Lessons 2–4 complete. Students must be comfortable with both Zeek `jq` queries and Arkime viewer navigation.

**PCAP:** `demo.pcap` — same PCAP, now using both tools together. This is the payoff lesson for the Zeek+Arkime block.

**Key teaching point:** This lesson isn't about learning new tool features. It's about building an investigation *workflow* that uses the right tool at the right moment. Students should leave with a mental model of "when do I reach for Zeek vs Arkime?"

---

## Theory Notes

### The workflow matters more than the tools

Students have spent four lessons learning tool mechanics. This lesson shifts to investigative methodology. The community ID correlation is the technical enabler, but the real skill is knowing *when* to switch tools and *why*.

Common anti-pattern to watch for: students who default to one tool for everything. A student who does the entire investigation in Arkime is missing Zeek's speed for broad queries. A student who stays in Zeek is missing the packet-level evidence that makes findings provable.

### Community ID gotchas

- Zeek's field is `community_id` (underscore). Arkime's search field is `communityId` (camelCase). Students will trip on this.
- Community ID is based on the 5-tuple, so the same TCP connection has one community ID for its entire duration. But if Zeek or Arkime split a long connection into multiple log entries (timeout, etc.), they'll share the same community ID.
- UDP "connections" are identified by the same 5-tuple, so a DNS query and response share a community ID.

---

## Practical Answer Key

### Exercise 1: Community ID — the basics

**Q1.1:** The community ID for the myexternalip.com connection will be a string like `1:abc123...` (exact value depends on the Zeek version, but it's deterministic).

**Q1.2:** Arkime should find exactly one matching session. Additional information Arkime shows:
- The full HTTP response body (the actual external IP address)
- Packet timing details
- Full header content (not just the fields Zeek extracts)
- The ability to export the session as a PCAP

**Q1.3:** Yes — the response body contains the external IP address as plaintext. This is the IP that the malware is reporting back to its C2 as the victim's public address.

**Instructor note:** This is the first time students see the full round trip: Zeek told them "a request was made to myexternalip.com." Arkime shows them "and the answer was 203.x.x.x." The value of combining both tools should be immediately clear.

---

### Exercise 2: Community ID — following the C2

**Q2.1:** The first POST to 36.89.106.69 — URI contains the `/chil13/JACKSON-PC_W617601.../81/` pattern.

**Q2.2:** The POST body in Arkime's packet view shows binary/encoded data — not human-readable. This is Ursnif's encrypted C2 protocol. Students can't decode it, but they can observe that data IS being sent and it's not plaintext.

**Q2.3:** The connection is typically short-lived (a few seconds). Orig_bytes (sent) is small-to-medium; resp_bytes (received) varies. For a check-in request (command `81`), the pattern is: small request out, variable response back — the C2 server is issuing commands. For exfiltration (command `90`), the pattern reverses: larger request out, small acknowledgment back.

---

### Exercise 3: Tracing a file download

**Q3.1:** Students need to chain: files.log → conn_uids → conn.log → community_id. This multi-hop correlation is a key skill.

**Q3.2:** The response body starts with `MZ` (0x4D 0x5A), confirming it's a PE executable. Students saw this in Lesson 3 but now they've reached it through a structured workflow starting from Zeek, not by browsing Arkime randomly.

**Q3.3:** Both are valuable for different audiences:
- MIME type (from Zeek) is machine-parseable and useful for automated detection rules and statistics
- Raw bytes (from Arkime) are forensic evidence — provable, exportable, can be submitted to a sandbox
- An incident report needs both: "Zeek classified the file as application/x-dosexec. Arkime packet inspection confirms the PE header (MZ signature at offset 0)."

---

### Exercise 4: Investigating lateral movement

**Q4.1:** The community ID for the SMB session containing CreateServiceW.

**Q4.2:** Arkime shows the raw SMB protocol exchange at the byte level. Zeek's dce_rpc.log gave the operation name (CreateServiceW) as a clean field. Arkime shows the full request including the service binary path, which reveals WHERE the malware executable is located on the DC's filesystem.

**Q4.3:** The sequence:
1. First the file was **written to C$ via SMB** (random .exe to \WINDOWS\)
2. Then the service was **created** (CreateServiceW pointing to that .exe)
3. Then the service was **started** (StartServiceW — executing the malware)
4. Then the service was **deleted** (DeleteService — covering tracks)

Students should reference smb_files.log (file write), dce_rpc.log (service operations), and Arkime sessions for the packet-level evidence.

---

### Exercise 5: Proving infection spread

**Q5.1:** The DC makes HTTP requests to:
- 203.176.135.102:8082 — C2 exfiltration (same server the workstation used)
- IP lookup services (checkip.amazonaws.com, icanhazip.com)

These match the same patterns seen from the infected workstation. The URI structure contains `GLOBALNETS-DC` instead of `JACKSON-PC`, confirming the DC is now an independent infected node.

**Q5.2:** Arkime shows the DC's outbound connections have similar payload patterns to the workstation's — encoded POST bodies, same URI structure, same user agents.

**Q5.3:** Both hosts contact 203.176.135.102. The workstation also contacts 36.89.106.69 which the DC may also contact. This proves:
- The DC was compromised (it's making C2 calls)
- It's using the same C2 infrastructure
- The infection is a propagating threat, not just a single compromised host

---

### Exercise 6: Full reconstruction

The complete timeline should include at minimum:

| # | Time | Event | Source |
|---|---|---|---|
| 1 | 20:46 | Failed TLS connections to 172.245.159.191, 104.168.125.105, 158.69.133.69 (dead C2) | Zeek conn.log |
| 2 | 20:52 | DNS queries for IP lookup services (ident.me, myexternalip.com) | Zeek dns.log |
| 3 | 20:55 | DNS query for .onion address (NXDOMAIN) | Zeek dns.log |
| 4 | 20:56 | IP lookup via myexternalip.com — external IP retrieved | Zeek http.log + Arkime payload |
| 5 | 20:57 | First C2 POST to 36.89.106.69 (/chil13/) | Both — Zeek http.log for fields, Arkime for payload |
| 6 | 20:57 | PE executables downloaded from 23.95.227.159 disguised as .png | Both — Zeek files.log for classification, Arkime for MZ bytes |
| 7 | 20:58 | NTLM authentication as craig.jackson to DC | Zeek ntlm.log |
| 8 | 20:58 | SMB access to C$ share on DC | Zeek smb_mapping.log |
| 9 | 20:58 | Random .exe files written to DC's \WINDOWS\ | Zeek smb_files.log + Arkime for payload |
| 10 | 20:58 | Remote service created and started on DC | Zeek dce_rpc.log + Arkime for service binary path |
| 11 | 21:01 | DC begins C2 communication to 203.176.135.102:8082 | Both |
| 12 | 21:01 | DC performs IP lookups | Zeek http.log |
| 13 | 21:04 | Second round of lateral movement (jim721 campaign) | Both |

**Q6.2:** Evidence paragraphs should follow the pattern:
"At [timestamp], Zeek's [log] recorded [finding] (community ID: [hash]). Examining the same session in Arkime confirms [deeper finding visible in the payload]."

---

### Exercise 7: Workflow reflection

**Q7.1:** Expected switch points:
- "Zeek told me a PE was downloaded — I switched to Arkime to see the actual file content"
- "Zeek showed a POST request — I switched to Arkime to see the POST body"
- "Zeek showed SMB file operations — I switched to Arkime to see the bytes being written"

**Q7.2:** Arkime back to Zeek:
- "In Arkime I saw the DC making outbound connections — I went back to Zeek dns.log to check what domains the DC queried"
- "Arkime showed a connection to a new IP — I searched Zeek conn.log to see all connections to that IP"

**Q7.3:** Sample SOP:
1. Run PCAP through Zeek → scan conn.log for top talkers, unusual ports, failed connections
2. Check dns.log for suspicious domains, IP lookups, NXDOMAIN
3. Check http.log for C2 patterns (raw IPs, unusual agents, encoded URIs)
4. Identify IOCs from Zeek logs
5. Import PCAP into Arkime → search by IOC IPs
6. Inspect sessions — verify file types, examine payloads, check for lateral movement
7. Use community ID to link Zeek findings to Arkime evidence
8. Tag sessions, export relevant PCAPs, compile IOC list and timeline

---

## Discussion Points

1. **"Could you have done this investigation with only one tool?"** — Technically yes, but it would be slower and less complete. Zeek without Arkime means you can't prove what was in the payloads. Arkime without Zeek means you're clicking through sessions manually instead of querying structured data.

2. **"In live monitoring, how would this workflow change?"** — Sets up Lessons 6–8 (Suricata). In live monitoring, you'd add Suricata alerts as the initial trigger rather than starting from Zeek cold. The workflow becomes: Suricata alert → Zeek context → Arkime evidence.

3. **"What about encrypted traffic?"** — Neither tool can see inside TLS. But Zeek's JA3 and SNI analysis combined with Arkime's certificate inspection gives significant visibility even without decryption. This is a realistic limitation that students should understand.

---

## Bridge to Lesson 6

"You've now mastered the Zeek + Arkime workflow for investigating network traffic after the fact. But how do you know something is worth investigating in the first place? In the next lesson, we introduce Suricata — a signature-based detection engine that watches traffic and tells you when it sees something matching a known threat. Suricata is the alarm bell. Zeek and Arkime are what you use after the alarm goes off."
