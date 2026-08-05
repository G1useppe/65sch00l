# 65sch00l — Lesson 4: Arkime Advanced — Hunting and Extraction

## Learning Objectives

By the end of this lesson you will be able to:

- Construct complex Arkime queries using field names, operators, wildcards, and boolean logic
- Use the connections graph to pivot from an IOC to related sessions
- Extract files transferred within packet captures
- Identify beaconing behaviour using session timing analysis
- Tag and annotate sessions for collaborative investigation
- Export filtered sessions as a new PCAP for external tool analysis

---

## Theory

### Arkime's query language in depth

Arkime's search bar supports a rich query language. Beyond the basic `ip.src == 10.0.0.128` you used in Lesson 3, you can search on any extracted field:

**Exact match:**
```
http.uri == /ico/VidT6cErs
http.user-agent == "WinHTTP loader/1.0"
```

**Wildcards:**
```
http.uri == *chil13*
http.user-agent == *MSIE*
```

**Existence (field exists or doesn't):**
```
http.user-agent == EXISTS!
tls.ja3 == EXISTS!
```

**Numeric comparisons:**
```
databytes > 100000
port.dst >= 443
```

**Boolean logic:**
```
ip.src == 10.0.0.128 && port.dst == 80
ip.dst == 36.89.106.69 || ip.dst == 23.95.227.159
(protocols == http || protocols == tls) && ip.src == 10.0.0.128
```

**Negation:**
```
ip.src == 10.0.0.128 && ip.dst != 10.0.0.10
protocols != dns
```

### Hunting workflows

Hunting in Arkime follows a pivot pattern:

1. **Start with a known IOC** — an IP, domain, hash, or user agent
2. **Find sessions matching the IOC** — search for it
3. **Examine those sessions** — look at the packet content, timing, and metadata
4. **Pivot to related sessions** — what else did the same source IP do? What other hosts talked to the same destination?
5. **Expand the picture** — use the connections graph to visualise relationships

### Beaconing detection

Malware often "beacons" — connecting to its C2 server at regular intervals (every 30 seconds, every 5 minutes, etc.). In Arkime, you can spot this by sorting sessions to the same destination by time and looking for consistent intervals. Regular timing that a human wouldn't produce is a strong C2 indicator.

### File extraction

Arkime can extract files that were transferred within sessions. For HTTP, this means response bodies (downloaded files). This is critical for obtaining malware samples without needing to re-download them from potentially-dead infrastructure.

---

## Practical

This lesson uses the same demo.pcap data already imported in Lesson 3.

Open Arkime viewer:

```
http://localhost:8005
```

**Important:** Adjust the time range to cover the PCAP. Click the time picker and set it to include 2020-05-08, or select "All."

---

### Exercise 1: Advanced searching

Use the search bar to find specific activity.

Find all HTTP sessions where the URI contains a hostname:

```
http.uri == *JACKSON*
```

**Q1.1:** How many sessions match? What C2 campaign strings appear in the URIs?

Find sessions with a specific user agent:

```
http.user-agent == *WinHTTP*
```

**Q1.2:** What hosts does the "WinHTTP loader" user agent connect to? What does it download?

Search for sessions with large response payloads:

```
databytes > 300000 && protocols == http
```

**Q1.3:** Which sessions transferred more than 300,000 bytes of data? What were the destination IPs?

Find TLS sessions with no SNI:

```
protocols == tls && tls.serverName != EXISTS!
```

**Q1.4:** How many TLS sessions have no Server Name Indication? What destination IPs are these? Why is missing SNI significant?

---

### Exercise 2: Pivoting from an IOC

Start with the C2 IP `36.89.106.69`. Find all sessions to this IP:

```
ip.dst == 36.89.106.69
```

**Q2.1:** How many sessions go to this IP? Over what time span?

Now find what *source IPs* connected to it:

**Q2.2:** Is it only 10.0.0.128, or does 10.0.0.10 also connect to this C2? What does that tell you about the scope of the compromise?

Pivot to see what else the infected host was doing at the same time. Find all sessions from 10.0.0.128 within the same time window, excluding internal traffic:

```
ip.src == 10.0.0.128 && ip.dst != 10.0.0.10 && ip.dst != 10.0.0.255 && ip.dst != 224.0.0.0/4
```

**Q2.3:** Build a list of all unique external destinations the infected host contacted. Categorise each as: C2, payload delivery, IP lookup, or unknown.

---

### Exercise 3: Connections graph

Click the **Connections** tab.

Set the source to "Src IP" and the destination to "Dst IP". Adjust the node size to "Sessions" or "Databytes".

**Q3.1:** Take a screenshot or sketch the graph. Which node has the most connections? Which external nodes are connected to both internal hosts?

Click on the edge (line) between 10.0.0.128 and 36.89.106.69 to filter sessions on that path.

**Q3.2:** What does the session list show? How does this compare to your Zeek http.log findings from Lesson 2?

Now change the destination field to "Dst IP:Dst Port" to see port-level detail.

**Q3.3:** Does this reveal any additional patterns? Are there connections to unusual ports?

---

### Exercise 4: Session timing — detecting beaconing

Search for the C2 sessions:

```
ip.dst == 36.89.106.69 && protocols == http
```

Look at the timestamps of these sessions in the session list.

**Q4.1:** What is the approximate time interval between C2 check-in sessions? Is the timing regular or irregular?

Now look at connections to `203.176.135.102`:

```
ip.dst == 203.176.135.102
```

**Q4.2:** What port does this traffic use? How does the timing compare to the 36.89.106.69 traffic?

**Q4.3:** Based on the timing patterns, which destination appears to be the primary C2 and which might be a secondary channel or exfiltration point?

---

### Exercise 5: Examining payloads

Find the sessions where executables were downloaded:

```
ip.dst == 23.95.227.159 && protocols == http
```

Expand one of these sessions and click to view the reassembled content.

**Q5.1:** Can you see the HTTP response body? What do the first bytes look like? (Hint: look for `MZ` — the Windows PE header signature.)

Now look at a C2 POST request:

```
ip.dst == 36.89.106.69 && http.method == POST
```

**Q5.2:** Expand a POST session. Can you see the request body being sent to the C2? Describe what you observe.

Look at the SMB file transfer sessions:

```
port.dst == 445 && databytes > 10000
```

**Q5.3:** Can you see the executable file content being written over SMB? How does the packet view compare to what Zeek's smb_files.log showed?

---

### Exercise 6: Tagging sessions

Arkime lets you tag sessions with labels for tracking your investigation.

Find the C2 sessions to 36.89.106.69. Select all of them using the checkbox, then click "Add Tags" and add the tag `c2-primary`.

Now tag the payload downloads from 23.95.227.159 with `payload-delivery`.

Tag the SMB lateral movement sessions with `lateral-movement`.

**Q6.1:** After tagging, search for all sessions with a specific tag:

```
tags == c2-primary
```

How many sessions did you tag? How would tagging help in a team investigation?

---

### Exercise 7: PCAP export

Sometimes you need to extract a subset of packets for analysis in another tool (Wireshark, CyberChef, a sandbox).

Search for the payload download sessions:

```
ip.dst == 23.95.227.159 && protocols == http
```

Select the sessions, then click the **Actions** dropdown and choose **Export PCAP**.

**Q7.1:** Save the exported PCAP. How large is it compared to the original demo.pcap?

**Q7.2:** If you wanted to give a malware analyst just the suspicious traffic without exposing the rest of the network capture, why is PCAP export useful?

---

### Exercise 8: Building the case

Using everything you've learned in Arkime across Lessons 3–4, write a brief investigation summary (one paragraph per point):

**Q8.1:** What was the initial indicator that led you to investigate?

**Q8.2:** What did the attacker do? (Describe the attack chain you observed in Arkime.)

**Q8.3:** What evidence did Arkime provide that Zeek alone could not?

**Q8.4:** What are the IOCs you would share with other analysts?

---

### Extension: Fast Finishers

Import the second PCAP and conduct an independent investigation:

```bash
sudo /opt/arkime/bin/capture --copy -r ~/st0ne_buntu/samples/easy123.pcap -c /opt/arkime/etc/config.ini
```

Adjust the Arkime time picker to focus on the new PCAP's time range.

**E1:** Using only Arkime (no Zeek), identify the infected host, the C2 infrastructure, and the malware delivery mechanism.

**E2:** Tag the key sessions with appropriate labels (c2, delivery, lateral-movement, etc.).

**E3:** Export the malicious sessions as a separate PCAP.

**E4:** Write a three-sentence summary of the incident.

---

### Cleanup

Sessions remain in Arkime for use in Lesson 5 (integration lesson). Do not delete indices.

---

## Key Takeaways

- Arkime's search language lets you query on any extracted session field with wildcards and boolean logic
- Pivoting from a known IOC to related sessions reveals the scope of an incident
- The connections graph visualises host relationships and helps identify spread
- Regular session timing (beaconing) is a strong indicator of automated C2
- File extraction from packet captures preserves malware samples for analysis
- Tagging and PCAP export support collaborative investigation and evidence sharing
- Arkime excels at the "show me exactly what happened" questions that Zeek's structured logs can't fully answer
