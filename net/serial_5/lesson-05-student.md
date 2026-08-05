# 65sch00l — Lesson 5: Zeek + Arkime Integration

## Learning Objectives

By the end of this lesson you will be able to:

- Explain the complementary strengths of Zeek and Arkime in an investigation workflow
- Use community ID to correlate a Zeek log entry with an Arkime session
- Execute a structured investigation workflow: broad search in Zeek, deep dive in Arkime
- Reconstruct a multi-stage attack using evidence from both tools
- Produce an investigation report with evidence references from each tool

---

## Theory

### Why use both tools?

You've now used Zeek and Arkime separately on the same traffic. You've seen that each reveals things the other doesn't. The real power comes from using them together in a structured workflow.

| Investigation phase | Best tool | Why |
|---|---|---|
| Initial triage — "what happened?" | Zeek | Structured logs, fast `jq` queries, immediate overview |
| Identify IOCs — IPs, domains, agents | Zeek | Purpose-built fields in dns.log, http.log, ssl.log |
| Deep inspection — "show me the bytes" | Arkime | Full packet access, payload viewing, file extraction |
| Visual mapping — "who talked to whom?" | Arkime | Connections graph, SPI view |
| Evidence preservation — "prove it" | Arkime | PCAP export, session tagging |
| Anomaly detection — protocol violations | Zeek | weird.log, automated protocol analysis |
| Lateral movement — SMB/RPC detail | Both | Zeek logs the operations; Arkime shows the file content |

### The workflow pattern

The most efficient investigation pattern is:

1. **Zeek first** — broad, fast, structured. Answer: "What are the interesting connections? What domains? What files? What looks abnormal?"
2. **Identify targets** — from Zeek output, select the specific connections or events you need to examine deeper
3. **Arkime second** — narrow, deep, packet-level. Answer: "What exactly was in that HTTP response? Can I extract the file? What does the payload look like?"
4. **Back to Zeek** — use findings from Arkime to inform new Zeek queries. "Now that I know this IP is C2, what else connected to it?"

### Community ID — the bridge

Community ID is a standardised hash computed from the connection 5-tuple (source IP, dest IP, source port, dest port, protocol). Both Zeek and Arkime compute it. The same connection produces the same hash in both tools.

This means you can:
- Find a suspicious entry in Zeek's conn.log
- Copy its `community_id` value
- Search for that exact value in Arkime
- Land directly on the right session with full packet access

No manual matching of IPs and ports. No time range guessing. One hash, one connection, both tools.

---

## Practical

This lesson uses the same demo.pcap data from Lessons 2–4. Both Zeek logs and Arkime sessions should already be available.

### Setup

Regenerate the Zeek logs if needed:

```bash
mkdir -p /tmp/lesson5 && cd /tmp/lesson5
/opt/zeek/bin/zeek -r ~/st0ne_buntu/samples/demo.pcap LogAscii::use_json=T policy/protocols/conn/community-id-logging
```

Open Arkime in Firefox:

```
http://localhost:8005
```

Adjust the time picker to cover 2020-05-08.

---

### Exercise 1: Community ID correlation — the basics

Start in Zeek. Find the HTTP request to `myexternalip.com`:

```bash
cat http.log | jq -r 'select(.host == "myexternalip.com") | [.ts, .uid, .["id.orig_h"], .["id.resp_h"], .["id.resp_p"], .uri, .community_id] | @tsv'
```

**Q1.1:** What is the community ID for this connection?

Now take that community ID and search for it in Arkime:

```
communityId == "<paste the value here>"
```

**Q1.2:** Does Arkime find the matching session? Expand it — what additional information does Arkime show that Zeek's http.log didn't?

**Q1.3:** Can you see the response body in Arkime? What is the external IP address returned by myexternalip.com?

---

### Exercise 2: Community ID correlation — following the C2

In Zeek, find the first HTTP POST to the C2 server:

```bash
cat http.log | jq -r 'select(.host == "36.89.106.69" and .method == "POST") | [.ts, .uri, .community_id] | @tsv' | head -1
```

**Q2.1:** What is the community ID? What is the URI?

Look up this session in Arkime using the community ID. Expand the session.

**Q2.2:** In Arkime's packet view, can you see the POST body? Describe what the data looks like (plaintext, encoded, encrypted?).

Now find the Zeek conn.log entry for the same connection using the community ID:

```bash
cat conn.log | jq 'select(.community_id == "<paste>") | [.ts, .duration, .orig_bytes, .resp_bytes, .conn_state] | @tsv' -r
```

**Q2.3:** How long did this connection last? How many bytes were sent vs received? What does the send/receive ratio suggest about the purpose of this connection?

---

### Exercise 3: Tracing a file download — Zeek to Arkime

In Zeek, find the executable file downloads:

```bash
cat files.log | jq -r 'select(.mime_type == "application/x-dosexec" and .source == "HTTP") | [.ts, .conn_uids, .seen_bytes, .filename] | @tsv'
```

The `conn_uids` field links the file to its parent connection. Take one of these UIDs and find the connection:

```bash
cat conn.log | jq -r 'select(.uid == "<paste uid>") | [.ts, .["id.orig_h"], .["id.resp_h"], .community_id] | @tsv'
```

**Q3.1:** What is the community ID for the connection that carried this executable?

Search for it in Arkime:

```
communityId == "<paste>"
```

