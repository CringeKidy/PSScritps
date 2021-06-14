#Elevating the powershell Session to Admin Perms

param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
        Read-Host "Was not able to start Powershell with Administrtor Permisssions please run Set-ExecutionPolicy Unrestricted"
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

#Asking if user want to multiple VMs being made
$MutipleVMs = Read-Host Do you want to do Mutiple VMs `n

#Seeing if you user said Yes or No
if($MutipleVMs.ToLower() -eq 'y' -or $MutipleVMs.ToLower() -eq 'yes'){
    $VMName = 'VM'
}
if($MutipleVMs.ToLower() -eq 'n' -or $MutipleVMs.ToLower() -eq 'no'){
    $VMName = Read-Host What is the name of the VM `n
}

#User input for VM Specs
$VMRam = Read-Host How much ram  `n     #User input for how much RAM
$VMSwitchs =  Get-VMSwitch              #User Input what switch do they want to add
$ExistingSwitchs = @()                  #Array for all the Switches that Already Exits

foreach($i in $VMSwitchs){  #Doing a Foreach Loop for the VM Switch that allready exits
    $ExistingSwitchs += $i
}
try{ #try cacth for error catching

    Write-Host -ForegroundColor Yellow List of adpaters:
        Write-Host -ForegroundColor Yellow $ExistingSwitchs.name 

    #Asking what switch do you want to add off the Existing Switchs
    $VMSwitchName = Read-Host What switch would you like to add `n


    if($ExistingSwitchs.name.contains($VMSwitchName)){
        
        #Tell user that script is adding VM Switch 
        Write-Host -ForegroundColor Magenta Ok Adding VM Switch 
    }
    else{

        #the switch dose not exits. So asking user if they want to make a new Switch
        $Answer = Read-Host it dosnet look like that switch exists do you want to create it 

        if($Answer.ToLower() -eq "yes" -or $Answer.ToLower() -eq "y"){
        
            #if they User enters Yes it gose through the process of making the switch
            Write-Host got the name: $VMSwitchName 
            $SwitchType = Read-Host What is the Switch Type 

            #if the user enters they want a WAN adaoter it will go through making the WAN Adapter
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
                    $HostSwitch = Read-host What is the Adapter that connects to the Internet on the HOST machine `n

                    New-VMSwitch -name $VMSwitchName.ToString() -NetAdapterName $HostSwitch.ToString() -AllowManagementOS $true
                }
            }

            #If the user wants to add a LAN Adapter it will go through the making a LAN adpater 
            if($SwitchType.ToLower() -eq 'local' -or $SwitchType.ToLower() -eq '.' -or $SwitchType.ToLower() -eq 'lan'){
                New-VMSwitch $VMSwitchName.ToString() -SwitchType Private
            }
        }
        else{
                #if the user dosnt not want ot make or add a Switch to the vm it will till the user they need switch to be able to create a vm
                Read-host You need a Network Adpater to create VM so Adding Defualt Switch
                $VMSwitchName = 'Default Switch'
                

            }
    }
}
catch{
    #if there is any errors that happen withen any of the Creating the VM Swictch 
    #it will catch it and continue the script
    Write-Host -ForegroundColor Red "An error occurred:"
      Write-Host -ForegroundColor Red $_
      Read-Host Push enter to exit
}

#Asking the user what Genaration do they want for the VM
$Gen = Read-Host What gen `n

#asking the user what CPU Core count they want in the VM 
$CoreCount = Read-Host How many cores 

#Askning the user where they would like to Astore the VHDP    
Write-Host "Where would you like to Store VHD"

#opens a File Exploer Windows
Add-Type -AssemblyName System.Windows.Forms
$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$FolderBrowser.RootFolder = 'MyComputer' 
$FolderBrowser.ShowDialog()

#Asking the User what size do they want the VHD
$VMSize = Read-Host What size is the hard Drive

#Varibale Validation for how much RAM the User want in the VM 
if([int64]$VMRam.ToLower().Contains("gb")){
    $RamOutput = [int64]$VMRam.tolower().Replace('gb','') * 1GB   #Gets the Number that the User inputed and devided by 1000mb EG 1gb * 1mb = 1024
}
if([int64]$VMRam.ToLower().Contains("mb")){
    $RamOutput = [int64]$VMRam.tolower().Replace('mb','') * 1MB   #Dose the same for MB
}

if([int64]$VMSize.ToLower().Contains("gb")){
    $VHDOutput = [int64]$VMSize.tolower().Replace('gb','') * 1GB  #Dose the same the RAM Coverts the 1GB to MB
}
if([int64]$VMSize.ToLower().Contains("mb")){
    $VHDOutput = [int64]$VMSize.tolower().Replace('mb','') * 1MB
}

if(-not([int64]$VMSize.ToLower().Contains("gb"))){
    $VHDOutput = [int64]$VMSize * 1gb
}
if(-not([int64]$VMRam.ToLower().Contains("gb"))){
    $RamOutput = [int64]$VMRam * 1gb
}

#Getting ready to make the VMS
if($MutipleVMs.ToLower() -eq 'y' -or $MutipleVMs -eq 'yes'){
    #Asking the user How many VMS they want to make 
    [int64]$HowMany = Read-Host How many VMs `n                                     

    #Inzilatinzoing the timer varibeles
    [int64]$DVDVMs = $HowMany + 1
    [int64]$NewNameInt = $HowMany + 1
    [int64]$NewNameInt2 = $HowMany  + 1
    [int64]$Otherint = $HowMany + 1
    [int64]$AddingDVDInt = $HowMany + 1


    #asking the user if they want to rename the VMS
    $NameVMs = Read-Host Do you want to name the Mutiple 
   
    $NameVMs -eq $NameVMs.ToLower()
    if($NameVMs -eq 'y' -or $NameVMs -eq 'yes'){
        #if yes it will do a loop to rename all of the vms
        $NewNamesList = @()
        do{
            $NewName = Read-Host What new name do you want to call "$VMName.$NewNameInt"
            $NewNameInt = $NewNameInt - 1

            if($NewName -ne ""){
            $NewNamesList += $NewName
            }

        }until($NewNameInt -eq 0)

        [int64]$NewNameInt = $HowMany

        Write-Host rerite the VM Names
        
        #Now making the new VMs with the renamed VMs
        do{
            foreach($i in $NewNamesList){
                new-vm $i -MemoryStartupBytes $RamOutput -NewVHDPath "$($FolderBrowser.SelectedPath)\$i.vhdx" -NewVHDSizeBytes $VHDOutput -SwitchName $VMSwitchName -Generation $Gen | Set-VM -ProcessorCount $CoreCount -StaticMemory -CheckpointType Disabled
                $NewNameInt = $NewNameInt - 1
                }
        }until($NewNameInt -eq 0)

    }

    if($NameVMs -eq 'n' -or $NameVMs -eq 'no'){

        #If user said No it will just do the vmname and add the int at the end EG VM.1
        do{
            new-vm "$VMName.$HowMany" -MemoryStartupBytes $RamOutput -NewVHDPath "$($FolderBrowser.SelectedPath)\$VMName.$HowMany.vhdx" -NewVHDSizeBytes $VHDOutput -SwitchName $VMSwitchName -Generation $Gen | Set-VM -ProcessorCount $CoreCount -StaticMemory -CheckpointType Disabled
            $HowMany = $HowMany - 1
        }until($HowMany -eq 0)
    }
}
else{
    #If MutipleUsers is No it will just make the VM with all of the Varibils
    new-vm $VMName.ToString() -MemoryStartupBytes $RamOutput -NewVHDPath "$($FolderBrowser.SelectedPath)\$VMName.vhdx" -NewVHDSizeBytes $VHDOutput -SwitchName $VMSwitchName -Generation $Gen | Set-VM -ProcessorCount $CoreCount -StaticMemory -CheckpointType Disabled
}    



#telling the user the Configuration of the VM
Write-Host VM Created:
    Write-Host -ForegroundColor Green "
        VM Name: $VMName
        VM RAM: $VMRam
        VM Core Count: $CoreCount
        Genaration: $Gen
        Switch: $VMSwitchName
        VM VHD Name: $VMName.vhdx
        VM VHD Path: $($FolderBrowser.SelectedPath)
        VM VHD Size: $VMSize
    "


#Asking the User wither they want to Add and ISO to the VM
$AddDrive = Read-Host Do you want to add ISO

if($AddDrive.ToLower() -eq 'y' -or $AddDrive.ToLower() -eq 'yes'){
    Write-Host Where is the iso
    
    #if the user said yes it will show a file Exploere and ask the user where the file is 
    Add-Type -AssemblyName System.Windows.Forms
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
    [void]$FileBrowser.ShowDialog()
    $FileBrowser.FileName

    Write-Host Adding Iso
    
    $VMDvdDrive = @()
    

    #Seeing wither the user did Mutiple VMs or not
    if($MutipleVMs.ToLower() -eq 'y' -or $MutipleVMs.ToLower() -eq 'yes'){
        
        #Seeing wither the User rename all of the VMs
        if($NameVMs -eq 'y' -or $NameVMs -eq 'yes'){
            
            #Sets the DVD as the First Boot Device 
            foreach($i in $NewNamesList){
                Add-VMDvdDrive $i -Path $FileBrowser.FileName 
                $VMDvdDrive += Get-VMDvdDrive $NewNamesList

                foreach($DVD in $VMDvdDrive){
                Set-VMFirmware $DVD.VMName -FirstBootDevice $DVD
                Write-Host Iso Added: $DVD.Name VM: $i 
                }
            }
        }
        if($NameVMs -eq 'n' -or $NameVMs -eq 'n'){
            
            #Sets the DVD as the First Boot Device 
            Do{
                Write-Host $AddingDVDInt
                Add-VMDvdDrive "$VMName.$AddingDVDInt" -Path $FileBrowser.FileName 
                $VMDvdDrive += Get-VMDvdDrive "$VMName.$AddingDVDInt"

                $AddingDVDInt = $AddingDVDInt - 1
             }until($AddingDVDInt -eq -1)

             foreach($DVD in $VMDvdDrive){
                Set-VMFirmware $DVD.VMName -FirstBootDevice $DVD
                Write-Host Iso Added: $DVD.Name VM: $DVD.VMName
            }
        }
     }
     #if the user just did one VM it will just add the ISO to the one VM
     if($MutipleVMs.ToLower() -eq 'n' -or $MutipleVMs.ToLower() -eq 'no'){
        Add-VMDvdDrive $VMName -Path $FileBrowser.FileName
        $DvdDrive = Get-VMDvdDrive $VMName
        Set-VMFirmware $VMName -FirstBootDevice $DvdDrive

        
     }
}





#Asking the User if they want to Start and Connect to the VMS
$VMConnect = Read-Host Do you want to connect to the VMs


if($VMConnect.ToLower() -eq 'y' -or $VMConnect -eq 'yes'){ 
         if($MutipleVMs.ToLower() -eq 'n' -or $MutipleVMs.ToLower() -eq 'no'){
            try{
                Start-VM $VMName
                vmconnect localhost $VMName
            }catch{
                Write-Host $_
                Read-Host Im gonna break your pc if i continue so im going to stop now
                Exit
            }
        }
        elseif($NameVMs -eq 'y' -or $NameVM -eq 'yes'){
            Try{
                foreach($i in $NewNamesList){
                Start-VM $i
                vmconnect localhost $i
                }
            }catch{
                Write-Host $_
                Read-Host Im gonna break your pc if i continue so im going to stop now
                Exit
            }
     
        }
        elseif($NameVMs -eq 'n' -or $NameVM -eq 'n'){
            try{
                    do{
                        Start-VM "$VMName.$Otherint"
                        vmconnect localhost "$VMName.$Otherint"
                        $Otherint = $Otherint - 1

                    }until($Otherint -eq -1)
                }
            catch{
                Write-Host $_
                Read-Host Im gonna break your pc if i continue so im going to stop now
                Exit
            }
    }  
}


exit