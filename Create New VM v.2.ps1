param([switch]$Elevated)

Start-Process powershell -ArgumentList '-noprofile -file MyScript.ps1' -verb RunAs

$MutipleMVs = Read-Host Is there Mutiple VMs?


if($MutipleMVs.ToLower() -eq "yes" -or $MutipleMVs.ToLower() -eq "y"){
    $Amount = Read-Host "How many VMs"
    $VMSettings = Read-Host "Do you want to use Indavidual Settings"
        if($VMSettings.ToLower() -eq "yes" -or $VMSettings.ToLower() -eq "y"){
        
            $DataCollection = @()
            $Data = New-Object -TypeName PSObject
            $Data | Add-Member -MemberType NoteProperty -Name Name -Value ""
            $Data | Add-Member -MemberType NoteProperty -Name "VMRam (GB or MB)" -Value ""
            $Data | Add-Member -MemberType NoteProperty -Name "Genration" -Value ""
            $Data | Add-Member -MemberType NoteProperty -Name "Core Count" -Value ""
            $Data | Add-Member -MemberType NoteProperty -Name "VHD Path" -Value ""
            $Data | Add-Member -MemberType NoteProperty -Name "VHD Size (GB or MB)" -Value ""
            $Data | Add-Member -MemberType NoteProperty -Name "Network Switch" -Value ""
            $Data | Add-Member -MemberType NoteProperty -Name "ISO Path" -Value ""
            $DataCollection += $Data
            $DataCollection | Export-csv "./Settings.csv" -force

            Read-Host "There is a csv in the place where you started this script open and it put the settings in you want and then push enter"
            
            Import-csv "./Settings.csv" | ForEach-Object {
                Write-Host "VMName: $Name"
            }



        }

}