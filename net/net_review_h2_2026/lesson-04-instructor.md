# 65sch00l — Lesson 4: Instructor Guide

## Lesson Overview

**Duration:** 120 minutes (15 theory, 105 practical)

**Prerequisites:** Lessons 1–3 complete. Students should be comfortable navigating Arkime's viewer and performing basic searches.

**PCAP:** `demo.pcap` (already imported from Lesson 3). `easy123.pcap` available for fast finishers.

**Key shift:** This lesson moves from "navigating the tool" to "using the tool to investigate." Students should be making analytical decisions, not just following instructions. The exercises are more open-ended than Lesson 3.

---

## Practical Answer Key

### Exercise 1: Advanced searching

**Q1.1:** Sessions with "JACKSON" in the URI — approximately 20+. Campaign strings visible: `chil13`, `jim721`. Students may also find `lib721` (the DC's campaign string) if they search more broadly with `*PC*` or `*DC*`.

**Q1.2:** "WinHTTP loader" connects to `23.95.227.159` (port 80) and `checkip.amazonaws.com`. Downloads files disguised as images (`imgpaper.png`, `cursor.png`) and performs IP lookups.

**Q1.3:** Sessions over 300KB — primarily the downloads from `23.95.227.159` (the ~341,504 byte PE executables). Students should note the repeated identical size — multiple downloads of the same payload.

**Q1.4:** TLS sessions without SNI — these connect to IPs like `5.182.211.215` and `144.91.76.208`. Missing SNI means the client connected directly to an IP without specifying a hostname in the TLS handshake. Legitimate browsers almost always send SNI. This pattern is typical of malware C2 using TLS for encryption without proper domain infrastructure.

---

### Exercise 2: Pivoting from an IOC

**Q2.1:** Multiple sessions to 36.89.106.69, spanning the full capture duration. The C2 check-ins occur periodically.

**Q2.2:** Both `10.0.0.128` AND `10.0.0.10` connect to C2 infrastructure. The DC's connections appear later in the timeline, confirming the infection spread from the workstation to the DC. If students only see 10.0.0.128 at first, prompt them to check 203.176.135.102 — the DC communicates with this secondary C2 server.

**Q2.3:** External destinations for 10.0.0.128:

| IP | Category |
|---|---|
| 36.89.106.69 | C2 (primary HTTP) |
| 203.176.135.102 | C2 / exfiltration |
| 23.95.227.159 | Payload delivery |
| 5.182.211.215 | C2 (TLS) |
| 144.91.76.208 | C2 (TLS) |
| 172.245.159.191 | Dead C2 (connection failed) |
| 104.168.125.105 | Dead C2 (connection failed) |
| 158.69.133.69 | Dead C2 (connection failed) |
| 216.239.32.21 | IP lookup (myexternalip.com) |
| Various | Other IP lookup services |

---

### Exercise 3: Connections graph

**Q3.1:** The graph should show 10.0.0.128 as the most-connected node, with lines to 10.0.0.10 (internal) and multiple external IPs. The DC (10.0.0.10) should also have lines to some external IPs (the ones it contacted after being compromised).

Key observation: external IPs connected to BOTH internal hosts indicate the infection spread. If students don't spot this, ask: "Are there any external IPs that both internal hosts talk to?"

**Q3.2:** The filtered session list for 10.0.0.128 ↔ 36.89.106.69 shows the HTTP C2 check-ins. Students should confirm these match the Zeek http.log findings — same URIs, same user agents, same patterns.

**Q3.3:** Port-level detail reveals: port 80 (HTTP C2), port 443 (TLS C2), port 8082 (secondary C2/exfil on 203.176.135.102), port 445 (SMB lateral movement — internal only). Port 8082 is notable — non-standard HTTP port suggests dedicated exfiltration infrastructure.

---

### Exercise 4: Session timing — detecting beaconing

**Q4.1:** C2 check-ins to 36.89.106.69 occur approximately every 2–5 minutes. The timing isn't perfectly regular (some jitter), which is common in modern malware to avoid simple periodicity detection.

**Q4.2:** Traffic to 203.176.135.102 on port 8082. The timing correlates with the C2 check-ins — suggesting data is exfiltrated shortly after each C2 poll.

**Q4.3:** 36.89.106.69 appears to be the primary C2 (regular check-ins, command polling). 203.176.135.102:8082 appears to be the exfiltration channel (larger POST bodies, less frequent, triggered by C2 commands).

**Instructor note:** Beaconing detection is an important concept for live analysis. In this PCAP the intervals aren't perfectly regular, which is realistic — most modern C2 frameworks add jitter (random delay) to avoid detection. Ask students: "If you were writing malware, would you beacon at exactly the same interval every time? Why not?"

---

### Exercise 5: Examining payloads

**Q5.1:** The response body for downloads from 23.95.227.159 starts with `MZ` followed by `PE` — confirming these are Windows PE executables despite the `.png` filenames. Students should be able to see this in the hex or ASCII payload view.

**Q5.2:** POST request bodies to 36.89.106.69 contain encoded/encrypted data. Students won't be able to read it in plaintext — Ursnif encrypts its C2 communications. The key observation is that data IS being sent (the body isn't empty), and it's not human-readable.

