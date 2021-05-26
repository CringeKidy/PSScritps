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

$ComputerName = Read-Host What Computer `n
$ScopeID = Read-Host What is the Scope id `n

if($ComputerName -eq "." -or $ComputerName -eq "local"){
    $ComputerName = HostName
}

$Chosse = Read-Host Create or Manage Scope `n

if($Chosse.ToLower() -eq "create"){
    $Listtype = @('splitscope', 'multi-scope', 'scope', 'multicast')

    Write-host -ForegroundColor Yellow $Listtype
    $ScopeType = Read-Host What is the scope type

    if($ScopeType.ToLower() -eq 'multi cast' -or $ScopeType.ToLower() -eq "multicast"){
        $ScopeName = Read-Host What is the Scope Name `n
        $ScopeStartRange = Read-Host What is the Scope Start range eg.255.255.0
        $ScopeEndRange = Read-Host What is the Scope End Range eg.255.255.255.254


        Add-DhcpServerv4MulticastScope -ComputerName $ComputerName -Name $ScopeName -StartRange $ScopeStartRange -EndRange $ScopeEndRange -State Active 
    }
    if($ScopeType.ToLower() -eq 'scope'){
        $ScopeName = Read-Host What is the Scope Name
        $ScopeStartRange = Read-Host What is the Start Range eg.192.168.1.1 `n
        $ScopeEndRange = Read-Host What is the End Range eg.192.168.1.254 `n
        $ScopeSubNet = Read-Host What is the Sub-net mask eg.255.255.255.0 `n

        Add-DhcpServerv4Scope -ComputerName $ComputerName -Name $ScopeName -StartRange $ScopeStartRange -EndRange $ScopeEndRange -SubnetMask $ScopeSubNet
        Write-Host Scope Created
    }
    if($ScopeType.ToLower() -eq 'multi-scope'){
        $Hosts = @()

        do{
            $HostNames = Read-Host What are the Host Names `n
            if($HostNames -ne ""){
                $Hosts += $Hostnames
            }
        }until($HostNames -eq "")

        $ScopeName = Read-Host What is the Scope Name
        $ScopeStartRange = Read-Host What is the Start Range eg.192.168.1.1 `n
        $ScopeEndRange = Read-Host What is the End Range eg.192.168.1.254 `n
        $ScopeSubNet = Read-Host What is the Sub-net mask eg.255.255.255.0 `n

        Write-Host $Hosts

        $Hosts = $Hosts | ForEach-Object { 
            if( $Hosts.IndexOf($_) -eq ($Hosts.count -1) ){
                $_.replace(";","")
            }else{$_}  
        }
        
        foreach($i in $Hosts){

            Add-DhcpServerv4Scope -ComputerName $i -Name $ScopeName -StartRange $ScopeStartRange -EndRange $ScopeEndRange -SubnetMask $ScopeSubNet
        }

        Write-Host Scope Created
    }
    if($ScopeType.ToLower() -eq 'split scope' -or $ScopeName.ToLower() -eq 'splitscope'){
        $PartnerSever = Read-Host What is the Partner Sever `n 
        $ScopeName = Read-Host What is the Scope Name `n
        $Load = Read-Host What Load Ballance do you want eg.50 `n
        $MClinetTime = Read-Host Whats the Max Client Lead Time eg.1:00:00 `n
        $StateSwicth = Read-Host Whats the Switch state Interval eg 00:45:00 `n
        $ShardedSecret = Read-Host Whats the Shared Secret eg.P@ssw0rd

        Add-DhcpServerv4Failover –ComputerName $ComputerName –PartnerServer $PartnerSever –Name $ScopeName -ScopeId $ScopeID -SharedSecret $ShardedSecret
        Add-DhcpServerv4Failover –ComputerName $PartnerSever –PartnerServer $ComputerName –Name $ScopeName -ScopeId $ScopeID -SharedSecret $ShardedSecret
    }
    else{
        Write-Host That type is not supported
    }
}

$Item = Read-Host What are we Changing

try{
    if($Item.ToLower() -eq "router"){
        $Value = Read-Host What is the Router IP `n

        Set-DhcpServerv4OptionValue -ComputerName $ComputerName -ScopeID $ScopeID -OptionID 3 -Value $Value
    } 
    if($Item.ToLower() -eq "dns server" -or $Item.toLower() -eq "dnsserver"){
       $Value = Read-Host What is the DNS Server ip

       Set-DhcpServerv4OptionValue -ComputerName $ComputerName -ScopeID $ScopeID -OptionID 6 -Value $Value
    } 
    if($Item.ToLower() -eq "dns domain" -or $Item.ToLower() -eq "dnsdomain"){
        $Value = Read-Host What is the DNS Domain

        Set-DhcpServerv4OptionValue -ComputerName $ComputerName -ScopeID $ScopeID -OptionID 15 -Value $Value
    } 
    if($Item.ToLower() -eq "reservations" -or $Item.ToLower() -eq "res"){
        $ScopeStartRange = Read-Host IP Start Range eg.192.168.1.1
        $ScopeEndRange = Read-Host IP End Range eg.192.168.1.1 

        Add-DhcpSeverv4ExclusionRange -ScopeID $ScopeID -ComputerName $ComputerName -StartRange $ScopeStartRange -EndRange $ScopeEndRange
    } 
     
}
catch{
    Write-Host an error has Occurred 
        Write-Host $_
}

Read-Host Push enter to exit