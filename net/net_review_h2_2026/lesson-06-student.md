# 65sch00l — Lesson 6: Suricata Foundations — Signature-Based Detection

## Learning Objectives

By the end of this lesson you will be able to:

- Explain how Suricata's signature-based detection differs from Zeek's protocol analysis
- Run Suricata against a PCAP file in offline analysis mode
- Read and interpret fast.log and eve.json alert output
- Look up ET rule SIDs to understand what triggered an alert
- Triage alerts by counting, grouping, and assessing severity
- Distinguish true positives from benign true positives and informational alerts

---

## Theory

### What is Suricata?

Suricata is an intrusion detection system (IDS) that matches network traffic against a library of signatures (rules). Each rule describes a specific pattern — a known malware callback, an exploit attempt, a policy violation — and when Suricata sees traffic matching that pattern, it generates an alert.

Remember the analogy from Lesson 1: Zeek is a CCTV system that records everything. Suricata is the security guard with a list of known criminals. The guard can't record everything, but when someone on the list walks in, the guard sounds the alarm immediately.

### Rule anatomy

Every Suricata rule has two parts — the header and the options:

```
alert http $HOME_NET any -> $EXTERNAL_NET any (msg:"ET MALWARE Example Trojan Checkin"; flow:established,to_server; http.uri; content:"/malware/checkin"; http.user_agent; content:"EvilBot/1.0"; sid:2099999; rev:1;)
```

**Header:** `alert http $HOME_NET any -> $EXTERNAL_NET any`
- `alert` — action (alert, drop, pass)
- `http` — protocol
- `$HOME_NET any` — source IP and port
- `->` — direction
- `$EXTERNAL_NET any` — destination IP and port

**Options** (in parentheses):
- `msg` — the alert message displayed when it fires
- `flow` — connection state (established, to_server)
- `content` — the pattern to match
- `http.uri`, `http.user_agent` — which part of the protocol to search
- `sid` — unique rule ID
- `rev` — rule revision number

### The Emerging Threats ruleset

The ET Open ruleset contains tens of thousands of rules organised into categories:

| Category | What it detects |
|----------|----------------|
| ET MALWARE | Known malware families, C2 communications |
| ET TROJAN | Trojan-specific signatures |
| ET REMOTE_ACCESS | Remote access tools (RATs, RMM abuse) |
| ET INFO | Informational — not necessarily malicious but noteworthy |
| ET POLICY | Policy violations — things that shouldn't happen on your network |
| ET EXPLOIT | Exploit attempts |
| ET HUNTING | Broader patterns useful for threat hunting |

### Output formats

Suricata produces two main alert outputs:

**fast.log** — one-line-per-alert, human-readable, good for quick review:
```
02/28/2026-19:55:51.679800  [**] [1:2035892:8] ET REMOTE_ACCESS NetSupport Remote Admin Checkin [**] [Classification: Misc activity] [Priority: 3] {TCP} 10.2.28.88:51912 -> 45.131.214.85:443
```

**eve.json** — detailed JSON, machine-parseable, contains full alert context including the matching rule, flow data, and protocol details. This is what you use for serious analysis.

### HOME_NET and EXTERNAL_NET

On st0ne_buntu, both are set to `any` — meaning Suricata will match rules regardless of which subnet the traffic comes from. This is necessary for offline PCAP analysis where you don't know the source network in advance.

---

## Practical

### Setup

Run Suricata against the provided PCAP:

```bash
mkdir -p /tmp/lesson6/suricata
sudo suricata -r ~/st0ne_buntu/samples/easy123.pcap -c /etc/suricata/suricata.yaml -l /tmp/lesson6/suricata/ -k none
```

---

### Exercise 1: First look at the alerts

Check how many alerts fired:

```bash
wc -l /tmp/lesson6/suricata/fast.log
```

**Q1.1:** How many total alerts did Suricata generate?

Look at the first 10 alerts:

```bash
head -10 /tmp/lesson6/suricata/fast.log
```

**Q1.2:** What alert signatures appear? What is their priority level?

---

### Exercise 2: Counting and grouping alerts

Extract just the signature names and count them:

```bash
grep -oP '\] \K[^\[]+(?= \[\*\*\])' /tmp/lesson6/suricata/fast.log | sort | uniq -c | sort -rn
```

**Q2.1:** How many unique alert signatures fired? List each one and its count.

**Q2.2:** Which signature fired the most? What does the name suggest it detects?

**Q2.3:** Are there any alerts that only fired once or a small number of times? Why might a rare alert be more interesting than a frequent one?

---

### Exercise 3: Working with eve.json

Extract just the alert events from eve.json:

