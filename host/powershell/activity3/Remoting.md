# Remoting

## How to enable PSRemoting

For non-domain, run:

```powershell
Set-Item WSMan:\localhost\Client\TrustedHosts -Value *
```

```powershell
Enable-PSRemoting -Force
Set-Service WinRM -StartupType Automatic
Start-Service WinRM
```

## Testing Remoting

Testing WinRM is turned on.

```powershell
Test-WSMan -ComputerName <ComputerName>
```

## Remote Execution Options

Execute a one-off command:

```powershell
Invoke-Command -ComputerName <ComputerName> -ScriptBlock {<Script>}
```

Execute a one-off command with credentials:

```powershell
Invoke-Command -ComputerName <ComputerName> -Credential (Get-Credential) -ScriptBlock {<Script>}
```

## Run a script remotely

Execute a one-off script:

```powershell
Invoke-Command -ComputerName <computername> -FilePath <Full path to *.ps1>
```

If credentials are required:

```powershell
Invoke-Command -ComputerName <computername> -FilePath <Full path to *.ps1> -Credential (Get-Credential)
```

## Interactive shell like SSH

Enter a PSSession:

```powershell
Enter-PSSession -ComputerName <ComputerName>
```

Exit a PSSession:

```powershell
Exit-PSSession
```

## Background Sessions

Creating, listing, entering and removing sessions:

```powershell
# Create session
$session = New-PSSession -ComputerName <computername>

# Many sessions
$session = New-PSSession -ComputerName <PC1, PC2, PC3>

# List active sessions
Get-PSSession

# Enter a session by ID
Enter-PSSession -Id <ID number>

# Remove all sessions
Get-PSSession | Remove-PSSession
```

## Immersive Labs

PowerShell Basics: Ep.11 – Remoting
