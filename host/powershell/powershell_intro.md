# Introduction to PowerShell

## Why are we learning about PowerShell again?

- **Low impact**
    - Native to Windows – no install required.
    - Do not need to touch the disk (much).
- **Faster than Command Prompt**
- **Can be used for automation**
- **One of the few tools we have available to "hunt" during DCI.**

---

# Structure of commands

`Verb-Noun -Parameter Value (-Parameter Additional)`

![Pasted image 20250915111917.png](65school/host/powershell/attachments/Pasted%20image%2020250915111917.png)

---

## Upgrading Commands

One of the most important skills when hunting with PowerShell is learning how to **upgrade** basic commands into more powerful pipelines.

We’ll use **process hunting** as our example.
### Start simple

See everything that’s running.

`Get-Process`
### Refine

Only show the fields you care about.

`Get-Process | Select-Object Name, Id, Path`

### Filter

Look only for a specific process, like PowerShell.

`Get-Process | Where-Object { $_.Name -like "powershell*" }`

### Sort / Limit

Find the top 5 memory-hungry processes.

`Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5 Name, Id, WorkingSet`

### Export

Save results for later analysis.

`Get-Process | Select-Object Name, Id, Path, CPU |   Export-Csv -Path .\process_list.csv -NoTypeInformation`

Export as JSON (useful for scripts/automation):

`Get-Process | Select-Object Name, Id, Path |   ConvertTo-Json | Out-File .\process_list.json`

---


# Hunting with PowerShell

## Basic Hunting

- System Information
- User Accounts
- Processes
- Services
- Network Information
- Persistence
- File Info
- Installed Programs
- Event Logs
- Execution Artefacts


---

## System Information

### Scenario

You've been asked to perform a hunt on a Windows Network.  
You (Host Analyst) have been tasked with performing a baseline of the network.  
This requires you to confirm all the host names and their versions of Windows.

### Answers

**Basic:**

```powershell
systeminfo
```

```powershell
hostname
```

**Upgraded:**

```powershell
Get-ComputerInfo | Select-Object CsName, WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer
```

---

## 👤 User Accounts

### Scenario

It's five days into the hunt, someone reports a user performing suspicious activity. You check the baseline and see that the user account was present during the baseline. This doesn't mean that the user account is clear.

The account is a domain account.

### Answers

**Basic:**

```powershell
net user <username> /domain
```

**Upgraded:**

```powershell
Get-ADUser <username> -Properties MemberOf | Select-Object SamAccountName, MemberOf
```

```powershell
Get-ADUser <username> -Properties LastLogonDate | Select-Object SamAccountName, LastLogonDate
```

---

## ⚙️ Processes & Services

### Scenario

You see PowerShell.exe running on a host but are unsure if it's normal for that process to be running.

List all running processes.  
Check process metadata including paths and arguments.

**Questions to ask yourself:**

- Does it make sense for PowerShell to be running?
    
- Is it explainable?
    

### Answers

**Basic:**

```powershell
Get-Process
```

```powershell
Get-Process powershell
```

**Upgraded:**  
Path to executable:

```powershell
Get-Process powershell | Select-Object Id, Path
```

Command line:

```powershell
Get-WmiObject Win32_Process -Filter "Name='powershell.exe'" |
  Select-Object ProcessId, ExecutablePath, CommandLine
```

Parent Process:

```powershell
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
  Select-Object ProcessId, ParentProcessId, CommandLine
```

---

## 🌐 Network & Remote Connections

### Scenario

A network analyst has asked you to confirm that the network traffic they're seeing is coming from the host you're looking at, and if there's anything that could be causing that traffic (e.g., malicious process).

### Answers

**Basic:**

```cmd
netstat -ano
```

```cmd
netstat -bano
```

**Upgraded:**

```powershell
Get-NetTCPConnection -State Established |
  Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess
```

---

## 🔒 Persistence

### Scenario

Your team located some malware and are devising a remediation plan.  
You need to make sure you remove all the persistence mechanisms for the malware.

### Answers

**Basic:**

```cmd
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run
reg query HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run
```

```cmd
schtasks /query /fo LIST /v
```

**Upgraded:**

```powershell
Get-ScheduledTask | Select-Object TaskName, TaskPath, State
```

---

## 📂 File System

### Scenario

During your hunt, you want to check for suspicious files that may have been dropped by malware, scripts used for persistence, or tools staged by an attacker.

### Answers

**Basic:**

```powershell
Get-ChildItem -Path "C:\Users\$env:USERNAME\AppData" -Recurse -File | Select-Object FullName

```

**Upgraded:**  
Find recently created files (last 7 days):

