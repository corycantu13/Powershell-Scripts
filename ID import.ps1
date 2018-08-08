#Active Directory ID Import#
#Version 1.0#
<#
.SYNOPSIS
Imports Student or Teacher ID into users AD Account

.DESCRIPTION
Imports Student or Teacher ID from C:\scripts\IDimport.csv to the corresponding users AD account

.NOTES
This was used to import IDs into active directory to make automated account creation easier

#>

Import-module ActiveDirectory  
Import-CSV "C:\Scripts\IDimport.csv" | % { 
$User = $_.UserName 
$ID = $_.EmployeeID 
Set-ADUser $User -employeeID $ID 
} 