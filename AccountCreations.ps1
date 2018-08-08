# Globals
$DomainEmail="@springfield-schools.org"
$DomainName="DC=SLSD,DC=local"
$NTDomain="@SLSD.local"

$InFile = "C:\Scripts\Accounts\students.csv"
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
# Function : CreateStudentAccount           
# Notes :  	Check if student account exists.
#			If it doesnt, create it.        
#############################################
function CreateStudentAccount {

	Param ([string]$UserName, [string]$Password)
	
	$defpassword = (ConvertTo-SecureString "$UserPass" -AsPlainText -force)
	$UserEmail = $SamName   + $DomainEmail
	$UPN = $SamName + $NTDomain

	# Look for user with same SAMAccountName
	$CheckExist = try {Get-ADuser -LDAPFilter "(EmployeeID=$($acct.StateID))" -SearchBase "OU=Students,OU=Users and Computers,$DomainName"} catch {$null}
	$DN = Get-ADuser -LDAPFilter "(EmployeeID=$($acct.StateID))" -SearchBase "OU=Students,OU=Users and Computers,$DomainName" | Select-Object -Expand DistinguishedName
	$SN = Get-ADuser -LDAPFilter "(EmployeeID=$($acct.StateID))" -SearchBase "OU=Students,OU=Users and Computers,$DomainName" | Select-Object -Expand SamAccountName
	
	
	if(($CheckExist -ne $null) -and (($CheckExist | Select-Object -Expand SamAccountName) -eq $SamName)){
		# User Already Exists, Set a meaningful return Value
		$CreateStudentAccount = "Correct"
	} elseif (($CheckExist -ne $null) -and ($SN -ne $SamName)) {
		#Rename-ADObject -Identity $DN -NewName $SamName
		
		Set-ADUser $SN -DisplayName ($acct.FirstName+" "+$acct.LastName) `
									  -EmailAddress ($UserEmail) `
									  -Givenname $acct.FirstName `
									  -Surname $acct.LastName `
									  -Description "Grade $($acct.Grade) at $($school.Get_Item($acct.Schoolid))" `
									  -Enabled $true `
									  -Office ($UserPass) `
									  -Department $acct.Grade `
									  -Company $acct.Schoolid `

		$CreateStudentAccount = "Renamed"
	} Else {
	
		# Create the User's AD Account
		try {
				New-ADUser  -DisplayName ($acct.FirstName+" "+$acct.LastName) `
							-Name ($UserName) `
                            -SamAccountName ($SamName) `
                            -EmailAddress ($UserEmail) `
							-UserPrincipalName ($UPN) `
							-AccountPassword ($defpassword) `
							-EmployeeID ($acct.StateID) `
							-Office ($UserPass) `
							-givenname $acct.FirstName `
							-surname $acct.LastName `
							-Description "Grade $($acct.Grade) at $($school.Get_Item($acct.Schoolid))" `
							-Enabled $true `
							-ChangePasswordAtLogon $false `
							-CannotChangePassword $true `
							-Title "Student" `
							-Department $acct.Grade `
							-Company $($school.Get_Item($acct.Schoolid)) `
							-Path "OU=$($strGradYear),OU=Students,OU=Users and Computers,$DomainName"
				 $CreateStudentAccount = "Created"
			}
		catch [system.Object] {
			$CreateStudentAccount = "Error"
			
		}
	}

	$CreateStudentAccount

}
# End function CreateStudentAccount
# -------------------------------------------

#############################################
# Function:  Move to OU's based on CSV
# Notes:  Makes sure users are in right OU
#############################################



function MoveToOU {
	$UserLoc = ((Get-ADUser -Identity $SamName -Properties DistinguishedName).DistinguishedName -split ",",2)[1]
	$UserDN = (Get-ADUser -Identity $SamName).DistinguishedName
	
	$TargetOU = "OU=$($strGradYear),OU=Students,OU=Users and Computers,$DomainName"
	if($UserLoc -eq $TargetOU){
		$MoveToOU = "Correct"
	} else {
		Move-ADObject -Identity $UserDN -TargetPath $TargetOU
		$MoveToOU = "Moved"
		Set-ADUser  -Identity $SamName `
					-Company $($school.Get_Item($acct.Schoolid)) `
					-Description "Grade $($acct.Grade) at $($school.Get_Item($acct.Schoolid))" `
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

#Get First Initial
$init = $acct.FirstName.Substring(0,1)
#Strip Spaces out of last name
$lname = $acct.LastName -replace '\s',''
#Get first 2 of school id
$id = $acct.Stateid.Substring(0,2)
#Set Grad year. ***THIS MUST BE ADJUSTED EACH SCHOOL YEAR!!!*** It must be the grad year of the current senior class (2019 for the 2018/2019 school year)
$curryr = 2019
###
# Set other variables
#find the number to add to the current grad year
$gradoffset = 12-$acct.Grade
#Set graduation year
$gradyear = $curryr + $gradoffset
#Cast Grad Year to String for use in other parts of the Script
$strGradYear = [string]$gradyear
####

	# Create username
	$UserName = $acct.FirstName+" "+$acct.LastName
	$SamName = $id + $init + $lname
	$Obj = New-Object System.object
	$Obj | Add-Member -Type NoteProperty -name UserName -value $UserName
	
	# Create password
	$UserPass = "{0:D8}" -f [int]$acct.StateID
	$Obj | Add-Member -Type NoteProperty -name UserPass -value $UserPass
	
	# Create users
	$CreatedStatus=CreateStudentAccount $UserName $UserPass #$SamName
	$Obj | Add-Member -Type NoteProperty -name CreatedStatus -value $CreatedStatus
	
	# Move to OU
	$OUStatus=MoveToOU
	$Obj | Add-Member -Type NoteProperty -name OUStatus -value $OUStatus
	
	$ObjArr.add($Obj) 
    $ObjIdx ++
}

$ObjArr | Export-CSV $LogFile -notype

#Find accounts that are 1. Not in CSV and 2. Have EmployeeID and disable them
$IDS = Import-CSV -Path "C:\Scripts\Accounts\students.csv" | Select-object -ExpandProperty StateID
Get-ADUser -filter * -SearchBase "OU=Students,OU=Users and Computers,$DomainName" -Properties EmployeeID | Where-Object{$_.distinguishedname -notmatch 'OU=Disabled'} |
	Where-Object{$_.EmployeeID -and ($IDS -notcontains $_.EmployeeID)} | Disable-ADAccount

#Find all disable=Users and Computers and move to the disabled OU
Search-ADAccount -AccountDisabled -UsersOnly -SearchBase "OU=Students,OU=Users and Computers,$DomainName" | Where-Object {$_.distinguishedname -notmatch 'OU=Disabled'} |
Move-ADObject -TargetPath "OU=Disabled,OU=Students,OU=Users and Computers,$DomainName"