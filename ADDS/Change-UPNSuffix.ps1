$path = read-host "What is the path eg(OU=User, DC=Adatum, DC=COM)"
$oldUPN = read-host "What is the old UPN(eg adatum.com)"
$newUPN = Read-Host "What is the new UPN eg(adatum.co.nz)"


Try{
    get-aduser -searchbase $path -filter * | `    
    foreach { `
        $newUPN = $_.UserPrincipalName.Replace($oldUPN,$newUPN)
        $_ | set-aduser -UserPrincipalName $newupn
        }
}
catch{
    Write-Host There was an error
    write-host $_
}