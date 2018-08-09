#Remove Computers Script#
#Version 1.0#
<#
.SYNOPSIS
Removed Computers from Active Directory read from c:\scripts\computers.txt

.DESCRIPTION
Pulls computers from c:\scripts\computers.txt and removes them from Active Directory

.NOTES
Used to remove graduated users mostly. 
#>

Get-Content -Path C:\scripts\computers.txt | Remove-ADComputer
