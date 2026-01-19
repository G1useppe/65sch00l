# Splunk Lesson Plan

## 1. What is Splunk?

- Splunk is a **Security Information and Event Management (SIEM)** tool.
- It collects, indexes, and analyzes log data from various sources.
- It helps with **hunting, monitoring, alerting, and reporting**.

**How it works:**
- **Ingest**: Data is ingested via Splunk forwarders (Universal/Heavy), APIs, or direct inputs like HTTP Event Collector (HEC).
- **Index**: Data is parsed, tagged with metadata (e.g., sourcetype, host), and stored in indexes (e.g., `main`, `security`).
- **Search**: Use SPL (Search Processing Language) to query data with commands like `search`, `stats`, and `timechart`.
- **Visualize**: Create dashboards, alerts, or reports to display insights.

**Example Command:**
```spl
index=sysmon | stats count by sourcetype, host | sort -count
```
- Lists all Sysmon sourcetypes and hosts with their event counts to confirm data ingestion.

## 2. Data Sources You’ll Use

- **Velociraptor**: Endpoint telemetry (e.g., process execution via `Windows.EventLogs.ProcessExecution`, persistence via `Windows.Sysinternals.Autoruns`, file access via `Windows.FileSystem.RecentFiles`).
- **Zeek**: Network metadata (connections, DNS, HTTP, SSL logs).
- **Suricata**: IDS/IPS alerts, packet-level detection (e.g., malware signatures).
- **Sysmon**: Windows logging (process creation, registry changes, file writes, network connections).

## 3. Hunting in Splunk

**Why hunt in Splunk?**
- To proactively answer: _“If an attacker is in my environment, what would I see?”_

**Steps:**
1. Form a hypothesis (e.g., _Suspicious PowerShell execution indicating a potential attack_).
2. Search across datasets using SPL.
3. Correlate data from multiple sources (e.g., Sysmon + Zeek + Suricata).
4. Save results as dashboards or alerts for ongoing monitoring.

**Example Commands:**
- Hunt for PowerShell executing suspicious commands:
  ```spl
  index=sysmon EventCode=1 Image="*powershell.exe" CommandLine IN ("*Invoke-WebRequest*", "*DownloadFile*") | table _time, host, CommandLine, ParentImage
  ```
  - Shows PowerShell processes with specific command-line patterns, including execution time, host, command, and parent process.
- Correlate Sysmon and Zeek for suspicious network activity:
  ```spl
  index=sysmon EventCode=1 Image="*powershell.exe" | join host [search index=zeek sourcetype=bro_conn | where dest_port=80 OR dest_port=443] | table _time, host, CommandLine, dest_ip, dest_port
  ```
  - Matches PowerShell executions with HTTP/HTTPS connections from the same host.

## 4. Searching with SPL

**Basic Syntax:**
```
index=<source> <filters> | <commands>
```

**Example Commands:**
- **Sysmon → Suspicious PowerShell with encoded commands:**
  ```spl
  index=sysmon EventCode=1 Image="*powershell.exe" CommandLine="* -EncodedCommand *" | rex field=CommandLine "-EncodedCommand\s+(?<encoded_cmd>\S+)" | table _time, host, CommandLine, encoded_cmd
  ```
  - Extracts and displays encoded PowerShell commands for further analysis.
- **Zeek → Rare DNS domains:**
  ```spl
  index=zeek sourcetype=bro_dns | stats count by query, src_ip | where count < 5 | sort count | table src_ip, query, count
  ```
  - Identifies rare DNS queries with source IPs to spot potential C2 domains.
- **Suricata → High-severity alerts:**
  ```spl
  index=suricata alert.severity=1 | stats count by src_ip, dest_ip, signature, dest_port | sort -count | table src_ip, dest_ip, signature, dest_port, count
  ```
  - Lists high-severity alerts with source/destination IPs, signature, and port.
