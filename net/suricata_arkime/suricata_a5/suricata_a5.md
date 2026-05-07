# Lesson 5 — Static Workflow with Arkime (Docker)

## Summary

In Lesson 1 you explored Arkime via the demo server and (optionally) a local install. This lesson sets up a **full Arkime stack using Docker Compose** — Arkime capture, Arkime viewer, and OpenSearch — so you can ingest PCAPs and investigate session data on your own machine. This is the foundation for the live pipeline exercises in Lessons 6 and 7, and gives you a portable, reproducible analysis environment you can spin up anywhere Docker runs.

---

## Prepare

### Download the Dataset

```bash
cd ~/65sch00l/net/suricata_arkime/suricata_a5
mkdir -p .rsrc

# Use a different, richer PCAP for this exercise
PCAP_FILE=".rsrc/demo.pcap"
if [ ! -f "$PCAP_FILE" ]; then
  if [ -f "../suricata_a2/.rsrc/demo.pcap" ]; then
    cp ../suricata_a2/.rsrc/demo.pcap "$PCAP_FILE"
  else
    PCAP_ZIP=".rsrc/2024-09-04-traffic-analysis-exercise.pcap.zip"
    curl -L -o "$PCAP_ZIP" \
      "https://www.malware-traffic-analysis.net/2024/09/04/2024-09-04-traffic-analysis-exercise.pcap.zip"
    unzip -P "$MTA_PASS" "$PCAP_ZIP" -d .rsrc/
    mv .rsrc/2024-09-04-traffic-analysis-exercise.pcap "$PCAP_FILE"
  fi
else
  echo "PCAP already exists."
fi
```

### Verify Tools

```bash
docker --version         || echo "ERROR: docker not found"
docker compose version   || echo "ERROR: docker compose not found"
```

### Set System Limits for OpenSearch

OpenSearch requires increased virtual memory limits. This only needs to be done once per host:

```bash
# Check current value
sysctl vm.max_map_count

# Set temporarily (resets on reboot)
sudo sysctl -w vm.max_map_count=262144

# Set permanently
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

---

## Brief

This lesson covers:

1. Standing up a Dockerized Arkime + OpenSearch stack
2. Ingesting a PCAP file into Arkime for indexing
3. Navigating the viewer to investigate session data
4. Practicing the Arkime queries from Lesson 1 against your own indexed data

---

## Docker Compose Stack

Create the Arkime stack:

```bash
mkdir -p arkime-raw arkime-etc arkime-logs

cat > docker-compose.yml << 'EOF'
services:
  opensearch:
    image: opensearchproject/opensearch:2.18.0
    container_name: arkime-opensearch
    environment:
      - discovery.type=single-node
      - OPENSEARCH_INITIAL_ADMIN_PASSWORD=Arkime_Lab_2024!
      - DISABLE_SECURITY_PLUGIN=true
      - "OPENSEARCH_JAVA_OPTS=-Xms1g -Xmx1g"
    volumes:
      - opensearch-data:/usr/share/opensearch/data
    ports:
      - "9200:9200"
    healthcheck:
      test: ["CMD-SHELL", "curl -s http://localhost:9200 | grep -q 'cluster_name'"]
      interval: 10s
      timeout: 5s
      retries: 30
    restart: unless-stopped

  arkime-init:
    image: ghcr.io/arkime/arkime/arkime:v5-latest
    container_name: arkime-init
    network_mode: host
    depends_on:
      opensearch:
        condition: service_healthy
    volumes:
      - ./arkime-raw:/opt/arkime/raw
      - ./arkime-etc:/opt/arkime/etc
    environment:
      - ARKIME__elasticsearch=http://localhost:9200
    command: /opt/arkime/bin/docker.sh initnoprompt
    restart: "no"

  arkime-viewer:
    image: ghcr.io/arkime/arkime/arkime:v5-latest
    container_name: arkime-viewer
    network_mode: host
    depends_on:
      arkime-init:
        condition: service_completed_successfully
    volumes:
      - ./arkime-raw:/opt/arkime/raw
      - ./arkime-etc:/opt/arkime/etc
      - ./arkime-logs:/opt/arkime/logs
    environment:
      - ARKIME__elasticsearch=http://localhost:9200
    command: /opt/arkime/bin/docker.sh viewer
    restart: unless-stopped

volumes:
  opensearch-data:

EOF
```

---

## Demonstration — Bringing Up the Stack

### Step 1: Start OpenSearch and Initialize Arkime

```bash
docker compose up -d opensearch
docker compose logs -f opensearch 2>&1 | grep -m1 "started"
```

Once OpenSearch is healthy, run the init container to create indices and an admin user:

```bash
docker compose up arkime-init
```

### Step 2: Start the Viewer

```bash
docker compose up -d arkime-viewer
```

Wait for the viewer to come up, then open it:

```bash
echo "Arkime Viewer: http://localhost:8005"
firefox http://localhost:8005 &
```

Default credentials are created by the init process — check the init logs if needed:

```bash
docker logs arkime-init 2>&1 | grep -i "admin"
```

### Step 3: Ingest the PCAP

Use `arkime-capture` in a one-shot container to read the PCAP and index its sessions:

```bash
docker run --rm \
  --network host \
  -v "$(pwd)/.rsrc:/import:ro" \
  -v "$(pwd)/arkime-raw:/opt/arkime/raw" \
  -v "$(pwd)/arkime-etc:/opt/arkime/etc" \
  -e ARKIME__elasticsearch=http://localhost:9200 \
  ghcr.io/arkime/arkime/arkime:v5-latest \
  /opt/arkime/bin/docker.sh capture -r /import/demo.pcap --copy
```

The `--copy` flag tells capture to copy the PCAP to `arkime-raw` so the viewer can serve packet data.

### Step 4: Explore in the Viewer

Refresh the Arkime viewer in your browser. Set the time range to **All** (or adjust to cover the PCAP's timespan). You should now see all indexed sessions.

Practice the queries from Lesson 1:

```
http.uri == EXISTS!
dns.host == EXISTS!
ip.src == 172.17.0.0/24 && port.dst != 80 && port.dst != 443
http.method == POST
bytes > 500000
```

Explore SPI View, SPI Graph, and Connections pages with your own data.

---

## Execute — Fights On

**Narrative:** You've been handed a PCAP from a different incident and asked to ingest it into Arkime for team investigation.

1. Download and ingest a new PCAP (reuse one from a previous lesson or download a fresh one):

   ```bash
   docker run --rm \
     --network host \
     -v "$(pwd)/.rsrc:/import:ro" \
     -v "$(pwd)/arkime-raw:/opt/arkime/raw" \
     -v "$(pwd)/arkime-etc:/opt/arkime/etc" \
     -e ARKIME__elasticsearch=http://localhost:9200 \
     ghcr.io/arkime/arkime/arkime:v5-latest \
     /opt/arkime/bin/docker.sh capture -r /import/demo.pcap --copy
   ```

2. In the viewer, find the infected host using SPI View and search queries
3. Export the suspicious sessions as a PCAP for sharing with the team (Actions > Export PCAP)
4. Tag sessions with your findings (right-click > Add Tag)
5. Map findings to **MITRE ATT&CK**

### Tear Down

```bash
docker compose down
# To also remove the OpenSearch data volume:
# docker compose down -v
```

---

## Debrief

After this lesson you should be able to:

- Deploy a Dockerized Arkime + OpenSearch stack from scratch
- Ingest PCAP files into Arkime for indexing
- Navigate and query your own indexed data in the Arkime viewer
- Export and tag sessions for collaborative investigation
- Understand the relationship between capture (indexing) and viewer (querying) components
