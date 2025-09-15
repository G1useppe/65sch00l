## Config
Load the Windows VM  
```
Username: hcmadmin
Password: Password1
```
## Rules:

- Only PowerShell is to be used

**Do not read any of the artefacts source code (its a PowerShell activity not an incident response)**
**(eg. do not use "cat file.xx")**

1. **Flag Hunt**
    
    - Identify all the flags on the system.
        
    - Provide the commands you used to find them.
        
    
    1. =
        
    2. =
        
    3. =
        
2. **Process Discovery**
    
    - Identify any **suspicious processes** running.
        
    - Provide the commands you used.
        
    - Bonus: capture the **full command line** that launched the process.
        
3. **Parent Process Investigation**
    
    - Determine which process launched the suspicious one.
        
    - Provide the commands you used to correlate parent → child.
        
4. **Persistence – Registry**
    
    - Check if persistence is being maintained via registry.
        
    - Which keys did you find, and what command(s) did you use?
        
5. **Persistence – Scheduled Task**
    
    - Check if persistence is being maintained via Scheduled Task.
        
    - Which task did you find, and what command(s) did you use?
        
6. **File System Artifacts**
    
    - Identify any suspicious files related to this activity (e.g., scripts in `%TEMP%`).
        
    - Provide the commands you used.
        
7. **Network Connections (Optional)**
    
    - Does the suspicious process create any network connections?
        
    - Which commands would you use to verify this?
        
8. **Process Resource Usage**
    
    - How much CPU or memory is the suspicious process using?
        
    - Provide the commands you used.
        
9. **Correlation**
    
    - Based on your findings, list all artifacts (files, processes, registry keys, tasks).
        
    - Show how they are linked together.
        
10. **Eradication Plan**
    

- What exact commands would you use to remove:
    
    - The running process
        
    - The registry persistence
        
    - The scheduled task
        
    - All dropped artifacts (flags, scripts)














