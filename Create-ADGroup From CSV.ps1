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

$Groups = Import-Csv $CSVFile.FileName

Foreach($Group in $Groups){
    $Settings = @{
        'Name' = $Group.Name
        'GroupScope' = $Group.GroupScope
        'Path' = $Group.Path
    }

    Try{
        Get-ADOrganizationalUnit $Settings.Path
    }
   catch{
        New-ADOrganizationalUnit -Name ($Settings.Path -split ',')[0].Substring(3) 
   }

    New-ADGroup @Settings


}