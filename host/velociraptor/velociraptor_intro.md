## What is Velociraptor?

Velociraptor is an open-source **endpoint visibility and digital forensic tool**. It acts as a **host-based agent** that allows security teams to collect, monitor, and query forensic artefacts across endpoints in real time. By deploying Velociraptor agents across systems, organizations can quickly investigate incidents, detect malicious activity, and feed telemetry back into a **Security Information and Event Management (SIEM)** system.

---

## How Do We Use Velociraptor?

Velociraptor functions as an **endpoint agent**. Once installed on endpoints, it communicates back to a central server and provides detailed forensic data. This data can then be aggregated and forwarded to a SIEM for further correlation and alerting.

### High-Level Workflow

1. **Deployment**: Velociraptor agents are installed on endpoints.
    
2. **Collection**: Agents continuously or on-demand collect artefacts.
    
3. **Querying**: Analysts query artefacts through the Velociraptor GUI.
    
4. **Integration**: Results can be fed into a SIEM for centralized visibility.
    

_(Insert diagram here showing endpoints → Velociraptor server → SIEM)_

---

## What Do We Need to Know About Velociraptor?

### 1. Searching for Artefacts

- Velociraptor uses **VQL (Velociraptor Query Language)** to query forensic artefacts.
- Artefacts can be searched for by predefined categories (e.g., processes, registry keys, event logs).
- Analysts can craft queries or use community-contributed artefacts for common investigations.
- Key use cases:
    - Searching for persistence mechanisms.
    - Identifying suspicious processes.
    - Extracting forensic artefacts such as Prefetch files or browser history.

### 2. Installing Velociraptor on Endpoints

- Installation requires generating a **client configuration file** from the Velociraptor server.
- The agent binary is then distributed to endpoints (via GPO, SCCM, Intune, etc.).
- Once launched, the agent connects securely back to the server.
- Supports Windows, Linux, and macOS.
### 3. Navigating the Velociraptor GUI

- **Dashboard**: Overview of connected clients and ongoing hunts.
- **Hunts**: Large-scale data collection campaigns across many endpoints.
- **Notebooks**: Interactive workspaces for storing queries, notes, and results.
	- If you need to quickly check the output of a hunt - check here.
- **Artefact Repository**: Library of artefacts to pull from endpoints.
- **Results View**: Collected artefacts can be viewed, filtered, and exported.

### 4. What Artefacts to Pull

Some of the most common and useful artefacts include:

- **System Information**: OS version, hostname, uptime.
- **Process Listings**: Active processes and command-line arguments.
- **Persistence Mechanisms**: Registry run keys, scheduled tasks.
- **File System Data**: Recently modified files, prefetch data, temp files.
- **Network Connections**: Active connections, listening ports.
- **Browser Artefacts**: History, cookies, and cached content.