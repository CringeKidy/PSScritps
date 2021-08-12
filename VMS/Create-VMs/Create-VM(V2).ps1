function Get-Switch {
    param (
        [String] $Name,
        [String] $Type
    )

    $SwitchExists = Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue

    if($SwitchExists){
        return $Name
    }else{
        switch ($Type.ToLower()) {
            'lan' 
            { 
                $SwitchExists = Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue
                
                if(!$SwitchExists){
                    New-VMSwitch $Name -SwitchType Private
                    return $Name
                }
                else{
                    return $Name
                }
            }
            'wan'
            {
    
                $SwitchExists = Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue
    
                if(!$SwitchExists){
                    $WANCard = Get-NetAdapter -Name * -Physical
    
                    if(!$WANCard){
                        $SearchName = Read-Host "Couldnt find a NIC called Ethernet or Wi-fi. What is the name of your external"
                        $WANCard = Get-NetAdapter -Name $SearchName -Physical
                    }
    
                    New-VMSwitch -name $Name -NetAdapterName $WANCard[0].Name -AllowManagementOS $true
                    return $Name
                }
                else{
                    return $Name
                }
            }
            {$null -eq $Type}{
                return $VMSwitch = "Default Switch"
            }
        }
    }

    
}
function Get-ISO() {
    param (
        [string]$location
    )
    
    switch ($location) {
        (!$location){ 
            do{
                $IsoWanted = Read-Host 'there is no ISO added do you want to add one (Y or N)'
                switch -Regex ($IsoWanted.ToLower()) {
                    'y(es)?' 
                    {
                        Write-Host Where is the iso
    
                        Add-Type -AssemblyName System.Windows.Forms
                        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
                        $FileBrowser.ShowDialog()

                       return $FileBrowser.FileName
                    }
                    'n(o)?'{
                        $NetworkBoot = read-host "Would you like to network boot (Y or N)"

                        switch -Regex ($NetworkBoot.ToLower()){
                            'y(es)?'
                            {
                                return $true
                            }
                            'n(o)?'
                            {
                                return Write-Host "Ok then you are going to have some sort of boot device before booting VM"
                            }
                        }
                    }
                    Default 
                    {
                        Write-Host "Sorry that is not an option"
                        $IsoWanted = $false
                    }
                }

            }until($IsoWanted -ne $false)
        }
        {$null -ne $location}{
            
            $TestLocation = Test-Path $location

            if(!$TestLocation){
                do{
                    $IsoWanted = Read-Host 'the iso did not exits do you want to find a new one (Y or N)'
                    switch -Regex ($IsoWanted.ToLower()) {
                        'y(es)?' 
                        {
                            Write-Host Where is the iso
        
                            Add-Type -AssemblyName System.Windows.Forms
                            $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
                            $FileBrowser.ShowDialog()
    
                           return $FileBrowser.FileName
                        }
                        'n(o)?'{
                            $NetworkBoot = read-host "Would you like to network boot (Y or N)"
    
                            switch -Regex ($NetworkBoot){
                                'y(Yes)?'
                                {
                                    return $true
                                }
                                'n(No)?'
                                {
                                    return Write-Host "Ok then you are going to have some sort of boot device before booting VM"
                                }
                            }
                        }
                        Default 
                        {
                            Write-Host "Sorry that is not an option"
                            $IsoWanted = $false
                        }
                    }
    
                }until($IsoWanted -ne $false)
            }else{
                return $location
            }

            
        }
    }

}
function Set-VHDSize(){
    
    param(
        [String]$VHDSize,
        [int64]$VMVHDSize
    )
    
    switch ($VHDSize) {
        {$_.contains('gb')} { 
            
            $VMVHDSize = $_.replace('gb', '')
            return $VMVHDSize * 1GB
        }
        {$_.contains('mb')} { 
            $VMVHDSize = $_.replace('mb', '')
            return $VMVHDSize * 1MB
        }
        Default{
            $VHDFix = read-host 'There is no GB or MB added to VHD Size value what would you like to add'

            switch ($VHDFix.ToLower()) {
                'gb' 
                {
                    $VMVHDSize = $VHDSize.substring(0, 1) 
                    return $VMVHDSize * 1024
                }
                'mb' 
                {
                    $VMVHDSize = $VHDSize.substring(0, 1) 
                    return $VMVHDSize * 1024 * 1024
                }
            }
        }
    }
}

