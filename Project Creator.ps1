$ProjectName = Read-Host 'What is the name of the Project'
$Lang = Read-Host "What Code Lang"

try{
    Write-Host "Where Would you like for it to be stored"

    Add-Type -AssemblyName System.Windows.Forms
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    [void]$FolderBrowser.ShowDialog()
    $FolderBrowser.SelectedPath


    mkdir "$($FolderBrowser.SelectedPath.ToString())\$($ProjectName.ToString())" 
    $dir = "$($FolderBrowser.SelectedPath.ToString())\$($ProjectName.ToString())"  
}
catch{
    Write-Host "An error occurred:"
      Write-Host $_
}


try{ 
    
    New-Item -Path "$($dir)\$($ProjectName.ToString()).$($Lang.ToString())" -ItemType "file" -Value "Created by CringeKidy"; 

}
catch{
    Write-Host "An error occurred:"
      Write-Host $_
}

Write-Host "File Name: $($ProjectName.ToString()).$($Lang.ToString())" -ForegroundColor Green

if(($Lang -match "js") -or ($Lang -match "Javascript") -or ($Lang -match "javascript")){
    
   $answer = Read-Host "Would you like to make a package.json file"

    if(($answer -match "no") -or ($answer -match "n") -or ($answer -match "No")){
        Write-Host Ok Enjoy
    }

    elseif(($answer -match "yes") -or ($answer -match "y") -or ($answer -match "Yes"))
    {
        Write-Host Ok
        $v = Read-Host "Verison(1.0.0)" 
        $desc = Read-Host "Description"
        $main = "$($ProjectName.ToString()).$($Lang.ToString())"
        $author = Read-Host "Author"
        $lsc = Read-Host "Lincense(ISC)"
        
        if($v -match ""){
            $v="1.0.0"
        }
        if($lsc -match ""){
            $lsc = "ISC"
        }


       $json = @{
            name = "$ProjectName"
            verision = "$v"
            description = "$desc"
            main = "$main"
            author = "$author"
            lincense= "$lsc"

        }

       $json | ConvertTo-Json >  "$($FolderBrowser.SelectedPath)\$($ProjectName)\package.json"

       Write-Host File output: "$($FolderBrowser.SelectedPath)\$($ProjectName)\package.json"
       Get-Content -Raw -Path "$($FolderBrowser.SelectedPath)\$($ProjectName)\package.json" | ConvertFrom-Json

    }
  }


  Read-host Push Enter to Exit