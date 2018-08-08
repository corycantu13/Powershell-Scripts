#Last User Login Script#
#Version 1.0#
<#
.SYNOPSIS
Gets last login date/time for users in a specific OU

.DESCRIPTION
Collects last login date and time from a specific OU for users.  This is used to populate c:\scripts\logons.csv which can then be copied to c:\scripts\logons.txt.  To be used with removeusers.ps1 (pulls from c:\scripts\logons.txt) and deletenetworkshare.ps1 (pulls from c:\scripts\logons.txt)

.NOTES
Changed desired OU to whichever you need.  If you need to remove users copy the username from c:\scripts.csv into c:\scripts\logons.txt and follow instructions inside removeusers.ps1

#>


Get-ADUser -Filter * -SearchBase "ou=2018,ou=Students,ou=Users and Computers,dc=slsd,dc=local" -Properties CN,LastLogonDate| Select CN,LastlogonDate | Export-Csv c:\scripts\logons.csv
