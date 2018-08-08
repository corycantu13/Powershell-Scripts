#Active Directory Email Import#
#Version 1.0#
<#
.SYNOPSIS
Imports email addresses into users AD Account

.DESCRIPTION
Imports email address from C:\scripts\emailimport.csv to the corresponding users AD account

.NOTES
This was used to import emails into active directory to make automated account creation easier

#>
Import-Module ActiveDirectory
$Users = Import-CSV "C:\Scripts\emailimport.csv"
ForEach($User in $Users)
{
    Set-ADUser -Identity $user.SamAccountName -EmailAddress $user.EmailAddress

}