```bash
cat /tmp/lesson6/suricata/eve.json | jq -c 'select(.event_type == "alert")' > /tmp/lesson6/eve-alerts.json
wc -l /tmp/lesson6/eve-alerts.json
```

Look at the structure of a single alert:

```bash
head -1 /tmp/lesson6/eve-alerts.json | jq '.'
```

**Q3.1:** List five fields in an EVE alert that aren't visible in fast.log.

Extract the key fields:

```bash
cat /tmp/lesson6/eve-alerts.json | jq -r '[.timestamp, .alert.signature, .alert.severity, .src_ip, .dest_ip, .dest_port] | @tsv' | head -20
```

**Q3.2:** What source IP generates all the alerts? What destination IP and port do they target?

---

### Exercise 4: Understanding the alerts

Group alerts by signature ID:

```bash
cat /tmp/lesson6/eve-alerts.json | jq -r '.alert.signature_id' | sort | uniq -c | sort -rn
```

Look up what each SID does — search the rules file:

```bash
grep 'sid:2035892' /var/lib/suricata/rules/emerging-all.rules
```

**Q4.1:** Read the rule for SID 2035892. What specific content pattern does it match? What protocol keywords does it use?

```bash
grep 'sid:2013926' /var/lib/suricata/rules/emerging-all.rules
```

**Q4.2:** Read the rule for SID 2013926. Why does "HTTP traffic on port 443" trigger an alert? What is normally expected on port 443?

```bash
grep 'sid:2031071' /var/lib/suricata/rules/emerging-all.rules
```

**Q4.3:** Read the rule for SID 2031071. Is this alert malicious? What is the Microsoft Connection Test?

---

### Exercise 5: Alert triage

Using what you've learned, categorise each alert signature:

**Q5.1:** For each unique signature, assign a verdict:
- **True Positive (Malicious)** — this alert detected actual malicious activity
- **Benign True Positive** — the rule matched correctly, but the activity is legitimate
- **Informational** — noteworthy but not actionable on its own

Explain your reasoning for each.

**Q5.2:** If you were an analyst receiving these alerts in real time, which would you investigate first? Why?

**Q5.3:** The "NetSupport Remote Admin Checkin" alert fires hundreds of times. What does the repetition tell you about the nature of this activity?

---

### Exercise 6: Timeline analysis

Sort the alerts by time:

```bash
cat /tmp/lesson6/eve-alerts.json | jq -r '[.timestamp, .alert.signature] | @tsv' | sort | head -20
```

```bash
cat /tmp/lesson6/eve-alerts.json | jq -r '[.timestamp, .alert.signature] | @tsv' | sort | tail -20
```

**Q6.1:** What was the first alert? What was the last?

**Q6.2:** Over what time period do the alerts span?

Calculate the interval between "NetSupport Remote Admin Checkin" alerts:

```bash
cat /tmp/lesson6/eve-alerts.json | jq -r 'select(.alert.signature_id == 2035892) | .timestamp' | head -10
```

**Q6.3:** What is the approximate interval between check-ins? Is this consistent with automated (malware) or manual (human) behaviour?

---

### Exercise 7: What Suricata tells you vs what it doesn't

**Q7.1:** Based solely on Suricata's alerts, what can you confidently state about this PCAP?

**Q7.2:** What questions can Suricata NOT answer? List at least three things you'd want to know that Suricata doesn't tell you.

**Q7.3:** If you had Zeek logs for this same PCAP, what would you look for to fill in the gaps Suricata left?

---

### Extension: Fast Finishers

Run Suricata against the demo.pcap from Lessons 2–5:

```bash
mkdir -p /tmp/lesson6/demo-suri
sudo suricata -r ~/st0ne_buntu/samples/demo.pcap -c /etc/suricata/suricata.yaml -l /tmp/lesson6/demo-suri/ -k none
```

**E1:** How do the alert categories and volume compare to easy123.pcap?

**E2:** Does Suricata detect the lateral movement you found with Zeek? Why or why not?

**E3:** Which PCAP would be harder to investigate with Suricata alone? Why?

---

### Cleanup

```bash
cd ~ && rm -rf /tmp/lesson6
```

---

## Key Takeaways

- Suricata detects known threats by matching traffic against signature rules
- fast.log gives you a quick overview; eve.json gives you detailed, queryable data
- Not every alert is malicious — triage requires understanding the rule, the context, and the environment
- Alert frequency and timing reveal patterns (beaconing = automated C2)
- Suricata tells you WHAT matched a known pattern but not the full story of the incident
- Looking up the actual rule (SID) is essential for understanding why an alert fired