```powershell
Get-ChildItem -Path C:\Users\ -Recurse -File |
  Where-Object { $_.CreationTime -gt (Get-Date).AddDays(-7) } |
  Select-Object FullName, CreationTime
```

Find executables/scripts in unusual locations:

```powershell
Get-ChildItem -Path C:\Users\ -Recurse -Include *.exe,*.dll,*.bat,*.ps1 -ErrorAction SilentlyContinue
```

---

## Installed Programs
### Scenario

You want to confirm what software is installed on a host to look for potentially unwanted or malicious programs.

### Answers

**Basic:**

`Get-WmiObject Win32_Product`

**Upgraded (faster, cleaner):**

`Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |   Select-Object DisplayName, DisplayVersion, Publisher, InstallDate`


---

## Event Logs

### Scenario

You suspect suspicious logon activity and want to check the **Security** event logs for evidence.

### Answers

**Basic:**

`Get-EventLog -LogName Security`

**Upgraded (logon events only):**

`Get-EventLog -LogName Security -InstanceId 4624 -Newest 10 |   Select-Object TimeGenerated, ReplacementStrings`

**Upgraded (filter with Get-WinEvent):**

`Get-WinEvent -LogName Security -FilterHashtable @{Id=4624} |   Select-Object TimeCreated, Id, Message -First 20`

---

## Execution Artefacts

### Scenario

You want to see what has been executed on the host to look for suspicious commands or programs.

### Answers

**Basic (Prefetch — requires admin):**

`Get-ChildItem C:\Windows\Prefetch`

**Upgraded (show file names + creation time):**

`Get-ChildItem C:\Windows\Prefetch |   Select-Object Name, CreationTime, LastWriteTime`

**Upgraded (ShimCache / AppCompatCache — from registry):**

`Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache`

---
#powershell_activity1


# PowerShell Remoting

## ** NEED TO USE RANGE**

# PowerShell Scripting

### Learning Objectives

- Understand how simple PowerShell scripts can be used for **live hunting** and reconnaissance in restricted environments.
    
- Practice core scripting concepts: **variables, loops, conditionals, objects, and exporting**.
    
- Build a lightweight PowerShell script that you could use to help you during a hunt. 

### Prerequisites & Materials

- Lab VM or workstation with PowerShell (Windows 10/11). **Administrator rights recommended for full functionality.**
- Text editor (PowerShell ISE, VS Code) and access to a classroom network or isolated lab subnet (e.g., 192.168.56.0/24 or 10.1.21.0/24).
- All activities should be run in an isolated lab environment 

---

## Step 1: Variables & Loops

### Ping Sweep Example

```powershell
$network = "192.168.1"
foreach ($i in 1..20) {
  $ip = "$network.$i"
  Write-Host "Pinging $ip..."
}
```

**Concepts:** variables, string interpolation, iteration.

### Alternative Example — Process Check Loop (Remote)

```powershell
$hosts = "host1","host2","host3"
foreach ($h in $hosts) {
  Write-Host "Collecting processes from $h..."
  try {
    $procs = Invoke-Command -ComputerName $h -ScriptBlock { Get-Process | Select-Object Name,Id } -ErrorAction Stop
    foreach ($p in $procs) {
      [PSCustomObject]@{Host=$h; Name=$p.Name; Id=$p.Id}
    }
  } catch { Write-Warning "Failed to contact $h" }
}
```

**Concepts:** loops, remote execution, object output.

### Alternative — Local version (no remoting)

Use this when remoting is not available; behavior mirrors the remote collection but runs against the local machine.

```powershell
$hosts = 'localhost'
foreach ($h in $hosts) {
  Write-Host "Collecting processes from local machine..."
  $procs = Get-Process | Select-Object Name,Id
  foreach ($p in $procs) {
    [PSCustomObject]@{Host=$h; Name=$p.Name; Id=$p.Id}
  }
}
```

```powershell
$hosts = "host1","host2","host3"
foreach ($h in $hosts) {
  Write-Host "Collecting processes from $h..."
  try {
    $procs = Invoke-Command -ComputerName $h -ScriptBlock { Get-Process | Select-Object Name,Id } -ErrorAction Stop
    foreach ($p in $procs) {
      [PSCustomObject]@{Host=$h; Name=$p.Name; Id=$p.Id}
    }
  } catch { Write-Warning "Failed to contact $h" }
}
```

### Local Version — Process Check (Single Machine)

```powershell
$procs = Get-Process | Select-Object Name,Id
foreach ($p in $procs) {
  [PSCustomObject]@{Host=$env:COMPUTERNAME; Name=$p.Name; Id=$p.Id}
}
```

