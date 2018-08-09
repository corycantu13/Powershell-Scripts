#Automated Teacher Account Creation Script#
#Version 1.0#
<#
.SYNOPSIS
Automated Teacher Account Creation

.DESCRIPTION
Takes Powershell SIS export and attempts to create account automatically for teachers

.NOTES
Be sure to read comment sections on what areas do, this is for teachers there is another speically for teachers.

#>

# Globals
$DomainEmail="@springfield-schools.org"
$DomainName="DC=SLSD,DC=local"
$NTDomain="@SLSD.local"

$InFile = "C:\Scripts\Accounts\Teachers.csv"
$LogFile = "C:\Scripts\Accounts\logfile.csv"


Import-Module ActiveDirectory

$school = @{
        "7799" = "Crissey"
        "8649" = "Dorr"
        "16576" = "Holland"
        "119792" = "Holloway"
        "35501" = "SMS"
        "35477" = "SHS"
        }

#############################################
# Function : CreateTeacherAccount           
# Notes :  	Check if teacher account exists.
#			If it doesnt, create it.        
#############################################
function CreateTeacherAccount {

	Param ([string]$UserName, [string]$Password)
	
	$defpassword = (ConvertTo-SecureString "$UserPass" -AsPlainText -force)
	$UserEmail = $SamName + $DomainEmail
	$UPN = $SamName + $NTDomain

	# Look for user with same SAMAccountName
	$CheckExist = try {Get-ADuser -LDAPFilter "(EmployeeID=$($acct.teacherID))" -SearchBase "OU=Teachers,OU=Users and Computers,$DomainName"} catch {$null}
	$DN = Get-ADuser -LDAPFilter "(EmployeeID=$($acct.TeacherID))" -SearchBase "OU=Teachers,OU=Users and Computers,$DomainName" | Select-Object -Expand DistinguishedName
	$SN = Get-ADuser -LDAPFilter "(EmployeeID=$($acct.TeacherID))" -SearchBase "OU=Teachers,OU=Users and Computers,$DomainName" | Select-Object -Expand SamAccountName
	
	
	if(($CheckExist -ne $null) -and (($CheckExist | Select-Object -Expand SamAccountName) -eq $SamName)){
		# User Already Exists, Set a meaningful return Value
		$CreateTeacherAccount = "Correct"
	} elseif (($CheckExist -ne $null) -and ($SN -ne $SamName)) {
		#Rename-ADObject -Identity $DN -NewName $SamName
		
		Set-ADUser $SN -DisplayName ($acct.FirstName+" "+$acct.LastName) `
									  -EmailAddress ($UserEmail) `
									  -Givenname $acct.FirstName `
									  -Surname $acct.LastName `
									  -Description "Teacher at $($school.Get_Item($acct.Schoolid))" `
									  -Enabled $true `
									  -Office $acct.Schoolid `

		$CreateTeacherAccount = "Renamed"
	} Else {
	
		# Create the User's AD Account
		try {
				New-ADUser  -DisplayName ($acct.FirstName+" "+$acct.LastName) `
							-Name ($UserName) `
                            -SamAccountName ($SamName) `
                            -EmailAddress ($UserEmail) `
							-UserPrincipalName ($UPN) `
							-AccountPassword ($defpassword) `
							-EmployeeID ($acct.TeacherID) `
							-Office $acct.Schoolid `
							-givenname $acct.FirstName `
							-surname $acct.LastName `
							-Description "Teacher at $($school.Get_Item($acct.Schoolid))" `
							-Enabled $true `
							-ChangePasswordAtLogon $false `
							-Title "Teacher" `
							-Company $($school.Get_Item($acct.Schoolid)) `
							-Path "OU=Teachers,OU=Users and Computers,$DomainName"
				 $CreateTeacherAccount = "Created"
			}
		catch [system.Object] {
			$CreateTeacherAccount = "Error"
			
		}
	}

	$CreateTeacherAccount

}
# End function CreateTeacherAccount
# -------------------------------------------

#############################################
# Function:  Move to OU's based on CSV
# Notes:  Makes sure users are in right OU
#############################################



function MoveToOU {
	$UserLoc = ((Get-ADUser -Identity $SamName -Properties DistinguishedName).DistinguishedName -split ",",2)[1]
	$UserDN = (Get-ADUser -Identity $SamName).DistinguishedName
	
	$TargetOU = "OU=Teachers,OU=Users and Computers,$DomainName"
	if($UserLoc -eq $TargetOU){
		$MoveToOU = "Correct"
	} else {
		Move-ADObject -Identity $UserDN -TargetPath $TargetOU
		$MoveToOU = "Moved"
		Set-ADUser  -Identity $SamName `
					-Company $($school.Get_Item($acct.Schoolid)) `
					-Description "Teacher at $($school.Get_Item($acct.Schoolid))" `
					-Enabled $true
	}
	$MoveToOU
}

# End function MoveToOU
# -------------------------------------------


#############################################
# Main
#############################################
$AcctList=Import-CSV $InFile

# Obj entries are for producing logfile
$ObjArr = New-Object 'System.Collections.Generic.List[System.Object]'
$ObjIdx = 0



foreach ($acct in $AcctList) {

#Strip Spaces out of last name
$lname = $acct.LastName -replace '\s',''

	# Create username
	$UserName = $acct.FirstName+" "+$acct.LastName
	$SamName = $acct.FirstName + $lname
	$Obj = New-Object System.object
	$Obj | Add-Member -Type NoteProperty -name UserName -value $UserName
	
	# Create password
	$UserPass = $acct.LastName
	$Obj | Add-Member -Type NoteProperty -name UserPass -value $UserPass
	
	# Create users
	$CreatedStatus=CreateTeacherAccount $UserName $UserPass $SamName
	$Obj | Add-Member -Type NoteProperty -name CreatedStatus -value $CreatedStatus
	
	# Move to OU
	$OUStatus=MoveToOU
	$Obj | Add-Member -Type NoteProperty -name OUStatus -value $OUStatus
	
	$ObjArr.add($Obj) 
    $ObjIdx ++
}

$ObjArr | Export-CSV $LogFile -notype

#Find accounts that are 1. Not in CSV and 2. Have EmployeeID and disable them
$IDS = Import-CSV -Path "C:\Scripts\Accounts\Teachers.csv" | Select-object -ExpandProperty TeacherI
Get-ADUser -filter * -SearchBase "OU=Teachers,OU=Users and Computers,$DomainName" -Properties EmployeeID | Where-Object{$_.distinguishedname -notmatch 'OU=Disabled'} |
	Where-Object{$_.EmployeeID -and ($IDS -notcontains $_.EmployeeID)} | Disable-ADAccount

#Find all disabled Users and move to the disabled OU
Search-ADAccount -AccountDisabled -UsersOnly -SearchBase "OU=Teachers,OU=Users and Computers,$DomainName" | Where-Object {$_.distinguishedname -notmatch 'OU=Disabled'} |
Move-ADObject -TargetPath "OU=Disabled,OU=Teachers,OU=Users and Computers,$DomainName"