function Set-Ram(){
    
    param(
        [String]$RAM,
        [int64]$VMRam
    )
    
    switch ($RAM) {
        {$_.contains('gb')} { 
            
            $VMRam = $_.replace('gb', '')
            return $VMRam * 1GB
        }
        {$_.contains('mb')} { 
            $VMRam = $_.replace('mb', '')
            return $VMRam * 1MB
        }
        Default{
            $RAMFix = read-host 'There is no GB or MB added to RAM size what would you like to add'

            switch ($RAMFix.ToLower()) {
                'gb' 
                {
                    $VMRam = $RAM.substring(0, 1) 
                    return $VMRam * 1024
                }
                'mb' 
                {
                    $VMRam = $RAM.substring(0, 1) 
                    return $VMRam * 1024 * 1024
                }
            }
        }
    }
}

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
    $CreationType = Read-Host 'You like to do this by CSV or go Through PS'
    switch -Regex ($CreationType.ToLower()) {
        "csv"
        {
            do{
                $CSVCreation = Read-Host "Do you want to make a csv"
                switch -Regex ($CSVCreation.ToLower()) {
                    "y(es)?" 
                    {
                        $newrow = [PSCustomObject] @{
                            "VMName" = "";
                            "Gen" = "1 or 2";
                            "RAM" = "<number><mb or gb>";
                            "Cores" = "just your max cores"
                            "Switch" = "Dosent matter if it dosent exists script can make it";
                            "SwitchType" = "This is for if the switch dosent exist options(LAN | WAN) if no type is provied script will not make new switch"
                            "VHDSize" = "<number><mb or gb>";
                            "VHDLocation" = "example(C:\VHD)"
                            "ISOLocation" = "example(C:\ISO\Windows10.iso)"
                        }
                    
                        $newrow | Export-Csv  "$env:USERPROFILE\Desktop\Fill_this_out.csv"
                        read-host "I have made a new csv on the desktop. EDIT it with the information you want to add and then come back and hit enter"
                    
                        $CSVLocation = "$env:USERPROFILE\Desktop\Fill_this_out.csv"

                        $VMConfig = Import-Csv $CSVLocation

                        foreach($Setting in $VMConfig){
                            $RAM = Set-Ram -RAM $Setting.RAM
                            $VHDSize = Set-VHDSize -VHDSize $Setting.VHDSize
                            $VMISO = Get-ISO -location $Setting.ISOLocation
                            $VMSwitch = Get-Switch -Name $Setting.Switch -Type $Setting.SwitchType
                            
                            if($VMISO -eq $true){
                                New-VM $Setting.VMName -MemoryStartupBytes $RAM -NewVHDPath "$($Setting.VHDLocation)\$($Setting.VMName).vhdx" -NewVHDSizeBytes $VHDSize -SwitchName "Default Switch" -Generation $Setting.Gen | Set-VM -ProcessorCount $Setting.Cores -DynamicMemory -CheckpointType Disabled
                                Set-VMFirmware -VMName $Setting.VMName -FirstBootDevice "Default Switch" -ErrorAction SilentlyContinue
                            }
                            else{
                                New-VM $Setting.VMName -MemoryStartupBytes $RAM -NewVHDPath "$($Setting.VHDLocation)\$($Setting.VMName).vhdx" -NewVHDSizeBytes $VHDSize -SwitchName $VMSwitch -Generation $Setting.Gen | Set-VM -ProcessorCount $Setting.Cores -DynamicMemory -CheckpointType Disabled
                                Add-VMDvdDrive -VMName $Setting.VMName -Path $VMISO

                                $Firmware = Get-VMFirmware -VMName $Setting.VMName
                                $hddrive = $Firmware.BootOrder[0]
                                $pxe = $Firmware.BootOrder[1]
                                $dvddrive = $Firmware.BootOrder[2]

                                Set-VMFirmware -VMName $Setting.VMName -BootOrder $dvddrive,$hddrive,$pxe
                            }
                        }

                        $finshed = $true
                    }
                    "n(ope)?"{
                        Write-Host Where is the CSV File
        
                        Add-Type -AssemblyName System.Windows.Forms
                        $CSVFile = New-Object System.Windows.Forms.OpenFileDialog 
                        [void]$CSVFile.ShowDialog()
                        $CSVLocation = $CSVFile.FileName

                        $VMConfig = Import-Csv $CSVLocation

                        foreach($Setting in $VMConfig){
                            $RAM = Set-Ram -RAM $Setting.RAM
                            $VHDSize = Set-VHDSize -VHDSize $Setting.VHDSize
                            $VMISO = Get-ISO -location $Setting.ISOLocation
                            $VMSwitch = Get-Switch -Name $Setting.Switch -Type $Setting.SwitchType
                            
                            if($VMISO -eq $true){
                                New-VM $Setting.VMName -MemoryStartupBytes $RAM -NewVHDPath "$($Setting.VHDLocation)\$($Setting.VMName).vhdx" -NewVHDSizeBytes $VHDSize -SwitchName "Default Switch" -Generation $Setting.Gen | Set-VM -ProcessorCount $Setting.Cores -DynamicMemory -CheckpointType Disabled
                                Set-VMFirmware -VMName $Setting.VMName -FirstBootDevice "Default Switch" -ErrorAction SilentlyContinue
                            }
                            else{
                                New-VM $Setting.VMName -MemoryStartupBytes $RAM -NewVHDPath "$($Setting.VHDLocation)\$($Setting.VMName).vhdx" -NewVHDSizeBytes $VHDSize -SwitchName $VMSwitch -Generation $Setting.Gen | Set-VM -ProcessorCount $Setting.Cores -DynamicMemory -CheckpointType Disabled
                                Add-VMDvdDrive -VMName $Setting.VMName -Path $VMISO

                                $Firmware = Get-VMFirmware -VMName $Setting.VMName
                                $hddrive = $Firmware.BootOrder[0]
                                $pxe = $Firmware.BootOrder[1]
                                $dvddrive = $Firmware.BootOrder[2]

                                Set-VMFirmware -VMName $Setting.VMName -BootOrder $dvddrive,$hddrive,$pxe
                            }
                        }

                        $finshed = $true
                    }
                    default{
                        Write-Output "Sorry that is not an option"
                        $CSVCreation = 'nope'
                    }
                }
            }
            until($CSVCreation -ne 'nope')

            $finshed = $true
        }
        "p(owershell)?"
        {
            $MutipleVMS = Read-Host "Build Mutiple VMS?"

            switch -regex ($MutipleVMS) {
                "y(Yes)?"
                {
                    do{
                        $Amount = Read-Host "How many VMs?"
                        Write-Host "Sorry that is not a Number"
                    }
                    until($Amount -match '^\d+$')

                    $CustomizeVM = Read-Host "Do you want to do Spreate Settings for Each VM"
                    $SavedSettings = @{
                        $VMName = @($null);
                        $VMRam = @($null);
                        $VMCores = @($null);
                        $VMGen = @($null);
                        $VHDSize = @($null);
                        $VHDLocation = @($null);
                    }

                    switch -regex ($CustomizeVM) {
                        'y(Yes)?'
                        {
                           $Things = 'VMName', 'VMRam', 'VMCores', 'VMGen', 'VHDSize', 'VMLocation';
                            do{
                                foreach ($name in $Things) {
                                    $Answer = Read-Host "please enter the value for $($VMName)"

                                    $Answer = $Answer.Split(" ")
                                    Write-Host $Answer
                                }
                                
                            }until($Amount -eq 0)
                        }
                        Default {}
                    }


                }
                Default {}
            }
            
            
            
            New-VM $Setting.VMName -MemoryStartupBytes $RAM -NewVHDPath "$($Setting.VHDLocation)\$($Setting.VMName).vhdx" -NewVHDSizeBytes $VHDSize -SwitchName "Default Switch" -Generation $Setting.Gen | Set-VM -ProcessorCount $Setting.Cores -DynamicMemory -CheckpointType Disabled
            $finshed = $true
            
        }
        default{
            Write-Output "Sorry that is not an option"
            $finshed = $false
        }
    }
}
until($finshed -eq $true)
