#This If statment is the first thing that gets called when script is ran
#It makes sure that the currnet ps session is running as administrator
#and if not then it will open a new PS Session with Administrator perms
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # Relaunch as an elevated process:
  Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit
}
Set-ExecutionPolicy Unrestricted


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

$xmlfile > ($profileFile)
netsh wlan add profile filename="$($profileFile)"
netsh wlan show profiles $SSID key=clear
netsh wlan connect name=$SSID

while (!(test-connection 1.1.1.1 -Count 1 -Quiet)) {
  Read-Host "There seems to be no internet connection please fix this before carrying on"
}

Write-Host "This may take a while"
$urls = @(
    [pscustomobject]@{Name="Ninite";URL="https://ninite.com/chrome-teamviewer15-vlc/ninite.exe"} 
    [pscustomobject]@{Name="AdobeReader";URL="http://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/2100720091/AcroRdrDC2100720091_en_US.exe"}
    )

foreach($website in $urls){
    $Downloadfolder = "$env:TEMP\$($website.Name).exe"
    Invoke-WebRequest -Uri $website.URL -OutFile $DownloadFolder
    Write-Host "Installing $($website.Name)"
    Start-Process -FilePath $DownloadFolder
}

Start-Process "https://remote.miltech.co.nz/"

Write-host "Doing Updates"

#Importing modules needed to be able to get windows updates
Install-PackageProvider -Name NuGet -force
Install-Module PSWindowsUpdate -force
Import-Module PSWindowsUpdate

#Gets and install the updates that it finds
Get-WindowsUpdate -Download -Install -ForceInstall -ForceDownload -AcceptAll -AutoReboot

Read-Host "Thanks for using this script :)"