#This If statment is the first thing that gets called when script is ran
#It makes sure that the currnet ps session is running as administrator
#and if not then it will open a new PS Session with Administrator perms
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # Relaunch as an elevated process:
  Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit
}


write-host -ForegroundColor Cyan -BackgroundColor Black "Installing Chocoltey"
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

write-host -ForegroundColor Green -BackgroundColor Black "Installing Google Chrome, Adobe Reader and 7zip with choco"
choco install googlechrome adobereader 7zip -y


#Resets the localuser to be for end user
Set-LocalUser -name "Administrator" -Password ([SecureString]::new())
Rename-LocalUser -Name "Administrator" -NewName "Owner"

Invoke-WebRequest -Uri 'https://remote.miltech.co.nz/Bin/ConnectWiseControl.ClientSetup.exe?h=remote.miltech.co.nz&p=8041&k=BgIAAACkAABSU0ExAAgAAAEAAQBHVL0oYtAUfDX7vbfqclkRp9IgxCDsMQ7ZzmZUgfxY3bFmYK7I6gGHmrxOQorr1SCWiffAzjyTJ2XuNErZm7F%2BvRHSgmOylOFVexnzJ4LzwhlmvdiQr7HhJVfI8GyJfBizJnVc%2FS84SsT0ZsfqSz0AnPWqBc9r6oqMDmqEr0ZlfuJyTrRXLd0h%2FD%2B5KMyr93Cp2S8Nsubfy1LEEdkZdGnfs5uJgfOCwIvI2wC0jbXrKG9fioe9eJnTKFnt2LBlWJAlGpnif7ZBt8g2wWf9%2B4k4OVvm%2FavpSwp2%2BQzV3GRb1cwyexrCZd9xSmIYO5Js68ckeimv%2BasGWpf1GHjSbwGd&e=Access&y=Guest&t=&c=Customer&c=&c=LAB%2FTGA&c=&c=&c=&c=&c=' -OutFile  $env:TEMP/remote.exe
Start-Process "$ENV:temp\remote.exe" -Verb RunAs

