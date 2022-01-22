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


$ChangeUPN = read-host "What is the UPN you want to change to eg(adatum.co.nz)" 

$ExsitingUPN = Get-UserPrincipalNamesSuffix

foreach($upn in $ExsitingUPN){
 
    if($upn -ne $ChangeUPN){
        Get-ADForest | Format-List UPNSuffixes
        Get-ADForest | Set-ADForest -UPNSuffixes @{add="$ChangeUPN"}
    }
}

do{
    $AllUsers = Read-Host "would you like to do this for all currnet mailboxs? (Y or N)"
    switch -regex ($AllUsers) {
        'y(Yes)?'
        {
            $Username = Get-Aduser -Filter * | Select-Object SamAccountName

            foreach($u in $Username){
                Get-User $u.Alias | Set-User -UserPrincipalName "$($u.Alias)@$ChangeUPN"
            }
            $AllUsers = $true
        }
        'n(No)?'
        {
            do{
                $CSVCreation = Read-Host "Do you want to create a CSV | has to be done by csv (Y or N)"
                switch -regex ($CSVCreation) {
                    'y(Yes)?'
                    {
                        $NewCSV = [PSCustomObject]@{
                            "Alias" = "This is the Account name eg Joe.Blogs"
                        }

                        $NewCSV | Export-Csv  "$env:USERPROFILE\Desktop\Fill_this_out.csv"
                        read-host "I have made a new csv on the desktop. EDIT it with the information you want to add and then come back and hit enter"
        
                        $CSVLocation = "$env:USERPROFILE\Desktop\Fill_this_out.csv"
                        $CSVCreation = $true
                    }
                    'n(No)?'
                    {
                        Write-Host Where is the CSV File
    
                        Add-Type -AssemblyName System.Windows.Forms
                        $CSVFile = New-Object System.Windows.Forms.OpenFileDialog 
                        $CSVFile.ShowDialog()
                        $CSVLocation = $CSVFile.FileName
                        $CSVCreation = $true
                    }
                    Default 
                    {
                        Write-Host "Sorry that is not an option"
                        $CSVCreation = $false
                    }
                }
            }
            until($CSVCreation -ne $false)

            $Users = Import-Csv $CSVLocation

            foreach($name in $Users){
                Get-Mailbox -Identity "$($name.Alias)" | Set-User -UserPrincipalName "@$ChangeUPN"
            }

        }
        Default 
        {
            Write-Host "Sorry that is not an option"
            $AllUsers = $false
        }
    }
}until($AllUsers -ne $false)

Read-Host "yes"