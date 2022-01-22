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
    
    if($Type.ToLower() -eq "csv"){


        $CSVCreation = Read-Host "Would you like to make the CSV"

        if($CSVCreation.ToLower() -eq 'y' -or $CSVCreation.ToLower() -eq 'yes'){
            $newrow = [PSCustomObject] @{
                "Name" = "Placeholder";
                "ServerName" = "";
                "Userlogin" = "UPN or SAM login";
            }
        
            $newrow | Export-Csv  "$env:USERPROFILE\Desktop\Fill_this_out.csv"
            read-host "I have made a new csv on the desktop. EDIT it with the information you want to add and then come back and hit enter"
        
            $CSVLocation = "$env:USERPROFILE\Desktop\Fill_this_out.csv"
        }
        else{
            Write-Host Where is the CSV File
    
            Add-Type -AssemblyName System.Windows.Forms
            $CSVFile = New-Object System.Windows.Forms.OpenFileDialog 
            [void]$CSVFile.ShowDialog()
            $CSVLocation = $CSVFile.FileName
        }
    
        $Credintal = Read-Host "Is connection information in the CSV Y or N"

        if($Credintal.ToLower() -eq "y" -or $Credintal.ToLower() -eq "yes" ){
            $Users = Import-Csv $CSVLocation
            $Login = $Users[0].Userlogin
            $Server = $Users[0].ServerName

            $ServerSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$Server/PowerShell/ -Authentication Kerberos -Credential $Login
            Import-PSSession $ServerSession -DisableNameChecking `

            foreach ($user in $Users) { 
                Enable-Mailbox -Identity $user.Name -DisplayName $user.Name -Alias $user.name;
            }
            $finshed = $true

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
            
            Import-PSSession $ServerSession -DisableNameChecking 

            $Users = Import-Csv $CSVLocation

            foreach ($user in $Users) { 
                Enable-Mailbox -Identity $user.Name -DisplayName $user.Name -Alias $user.name;
            }

            $finshed = $true

        }
    }
    if($Type.ToLower() -eq "ou"){
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

        $OUpath = read-host "What is the OU Path eg(OU=Users,DC=adatum,DC=com)"

        $ADUsers = Get-ADUser -Filter * -SearchBase $OUpath | Select-Object -expand SamAccountName

        foreach($user in $ADUsers){
            Enable-Mailbox -Identity $user -DisplayName $user -Alias $user;
        }




    }
    else{
        Write-Host "Sorry that is not an option"
    }
}
until($finshed -eq $true)


Read-Host "yes"