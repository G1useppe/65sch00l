# Suricata & Arkime — Course Introduction

## Overview

This module builds proficiency in **network traffic analysis** using two core tools: **Suricata** (an IDS/IPS engine) and **Arkime** (a large-scale packet capture and indexing platform). Over seven lessons, you will progress from static PCAP analysis through to live detection pipelines, integrating Suricata alerts with Arkime session data and Splunk dashboards.

## Prerequisites

- Comfortable with the Linux command line (bash, file navigation, pipes)
- Basic understanding of TCP/IP, DNS, and HTTP
- Familiarity with Wireshark (packet inspection, filters, following streams)
- Docker and Docker Compose installed (for lessons 4–7)

## Environment Setup

All lessons pull their PCAP datasets from [malware-traffic-analysis.net](https://www.malware-traffic-analysis.net/) using `curl`. Each lesson's **Prepare** section includes a download script that checks for existing files before downloading and handles password-protected zip extraction automatically.

> **WARNING:** These PCAPs contain real malware traffic. Handle them in an isolated analysis environment — never on a production network or unprotected Windows host.

### Required Tools

Lessons 1–3 (static analysis) require local installs:

- `suricata` — IDS engine
- `wireshark` / `tshark` — packet analysis
- `capinfos` — PCAP metadata (ships with Wireshark)
- `jq` — JSON processing
- `curl` / `unzip` — dataset retrieval

Lessons 4–7 (live capture and indexing) use Docker Compose stacks that bundle:

- Suricata (live IDS)
- Arkime (capture + viewer) with OpenSearch
- tcpreplay (traffic replay)
- Splunk (lessons 6–7 only)

### PCAP Password

All zip archives from malware-traffic-analysis.net are password-protected. Check the [about page](https://www.malware-traffic-analysis.net/about.html) for the current password scheme. Throughout these lessons, the password variable `$MTA_PASS` is used — set it once per session:

```bash
# Set this to the current malware-traffic-analysis.net password
export MTA_PASS="infected"
```

## Lesson Progression

| # | Lesson | Mode | Key Skills |
|---|--------|------|------------|
| 1 | Arkime Fundamentals | Static (demo server + local) | Session navigation, SPI View, search queries, MITRE mapping |
| 2 | Suricata Read Mode & Wireshark | Static (local) | Offline IDS, eve.json parsing, alert-to-packet correlation |
| 3 | Capinfos & Sequence Diagramming | Static (local) | PCAP metadata, flow visualization, alert overlay |
| 4 | Live Capture with Docker | Live (Docker) | tcpreplay, containerized Suricata + Wireshark, real-time alerts |
| 5 | Arkime Static Workflow (Docker) | Static (Docker) | Dockerized Arkime + OpenSearch, PCAP ingest, session indexing |
| 6 | Suricata Logs in Splunk | Static (Docker) | Splunk ingest, alert dashboards, SPL queries |
| 7 | Live Suricata–Splunk Pipeline | Live (Docker) | End-to-end detection pipeline, MITRE ATT&CK Navigator |

## MITRE ATT&CK Integration

Every lesson includes a mapping step where you relate observed network behaviors to MITRE ATT&CK techniques. By lesson 7, you will have populated an ATT&CK Navigator layer representing all detections across the course.

## Resources

- [Arkime Documentation](https://arkime.com/)
- [Arkime Docker Guide](https://arkime.com/docker)
- [Suricata Documentation](https://docs.suricata.io/)
- [Emerging Threats Ruleset](https://rules.emergingthreats.net/)
- [malware-traffic-analysis.net](https://www.malware-traffic-analysis.net/)
- [MITRE ATT&CK Navigator](https://mitre-attack.github.io/attack-navigator/)
