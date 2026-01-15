## PowerShell: Checking Security Event Logs

### 1. Get all Security event logs
```powershell
$EventLogs = Get-EventLog -LogName Security

$FailedLogons = $EventLogs | Where-Object {$_.EventID -eq 4625} | Measure-Object -Line

$ClearedLogs = $EventLogs | Where-Object {$_.EventID -eq 1102} | Measure-Object -Line


```

## PowerShell: Count Automatic Services
### 1. Get all services
```powershell
$service = Get-Service

$autoServices = $service | Where-Object {$_.StartType -eq "Automatic"} | Measure-Object -Line
```
