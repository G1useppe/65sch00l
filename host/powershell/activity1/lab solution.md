<h1>Lab Solution</h1>

<br>

**Lab 1**
Process Checks

<br>
```
#Get user input for a string
$procname = Read-Host "Give me a process 
string"

#Check if the process name given from user 
is running on the system
if (Get-Process -Name $procname 
-ErrorAction SilentlyContinue) {
    Write-Host "$procname is running"
}
#Print out that the process is not running
else {
    Write-Host "$procname is not running"
}
```

<br>

**Lab 2**
<br>
```
# Get user input class marks
$value = Read-Host "Give me your class 
mark!!"

# Convert to integer
$mark = [int]$value

# Check if we can pass
if ($mark -gt 50 -and $mark -le 65) {
    Write-Host "You passed!"
}
elseif ($mark -gt 65 -and $mark -le 75) {
    Write-Host "You got credit!"
}
elseif ($mark -gt 75 -and $mark -le 85) {
    Write-Host "You got distinction!"
} 
elseif ($mark -gt 85 -and $mark -le 100) {
    Write-Host "Get a high distinction!"
}

```
