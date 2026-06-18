# Commandlets

## Types of commandlets

- `Get-ComputerInfo` – OS and hardware info
- `Get-LocalUser` – local user accounts
- `Get-Process` – Running Processes
- `Get-Service` – status of windows services
- `Get-NetIPConfigurations` – IPs, interfaces, DNS
- `Get-ScheduledTask` – scheduled tasks
- `Get-EventLog` – Classic logs
- `Get-History` – Current PowerShell session history

## Get-Member

Able to see the Methods, Properties in a class.

```powershell
Get-Service | Get-Member
```

## How to set variables as commandlets

Can set a variable as a commandlet and then execute a method within the commandlet.

```powershell
$service = Get-Service -Name DcomLaunch
$service.Refresh()
```

```powershell
$service = Get-Service
$service.Name
```

Example members exposed on the object:

```
Name        AliasProperty   Name = ServiceName
Pause       Method          void Pause()
Refresh     Method          void Refresh()
Start       Method          void Start(), ...
Stop        Method          void Stop()
```

## Select-Object

Able to select the property of an Object and output it in the command line.

```powershell
$service = Get-Service
$service | Select-Object Name, StartType, CanShutdown
```

## Where-Object

Select a property and then further filter your output.

```powershell
$service = Get-Service
$service | Select-Object Name, StartType, CanShutdown | Where-Object {$_.Name -eq "ALG"}
```

## Get-CimInstance vs Get-WMIObject

Able to query the Windows database through the many classes it has.

- To view all the classes run `Get-CimClass`
- `Get-WMIObject` is an older version, `Get-CimInstance` is modern

## Get-CimInstance

To view all the columns in a class — can get more in-depth detail about the class.

```powershell
# 1) Get the class definition
$c = Get-CimClass -ClassName Win32_Process

# 2) List all properties
$c.CimClassProperties | Select-Object Name
```

```powershell
Get-CimInstance -ClassName Win32_Process | Select-Object ProcessId, Name, CommandLine, ExecutablePath, ParentProcessId
```

## Get-WMIObject

- To view all the classes
- To get process information

```powershell
Get-WmiObject -List
```

```powershell
Get-WmiObject -Class Win32_Process | Select-Object PSComputerName, Name, CommandLine
```

## Lab — make PowerShell commands

- `Get-EventLog`
  - Tell me how many incorrect logons have occurred on the machine you are using
  - Check if event logs have been cleared
- `Get-Service` – Tell me how many services are automatic

## Lab Solution

**Service Lab**

```powershell
$service = Get-Service
$service | Where-Object {$_.StartType -eq "Automatic"} | Measure-Object -Line
```

**Event Log Lab**

```powershell
$EventLogs = Get-EventLog -LogName Security | Where-Object {$_.EventID -eq 4625} | Measure-Object -Line
$EventLogs
```

## Lab table-top exercise

- You have been told a computer is running slow and a member did click on a suspicious link.
  - (What PowerShell commandlets will you run!!)
- Upon further investigation you find a malicious process.
  - (What PowerShell commandlets will you run!!)
- What mitigation steps will you run to deem the computer safe for usage?
