# Scripting

## Types of Variable

- Integers
- Floating Points
- Strings
- Boolean
- Datetime
- Integer Arrays
- Hash Table

## Assign a variable

Syntax is important!!!

| Type | Example |
|------|---------|
| **int** | `$age = 30` |
| **string** | `$name = "Alice"` |
| **bool** | `$IsReady = $true` |
| **array** | `$numbers = 1, 2, 3` |
| **hashtable** | `$person = @{ Name='Bob'; Age=25 }` |

## Demo Assigning Variables

Using PowerShell ISE, show how to initialise variables.

```powershell
$age = 30
$name = "Alice"
$number = @(1,2,3)
$hashtable = @{person = "Bob"}
```

## Comparison Operator

Use comparator operators for better scripting.

| Operator | Example | Result |
|----------|---------|--------|
| `-eq` | `5 -eq 5` | True |
| `-ne` | `5 -ne 3` | True |
| `-gt` | `5 -gt 3` | True |
| `-ge` | `5 -ge 5` | True |
| `-lt` | `3 -lt 5` | True |
| `-le` | `5 -le 5` | True |

## Conditional Statement

Can use conditional statements too.

```
if (condition) { action }
    elseif (condition) { action }
else { action }
```

```powershell
$name = "Craggs"

if ($name -eq "Mario") {
    Write-Host "It is me Mario"
}
elseif ($name -eq "Lugi") {
    Write-Host "It is me Lugi"
}
else {
    Write-Host "It is Craggs Oh NO"
}
```

## Lab

- Assign a variable with the value 7
- Write an if, elseif and else statement to check if the value is greater than or less than 7

```powershell
# Write your solution here

```

## Lab 2 — Pass/Fail Marks

- Get user input on a number between 0–100
- Above 50 and less than 65, print **Pass**
- Greater than or equal to 65 and less than 75 is **Credit**, print Credit
- Greater than or equal to 75 and less than 85 is **Distinction**
- Greater than or equal to 85 and less than 100 is **High Distinction**

```powershell
# Write your solution here

```

## ForEach in PowerShell

Iterate through an array.

## Demo For loops

- Make an array of vegetables
- Use conditional statements within the for loop to check if the vegetable is in the array

```powershell
$vegetables = @("Pears", "Apple", "Strawberry")

foreach($vegetable in $vegetables) {
    if ($vegetable -eq "Pears") {
        Write-Host "Vegetable is a pear"
    }
    elseif ($vegetable -eq "Potato") {
        Write-Host "Vegetable is a potato"
    }
    else {
        "I don't know what a vegetable it is"
    }
}
```

## Lab 3 — Foreach

- Make a password array
- Get user input and get a new password from them
- Check if new password is in the array
- Display "password already used" or "new password is valid"

```powershell
# Write your solution here

```

## Lab 4 — Summary Lab **Challenge**

Given an array of integers `nums` and an integer `target`, return indices of the two numbers such that they add up to `target`.

You may assume that each input would have exactly one solution, and you may not use the same element twice.

- Input: `nums = [2,7,11,15]`, `target = 9`
- Output: `[2,7]`

```powershell
# Write your solution here

```