**Concepts:** loops, object output, safe to test locally.

---

## Step 2: Adding a Test

### Ping Test Example

```powershell
if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
  "$ip is UP"
} else {
  "$ip is DOWN"
}
```

**Concepts:** conditionals, ICMP test.

### Alternative Example — Suspicious Process Check (Remote)

```powershell
$hosts = "host1","host2"
foreach ($h in $hosts) {
  try {
    $found = Invoke-Command -ComputerName $h -ScriptBlock {
      Get-Process | Where-Object { $_.ProcessName -match 'mimikatz|enc' }
    }
    if ($found) { Write-Warning "$h suspicious process found" }
    else { Write-Host "$h clean" }
  } catch { Write-Host "No access to $h" }
}
```

**Concepts:** remote execution, regex filters, error handling.

### Alternative — Local version (simpler)

This local version searches processes on the local machine for suspicious patterns. Students can run and validate without networked hosts.

```powershell
$patterns = 'mimikatz','-enc'
$found = Get-Process | Where-Object { $p = $_.ProcessName; $patterns | ForEach-Object { $p -match $_ } | Where-Object { $_ } }
if ($found) { $found | Select-Object Name,Id } else { Write-Host 'No suspicious local processes found' }
```

```powershell
$hosts = "host1","host2"
foreach ($h in $hosts) {
  try {
    $found = Invoke-Command -ComputerName $h -ScriptBlock {
      Get-Process | Where-Object { $_.ProcessName -match 'mimikatz|enc' }
    }
    if ($found) { Write-Warning "$h suspicious process found" }
    else { Write-Host "$h clean" }
  } catch { Write-Host "No access to $h" }
}
```

### Local Version — Suspicious Process Check

```powershell
$found = Get-Process | Where-Object { $_.ProcessName -match 'powershell' }
if ($found) {Write-Warning "Suspicious process found locally" }
else { Write-Host "No suspicious process" }
```

**Concepts:** regex filters, simple conditionals.

---

## Step 3: Collecting Results into Objects

### Ping Sweep Results

```powershell
$results += [PSCustomObject]@{IP=$ip; Status=$status}
```

**Concepts:** objects, structured results.

### Alternative Example — Event Log Counts (Remote)

```powershell
$summary = @()
foreach ($h in "host1","host2") {
  try {
    $count = (Get-WinEvent -ComputerName $h -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 50).Count
    $summary += [PSCustomObject]@{Host=$h; FailedLogons=$count}
  } catch {
    $summary += [PSCustomObject]@{Host=$h; FailedLogons='Error'}
  }
}
$summary
```

### Local Version — Event Log Counts

```powershell
$count = (Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 50).Count
[PSCustomObject]@{Host=$env:COMPUTERNAME; FailedLogons=$count}
```

**Concepts:** simple metric collection.

---

## Step 4: Exporting Results

### Ping Sweep Export

```powershell
$results | Export-Csv -Path ping.csv -NoTypeInformation
```
-NoTypeInformation stops PowerShell from default adding a line at the top of the output
**Concepts:** persistence, analyst handoff.

### Alternative Example — Process Inventory Export (Local)

```powershell
$processes = Get-Process | Select-Object Name,Id
$processes | Export-Csv -Path processes.csv -NoTypeInformation
```

**Concepts:** structured export.

---

## Step 5: Optional Checks

### Ping Sweep + Port Example (Optional)

```powershell
if (Test-NetConnection -ComputerName $ip -Port 445 -InformationLevel Quiet) {
  "$ip has port 445 open"
}
```

**Concepts:** simple port check.

### Alternative Example — Netstat Snapshot (Local)

```powershell
Get-NetTCPConnection | Where-Object { $_.State -eq 'Listen' } | Select-Object LocalAddress,LocalPort,OwningProcess
```

**Concepts:** list listening ports, safe enrichment.

---

## Additional Alternatives (Ideas for Projects)

- **Scheduled Tasks:** `Get-ScheduledTask | Where-Object { $_.Actions -match 'powershell' }`
    
- **Autoruns / Registry Run keys:** `Get-ItemProperty 'HKLM:\...\Run'`
    
- **File Hashing:** `Get-ChildItem C:\Temp -Recurse | Get-FileHash`
    
- **DNS Cache:** `Get-DnsClientCache`
    
- **Active Connections:** `Get-NetTCPConnection | Group-Object RemoteAddress`
    

## Capstone: Assemble your own script


Create a PowerShell script which preforms something which you might consider **useful for a hunt scenario**. Output your results so that they're formatted similar to examples above and so that it is saved as a file. 
