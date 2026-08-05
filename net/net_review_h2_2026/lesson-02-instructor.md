# 65sch00l — Lesson 2: Instructor Guide

## Lesson Overview

**Duration:** 120 minutes (30 theory, 90 practical)

**Prerequisites:** Lesson 1 complete. Students should be comfortable with `jq` basics, conn.log, and dns.log.

**PCAP:** `demo.pcap` — Ursnif/Gozi banking trojan infection from 2020-05-08. This PCAP contains a complete infection chain: initial C2 contact, payload delivery, IP discovery, credential theft, and lateral movement from a workstation (JACKSON-PC, 10.0.0.128) to the domain controller (Globalnets-DC, 10.0.0.10).

**This is the PCAP used for Lessons 2–5.** Students are not told the malware family. They discover the attack through analysis.

---

## Network Environment

| Host | IP | Role |
|------|-----|------|
| JACKSON-PC | 10.0.0.128 | Workstation (infected) |
| Globalnets-DC | 10.0.0.10 | Domain controller / DNS server |
| Domain | globalnets.org | Internal AD domain |

## Attack Summary (for instructor reference only)

1. JACKSON-PC is already infected with Ursnif/Gozi
2. Malware performs IP discovery (myexternalip.com, ident.me, etc.)
3. C2 check-ins to 36.89.106.69 (HTTP POST with hostname in URI)
4. C2 data exfiltration to 203.176.135.102:8082
5. Payload download from 23.95.227.159 (PE executables disguised as .png)
6. Attempted .onion resolution (Tor C2 fallback)
7. Credential theft and lateral movement via SMB to domain controller
8. Remote service creation on DC (malware execution)
9. DC itself begins C2 communication and IP discovery
10. Second round of lateral movement (repeated pattern)

---

## Practical Answer Key

### Exercise 1: Orientation

**Q1.1:** Two internal hosts:
- `10.0.0.128` — JACKSON-PC, a workstation (hostname visible in DNS queries for `jackson-pc.globalnets.org`)
- `10.0.0.10` — Globalnets-DC, the domain controller and DNS server (visible in LDAP SRV records, Kerberos service, and as the target of all DNS queries)

**Q1.2:** Internal domain: `globalnets.org`

---

### Exercise 2: DNS

**Q2.1:** External domains:
- `myexternalip.com` — **Suspicious.** IP lookup service. Malware uses these for host profiling.
- `ident.me` — **Suspicious.** Another IP lookup service. Multiple IP checkers is a strong indicator.
- `icanhazip.com` — **Suspicious.** Yet another IP lookup.
- `checkip.amazonaws.com` — **Suspicious.** And another. Four IP lookup services is extremely abnormal.
- `ip.anysrc.net` — **Suspicious.** Fifth IP lookup service.
- `5efxqhk2zhgnc24l.onion` — **Highly suspicious.** Tor hidden service address. Cannot resolve via standard DNS. Strong malware indicator.

**Instructor note:** The clustering of five distinct IP lookup services is itself a signature-level indicator. Legitimate software uses one at most. Malware queries several as redundancy. Ask students: "If you were writing software that needed to know its public IP, how many services would you query?"

**Q2.2:** NXDOMAIN responses:
- `5efxqhk2zhgnc24l.onion` — Cannot resolve .onion via DNS. This is Ursnif attempting to reach its Tor-based C2. **This is the most significant finding.**
- `wpad.globalnets.org` and `wpad.localdomain` — Normal; WPAD auto-discovery probes.

**Q2.3:** Filtering out infrastructure, the external domains are almost exclusively IP lookup services plus the .onion address. The pattern: the infected host is performing reconnaissance on its own external identity.

---

### Exercise 3: HTTP

**Q3.1:** HTTP hosts and URIs:

| Host | URI pattern | Notes |
|------|-------------|-------|
| `36.89.106.69` | `/chil13/JACKSON-PC_W617601.../81/` and `/83/` | C2 check-in with hostname in path |
| `36.89.106.69` | `/jim721/JACKSON-PC_W617601.../81/` | Second C2 campaign string |
| `36.89.106.69` | `/lib721/GLOBALNETS-DC_W617601.../81/` | DC also doing C2 (infection spread) |
| `203.176.135.102:8082` | `/chil13/.../90` and `/jim721/.../90` | Data exfiltration |
| `23.95.227.159` | `/ico/VidT6cErs` | Initial payload download |
| `23.95.227.159` | `/images/imgpaper.png`, `/images/cursor.png` | PE executables disguised as images |
| `myexternalip.com` | `/raw` | IP lookup |
| `checkip.amazonaws.com` | `/` | IP lookup |
| `icanhazip.com` | `/` | IP lookup |
| `ip.anysrc.net` | `/plain` | IP lookup |

