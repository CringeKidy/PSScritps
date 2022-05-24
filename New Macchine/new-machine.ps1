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

Function Add-Wifi(){
    $profileFile = "Wifi.xml"
    $SSID = 'www.miltech.co.nz'
    $PW = 'bEtt3rW!f1'
    
    if(Test-Path($profileFile)){
      Remove-Item($profileFile)
    }
    
    $xmlfile="<?xml version=""1.0""?>
    <WLANProfile xmlns=""http://www.microsoft.com/networking/WLAN/profile/v1"">
        <name>$SSID</name>
        <SSIDConfig>
            <SSID>
                <name>$SSID</name>
            </SSID>
        </SSIDConfig>
        <connectionType>ESS</connectionType>
        <connectionMode>auto</connectionMode>
        <MSM>
            <security>
                <authEncryption>
                    <authentication>WPA2PSK</authentication>
                    <encryption>AES</encryption>
                    <useOneX>false</useOneX>
                </authEncryption>
                <sharedKey>
                    <keyType>passPhrase</keyType>
                    <protected>false</protected>
                    <keyMaterial>$PW</keyMaterial>
                </sharedKey>
            </security>
        </MSM>
    </WLANProfile>
    "
    
    
    
    $xmlfile > ("$($env:TEMP)\$profileFile")
    netsh wlan add profile filename="$($env:TEMP)\$profileFile"
    netsh wlan show profiles $SSID key=clear
    netsh wlan connect name=$SSID
    
    while (!(test-connection 1.1.1.1 -Count 1 -ErrorActoin SilentlyContinue)) {
      Read-Host "There seems to be no internet connection please fix this before carrying on"
    }
}

Write-host 'Changing time zone to new zeland' -BackgroundColor Cyan -ForegroundColor White
Set-TimeZone -id "New Zealand Standard Time"

$ComputerName = Read-Host "Please enter a name to rename the computer EG:(JustaceCornelder)"
Rename-Computer($ComputerName)


$NeedWifi = read-host "do you need to add wifi?"
if($NeedWifi -eq "y" -or $NeedWifi -eq "yes" ){
    Add-Wifi
}

write-host -ForegroundColor Cyan -BackgroundColor Black "Installing Chocoltey"
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

write-host -ForegroundColor Green -BackgroundColor Black "Installing Google Chrome, Adobe Reader and 7zip with choco"
choco install googlechrome adobereader 7zip -y

write-host "Installing Remote Connect using ComputerName" -ForegroundColor Black -BackGround Cyan

$URI = 'https://remote.miltech.co.nz/Bin/ConnectWiseControl.ClientSetup.exe?h=remote.miltech.co.nz&p=8041&k=BgIAAACkAABSU0ExAAgAAAEAAQBHVL0oYtAUfDX7vbfqclkRp9IgxCDsMQ7ZzmZUgfxY3bFmYK7I6gGHmrxOQorr1SCWiffAzjyTJ2XuNErZm7F%2BvRHSgmOylOFVexnzJ4LzwhlmvdiQr7HhJVfI8GyJfBizJnVc%2FS84SsT0ZsfqSz0AnPWqBc9r6oqMDmqEr0ZlfuJyTrRXLd0h%2FD%2B5KMyr93Cp2S8Nsubfy1LEEdkZdGnfs5uJgfOCwIvI2wC0jbXrKG9fioe9eJnTKFnt2LBlWJAlGpnif7ZBt8g2wWf9%2B4k4OVvm%2FavpSwp2%2BQzV3GRb1cwyexrCZd9xSmIYO5Js68ckeimv%2BasGWpf1GHjSbwGd&e=Access&y=Guest&t=&c=Customer&c=&c=LAB%2FTGA&c=&c=&c=&c=&c='
Invoke-WebRequest -URI $URI -OutFile "$env:TEMP\remote.exe"
Start-Process -FilePath "$env:TEMP\remote.exe" -Wait


Write-host "Doing Updates, please dont touch from now on" -ForegroundColor Black -BackgroundColor White

#Importing modules needed to be able to get windows updates
Install-PackageProvider -Name NuGet -force
Install-Module PSWindowsUpdate -force
Import-Module PSWindowsUpdate

#Gets and install the updates that it finds
Get-WindowsUpdate -Download -Install -ForceInstall -ForceDownload -AcceptAll



Read-Host "Thanks for using this script :). Please restart the computer as there are Updates that need to be Installed"