**Q5.3:** SMB sessions show the file write operations at the packet level. Compared to Zeek's smb_files.log (which just logged the filename and action), Arkime shows the actual file content being transferred in the SMB Write Request packets. This is where you could theoretically carve out the malware binary.

---

### Exercise 6: Tagging sessions

**Q6.1:** Tags help in team investigations by:
- Marking sessions that have been reviewed (prevents duplicate work)
- Categorising by attack phase (initial access, C2, lateral movement, exfiltration)
- Creating named sets that can be filtered and exported together
- Providing an audit trail of the investigation

**Instructor note:** Demonstrate how tags appear as filterable fields. In a real SOC with multiple analysts working the same incident, tagging prevents two people from analysing the same sessions independently.

---

### Exercise 7: PCAP export

**Q7.1:** The exported PCAP should be much smaller than the original — only the sessions matching the filter are included. This is typically a few hundred KB vs the 42 MB original.

**Q7.2:** PCAP export is useful for:
- Sharing evidence with other analysts without exposing unrelated network traffic
- Sending samples to a sandbox or malware analyst
- Preserving evidence for legal proceedings
- Feeding into other tools (Wireshark for manual analysis, CyberChef for decoding)

---

### Exercise 8: Building the case

Look for students to demonstrate:
- Clear identification of the attack sequence (not just listing IOCs)
- Specific evidence references ("in session X at time Y, we observed Z")
- Understanding of what Arkime uniquely contributed (payload content, visual graph, file extraction)
- Complete IOC list organised by category

Weak answers just list IPs and domains. Strong answers describe the attack narrative with evidence.

---

### Extension: Fast Finishers

`easy123.pcap` contains a NetSupport Manager RAT infection. Key differences from demo.pcap:
- Different malware family and C2 pattern
- C2 over TCP 443 to 45.131.214.85
- Different delivery mechanism
- No lateral movement (simpler infection)

Run the PCAP through Arkime yourself before the lesson and note:
- The infected host's IP and hostname
- The C2 destination and port
- Any file downloads
- The timeline of events

Students should be able to conduct this investigation independently using the skills from Lessons 3–4 without guidance.

---

## Discussion Points

1. **"What would you do differently now vs Lesson 3?"** — Students should articulate a hunting strategy rather than clicking randomly. Good answer: "Start with the most-connected external IP, examine those sessions, pivot to related hosts."

2. **"How would you detect beaconing in live traffic?"** — This sets up the transition to Suricata and live monitoring. Regular automated connections are detectable by both timing analysis (Arkime) and signatures (Suricata).

3. **"What evidence would you need for an incident report?"** — Push students beyond IOC lists toward evidence packages: exported PCAPs, tagged sessions, timeline documentation. This connects to their DFIR background.

---

## Bridge to Lesson 5

"You've now used Zeek and Arkime separately on the same PCAP. You found the same attack from both angles, but each tool showed different things. In the next lesson, we'll combine them — using community ID to correlate a Zeek log entry with an Arkime session, building a workflow that starts with Zeek's speed and finishes with Arkime's depth."
