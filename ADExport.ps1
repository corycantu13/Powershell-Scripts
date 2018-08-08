#Export Users from Active Directory#
#Version 1.0#
<#
.SYNOPSIS
Exports users from Active Directory

.DESCRIPTION
Exports users from active directory with certain attributes attached.  These can be modified below

.NOTES
This was used to ensure users had their email properly attached to either AD Account

#>

Import-module ActiveDirectory
get-aduser -filter "enabled -eq 'true'"  -SearchBase "OU=Teachers,OU=Users and Computers,DC=SLSD,DC=Local" -Properties displayName,givenName,sn,samaccountname,mail,employeeid |
select displayName,givenName,sn,Samaccountname,mail,employeeid |
export-csv "c:\scripts\export.csv" -NoTypeInformation