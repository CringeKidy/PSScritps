#This If statment is the first thing that gets called when script is ran
#It makes sure that the currnet ps session is running as administrator
#and if not then it will open a new PS Session with Administrator perms
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # Relaunch as an elevated process:
  Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit
}

$MutipleVMs = Read-host "Is there mutiple VMs"

Switch -Regex ($MutipleVMs) {
    "Y" {
        $VMNamesArray= @()
        do{
            $VMNames = "What are the VM Names (push enter again when finsished"
            $VMNames += $VMNamesArray
        }until($VMNames -eq "")

        foreach($VM in $VMNamesArray){
            Get-VHD
        }
    }
    "N"{

    }
}