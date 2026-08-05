# 65sch00l — Lesson 3: Instructor Guide

## Lesson Overview

**Duration:** 90 minutes (20 theory, 70 practical)

**Prerequisites:** Lessons 1–2 complete. Students should be familiar with the demo.pcap traffic from their Zeek analysis.

**PCAP:** `demo.pcap` (same as Lesson 2). Students already know the network layout and have identified suspicious activity. This lesson teaches them to use Arkime to see the same traffic at packet level.

**Setup required:** demo.pcap must be imported into Arkime before the lesson. Students do this in Exercise 1, but have a pre-imported backup in case of issues.

**Extension PCAP:** `easy123.pcap` should be available in `~/st0ne_buntu/samples/` for fast finishers.

---

## Theory Notes

### Key message
Arkime is not "better" than Zeek or a replacement for it. The two tools answer different questions. Push students to articulate *when* they would reach for each tool rather than defaulting to one.

### Common student confusion
- **"Why can't I see inside TLS?"** — Arkime stores the raw packets, but TLS encrypts the payload. Arkime can show you the handshake (SNI, certificate) but not the encrypted content. This is the same limitation as any packet analysis tool.
- **"The session count doesn't match Zeek's conn.log"** — Arkime and Zeek may count sessions slightly differently (timeout thresholds, how they handle retransmissions). Small differences are normal.
- **"Where are the alerts?"** — Arkime doesn't generate alerts. It indexes and presents. Suricata alerts come in Lesson 6.

---

## Practical Answer Key

### Exercise 1: Navigate the viewer

