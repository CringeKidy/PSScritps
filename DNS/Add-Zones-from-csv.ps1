#This If statment is the first thing that gets called when script is ran
#It makes sure that the currnet ps session is running as administrator
#and if not then it will open a new PS Session with Administrator perms
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # Relaunch as an elevated process:
  Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit
}

do{
    $DNSServerName = read-host "What is the name of the DNS Server where you want to add zones (just do . if it is this computer)"
    $DNSServer = Resolve-dnsName -Name $DNSServerName

    if(!$DNSServer){
        Write-Host "Sorry that server dose not exists"
        $DNSServerName = $false
    }
}until($DNSServerName -ne $false)

Write-Host "where is the CSV to import zones"
Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
$FileBrowser.ShowDialog()

$Zones = Import-CSV $FileBrowser.FileName
$NOip = @()

foreach($zone in $Zones){
   $ZoneExists = Get-DnsServerZone -ComputerName $DNSServerName -Name $zone.DomainName

    if(!$zone.PublicIP){
        $NOip += $zone.DomainName
    }

   if(!$ZoneExists){
       Write-Host "There is no Zone called $($zone.DomainName) so creating a new one and adding records"
       Add-DnsServerPrimaryZone -ComputerName $DNSServerName -Name $zone.DomainName -ReplicationScope Forest
       Add-DnsServerResourceRecordA -ComputerName $DNSServerName -Name "mail" -IPv4Address $zone.PublicIP -ZoneName $zone.DomainName
       Add-DnsServerResourceRecordMX -ComputerName $DNSServerName -Name "mail" -MailExchange "mail.$($zone.DomainName)" -Preference 1 -ZoneName $zone.DomainName
   }
   else{
       Write-Host "There is already a zone called $($zone.DomainName)"
   }
}

Read-Host "was unable to make MX record for these people because they did not have valid ip | List of domain names: $NOip"