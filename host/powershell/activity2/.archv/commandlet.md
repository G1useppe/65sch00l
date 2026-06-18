## PowerShell Cmdlet Overview

- PowerShell cmdlets typically follow a **Verb-Noun** naming convention, making them easier to understand and remember.

- **Get-ComputerInfo**  
  Provides a quick snapshot of the operating system and hardware configuration.

- **Get-LocalUser**  
  Displays local user accounts, useful for security checks and account management.

- **Get-Process**  
  Shows currently running applications and processes, helpful when troubleshooting performance issues.

- **Get-Service**  
  Allows you to check whether critical Windows services are running or stopped.

- **Get-NetIPConfiguration**  
  Provides network details such as IP addresses, network adapters, and DNS settings.

- **Get-ScheduledTask**  
  Identifies tasks that run automatically in the background, including updates and maintenance jobs.

- **Get-EventLog**  
  Used to review classic Windows event logs to diagnose system errors or events.

- **Get-History**  
  Displays commands used in the current PowerShell session, useful for auditing or repeating tasks.



  ### Get-Member

- **Get-Member** displays the properties and methods available on a PowerShell object.
- Because PowerShell works with objects, this helps you understand what data you can access.
- In the example, `Get-Process | Get-Member` is used to examine process objects.
- The output shows the object type along with its properties and methods.
- This cmdlet is useful for exploring objects before creating more advanced commands.


### Using Variables with Cmdlets

- PowerShell allows you to store the result of a cmdlet in a variable.
- This lets you reuse the object without running the cmdlet again.
- In the example, the output of `Get-Service` is stored in the `$service` variable.
- Once stored, you can access the object’s **methods**, such as `.Refresh()`.
- You can also access **properties**, like `.Name`.
- This approach makes scripts more readable and efficient.



## Where-Object

- **Where-Object** is used to filter objects based on conditions.
- It allows you to return only items that meet specific criteria.
- Filtering is done using comparison operators like `-eq`, `-gt`, and `-like`.
- This cmdlet is commonly used in pipelines to narrow down results.
- **Where-Object** helps make commands more efficient and focused.


## Select-Object

- **Select-Object** is used to choose specific properties from an object.
- It helps reduce output to only the information you need.
- This makes command results easier to read and work with.
- **Select-Object** can also create calculated or renamed properties.
- It is commonly used when formatting output or preparing data for reports.


## Get-CimInstance vs Get-WmiObject

- **Get-CimInstance**  
  - Modern cmdlet using **WS-Management (CIM protocol)**  
  - Works well **remotely** and is firewall-friendly  
  - Faster and recommended for **new scripts**

- **Get-WmiObject**  
  - Older cmdlet using **DCOM**  
  - Less efficient over networks  
  - Mainly for **legacy scripts or backward compatibility**

**Simple way to remember:**  
- Use **Get-CimInstance** for modern tasks  
- Use **Get-WmiObject** only for older scripts