- **Velociraptor → Suspicious process executions:**
  ```spl
  index=velociraptor sourcetype=velociraptor_artifact Artifact="Windows.EventLogs.ProcessExecution" ProcessName IN ("powershell.exe", "cmd.exe") | table _time, host, ProcessName, CommandLine, User
  ```
  - Filters for processes like PowerShell or cmd.exe from Velociraptor’s process execution artifact, showing execution details.

**Pro Tip:**
- Use `| table` to format output and `| dedup` to remove duplicates (e.g., `| dedup host`).

## 5. Dashboards & Visualization

- Dashboards visualize trends and patterns for quick analysis.
- Common visualization types:
  - **Timecharts**: Show trends over time (e.g., event frequency).
  - **Top talkers**: Identify frequent IPs, users, or domains.
  - **Heatmaps**: Visualize patterns like user logons across hosts.

**Example Commands for Dashboards:**
- **Sysmon → Process execution frequency by user:**
  ```spl
  index=sysmon EventCode=1 | timechart span=1h count by User | where count > 10
  ```
  - Creates a timechart of process executions per user, filtering for high activity.
- **Zeek → DNS queries over time:**
  ```spl
  index=zeek sourcetype=bro_dns | timechart span=30m count by query | head 5
  ```
  - Visualizes the top 5 DNS queries over 30-minute intervals.
- **Suricata → High-severity alerts by subnet:**
  ```spl
  index=suricata alert.severity=1 | eval subnet=mvindex(split(src_ip, "."), 0, 2) | stats count by subnet | sort -count
  ```
  - Groups alerts by subnet for a pie chart.
- **Velociraptor → Suspicious autorun entries per host:**
  ```spl
  index=velociraptor sourcetype=velociraptor_artifact Artifact="Windows.Sysinternals.Autoruns" ImagePath="*.exe" | stats count by host, ImagePath | sort -count
  ```
  - Displays executable autorun entries per host from Velociraptor’s Autoruns artifact.

**Dashboard Tip:**
- After running a search, click **Visualize** in Splunk’s UI, select a chart type (e.g., Line, Pie), and save to a dashboard panel (e.g., “Security Events Overview”).

## 6. Creating Alerts

- Alerts trigger notifications when a search condition is met (e.g., email, webhook, ticketing system).

**Steps:**
1. Run a search query.
2. Click **Save As → Alert**.
3. Define trigger conditions (e.g., `> 5 events in 10 minutes`).
4. Set actions: Email, webhook, or create a ticket (e.g., ServiceNow).

**Example Commands for Alerts:**
- **Alert on 5 failed logons from the same IP in 10 minutes:**
  ```spl
  index=sysmon EventCode=4625 | stats count by src_ip | where count > 5 | table src_ip, count
  ```
  - Triggers for IPs with more than 5 failed logon attempts in a 10-minute window.
- **Alert on Suspicious PowerShell Network Activity:**
  ```spl
  index=sysmon EventCode=1 Image="*powershell.exe" | join host [search index=zeek sourcetype=bro_conn dest_port IN (80, 443)] | stats count by src_ip, dest_ip | where count > 3
  ```
  - Alerts for PowerShell executions with HTTP/HTTPS connections.
- **Alert on Velociraptor suspicious autorun entries:**
  ```spl
  index=velociraptor sourcetype=velociraptor_artifact Artifact="Windows.Sysinternals.Autoruns" ImagePath IN ("*powershell.exe", "*cmd.exe") | stats count by host, ImagePath | where count > 2 | table host, ImagePath, count
  ```
  - Triggers for hosts with multiple suspicious autorun entries.

**Alert Tip:**
- Set **Throttle** to avoid alert spam (e.g., “Suppress for 1 hour after triggering”).

## 7. Reports

- Reports are scheduled searches for summaries, trends, or compliance.
- Useful for daily/weekly/monthly insights or audit requirements.

**Steps:**
1. Run a search.
2. Click **Save As → Report**.
3. Set a title and schedule (e.g., daily at 8 AM).
4. Choose delivery: Add to a dashboard, email as PDF, or export as CSV.

