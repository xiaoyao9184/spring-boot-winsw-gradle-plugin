#Test var
$Username = "administrator"
$Password = "stay young stay simple"
$ComputerName = "192.168.1.0_0"
$RemoteWorkPath = "D:\Test\boot\xy-boot-admin"
$RemoteJarService = "xy-boot-admin"

#CI var
#$Username = $env:User
#$Password = $env:Password
#$ComputerName = $env:Computer
#$RemoteWorkPath = "D:\Test\boot\" + $env:mainBootName
#$RemoteJarService = $env:mainBootName


$Script = {
    param($workPath,$jarService)

    #Into
    cd $workPath

    #Install
    $service = Get-Service $jarService
    if(!$service){
        Write-Host "Service needs to be installed!"
        $winswExeCommand = $workPath + "\" + $jarService + ".exe install"
        Invoke-Expression -Command:$winswExeCommand
        $service = Get-Service $jarService
    }

    #Stop
    if($service.Status -eq "Running"){
        Write-Host "Service needs to be stopped!"
        Stop-Service $jarService
        Start-Sleep -Seconds 5
    }
    
    #Replace
    if(Test-Path .\temp\){
        $tempFiles = Get-ChildItem .\temp\
        if($tempFiles.Count -gt 0){
            Move-Item -path .\temp\* -destination .\ -force
        }
        Remove-Item .\temp\
    }

    #Start
    Start-Service $jarService

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
$Job = Invoke-Command -Session $Session -Scriptblock $Script -ArgumentList $RemoteWorkPath,$RemoteJarService -AsJob 
$Null = Wait-Job -Job $Job

#Close Session
Remove-PSSession -Session $Session