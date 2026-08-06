# 65sch00l — Lesson 8: Capstone — Full Stack Investigation

## Scenario

Your SOC has received a PCAP from a network segment that may have been compromised. No context has been provided beyond the raw capture. Your task is to investigate the PCAP using all three tools — Suricata, Zeek, and Arkime — identify what happened, and produce a formal investigation report.

This is an independent exercise. There are no guided questions or step-by-step instructions. You decide which tools to use, in what order, and what to investigate.

---

## Objectives

- Conduct an independent network traffic investigation using Suricata, Zeek, and Arkime
- Identify the compromised host(s), the threat, and the scope of the incident
- Correlate findings across all three tools using community ID
- Produce a structured investigation report with evidence references
- Compile a complete IOC list

---

## Setup

### Suricata

```bash
mkdir -p /tmp/capstone/suricata
sudo suricata -r ~/st0ne_buntu/samples/nemotodes.pcap -c /etc/suricata/suricata.yaml -l /tmp/capstone/suricata/ -k none
```

### Zeek

```bash
mkdir -p /tmp/capstone/zeek && cd /tmp/capstone/zeek
/opt/zeek/bin/zeek -r ~/st0ne_buntu/samples/nemotodes.pcap LogAscii::use_json=T policy/protocols/conn/community-id-logging
```

### Arkime

```bash
sudo /opt/arkime/bin/capture --copy -r ~/st0ne_buntu/samples/nemotodes.pcap -c /opt/arkime/etc/config.ini 2>/dev/null
```

Arkime viewer: `http://localhost:8005` (adjust time picker to cover the PCAP's date range)

---

## Deliverables

### 1. Network Map

Identify and document:
- All internal hosts (IPs, hostnames, roles)
- The internal domain name
- The DNS server
- Any user accounts visible in authentication logs

### 2. Investigation Timeline

Produce a chronological timeline of significant events. Each entry should include:
- Timestamp
- What happened
- Which tool provided the evidence
- The community ID (where applicable)

Minimum 10 events.

### 3. Threat Assessment

Answer these questions in your report:
- What is the nature of the threat? (malware family if identifiable, type of attack)
- Which host(s) are compromised?
- What is the C2 infrastructure? (IPs, ports, protocols, domains)
- Is there evidence of lateral movement?
- Is there evidence of data exfiltration?
- What is the beaconing interval (if any)?

### 4. IOC List

Compile a structured IOC list:
- IP addresses
- Domains
- User agent strings
- JA3 hashes (if available)
- File hashes (if available)
- URI patterns
- Suricata SIDs that fired

### 5. Tool Comparison

Write a brief paragraph for each tool describing what it contributed to the investigation that the other two could not.

### 6. Recommendations

If this were a real incident, what would your immediate response actions be? List at least three specific, actionable steps.

---

## Assessment Criteria

Your report will be evaluated on:

| Criteria | Weight |
|----------|--------|
| Accurate identification of compromised hosts and threat | 25% |
| Completeness of the timeline (key events captured) | 20% |
| Effective use of all three tools (not just one) | 20% |
| Cross-tool correlation using community ID | 15% |
| Quality of IOC list and recommendations | 10% |
| Clear, professional report structure | 10% |

---

## Time Allocation

You have 120 minutes. Suggested pacing (not prescriptive):

- **First 10 minutes** — run all three tools, orient yourself
- **Next 30 minutes** — Suricata triage + Zeek broad analysis
- **Next 30 minutes** — deep dive into suspicious findings, Arkime for evidence
- **Next 20 minutes** — cross-tool correlation, fill gaps
- **Final 30 minutes** — write the report, compile IOCs, review

---

## Report Template

Use this structure or your own:

```markdown
# Incident Report: [Case Name]

**Date:** 
**Analyst:**
**PCAP:**

## Executive Summary
(2-3 sentences: what happened, how bad is it, what needs to happen next)

## Network Environment
(hosts, domain, roles)

## Timeline of Events
| Time | Event | Tool | Community ID |
|------|-------|------|-------------|
| | | | |

## Threat Analysis
(what the threat is, how it operates, scope of compromise)

## Indicators of Compromise
### IP Addresses
### Domains
### User Agents
### URI Patterns
### Suricata SIDs
### File Hashes / JA3

## Tool Contributions
### Suricata
### Zeek
### Arkime

## Recommendations
1. 
2. 
3. 

## Evidence References
(community IDs, log file paths, Arkime session references)
```

---

## Cleanup

```bash
cd ~ && rm -rf /tmp/capstone
```

---

Good luck.