**Example Commands for Reports:**
- **Daily report of top 10 rare DNS domains:**
  ```spl
  index=zeek sourcetype=bro_dns | stats count by query, src_ip | sort count | head 10 | table src_ip, query, count
  ```
  - Lists the 10 least frequent DNS queries with source IPs.
- **Weekly report of top processes by host:**
  ```spl
  index=sysmon EventCode=1 | stats count by host, Image | sort -count | head 20 | table host, Image, count
  ```
  - Summarizes the top 20 processes executed per host.
- **Monthly report of Velociraptor recent file access:**
  ```spl
  index=velociraptor sourcetype=velociraptor_artifact Artifact="Windows.FileSystem.RecentFiles" FilePath IN ("*.ps1", "*.bat") | stats count by host, FilePath, User | sort -count | table host, FilePath, User, count
  ```
  - Tracks access to suspicious file types for compliance audits.

**Report Tip:**
- Use `| eval` to format fields, e.g., `| eval time=strftime(_time, "%Y-%m-%d %H:%M:%S")`.

## Capstone: Hands-On Splunk Hunting Exercise

**Objective:** Perform a threat hunt in Splunk to detect a simulated attacker performing reconnaissance and lateral movement.

**Scenario:**
- An attacker may be using PowerShell for reconnaissance and connecting to external IPs for command-and-control (C2).

**Tasks:**
1. **Hypothesis 1: Suspicious PowerShell Execution**
   - Search for PowerShell processes with unusual command-line arguments.
   - Command:
     ```spl
     index=sysmon EventCode=1 Image="*powershell.exe" CommandLine IN ("*whoami*", "*netstat*", "*Invoke-WebRequest*") | table _time, host, User, CommandLine, ParentImage
     ```
   - **Output:** Table of PowerShell executions with time, host, user, command, and parent process.

2. **Hypothesis 2: Correlate with Network Activity**
   - Check if hosts running suspicious PowerShell made HTTP/HTTPS connections.
   - Command:
     ```spl
     index=sysmon EventCode=1 Image="*powershell.exe" | join host [search index=zeek sourcetype=bro_conn dest_port IN (80, 443)] | stats count by host, dest_ip, dest_port | table host, dest_ip, dest_port, count
     ```
   - **Output:** Hosts with PowerShell activity and their external connections.

3. **Hypothesis 3: Check for Velociraptor Autorun Artifacts**
   - Look for suspicious autorun entries from the same hosts.
   - Command:
     ```spl
     index=velociraptor sourcetype=velociraptor_artifact Artifact="Windows.Sysinternals.Autoruns" ImagePath IN ("*.exe", "*.ps1") | stats count by host, ImagePath | sort -count | table host, ImagePath, count
     ```
   - **Output:** Hosts with executable or script autorun entries.

4. **Create a Dashboard Panel**
   - Combine searches into a dashboard.
   - Example: Timechart of Velociraptor process executions:
     ```spl
     index=velociraptor sourcetype=velociraptor_artifact Artifact="Windows.EventLogs.ProcessExecution" ProcessName="powershell.exe" | timechart span=1h count by host
     ```
   - Save as a panel named “PowerShell Activity by Host.”

5. **Set Up an Alert**
   - Alert for hosts with more than 3 Velociraptor process executions followed by HTTP connections in 10 minutes:
     ```spl
     index=velociraptor sourcetype=velociraptor_artifact Artifact="Windows.EventLogs.ProcessExecution" ProcessName="powershell.exe" | join host [search index=zeek sourcetype=bro_conn dest_port IN (80, 443)] | stats count by host | where count > 3
     ```
   - Configure to email the instructor when triggered.

**Deliverable:**
- Submit a screenshot of the dashboard and alert configuration, with a brief explanation of findings (e.g., “Host X showed PowerShell running `whoami` and connecting to IP Y, with a Velociraptor autorun entry for a suspicious executable.”).

**Instructor Notes:**
- Provide a Splunk instance with sample Sysmon, Zeek, Suricata, and Velociraptor data.
- Encourage students to modify SPL queries (e.g., time ranges) to explore variations.
- Discuss findings as a class to reinforce correlation techniques.