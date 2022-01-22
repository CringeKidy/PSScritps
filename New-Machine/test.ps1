#This If statment is the first thing that gets called when script is ran
#It makes sure that the currnet ps session is running as administrator
#and if not then it will open a new PS Session with Administrator perms
if ($(new-object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator) -or $($Elevated -eq $True)) {
    Start-Process powershell -Verb runAs -ArgumentList "-NoExit";
}

#Importing modules needed to be able to get windows updates
Install-PackageProvider -Name NuGet -force
Install-Module PSWindowsUpdate -force
Import-Module PSWindowsUpdate

#Gets and install the updates that it finds
Get-WindowsUpdate -Download -Install -ForceInstall -ForceDownload -AcceptAll -AutoReboot