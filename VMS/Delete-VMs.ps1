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

$MutipleVms = Read-Host Do mutiple VMs

$VMlist = @()
$VMVHDList = @()

if($MutipleVms.ToLower() -eq "y" -or $MutipleVms.ToLower() -eq "yes"){
    Write-Host Enter all the names of the VMS you want to delete. When finshed just Push enter
    do{

    $HowMany = Read-Host What is the vms Name

    if($HowMany -ne ""){
        $VMlist += $HowMany
    }

    }until($HowMany -eq "")

        Write-Host VM Names: $VMlist

        Write-Host Getting VHDS `n
        $CountDown = $VMlist.count
    do{
        
        foreach($i in $VMlist){

            $A = Get-VM $i| Select-Object -ExpandProperty HardDrives | Select-Object Path
            $A = Get-VM $i | Select-Object -ExpandProperty HardDrives
            $B=$A.Path

            Remove-Item -Path $B
            Write-Host Deleting DVD: $B `n

           $CountDown = $CountDown - 1
        }
    }until($CountDown -eq 0)

    $CountDown = $VMlist.count
    Write-Host $CountDown 
    do{
       foreach($e in $VMlist){
        Write-Host Deleting VM: $e `n
        Remove-VM $e -Force

        $CountDown = $CountDown - 1
       }
       

    }until($CountDown -eq 0)

    Read-Host "VMS that were Delete
        $VMList
        Push enter to exit
        "
    break
}

Write-Host Write the VM Name you want to delete
$VMName = Read-Host What is the VM Name

Write-Host Getting Dvd `n

$A = Get-VM $VMName| Select-Object -ExpandProperty HardDrives | Select-Object Path
$A = Get-VM $VMName | Select-Object -ExpandProperty HardDrives
$B=$A.Path

Remove-Item -Path $B
Write-Host Deleting DVD: $B `n

Write-Host Deleting VM `n
Remove-VM $VMName -Force

Read-Host Push Enter to exit


