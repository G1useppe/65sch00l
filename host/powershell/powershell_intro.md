

# Introduction to PowerShell
## Why are we learning about PowerShell again?
- Low impact
	- Native to Windows - no install required.
	- Do not need to touch the disk (much)
- Faster than Command Prompt
- Can be used for automation
- Its on of the few tools we have available to "hunt" during DCI.

# Structure of commands

Verb-Noun -Parameter Value (-Parameter additional)
![[Pasted image 20250915111917.png]]

# Hunting with PowerShell

## Basic hunting
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

### System Information
Scenario:
You've been asked to preform a hunt on a Windows Network.
You (Host Analyst) have been tasked with preforming a baseline of the network.
This requires you to confirm all the host names and their versions of Windows.

Activity:
What command could you run on the hosts on the network to retrieve this?

### User Accounts
Scenario:
It's five days into the hunt, someone reports a user preforming suspicious activity. You check the baseline and see that the user account was present during the baseline. This doesn't mean that the user account is clear.

Activity: 
How else could you check if the account is suspicious?
- The account is a domain account.

### Processes & Services
Scenario:
You see PowerShell.exe running on a host but are unsure if its normal for that process to be running.

Activity:
List all running processes.
Check process metadata including paths and arguments
List all the services on the machine


# Combining commands

# Captsone