**Q3.2:** Requests to raw IPs (36.89.106.69, 203.176.135.102, 23.95.227.159) — no hostname. Legitimate web traffic almost always uses domain names. Direct-to-IP HTTP requests are a common malware behaviour to avoid DNS-based blocking.

**Q3.3:** User agents:
- `Mozilla/4.0 (compatible; MSIE 7.0; ...)` — Spoofed legacy IE7 agent. No modern system runs IE7. This is Ursnif's hardcoded C2 user agent.
- `WinHTTP loader/1.0` — A loader/dropper component. Not a browser.
- `Winhttp 1/0` — Another variant of the loader.
- `curl/7.69.1` and `curl/7.69.0` — Command-line curl. Unusual on a corporate Windows machine unless explicitly installed.
- No user agent (null) — Several requests with no user agent at all.

**Instructor note:** The MSIE 7.0 user agent is a giveaway — ask students "When was IE7 last current?" (2006–2009). A 2020 connection using IE7's user agent is almost certainly spoofed.

**Q3.4:** POST requests go to `36.89.106.69` and `203.176.135.102:8082`. The body sizes range from ~200 to ~4800 bytes. The larger POST bodies (to port 8082) are likely stolen data being exfiltrated.

**Q3.5:** The URI path encodes: campaign ID (`chil13` or `jim721`), hostname + OS version + a hash (`JACKSON-PC_W617601.2290578EEF...`), and a command ID (`81`, `83`, `90`). This is the Ursnif URI structure — each path component identifies the infected machine to the C2 server.

---

### Exercise 4: File transfers

**Q4.1:** File types: `text/plain`, `text/json`, and `application/x-dosexec` (Windows PE executables).

