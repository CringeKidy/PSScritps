param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}
$InstallLocal = Read-Host Where are we installing DHCP

if($InstallLocal -eq "." -or $InstallLocal -eq "local"){
    
   $InstalLocal = hostname
    
  try{
    Write-Host Installing DHCP 
    Install-WindowsFeature DHCP -IncludeManagementTools -ComputerName $InstallLocal
    }
    catch{
        Write-Host There was an error
        Write-Host $_
        Read-Host Push enter to exit
    }
}
else{
    try{
        Write-Host Installing DHCP -Co
        Install-WindowsFeature DHCP -IncludeManagementTools 
    }
    catch{
        Write-Host There was an error
        Write-Host $_
        Read-Host Push enter to exit
    }
}

$DHCPInstall = $InstallLocal

if($DHCPInstall -eq '.' -or $DHCPInstall -eq 'local'){
    $DHCPServer = hostname
    $DHCPSeverIP = Read-host "Whats is $DHCPServer's ip"

    try{
    Write-Host Creating DHCP
    Add-DhcpServerInDC -DnsName $DHCPServer -IPAddress $DHCPSeverIP
    
    Write-Host DHCP Security Group 
    Add-DHCPServerSecurityGroup -ComputerName $DHCPServer

    Write-Host Changing resgirty for dhcp 
    Set-ItemProperty –Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 –Name ConfigurationState –Value 2

    Write-Host Restarting DHCP
    restart-service dhcpserver
    }
    catch{
        Write-Host There was an error
        Write-Host $_
        Read-Host Push enter to exit
    }
} 
else{
    $DHCPServer = $DHCPInstall
    $DHCPSeverIP = Read-host "Whats is $DHCPServer's ip"

    try{
        Write-Host Creating DHCP
        Add-DhcpServerInDC -DnsName $DHCPServer -IPAddress $DHCPSeverIP
    
        Write-Host DHCP Security Group 
        Add-DHCPServerSecurityGroup -ComputerName $dhcpserver

        Write-Host Changing resgirty for dhcp 
        Set-ItemProperty –Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 –Name ConfigurationState –Value 2

        Write-Host Restarting DHCP
        restart-service dhcpserver
    }
    catch{
        Write-Host There was an error        Write-Host $_
        Read-Host Push enter to exit
    }
}

$ScopeName = Read-Host What do you want to name the scope 
$ScopeStartRange = Read-Host What is the Scope Start Range eg.192.168.1.1
$ScopeEndRange = Read-Host What is the Scope End Range eg.192.168.1.254
$ScopeSubnet = Read-Host What is the subnet eg.255.255.255.0

try{
    Add-DhcpServerv4Scope -ComputerName $InstallLocal -name $ScopeName -StartRange $ScopeStartRange -EndRange $ScopeEndRange -SubnetMask $ScopeSubnet -State Active
    Write-Host Making Scope
}
catch{
    Write-Host There was an error
    Write-Host $_
    Read-Host Push enter to exit
}


$Exe = Read-Host Any Exclusions 

if($Exe -eq "y" -or $Exe -eq "yes" -or $Exe -eq "Yes"){
    
    do{
        $ScopeID = Read-Host what is the scope id eg.192.168.1.0
        $StartRange = Read-Host What is the Device IP

    
        try{
         Add-DhcpServerv4ExclusionRange -ScopeID $ScopeID -ComputerName $InstallLocal -StartRange $StartRange -EndRange $StartRange
         Write-Host Adding Exclusion
        }
        catch{
            Write-Host There was an error
            Write-Host $_
            Read-Host Push enter to exit
        }

        $UserLoop = Read-host Any More

    }until($UserLoop -eq "n")

}
else{
    $ScopeID = Read-Host What is the scope id eg.192.168.1.0
}

$RouterIP = Read-Host What is the router ip


try{
        Set-DhcpServerv4OptionValue -OptionID 3 -ScopeID $ScopeID  -ComputerName $InstallLocal -Value $RouterIP 
        Write-host Adding router  
        
}
catch{
        Write-Host There was an error
        Write-Host $_
        Read-Host Push enter to exit
}

$DNSDomain = Read-Host What is the DNS Domain 
$DNSserver = Read-Host What is the DNS Server IP

try{
        Set-DhcpServerv4OptionValue -OptionID 15 -ScopeID $ScopeID  -ComputerName $InstallLocal -Value $DNSDomain 
        Write-Host Adding DNS
}
catch{
        Write-Host There was an error
        Write-Host $_
        Read-Host Push enter to exit
}

try{
        Set-DhcpServerv4OptionValue -OptionID 6 -ScopeID $ScopeID -ComputerName $InstallLocal -Value  $DNSserver 
        Write-Host Adding DNS Server
}
catch{
        Write-Host There was an error
        Write-Host $_
        Read-Host Push enter to exit
}


Write-host -ForegroundColor Green "Server Options: 
                  DHCP Sever Name: $DHCPServer
                  DHCP Server IP: $DHCPSeverIP
                  Scope ID: $ScopeID
                  Router IP: $RouterIP
                  Scope Name: $ScopeName"


Read-Host DHCP Server made Push enter to exit 