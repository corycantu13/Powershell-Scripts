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