#This If statment is the first thing that gets called when script is ran
#It makes sure that the currnet ps session is running as administrator
#and if not then it will open a new PS Session with Administrator perms
if ($(new-object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator) -or $($Elevated -eq $True)) {
  Start-Process powershell -Verb runAs -ArgumentList "-NoExit";
}

#Connecting to WIFI
# Fill in mandatory details for the WiFi network
$WirelessNetworkSSID = 'www.miltech.co.nz'
$WirelessNetworkPassword = 'bEtterW!f1'
$Authentication = 'WPA2PSK' # Could be WPA2
$Encryption = 'AES'

# Create the WiFi profile, set the profile to auto connect
$WirelessProfile = @'
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1"&gt;
	<name>{0}</name>
	<SSIDConfig>
		<SSID>
			<name>{0}</name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>auto</connectionMode>
	<MSM>
		<security>
			<authEncryption>
				<authentication>{2}</authentication>
				<encryption>{3}</encryption>
				<useOneX>false</useOneX>
			</authEncryption>
			<sharedKey>
				<keyType>passPhrase</keyType>
				<protected>false</protected>
				<keyMaterial>{1}</keyMaterial>
			</sharedKey>
		</security>
	</MSM>
</WLANProfile>
'@ -f $WirelessNetworkSSID, $WirelessNetworkPassword, $Authentication, $Encryption

# Create the XML file locally s
$random = Get-Random –Minimum 1111 –Maximum 99999999
$tempProfileXML = "$env:TEMP\tempProfile$random.xml"
$WirelessProfile | Out-File $tempProfileXML

# Add the WiFi profile and connect
Start-Process netsh ('wlan add profile filename={0}' -f $tempProfileXML)

# Connect to the WiFi network – only if you need to
Start-Process netsh ('wlan connect name="{0}"' -f $WirelessNetworkSSID)

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