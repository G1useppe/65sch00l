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

```cmd
dir C:\Users\%USERNAME%\AppData /s /b /a:-d
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

## 🔄 Combining Commands

- Use **`| Select-Object`** to narrow fields.
    
- Use **`| Where-Object`** to filter results.
    
- Example: Find only PowerShell processes and show their command lines:
    
    ```powershell
    Get-WmiObject Win32_Process -Filter "Name='powershell.exe'" |
      Select-Object ProcessId, CommandLine
    ```
    

---

## 🏁 Capstone

- Apply everything learned (system info, accounts, processes, services, network, persistence, file hunts).
    
- Upgrade from **basic commands** to **refined hunting pipelines**.