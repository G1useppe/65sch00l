<h1>Lab Solution</h1>

**Lab 1 Process Check**

# Get user input for process name
$procName = Read-Host "Enter a process name"

# Check if process is running
if (Get-Process -Name $procName -ErrorAction SilentlyContinue) {
    Write-Host "$procName is running" -ForegroundColor Green
} else {
    Write-Host "$procName is not running" -ForegroundColor Red
}

**Lab 2 Grade Checker**
# Get user input and convert to integer
$mark = [int](Read-Host "Enter your class mark (0-100)")

# Grade evaluation
if ($mark -gt 50 -and $mark -le 65) {
    Write-Host "You passed!" -ForegroundColor Yellow
} elseif ($mark -gt 65 -and $mark -le 75) {
    Write-Host "You got a Credit!" -ForegroundColor Cyan
} elseif ($mark -gt 75 -and $mark -le 85) {
    Write-Host "You got a Distinction!" -ForegroundColor Magenta
} elseif ($mark -gt 85 -and $mark -le 100) {
    Write-Host "High Distinction! Excellent work!" -ForegroundColor Green
} else {
    Write-Host "Failed or invalid mark" -ForegroundColor Red
}
