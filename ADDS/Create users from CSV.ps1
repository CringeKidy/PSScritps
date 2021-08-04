param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
        Read-Host Was not able to start Powershell with Administrtor Permisssions
        Set-ExecutionPolicy Unrestricted 
    } else {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

$CSVCreation = read-host 'Do you want a CSV Created Y or N'
$CSVLocation;

if($CSVCreation.ToLower() -eq 'y' -or $CSVCreation.ToLower() -eq 'yes'){
    $newrow = [PSCustomObject] @{
        "FirstName" = "";
        "LastName" = "";
        "FullName" = "";
        "UserName" = "just take the full name and do a find and replace on this row and replace all spaces with a dot";
        "Password" = "P@ssw0rd";
        "Path" = "";
        "Group" = "";
        "UPN" = "use formla =CONCAT(D3, '@<your domian FQDN>)";
    }

    $newrow | Export-Csv  "$env:USERPROFILE\Desktop\Fill_this_out.csv"
    read-host "I have made a new csv on the desktop. EDIT it with the information you want to add and then come back and hit enter"

    $CSVLocation = "$env:USERPROFILE\Desktop\Fill_this_out.csv"
}
else{
    Write-Host Where is the CSV File
    
    Add-Type -AssemblyName System.Windows.Forms
    $CSVFile = New-Object System.Windows.Forms.OpenFileDialog 
    [void]$CSVFile.ShowDialog()
    $CSVLocation = $CSVFile.FileName
    write-host $CSVLocation
}



$Users = Import-Csv $CSVLocation

Foreach($User in $Users){
   $password = (ConvertTo-SecureString -AsPlainText $User.Password -force)

   Try{
        Get-ADOrganizationalUnit $User.Path
   }
   catch{
        New-ADOrganizationalUnit -Name ($User.Path -split ',')[0].Substring(3) 
   }

   Try{
        Get-ADGroup  $User.Group
   }
   catch{
        New-AdGroup -Name $User.Group  -GroupScope Global -Path $User.Path
   }

   New-ADUser -Name $User.FullName -DisplayName $User.UserName -GivenName $User.FirstName -Surname $User.LastName -SamAccountName $User.UserName `
              -UserPrincipalName $User.UPN -AccountPassword $password -Enabled $true -Path $User.Path
   Add-ADGroupMember -Identity $User.Group -Members $User.UserName

}



Read-Host Push enter to exit