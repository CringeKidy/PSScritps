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
        Set-ExecutionPolicy Unrestricted 
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

$Adpater = "Ethernet"
$Ipaddress = 172.16.0.10
$Prefix = 24
$gateway = 172.16.0.1
$DNSServer = 172.16.0.10
$NewAdaptername = "London_Network"
$ComputerName = "LON-"

$Adpater = Read-Host "Name of the adpater ($Adpater)"
$Ipaddress = Read-Host "What is the new IP Address ($Ipaddress)"
$Prefix = Read-Host "What is the Prefix Length ($Prefix)"
$gateway = Read-Host "What is the New Default Gateway ($gateway)"
$DNSServer = Read-Host "What is the New DNS Server ($DNSServer)"
$NewAdaptername = Read-Host "What is the New Adapter Name($NewAdpatername)"
$ComputerName = Read-Host "What is the new computer name($ComputerName)"



Set-TimeZone -id "New Zealand Standard Time"
New-NetIPAddress -Interfacealias $Adpater -IPAddress $Ipaddress -PrefixLength $Prefix -DefaultGateway $gateway
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddress $DNSSServer
Rename-NetAdapter $Adpater -NewName $NewAdaptername
Rename-Computer -NewName $ComputerName -Restart