<h1>Remote Labs</h1>

**Enable PSRemoting on both VM annd local Machine**
```
Enable-PSRemoting -Force
Set-Service WinRM -StartupType Automatic
Start-Servcie WinRM
Set-Item WSMan:\localhost\Client\TrustedHosts –Value *
```
**Test Windows Remote Management is up on both machines**
```
Test-WSMan -computerName <ComputerName>
```
**Running a remote command on local machine**
```
Invoke-Command -ComputerName <ComputerName> -Credential (Get-Credential) -ScriptBlock {<Script>}
```

