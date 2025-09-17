
## 1. What is Splunk?

- Splunk is a **Security Information and Event Management (SIEM)** tool.
    
- It collects, indexes, and analyzes log data from different sources.
    
- It helps with **hunting, monitoring, alerting, and reporting**.
    

**How it works:**

- **Ingest**: Data comes from agents, forwarders, or APIs.
    
- **Index**: Data is parsed and stored.
    
- **Search**: Use SPL (Search Processing Language) to explore data.
    
- **Visualize**: Dashboards, alerts, and reports show results.
    

---

## 2. Data Sources You’ll Use

- **Velociraptor** → Endpoint telemetry (process execution, file access, forensic artefacts).
    
- **Zeek** → Network metadata (connections, DNS, HTTP, SSL).
    
- **Suricata** → IDS/IPS alerts, packet-level detection.
    
- **Sysmon** → Windows logging (process creation, registry, file writes, network events).
    

---

## 3. Hunting in Splunk

**Why hunt in Splunk?**

- To answer: _“If an attacker is here, what would I see?”_
    
- To connect signals between endpoints and network data.
    

**Steps:**

1. Form a hypothesis (e.g., _Suspicious PowerShell was used_).
    
2. Search across datasets.
    
3. Correlate different sources (Sysmon + Zeek + Suricata).
    
4. Save results into dashboards or alerts.
    

---

## 4. Searching with SPL

**Basic syntax:**

```
index=<source> <filters> | <commands>
```

**Examples:**

- Sysmon → Suspicious PowerShell
    

```spl
index=sysmon EventCode=1 Image="*powershell.exe"
```

- Zeek → Rare DNS domains
    

```spl
index=zeek sourcetype=bro_dns | stats count by query | where count<5
```

- Suricata → High severity alerts
    

```spl
index=suricata alert.severity=1 | stats count by src_ip, signature
```

- Velociraptor → File execution traces
    

```spl
index=velociraptor event_type=FileExecution
```

---

## 5. Dashboards & Visualization

- Use dashboards to spot trends and patterns quickly.
    
- Common elements:
    
    - **Timecharts** → `| timechart count by EventCode`
        
    - **Top talkers** → IPs, users, domains
        
    - **Heatmaps** → User logons per host
        

**Examples:**

- Sysmon → Process execution frequency by user
    
- Zeek → DNS queries over time
    
- Suricata → High-severity alerts by subnet
    
- Velociraptor → Suspicious artifacts per host
    

---

## 6. Creating Alerts

- Alerts notify you when a search condition is met.
    
- Steps:
    
    1. Run a search query.
        
    2. Click **Save As → Alert**.
        
    3. Define trigger conditions (e.g., `> 5 events in 10 minutes`).
        
    4. Choose an action: email, webhook, create ticket, etc.
        

**Example:** Alert on 5 failed logons from the same IP in 10 minutes.

```spl
index=sysmon EventCode=4625 | stats count by src_ip | where count>5
```

---

## 7. Reports

- Reports are saved searches that run on a schedule.
    
- Useful for **daily summaries, weekly trends, or compliance checks**.
    

**Steps:**

1. Run your search.
    
2. Click **Save As → Report**.
    
3. Give it a title and schedule (daily/weekly/monthly).
    
4. Choose how results are shared (dashboard panel, email PDF, CSV export).
    

**Example:** Daily report of top 10 rare DNS domains.

```spl
index=zeek sourcetype=bro_dns | stats count by query | sort count | head 10
```

---

# Capstone