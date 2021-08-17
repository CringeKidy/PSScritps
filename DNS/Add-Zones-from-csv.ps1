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

    if($DNSServer){
        $DNSServerName = $true
    }
    else{
        Write-Host "Sorry that server dose not exists"
        $DNSServerName = $false
    }
}until($DNSServerName -ne $false)

