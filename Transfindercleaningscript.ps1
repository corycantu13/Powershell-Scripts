#Transfinder Export Cleaning Script#
#Version 1.0#
<#
.SYNOPSIS
Take Powerschool Export and eliminates Lot and Apt from the Address Field for import to Transfinder

.DESCRIPTION
Export from powerschool nightly includes Lot and Apt numbers in the street address.  This removed (almost) all of these so when imported into transfinder it will geocode. After removal it then copies the file to the Transfinder server for import

.NOTES

Change the filepath for the files to match the server it is being ran on

C:\FTP\Transfinder\students.txt
C:\FTP\Transfinder\studentsnew.txt
C:\FTP\Transfinder\studentsnew.csv

#>




Get-Content C:\scripts\students.txt | ForEach-Object {$_-replace(',.(Apt|Lot).{2,6}\t', "`t")} | Out-File C:\scripts\studentsnew.txt
Import-CSV c:\scripts\studentsnew.txt -Delimiter `t | Export-CSV C:\Scripts\studentsnew.csv -NoTypeInformation
