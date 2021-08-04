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
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

$finshed = $false
$Exits = $false

do{
    $Type = Read-Host "Would you like to use CSV or Use OU:"
    
    if($Type.ToLower() -ne "ou" -or $Type.ToLower() -ne "csv" ){
        Write-Host "Sorry that is not an option"
    }
    if($Type.ToLower() -eq "csv"){
    
        $Credintal = Read-Host "Is connection information in the CSV Y or N"

        if($Credintal.ToLower() -eq "y" -or $Credintal.ToLower() -eq "yes" ){

        }
        if($Credintal.ToLower() -eq "n" -or $Credintal.ToLower() -eq "no" ){
            do{
                $ServerName = Read-Host "What is the name of the server eg(exchange)"
                $Server = Get-ADComputer -Filter {Name -eq $ServerName}

                try{
                    $Server
                    
                    if($Server){
                        $Exits = $true
                    }
                    else{
                        Write-Host "Sorry not a server"
                    }
                }
                catch{
                    Write-Host "Sorry not a server"
                    $Exits = $false
                }

                
            }
            until($Exits -eq $true)

            $Exits = $false
            
            do{
                $ServerLogin = Get-Credential
                $ServerUser = Get-ADUser -Filter {Name -eq $ServerLogin.UserName -or UserPrincipalName -eq $ServerLogin.UserName -or SamAccountName -eq $ServerLogin.UserName} 
                

                if(!$ServerUser){
                    write-host "Not a user"
                    $Exits = $false
                    Write-Host $Exits
                }
                if($ServerUser){
                    $Exits = $true
                    Write-Host $Exits
                }

            }until($Exits -eq $true)

            

            $ServerSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ServerName/PowerShell/ -Authentication Kerberos -Credential $ServerLogin
            
            Import-PSSession $ServerSession -DisableNameChecking `

            Write-Host Where is the CSV File
    
            Add-Type -AssemblyName System.Windows.Forms
            $CSVFile = New-Object System.Windows.Forms.OpenFileDialog 
            [void]$CSVFile.ShowDialog()
            $CSVLocation = $CSVFile.FileName

            $Users = Import-Csv $CSVLocation

            foreach ($user in $Users) { 
                
            }

            $finshed = $true

        }
    }
    if($Type.ToLower() -eq "ou"){
    
    }
}
until($finshed -eq $true)


Read-Host "yes"