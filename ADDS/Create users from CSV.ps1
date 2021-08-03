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

Write-Host Where is the CSV File

Add-Type -AssemblyName System.Windows.Forms
$CSVFile = New-Object System.Windows.Forms.OpenFileDialog 
[void]$CSVFile.ShowDialog()
$CSVFile.FileName

$Users = Import-Csv $CSVFile.FileName

Foreach($User in $Users){
   $password = (ConvertTo-SecureString -AsPlainText $User."Password" -force)
   $Group = $User.Group

   $UPN = $User."User name" + "@" + $User.domain

   $Settings = @{
    'Name' = $User."User name"
    'GivenName' = $User."First name"
    'Surname' = $User."Last name"
    'Displayname' = $User."Full name"
    'SamAccountName' = $User."User name"
    'UserPrincipalName' = $UPN
    'AccountPassword' = $password
    'Enabled' = $true
    'Path' = $User.Path
   }


   Try{
        Get-ADOrganizationalUnit $Settings.Path
   }
   catch{
        New-ADOrganizationalUnit -Name ($Settings.Path -split ',')[0].Substring(3) 
   }


   Try{
       Get-ADGroup  $Group
   }
   catch{
    New-AdGroup -Name $Group  -GroupScope Global -Path $Settings.Path
   }

   New-ADUser @Settings
   Add-ADGroupMember -Identity $Group -Members $Settings.SamAccountName

}



Read-Host Push enter to exit