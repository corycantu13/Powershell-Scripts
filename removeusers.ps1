#Remove Users Script#
#Version 1.0#
<#
.SYNOPSIS
Removed Users from Active Directory read from c:\scripts\logons.txt

.DESCRIPTION
Pulls usernames from c:\scripts\logons.txt and removes them from Active Directory

.NOTES
Used to remove graduated users mostly.  Ensure you copy JUST the username from the csv file to the txt file

#>


Get-Content -Path C:\scripts\logons.txt | Remove-ADUser