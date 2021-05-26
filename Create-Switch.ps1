param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}


$VMSwitchName = Read-Host What is the VM NAme

            $SwitchType = Read-Host What is the Switch Type `n

            if($SwitchType.ToLower() -eq "wan" -or $SwitchType.ToLower() -eq "exe" -or $SwitchType.ToLower() -eq "external"){
                $HostSwitchs = @()
                $Command = Get-NetAdapter

                foreach($i in $Command){
                    $HostSwitchs += $i
                }

                if($HostSwitchs.name.contains($VMSwitchName)){
                    New-VMSwitch -name $VMSwitchName -NetAdapterName $VMSwitchName -AllowManagementOS $true
                }
                if(-not ($HostSwitchs.name -contains $SwitchName) -and $SwitchType -eq 'wan' -or $SwitchType -eq "external" ){
                    Write-Host That adapter dosent exits `n
                    Write-Host heres list of Adpaters`n
                    Write-Host $HostSwitchs.name `n
                    $HostSwitch = Read-host What is the host switch `n

                    New-VMSwitch -name $VMSwitchName.ToString() -NetAdapterName $VMSwitchName.ToString() -AllowManagementOS $true
                }
            }
            if($SwitchType.ToLower() -eq 'local' -or $SwitchType.ToLower() -eq '.' -or $SwitchType.ToLower() -eq 'lan'){
                New-VMSwitch $VMSwitchName.ToString() -SwitchType Private
            }
            else{
                Write-Host ok vm will not have an adapter 
            }