**Q1.1:** Arkime should show approximately 600–760 sessions (varies slightly from Zeek's ~759 connections). Differences come from how each tool handles connection timeouts and protocol boundaries.

**Q1.2:** Top 5 destination IPs by session count (approximate):
1. `10.0.0.10` — domain controller (DNS, SMB, Kerberos, LDAP)
2. `172.245.159.191` — failed TLS connection attempts
3. `36.89.106.69` — HTTP C2
4. `23.95.227.159` — payload delivery
5. `203.176.135.102` — data exfiltration

**Q1.3:** Protocols detected: TCP, UDP, HTTP, TLS, DNS, SMB, DCE/RPC, Kerberos, LDAP, NTP, QUIC

---

### Exercise 2: Basic searching

**Q2.1:** Approximately 500+ sessions from 10.0.0.128 (it's the primary infected host generating most traffic).

**Q2.2:** Sessions to 23.95.227.159 — port 80 (HTTP). These are the payload downloads (`imgpaper.png`, `cursor.png` which are actually PE executables). Students should notice multiple sessions to the same host.

**Q2.3:** Port 445 sessions — between 10.0.0.128 and 10.0.0.10. This is the SMB lateral movement traffic from Lesson 2.

**Q2.4:** HTTP sessions — should include connections to 36.89.106.69, 23.95.227.159, 203.176.135.102, myexternalip.com, checkip.amazonaws.com, etc.

**Q2.5:** Sessions from 10.0.0.128 to port 80 — the HTTP C2 and payload downloads.

**Q2.6:** Sessions from the workstation to non-DC hosts — this is all the external communication (C2, downloads, IP lookups). This represents the malicious outbound traffic.

---

### Exercise 3: Session detail

**Q3.1:** URIs to 23.95.227.159: `/ico/VidT6cErs`, `/images/imgpaper.png`, `/images/cursor.png`

**Q3.2:** Students should see the HTTP GET request and the response. The content type may say image/png, but the actual body starts with `MZ` (the PE executable magic bytes). **This is the key finding** — the server claims it's an image but delivers an executable.

**Instructor note:** If students don't notice the MZ header, point them to the first two bytes of the response body. Explain that `MZ` (0x4D5A) is the signature of a Windows PE executable. This is a classic delivery technique — disguising malware as images.

**Q3.3:** No — the content doesn't match the `.png` extension. Files named `imgpaper.png` and `cursor.png` are actually Windows executables.

**Q3.4:** The URI to 36.89.106.69 contains: `/chil13/JACKSON-PC_W617601.2290578EEF324A997DBD7A2BD20B9DC5/81/` — the hostname (JACKSON-PC), OS version, and a hash identifying the infected machine. This is the Ursnif C2 check-in structure.

**Q3.5:** User agent: `Mozilla/4.0 (compatible; MSIE 7.0; ...)` — matches exactly what Zeek showed. This confirms the cross-tool consistency.

---

### Exercise 4: SMB sessions

**Q4.1:** In the packet view, students should be able to see the SMB Create Request packets containing the randomly-named .exe filenames. These match what smb_files.log showed in Lesson 2.

**Q4.2:** Advantages of Arkime over Zeek for SMB:
- Can see the actual file content being transferred (the malware binary)
- Can see the exact SMB command sequence (negotiate, session setup, tree connect, create, write, close)
- Could potentially extract the transferred file from the packet stream
- Zeek's logs summarise; Arkime shows the raw interaction

---

### Exercise 5: TLS sessions

**Q5.1:** Some sessions have SNI values (like `myexternalip.com`), others have no SNI — direct-to-IP TLS connections, which are suspicious.

**Q5.2:** Certificate details vary by connection. Students should note any self-signed certificates or certificates with unusual CNs.

**Q5.3:** TLS encrypts the application data payload. Arkime (and any packet tool) can only see the unencrypted handshake. To see inside TLS you would need the server's private key or a TLS proxy — neither of which applies to offline PCAP analysis.

---

### Exercise 6: Connections view

**Q6.1:** The graph should show 10.0.0.128 as the central node with connections radiating out to multiple external IPs and to 10.0.0.10. The DC (10.0.0.10) also has some external connections (after it was compromised).

**Q6.2:** If 10.0.0.10 connects to the same external hosts as 10.0.0.128 (particularly 203.176.135.102 and the IP lookup services), this confirms the DC was compromised and is now performing its own C2 communication — the infection spread.

---

### Exercise 7: Compare with Zeek

**Q7.1:** Things Zeek showed that Arkime didn't make obvious:
- DNS query names are immediately searchable in dns.log; in Arkime you need to know to search for the right field
- The DCE/RPC operation names (CreateServiceW, StartServiceW) are explicitly logged by Zeek; in Arkime you'd have to decode them from the packet payload
- JA3 hashes are pre-computed in Zeek's ssl.log
- Zeek's weird.log flags protocol anomalies automatically

**Q7.2:** Things Arkime showed that Zeek couldn't:
- The actual MZ header in the "PNG" file downloads — proof they're executables
- The full HTTP response body content
- The visual connections graph
- The ability to export specific sessions as a new PCAP

**Q7.3:** Open-ended. Most analysts would start with Zeek for speed and structure, then pivot to Arkime for evidence. Accept either answer if well-reasoned.

---

### Extension: Fast Finishers

The easy123.pcap is a NetSupport Manager RAT infection. Students should find:
- An internal Windows host on a domain network
- HTTP/HTTPS traffic to external IPs associated with the RAT C2
- Different malware family than demo.pcap

Answers will depend on the PCAP content — run it through Arkime yourself before the lesson and note the key sessions.

---

## Common Issues

- **Arkime viewer not loading:** Check `systemctl status arkimeviewer`. If down: `sudo systemctl restart arkimeviewer`
- **No sessions visible after import:** Check the time range in the viewer — default may be "last hour" which won't include a 2020 PCAP. Adjust the time picker to "All" or the specific date range.
- **Students searching with wrong syntax:** Common mistakes: using `=` instead of `==`, forgetting quotes around strings, using Zeek field names instead of Arkime field names. Arkime uses `ip.src` not `id.orig_h`.

**Critical:** Make sure students adjust the time picker. The demo.pcap is from 2020-05-08. If the viewer defaults to "last 24 hours" they'll see nothing.

---

## Bridge to Lesson 4

"You now know how to navigate Arkime's viewer and inspect individual sessions. In the next lesson, you'll learn Arkime's advanced search capabilities — hunting across sessions, using the connections graph to pivot between hosts, extracting files from packet streams, and building a case using Arkime's tagging and export features."
