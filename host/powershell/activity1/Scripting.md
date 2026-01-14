<h1>Scripting</h1>
<br>

**Object-Oriented design**

Power Shell is an Object Orientated language.

A class is a set of rules used to define an object. 

For example:
When you run Get-Process on your computer you see every process having an Id, Name, CommandLine. These attributes are created whenever any process is created. This is because the process class requires these attributes for any process creation. 

Classes define how an object is created.

An object is an instance of a class for example seeing a cmd.exe process being spawned. 
<br>
<br>
**Types of Variables**

Assign a string
$string = "Put string here"

Assign a Integer
$int = 50

Assign a double
$float = 3.14

Assign a boolean
$bool = $true

Assign an array
$array = 1,2,3 OR $names = @("Mario", "Luigi", "Peach")
<br>
<br>
**Conditional Statement**

Types of conditition

if -> Check if the condition inside this statement is true if not move on to the rest of the code

elseif -> If multiple if statements are being used you can add multiple elseif statements

else -> If no conditions are met then run the else statement
<br>
<br>
**Lab 1 Process Check**
```
if (Get-Process -Name $procName -ErrorAction silentlyContinue) {
    
    if ($important -contains $procName) {
        Write-Host "$procName is important!"
    }
    else {

        Write-Host "$procName is running"
    }
}
else {

    Write-Host "$procName is not running."
}

<br>
<br>
```

**Compartor Operator**

The value on the left is what your comparing too. 
-eq -> Equal  

-ne -> not equal
-gt -> Greater than  

-ge -> Greater than equal too  

-lt -> less than  

-le -> less than equal too

<br>
<br>
**ForEach Loops**

Able to loop through an array and gather data from it. 

Step 1: Make an array
$names = @("mario", "Luigi")

Step 2: Make basic foreach syntax
foreach (#names in $names) {
}


Step 3: Add conditional statments within the foreach loop
foreach ( $name in $names ) {
    if ($name -eq "Blah") {
        Write-Host "Blach
    }
}

