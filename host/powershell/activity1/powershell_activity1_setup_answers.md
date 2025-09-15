### Setup Script:
place this in 
```
C:\users\hcmadmin\appdata\local\temp\run4eva.py
```


```python
import time
import os
import subprocess
import winreg

# 1. Write the PowerShell script to drop a decoy flag on Desktop
ps_script = r'''
$desktop = [Environment]::GetFolderPath("Desktop")
$path = Join-Path $desktop "flag.txt"
"Flag dropped at $(Get-Date)" | Out-File -FilePath $path -Append
'''
script_path = os.path.join(os.environ["TEMP"], "drop_flag.ps1")
with open(script_path, "w") as f:
    f.write(ps_script)

# 2. Install Scheduled Task (decoy persistence)
task_flag = os.path.join(os.environ["TEMP"], "task_installed.flag")
if not os.path.exists(task_flag):
    task_name = "FlagDropper"
    schtask_cmd = f'''SCHTASKS /Create /SC MINUTE /MO 3 /TN "{task_name}" /TR "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File {script_path}" /F'''
    subprocess.run(schtask_cmd, shell=True)

    with open(task_flag, "w") as f:
        f.write("installed")

# 3. Real persistence (registry Run key)
pythonw_path = "pythonw.exe"
script_self = os.path.abspath(__file__)
run_key_name = "run4eva"

try:
    with winreg.OpenKey(winreg.HKEY_CURRENT_USER,
                        r"Software\Microsoft\Windows\CurrentVersion\Run",
                        0, winreg.KEY_SET_VALUE) as key:
        winreg.SetValueEx(key, run_key_name, 0, winreg.REG_SZ,
                          f'{pythonw_path} "{script_self}"')
except Exception:
    pass

# 4. Hidden "real" flag file (NOT on Desktop)
real_flag = os.path.join(os.environ["TEMP"], "real_flag.txt")
if not os.path.exists(real_flag):
    with open(real_flag, "w") as f:
        f.write("This is the real flag! Catch me if you can!\n")

# 5. Keep process alive forever
while True:
    time.sleep(60)

```

### Run this 
```
pythonw.exe "C:\Users\hcmadmin\AppData\Local\Temp\run4eva.py"
```



## Cleanup script

```python
Write-Host "[*] Starting cleanup..." -ForegroundColor Yellow

# 1. Kill malicious process
Write-Host "[*] Killing pythonw.exe if running..."
Get-Process pythonw -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# 2. Remove persistence - Registry Run key
Write-Host "[*] Removing Run key persistence..."
if (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run") {
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "run4eva" -ErrorAction SilentlyContinue
}

# 3. Remove persistence - Scheduled Task
Write-Host "[*] Removing scheduled task persistence..."
if (Get-ScheduledTask -TaskName "FlagDropper" -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName "FlagDropper" -Confirm:$false
}

# 4. Remove dropped scripts
Write-Host "[*] Deleting implant scripts..."
$files = @(
    "$env:TEMP\run4eva.py",
    "$env:TEMP\drop_flag.ps1"
)
foreach ($file in $files) {
    if (Test-Path $file) {
        Remove-Item $file -Force -ErrorAction SilentlyContinue
    }
}

# 5. Remove flag files (Desktop + Temp + anywhere else under Users)
Write-Host "[*] Searching and removing flag files..."
$flags = Get-ChildItem -Path "C:\Users" -Filter "*flag*.txt" -File -Recurse -Force -ErrorAction SilentlyContinue
foreach ($flag in $flags) {
    Remove-Item $flag.FullName -Force -ErrorAction SilentlyContinue
}

Write-Host "[+] Cleanup complete." -ForegroundColor Green

```


## Answers

1. Identify the suspicious "flag" on the system and provide the command used to get it ( hint, it isn't "flag.txt" but it might be close to that)
There is 3 flags 

flag.txt.txt
theflag.txt
real_flag.txt

fake: flag.txt
```
Get-ChildItem -Path C:\ -Include '*flag*.txt' -File -Recurse -Force -ErrorActio
n SilentlyContinue
```




1. **Flag Hunt**
    

```
Get-ChildItem -Path C:\ -Include '*flag*.txt' -File -Recurse -Force -ErrorActio
n SilentlyContinue
```

2. **Process Discovery**
    

`Get-Process pythonw | Select-Object Id, Path Get-WmiObject Win32_Process -Filter "Name='pythonw.exe'" | Select-Object ProcessId, CommandLine`

3. **Parent Process Investigation**
    

`Get-CimInstance Win32_Process -Filter "Name='pythonw.exe'" |   Select-Object ProcessId, ParentProcessId, CommandLine Get-Process -Id <ParentProcessId>`

4. **Persistence – Registry**
    

`Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run | Select-Object run4eva`

5. **Persistence – Scheduled Task**
    

`Get-ScheduledTask | Where-Object TaskName -like '*FlagDropper*' Get-ScheduledTask -TaskName 'FlagDropper' | Select-Object TaskName, Actions, Triggers, State`

6. **File System Artifacts**
    

`Get-ChildItem -Path $env:TEMP -File -Force |   Where-Object { $_.Name -match 'run4eva|drop_flag|real_flag' }`

7. **Network Connections**
    

`$pid = (Get-Process pythonw).Id Get-NetTCPConnection -OwningProcess $pid`

8. **Process Resource Usage**
    

`Get-Process pythonw | Select-Object Name, Id, CPU, WorkingSet`

9. **Correlation**
    

- Process:
    

`Get-Process pythonw`

- Registry:
    

`Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run`

- Task Scheduler:
    

`Get-ScheduledTask | Where-Object TaskName -like '*FlagDropper*'`

- Files:
    

`Get-ChildItem $env:TEMP -Filter '*flag*.txt' -Force`

10. **Eradication Plan**
    

`Stop-Process -Name pythonw -Force Remove-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name 'run4eva' Unregister-ScheduledTask -TaskName 'FlagDropper' -Confirm:$false Remove-Item "$env:TEMP\run4eva.py","$env:TEMP\drop_flag.ps1","$env:TEMP\real_flag.txt","$env:USERPROFILE\Desktop\flag.txt" -Force`

---

👉 Do you want me to format this into a **student handout + instructor key** (two separate versions), so