**Q3.2:** In Arkime, expand the session and view the payload. Can you confirm the file is a PE executable by looking at the response body? What are the first bytes?

**Q3.3:** Zeek told you the file was `application/x-dosexec` with a specific byte count. Arkime shows you the actual content. Which piece of evidence is more useful in an incident report — the MIME type classification or the raw bytes? Why might you need both?

---

### Exercise 4: Investigating lateral movement — both tools

Start in Zeek. Find the DCE/RPC service creation:

```bash
cat dce_rpc.log | jq -r 'select(.operation == "CreateServiceW") | [.ts, .uid, .["id.orig_h"], .["id.resp_h"]] | @tsv'
```

Find the connection details:

```bash
cat conn.log | jq -r 'select(.uid == "<paste uid>") | [.ts, .["id.orig_h"], .["id.resp_h"], .["id.resp_p"], .community_id, .duration, .orig_bytes, .resp_bytes] | @tsv'
```

**Q4.1:** What is the community ID for the SMB session containing the service creation?

Now search Arkime:

```
communityId == "<paste>"
```

**Q4.2:** In Arkime's session detail, can you see the SMB commands within the packet view? How does the level of detail compare to Zeek's dce_rpc.log?

Now go back to Zeek and find what happened right *before* the service creation. Look at the SMB file operations in the same time window:

```bash
cat smb_files.log | jq -r 'select(.name | test("\\.exe")) | [.ts, .name, .action] | @tsv'
```

**Q4.3:** What is the sequence of events? First the file was _____, then the service was _____, then the service was _____. Fill in the blanks using evidence from both Zeek and Arkime.

---

### Exercise 5: The DC is compromised — proving infection spread

This is the critical analytical question: did the compromise spread from the workstation to the DC?

In Zeek, find HTTP requests originating from the DC:

```bash
cat http.log | jq -r 'select(.["id.orig_h"] == "10.0.0.10") | [.ts, .host, .uri, .user_agent] | @tsv'
```

**Q5.1:** What HTTP requests did the DC make? Do any of them match patterns you've seen from the infected workstation?

Find the community IDs for the DC's suspicious connections:

```bash
cat conn.log | jq -r 'select(.["id.orig_h"] == "10.0.0.10" and .["id.resp_h"] != "10.0.0.128" and .["id.resp_p"] != 53) | [.ts, .["id.resp_h"], .["id.resp_p"], .community_id] | @tsv' | head -10
```

Pick one and look it up in Arkime.

**Q5.2:** What does Arkime show for the DC's outbound connections? Is the content similar to what the workstation was sending?

In Arkime, use the connections graph. Set source to "Src IP" and look at both 10.0.0.128 and 10.0.0.10.

**Q5.3:** Which external IPs are contacted by BOTH the workstation and the DC? What does this prove?

---

### Exercise 6: Full reconstruction — the combined timeline

Using both Zeek and Arkime, build a complete timeline of the incident. For each event, record:

- **Timestamp**
- **What happened** (one sentence)
- **Source tool** (Zeek, Arkime, or both)
- **Key evidence** (the community ID, log entry, or session detail that supports it)

Your timeline should cover:

**Q6.1:** Write at least 12 events covering:
- Initial C2 contact
- IP discovery/profiling
- Payload download
- Lateral movement to the DC (file drop, service creation, execution)
- DC begins its own C2 communication
- Second round of activity

**Q6.2:** For three of these events, write a brief evidence paragraph that references both a Zeek log entry and an Arkime session, linked by community ID.

---

### Exercise 7: Workflow reflection

**Q7.1:** At which points in your investigation did you switch from Zeek to Arkime? What triggered the switch each time?

**Q7.2:** Were there moments where Arkime sent you *back* to Zeek? Describe one.

**Q7.3:** If you had to write a standard operating procedure for "how to investigate a suspicious connection," what would the steps be? Write 5–7 steps using both tools.

---

### Extension: Fast Finishers

Apply the integrated workflow to `easy123.pcap`.

Generate Zeek logs:

```bash
mkdir -p /tmp/lesson5-ext && cd /tmp/lesson5-ext
/opt/zeek/bin/zeek -r ~/st0ne_buntu/samples/easy123.pcap LogAscii::use_json=T policy/protocols/conn/community-id-logging
```

Arkime import (if not done in Lessons 3–4):

```bash
sudo /opt/arkime/bin/capture --copy -r ~/st0ne_buntu/samples/easy123.pcap -c /opt/arkime/etc/config.ini
```

**E1:** Using the integrated workflow (Zeek first → Arkime deep dive), investigate the easy123.pcap. Identify the infected host, the C2 infrastructure, and the attack chain.

**E2:** Find at least three connections and correlate them across both tools using community ID.

**E3:** Write a one-page incident summary with IOCs, referencing evidence from both Zeek and Arkime.

---

### Cleanup

```bash
cd ~ && rm -rf /tmp/lesson5 /tmp/lesson5-ext
```

Arkime sessions remain for reference.

---

## Key Takeaways

- Zeek for speed and structure, Arkime for depth and evidence — use both
- Community ID is the bridge: one hash links the same connection across both tools
- The optimal workflow is: Zeek (find) → Arkime (examine) → Zeek (expand) → Arkime (prove)
- Effective investigation reports reference evidence from both tools
- The combination answers questions neither tool can answer alone
