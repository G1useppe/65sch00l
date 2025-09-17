## What is Velociraptor?

Velociraptor is an open-source **endpoint visibility and digital forensic tool**. It acts as a **host-based agent** that allows security teams to collect, monitor, and query forensic artefacts across endpoints in real time. By deploying Velociraptor agents across systems, organizations can quickly investigate incidents, detect malicious activity, and feed telemetry back into a **Security Information and Event Management (SIEM)** system.

---

## How Do We Use Velociraptor?

Velociraptor functions as an **endpoint agent**. Once installed on endpoints, it communicates back to a central server and provides detailed forensic data. This data can then be aggregated and forwarded to a SIEM for further correlation and alerting.

### High-Level Workflow

1. **Environment setup:** Hunt server will be connected to client network.
	1. Either at the **Firewall**(likely) or **Switch**(Preferred, no firewall rules)
2. **Deployment**: Velociraptor agents are installed on endpoints.
3. **Collection**: Agents continuously or on-demand collect artefacts.
4. **Querying**: Analysts query artefacts through the Velociraptor GUI.
5. **Integration**: Results can be fed into a SIEM for centralized visibility.


![](attachments/Pasted%20image%2020250917104058.png)
- 

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

- **Generate Client Config**
    - On the Velociraptor server, create a `client.config.yaml` that contains server address, TLS certs, and keys.
    - Embed this config into the agent installer.
        
- **Build Installers**
    - Create small agent packages (MSI/EXE for Windows, binaries for Linux/macOS).
    - These come preconfigured to check in with your hunt server.
	    
- **Host agent**
	- HTTP Server on velociraptor server can host the agent which can be retrieved by endpoints. eg. `wget http://Velociraptorserver:port/velociraptorinstall.exe`
        
- **Distribute Agents**
    - **Enterprise tools**: Group Policy, Ansible ( Discuss with local defenders)
    - **Scripts**: PowerShell or shell scripts for bulk or ad-hoc installs.
    - **Manual installs**: For isolated or high-value systems.
        
- **Run as a Service**
    - Agents install as a background service/daemon so they persist after reboots.
    
- **Verify Check-in**
    - Confirm endpoints appear in the Velociraptor GUI under _Clients_.
    - From there, start hunts or queries.

### 3. Navigating the Velociraptor GUI

- **Dashboard**: Overview of connected clients and ongoing hunts.
- **Hunts**: Large-scale data collection campaigns across many endpoints.
- **Notebooks**: Interactive workspaces for storing queries, notes, and results.
	- If you need to quickly check the output of a hunt - check here.
- **Artefact Repository**: Library of artefacts to pull from endpoints.

### 4. What Artefacts to Pull

Some of the most common and useful artefacts include:

- **System Information**: OS version, hostname, uptime.
- **Process Listings**: Active processes and command-line arguments.
- **Persistence Mechanisms**: Registry run keys, scheduled tasks.
- **File System Data**: Recently modified files, prefetch data, temp files.
- **Network Connections**: Active connections, listening ports.
- **Browser Artefacts**: History, cookies, and cached content.