﻿#Test var
#$Username = "administrator"
#$Password = "stay young stay simple"
#$ComputerName = "192.168.1.0_0"
#$RemoteWorkPath = "D:\Test\boot\xy-boot-admin"
#$RemoteJarService = "xy-boot-admin"

#CI var
$Username = $env:User
$Password = $env:Password
$ComputerName = $env:Computer
$RemoteWorkPath = "D:\Test\boot\" + $env:mainBootName
$RemoteJarService = $env:mainBootName


$Script = {
    param($workPath,$jarService)

    #Into
    Write-Host "Navigate to work directory" $workPath
    cd $workPath

    $service = Get-Service $jarService -ErrorAction SilentlyContinue

    #Stop
    if($service -and ($service.Status -eq "Running"))
    {
        Write-Host "Service needs to be stopped!"
        Stop-Service $jarService
        Start-Sleep -Seconds 5
    }

    #Replace
    if(Test-Path .\temp\)
    {
        Write-Host "Replace files with the .\temp\ directory !"
        $tempFiles = Get-ChildItem .\temp\ | Measure-Object
        if($tempFiles.Count -gt 0){
            Move-Item -path .\temp\* -destination .\ -force
        }
        Remove-Item .\temp\
    }

    
    #Install
    if (!$service)
    {
        $exeService = $workPath + "\" + $jarService + ".exe"
        if(Test-Path $exeService){
            Write-Host "Service needs to be installed!"
            $winswExeCommand = "& " + $workPath + "\" + $jarService + ".exe install"
            #$winswExeCommand = $workPath + "\" + $jarService + ".exe"
            Write-Host $winswExeCommand
            #Start-Process $winswExeCommand -ArgumentList "install" -wait -NoNewWindow
            Invoke-Expression -Command $winswExeCommand
        }else{
            Write-Host -ForegroundColor Red "Error no winsw exe file to be install!"
            return
        }
    }   

    #Start
    Write-Host "Service need to be start!"
    Start-Service $jarService
    Start-Sleep -Seconds 2
}

#ISE DEBUG
if ($host.name -match 'ISE'){
    Invoke-Command -Scriptblock $Script -ArgumentList $RemoteWorkPath,$RemoteJarService
}

#Print
Write-Host "Username:" $Username "Password:" $Password "ComputerName:" $ComputerName
Write-Host "RemoteWorkPath:" $RemoteWorkPath "RemoteJarService:" $RemoteJarService

#Create credential object
$SecurePassWord = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $Username, $SecurePassWord

#Create session object with this
$Session = New-PSSession -ComputerName $ComputerName -credential $Cred

#Invoke-Command
Invoke-Command -Session $Session -Scriptblock $Script -ArgumentList $RemoteWorkPath,$RemoteJarService

#Close Session
Remove-PSSession -Session $Session