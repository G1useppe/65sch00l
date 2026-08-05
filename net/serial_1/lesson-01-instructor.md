# 65sch00l — Lesson 1: Instructor Guide

## Lesson Overview

**Duration:** 90 minutes (30 theory, 60 practical)

**Prerequisites:** Basic Linux CLI familiarity, understanding of TCP/IP (ports, protocols, IP addresses). Students should have a running st0ne_buntu VM.

**PCAP:** `lesson1.pcap` — a benign or low-complexity traffic sample. Ideally contains HTTP browsing, DNS lookups, and maybe some TLS — enough protocol diversity for students to see multiple log types, but no malware or attack activity. The goal is to learn Zeek and `jq`, not to investigate an incident.

**PCAP requirements:**
- 500–2000 connections (enough to make counting meaningful, not so many it's overwhelming)
- HTTP, DNS, and TLS at minimum
- Ideally from a small network (1–3 hosts) so students can map the environment
- No malware, no attack traffic — save that for Lesson 2

**Suggested sources for a simple PCAP:**
- Capture 10 minutes of your own browsing on the st0ne_buntu VM
- NETRESEC's publicly available PCAPs (https://www.netresec.com/?page=PcapFiles)
- Wireshark sample captures (https://wiki.wireshark.org/SampleCaptures)
- Generate with `curl` requests to a few websites while capturing with `tcpdump`

---

## Theory Notes

### CCTV analogy
The guard (Suricata) vs CCTV (Zeek) analogy works well. Emphasise that both are valuable — this isn't about one being better. The point is they do different things. Later lessons will show how they complement each other.

### Common student questions
- "Why would I use Zeek if it doesn't tell me what's bad?" — Because signatures miss novel threats, and Zeek's structured data enables hunting for things you don't have signatures for.
- "Isn't Wireshark better?" — Wireshark is for looking at individual packets. Zeek is for understanding thousands of connections at scale. You can't scroll through 50,000 packets in Wireshark.
- "What's the difference between JSON and TSV?" — Show both briefly. JSON is self-describing (field names included), TSV requires a header line. JSON is easier with `jq`, TSV is easier with `awk`/`cut`.

---

## Practical Notes

### Answer key

Answers depend on the PCAP selected. Before delivering this lesson, run the PCAP through Zeek and fill in the expected answers below.

**Q1.1:** _____ log files created (fill in)

**Q1.2:** Protocols present: _____ (fill in)

**Q2.1:** Key fields students should identify:
- `ts` — timestamp
- `id.orig_h` / `id.orig_p` — source IP and port
- `id.resp_h` / `id.resp_p` — destination IP and port
- `proto` — protocol (tcp/udp)
- `service` — detected application protocol
- `duration` — connection length
- `orig_bytes` / `resp_bytes` — data volume
- `conn_state` — connection state
- `community_id` — correlation hash

**Q2.2–Q4.2:** Fill in from PCAP analysis.

**Q4.2 — Connection states reference:**
- `SF` — Normal established and terminated (SYN, data, FIN)
- `S0` — SYN sent, no reply (connection attempt, no response)
- `S1` — Connection established, not terminated (still open when capture ended)
- `REJ` — Connection rejected (RST from responder)
- `RSTO` — Connection reset by originator
- `RSTR` — Connection reset by responder
- `SH` — Originator sent SYN+data, responder sent FIN (partial)

**Q5.1–Q5.2:** Open-ended. Look for students correctly identifying the network structure and forming reasonable hypotheses.

---

## Common Issues

- **`jq` syntax errors with dotted field names:** Zeek's field names contain dots (`id.orig_h`), which conflicts with `jq`'s dot accessor. Always use `.["id.orig_h"]` not `.id.orig_h`. Expect to repeat this several times.

- **Students overwhelmed by output:** Direct them to pipe through `head -5` first, then expand.

- **"Everything looks normal":** That's correct for this lesson. Affirm this — recognising normal is the prerequisite for recognising abnormal. Lesson 2 introduces abnormal.

---

## Bridge to Lesson 2

End the lesson with: "You've now mapped a normal network using Zeek. In the next lesson, we'll analyse a PCAP where something has gone wrong. The skills you just learned — counting connections, reading DNS queries, finding top talkers — are exactly what you'll use to find the problem."

This sets up the demo.pcap Ursnif/Gozi analysis in Lesson 2 where the same techniques suddenly reveal malicious activity.