**Q4.2:** Multiple executables transferred:
- Over HTTP from `23.95.227.159`: files named `imgpaper.png` and `cursor.png` but with MIME type `application/x-dosexec` and size 341,504 bytes. Downloaded multiple times. **These are PE executables disguised as image files.**
- Over SMB to `10.0.0.10` (the DC): randomly-named `.exe` files written to `\WINDOWS\` directory.

**Q4.3:** SMB executable filenames:
- `\WINDOWS\n3xpsu57gqbi7cracoczzznkl_r031vvuqhmx6i9l0qbsefkqqwhdepnvik2z1b2.exe`
- `\WINDOWS\4d9i7_qcwgmlkuly41qbit0ec0m1apncp5pw7bi7qeuq__3nr7hak4ynok8n13k1.exe`
- `\WINDOWS\kdusskpxu_hmv9xstfo_qa6bpmmqe1crntnsd1xqfinag3h50imnzvfm7a9xz4dg.exe`
- `\WINDOWS\eyjvj7qzil4m4uh1jg2pomt9jsisa7nu2u2kgjqosr9_g6eikh3qjx2cj6gcrn5o.exe`

The naming pattern is long random alphanumeric strings. No legitimate software names files this way. This is malware being deployed to the DC.

---

### Exercise 5: SMB lateral movement

**Q5.1:** Shares accessed:
- `\\10.0.0.10\IPC$` — Named pipe access (used for remote administration)
- `\\10.0.0.10\C$` — **Administrative share — direct access to the C: drive of the DC. This is not normal user activity.**
- `\\Globalnets-DC.globalnets.org\IPC$` — Same DC via hostname
- `\\Globalnets-DC\Shared` — A regular file share (likely legitimate)

The `C$` access is the critical finding. Only administrators can access the C$ share remotely, and it's almost exclusively used by management tools or attackers.

**Q5.2:** Files opened:
- `samr` — Security Account Manager pipe (user enumeration)
- `lsarpc` — Local Security Authority pipe (privilege/policy queries)
- `netlogon` — Domain authentication pipe
- `\svcctl` — Service Control Manager pipe (remote service management)
- Random `.exe` files written to `\WINDOWS\` — the malware payloads

The named pipes `samr`, `lsarpc`, `netlogon`, and `svcctl` in combination are a textbook lateral movement pattern: enumerate accounts, query privileges, authenticate, create and start a remote service.

**Q5.3:** The `svcctl` sequence: `OpenSCManagerW → CreateServiceW → StartServiceW → DeleteService` is remote code execution via service creation. The attacker opened the Service Control Manager on the DC, created a new service pointing to the dropped .exe, started it (executing the malware), then deleted the service to cover tracks.

**This happens twice** — once around timestamp 1588971349 and again around 1588971914.

---

### Exercise 6: Authentication

**Q6.1:** NTLM authentication: user `craig.jackson` from `10.0.0.128` to `10.0.0.10` (Globalnets-DC), domain `GLOBALNETS`. All attempts succeeded. This is the compromised user whose credentials the malware is using for lateral movement.

**Q6.2:** Kerberos: machine account `JACKSON-PC$/GLOBALNETS.ORG` requesting TGS tickets for LDAP services. This is normal domain-joined machine behaviour, but it provides context — JACKSON-PC is authenticated to the domain.

---

### Exercise 7: TLS connections

**Q7.1:** TLS connections from both `10.0.0.128` and `10.0.0.10` to external IPs including `5.182.211.215` and `144.91.76.208`. These are C2 channels over encrypted connections.

**Q7.2:** TLS connections with no SNI suggest the client is connecting directly to an IP without specifying a hostname — another indicator of malware C2 (legitimate browsers almost always send SNI).

---

### Exercise 8: Timeline

Expected timeline (students should capture the major beats):

| Time (approx) | Event | Evidence |
|---|---|---|
| 20:46–20:55 | Failed connection attempts to 172.245.159.191, 104.168.125.105, 158.69.133.69 on port 443 | conn.log — S0 states (SYN, no reply). Likely dead C2 servers. |
| 20:52 | DNS lookup for ident.me | dns.log — IP discovery begins |
| 20:54 | DNS lookup for globalnets-dc.globalnets.org; LDAP SRV queries | dns.log — Domain discovery |
| 20:55 | DNS query for 5efxqhk2zhgnc24l.onion (NXDOMAIN) | dns.log — Tor C2 attempt fails |
| 20:56 | IP lookup via myexternalip.com | http.log, dns.log — Host profiling |
| 20:57 | First C2 POST to 36.89.106.69 (/chil13/) | http.log — C2 check-in |
| 20:57 | Payload download from 23.95.227.159 (imgpaper.png, cursor.png = PE) | http.log, files.log |
| 20:58 | SMB access to DC C$ share, random .exe files written | smb_files.log, smb_mapping.log |
| 20:58 | Remote service creation on DC (svcctl CreateServiceW → StartServiceW) | dce_rpc.log |
| 20:59 | NTLM auth as craig.jackson to DC | ntlm.log |
| 21:01 | DC begins C2 communication (POST to 203.176.135.102:8082 from 10.0.0.10) | http.log — DC is now compromised |
| 21:01 | DC performs IP lookups (checkip.amazonaws.com, icanhazip.com) | http.log, dns.log |
| 21:04–21:08 | Second round of lateral movement, new campaign string (jim721) | http.log, smb_files.log, dce_rpc.log |

**Q8.2:** JACKSON-PC (10.0.0.128) was compromised first.

**Q8.3:** Yes — the compromise spread to Globalnets-DC (10.0.0.10). Evidence:
- Executable files written via SMB to DC's C$ share
- Remote service created and started on DC
- DC subsequently performs its own C2 communication and IP lookups
- DC has its own campaign string in C2 URIs (`GLOBALNETS-DC_W617601...`)

---

### Exercise 9: IOC list

**Expected IOCs:**

**IP addresses:**
- 36.89.106.69 (C2)
- 203.176.135.102 (C2/exfiltration)
- 23.95.227.159 (payload delivery)
- 5.182.211.215 (TLS C2)
- 144.91.76.208 (TLS C2)
- 172.245.159.191, 104.168.125.105, 158.69.133.69 (dead C2)

**Domains:**
- 5efxqhk2zhgnc24l.onion

**User agents:**
- `Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; Win64; x64; Trident/7.0; ...)`
- `WinHTTP loader/1.0`
- `Winhttp 1/0`

**URI patterns:**
- `/chil13/<HOSTNAME>_<OSVER>.<HASH>/<CMD>/`
- `/jim721/<HOSTNAME>_<OSVER>.<HASH>/<CMD>/`
- `/lib721/<HOSTNAME>_<OSVER>.<HASH>/<CMD>/`
- `/ico/VidT6cErs`
- `/images/imgpaper.png`, `/images/cursor.png`

---

## Discussion Points

After students complete the practical:

1. **"How did you decide what was suspicious?"** — Reinforce the heuristics: requests to raw IPs, multiple IP lookup services, .onion DNS, spoofed user agents, executables disguised as images, C$ share access, remote service creation.

2. **"At what point would you have been confident this was malicious?"** — Most students will say the SMB lateral movement. Push back — the HTTP POST with hostname-in-URI and the IE7 user agent were detectable much earlier.

3. **"What couldn't Zeek tell you?"** — Zeek doesn't tell you the malware family, the initial infection vector (how did JACKSON-PC get infected?), or what the TLS C2 channels were carrying. These are gaps that other tools (Suricata, Arkime) can help fill in later lessons.

4. **"If you were an analyst seeing this in real time, what would your first response action be?"** — Isolate JACKSON-PC and the DC. The DC being compromised is a critical escalation.

---

## Preparation for Lesson 3

Students will now have a strong understanding of what happened from Zeek's perspective. Lesson 3 introduces Arkime, which gives them packet-level access to the same PCAP — they'll be able to see the actual payload content, reassemble HTTP streams, and extract the transferred files.
