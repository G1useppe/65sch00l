<h1>Remoting</h1>
<br>
This lesson is on how to remote to other machines in Windows. No real theory required just need to know the commands to remote.

<br>
<br>

**Enable PSRemoting**
<br>
In order for you to remote into other machines you need to enable it on your machine and the other ones. 
```
Enable-PSRemoting -Force
Set-Service WinRM -StartupType Automatic
Start-Service WinRM
```

**Test your remoting is ready**
```
Test-WSMan -ComputerName <ComputerName>
```

**Remote Execution**
Execute a One-Off Command
<br>
```
Invoke-Command -ComputerName <ComputerName> -ScriptBlock {<Script>}
```

Execute a command with credentials
```
Invoke-Command -ComputerName <ComputerName> -Credential (Get-Credential) -ScriptBlock {<Script>}
```

**Interactive shell**
<br>
Entering a PSSession (Similar to an SSH session)
```
Enter-PSSession -ComputerName <ComputerName>
```
<br>
How to exit a PSSession 
<br>
```
Exit-PSSession
```

