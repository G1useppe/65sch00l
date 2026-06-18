
# PowerShell Remoting

## ** FIX **
Need range to accurately test this and remote use of scripts.

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
