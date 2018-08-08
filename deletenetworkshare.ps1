#Delete Network Share Script#
#Version 1.0#
<#
.SYNOPSIS
Deletes Users NetworkShare from Server8 read from c:\scripts\logons.txt

.DESCRIPTION
Pulls usernames from c:\scripts\logons.txt and Deletes Users NetworkShare from Server8

.NOTES
Used to remove graduated users mostly.  Ensure you are working in the right directory on the server \\server8\students$ or teachers$

#>

Import-Module ActiveDirectory
 
$users = get-content C:\Scripts\logons.txt
$profile = '\\server8\teachers$'
 
ForEach ($user in $users) {
    Remove-Item "$profile\$user" -Recurse -Force
}