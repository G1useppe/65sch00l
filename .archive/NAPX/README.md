# NAPX-Pro — Network Analysis Pipeline, Extended

A containerised, one-command network forensics pipeline that replays PCAPs through
Suricata, Zeek, and YARA, ingests everything into the ELK stack, enriches IOCs with
threat intelligence, and generates a self-contained HTML report.

## Quick Start

```bash
# 1. Place your PCAP in the input directory
mkdir -p input
cp /path/to/evidence.pcap input/

# 2. Configure (optional — defaults work out of the box)
cp .env.example .env
# Edit .env to add VirusTotal / AbuseIPDB keys if desired

# 3. Run
make run

# 4. Access
#    Kibana:  http://localhost:5601
#    Report:  ./output/report.html (auto-generated when analysis completes)
```

## Architecture

```
┌─────────────┐
│  input/*.pcap│
└──────┬───────┘
       │
       ▼
┌──────────────┐     ┌────────────┐     ┌─────────────┐
│ Orchestrator │────▶│  Suricata   │────▶│  eve.json    │
│ (tcpreplay)  │     │  (IDS/IPS)  │     └──────┬───────┘
│              │     └────────────┘            │
│              │     ┌────────────┐            │   ┌──────────┐
│              │────▶│    Zeek     │────▶ logs ─┼──▶│ Logstash │──▶ Elasticsearch
│              │     │  (NSM)     │            │   │ Filebeat │     ▲
│              │     └────────────┘            │   └──────────┘     │
│              │     ┌────────────┐            │                    │
│              │────▶│   YARA     │────▶ results               ┌───┴───┐
│              │     │ (scanner)  │                             │Kibana │
└──────┬───────┘     └────────────┘                             └───────┘
       │
       ▼
┌──────────────┐     ┌────────────────┐
│IOC Extractor │────▶│ Threat Intel   │
│              │     │ Enrichment     │
└──────┬───────┘     │ (VT, AbuseIPDB)│
       │             └────────────────┘
       ▼
┌──────────────┐
│ HTML Report  │──▶ output/report.html
│ Generator    │──▶ output/summary.json
└──────────────┘
```

## Components

| Container         | Purpose                                         |
| ----------------- | ----------------------------------------------- |
| elasticsearch     | Search and analytics engine (data store)         |
| kibana            | Visualisation dashboard                          |
| logstash          | Suricata eve.json parsing, GeoIP, normalisation |
| filebeat          | Ships Zeek, YARA, and IOC data to Elasticsearch |
| suricata          | IDS — alert generation from PCAP                |
| zeek              | NSM — conn/dns/http/ssl/file metadata           |
| yara-scanner      | File/payload pattern matching against rules     |
| orchestrator      | Coordinates replay, IOC extraction, enrichment  |
| report-generator  | Synthesises all outputs into HTML report        |

## Directory Structure

```
napx-pro/
├── docker-compose.yml          # Full stack definition
├── Makefile                    # Convenience targets
├── .env.example                # Configuration template
├── input/                      # Place PCAP(s) here
├── output/                     # Reports appear here
├── docker/
│   ├── Dockerfile.orchestrator
│   ├── Dockerfile.yara
│   ├── Dockerfile.report
│   ├── orchestrator.sh
│   ├── yara_scan.py
│   └── report_generator.py
├── scripts/
│   ├── extract_iocs.py
│   └── enrich_iocs.py
├── config/
│   ├── suricata/
│   │   ├── suricata.yaml
│   │   └── rules/              # Add custom .rules files
│   ├── zeek/
│   │   └── local.zeek
│   ├── logstash/pipeline/
│   │   └── suricata.conf
│   ├── filebeat/
│   │   └── filebeat.yml
│   └── yara/rules/
│       └── network_indicators.yar
└── README.md
```

## Configuration

All settings live in `.env`:

| Variable             | Default | Description                          |
| -------------------- | ------- | ------------------------------------ |
| `NAPX_INTERFACE`     | `lo`    | Network interface for live replay    |
| `NAPX_REPLAY_SPEED`  | `1.0`   | tcpreplay multiplier                 |
| `NAPX_ENRICHMENT`    | `false` | Enable threat intel API lookups      |
| `VT_API_KEY`         |         | VirusTotal API key                   |
| `ABUSEIPDB_KEY`      |         | AbuseIPDB API key                    |

## Make Targets

```
  make build     Build all container images
  make run       Build and start everything
  make down      Stop all containers
  make clean     Stop and remove all data
  make logs      Tail container logs
  make status    Show container status
  make report    Wait for and open the report
  make kibana    Open Kibana in browser
  make enrich    Re-run enrichment with API keys
```

## Cross-Tool Correlation

Both Suricata and Zeek are configured to emit **Community ID** flow hashes.
This means you can pivot between Suricata alerts and Zeek metadata in Kibana
using the `network.community_id` field — same flow, two perspectives.

## Adding Custom Rules

- **Suricata**: Drop `.rules` files in `config/suricata/rules/`
- **YARA**: Drop `.yar` files in `config/yara/rules/`
- **Zeek**: Edit `config/zeek/local.zeek` to load additional scripts

## Requirements

- Docker Engine 24+ with Compose v2
- 4GB+ RAM (8GB recommended for large PCAPs)
- A PCAP file to analyse
