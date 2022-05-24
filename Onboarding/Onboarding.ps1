Function Rename-Computer($ComputerName){
  
    $Confirm = Read-Host "Are you sure that you want to rename the Computer to $($ComputerName)"
  
    if($Confirm.ToLower() -eq 'n' -or $Confirm.ToLower() -eq 'no'){
      $ComputerName = Read-Host "What would you like the computer name to be? "
    }
  
    Remove-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "Hostname" 
    Remove-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "NV Hostname" 
  
    Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\Computername" -name "Computername" -value $ComputerName
    Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\ActiveComputername" -name "Computername" -value $ComputerName
    Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "Hostname" -value $ComputerName
    Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "NV Hostname" -value  $ComputerName
    Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "AltDefaultDomainName" -value $ComputerName
    Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "DefaultDomainName" -value $ComputerName
  
    return write-host "New Name: $($ComputerName)"
}

#This If statment is the first thing that gets called when script is ran
#It makes sure that the currnet ps session is running as administrator
#and if not then it will open a new PS Session with Administrator perms
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
# Relaunch as an elevated process:
Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
exit
}

$WorkingDir = split-path -parent $MyInvocation.MyCommand.Definition
$ConfigFile = Get-Content "$WorkingDir\config.conf"

Write-host "Getting Variables from config file" -Backgroundcolor black -ForegroundColor green

foreach($command in $ConfigFile){
  Set-variable -Name $command.split('=')[0] -value $command.split('=',2)[1]
  write-host $command
}

$Samesetting = read-host "do you still want use these settings; `n $CustomerID `n $FolderID `n "

if($Samesetting -eq 'n' -or $Samesetting -eq 'no'){
  $NewCustomerID = read-host "(CustomerID) What do you want to change the setting to :"
  $NewFolderID = read-host "(FolderID) What do you want to change the Setting to :" 

  (Get-Content -path "$WorkingDir\config.conf") | Foreach-object { $_.replace("$CustomerID","$NewCustomerID").replace("$FolderID", "$NewFolderID") } | Set-Content "$WorkingDir\config.conf"

}

Write-Host $CustomerID $FolderID

$ComputerName = Read-host "Please Enter the new name of this computer eg (HCSL/D 01)"
Rename-Computer($ComputerName)

$InstallFile = ("$env:TEMP\install.exe") 

write-host "Getting RMM installer." -Foregroundcolor white -Backgroundcolor black
Invoke-webrequest -URI 'https://rmm.syncromsp.com/dl/rs/djEtMTg0NzE2MDAtMTU5MTkxNzQxNC01MDI2MC0xNDIxNjYz' -outfile $InstallFile

write-host "Installing RMM" -ForegroundColor green -Backgroundcolor black


&$InstallFile --console --customerid "$CustomerID" --folderid "$FolderID"


Write-host "Checking if choco is installed" -ForegroundColor green
$testchoco = Get-Command choco.exe -ErrorAction SilentlyContinue
if(!$testchoco){
    Write-host "Choco does not seem to be installed, Installing that now"
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

Write-host -Backgroundcolor black -Foregroundcolor Red "Installing Office"
choco install office365proplus -y