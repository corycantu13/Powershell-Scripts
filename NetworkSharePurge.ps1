#Network Share Purge Script#
#Version 1.0#
<#
.SYNOPSIS
Remove Network Shares from Server8

.DESCRIPTION
Attempts to compare AD and Network share names and delete those not in Active Dirctory

.NOTES
Used to remove shares from server after comparing to AD, works at a very high level only use if you KNOW you will be deleting users that are potentially spelled wrong.
#>

Import-Module ActiveDirectory
 
$directories = get-childitem \\server8\Students$\*
 
ForEach ($d in $directories) {
    $name = $d.name
    $user = get-aduser -Filter {Name -eq $name}
       
    if (($user -eq $NULL)){
        Remove-Item $d -recurse -Force
        write-host $d
    }
}