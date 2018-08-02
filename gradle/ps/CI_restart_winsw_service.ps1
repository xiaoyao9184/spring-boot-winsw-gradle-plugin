Write-Host "Host in:" $host.name

#Default variable
$RemoteDeployPath = "D:\Test\boot\"


if ($host.name -match 'ISE')
{
    #Test var
    $Username = "administrator"
    $Password = "stay young stay simple"
    $ComputerName = "192.168.1.0_0"
    $RemoteWorkPath = "D:\Test\boot\xy-boot-admin"
    $RemoteJarService = "xy-boot-admin"
    $RemoteWinswName = "xy-boot-admin"
}
else
{
    #CI var
    $Username = $env:User
    $Password = $env:Password
    $ComputerName = $env:Computer
    $RemoteWorkPath = $env:workPath 
    $RemoteJarService = $env:mainBootName
    $RemoteWinswName = $env:winswName
}




$Script = {
    param($workPath,$jarService,$winswName)

    #Definition
    function getService($serviceName)
    {
        if($serviceName -match "\[|\]"){
            return Get-Service | Where-Object {$_.ServiceName -eq $serviceName}
        }else{
            return Get-Service $serviceName -ErrorAction SilentlyContinue
        }
    }

    #Into
    Write-Host "Navigate to work directory" $workPath
    Set-Location -LiteralPath $workPath

    #Check need replace
    $replaceFlag = $false
    if(Test-Path .\temp\){
        Write-Host "Replace files with the" $workPath\temp\ "directory !"
        $replaceFiles = Get-ChildItem .\temp\
        $fileStatus = $replaceFiles | Measure-Object
        if($fileStatus.Count -gt 0){
            Write-Host "Replace" $fileStatus.Count "files into the working directory!"
            $replaceFlag = $true
        }else{
            Write-Host "Replace no need!"
        }
    }else{
        Write-Host "Replace no need!"
    }

    #Service
    $service = getService($jarService)
    
    #Replace
    #when service is reunning need to stop for replace
    if($replaceFlag){
        #Stop
        if($service -and ($service.Status -eq "Running")){
            Write-Host "Service needs to be stopped!"
            #Stop-Service $jarService
            $service.Stop();
            Start-Sleep -Seconds 5
            Write-Host "Service stop completed!"
            $service = getService($jarService)
        }

        #Replace
        Write-Host "Replacing file!"
        foreach($f in $replaceFiles){
            Move-Item -LiteralPath $f.FullName -Destination $workPath\$f -force
        }
        Remove-Item .\temp\ -ErrorAction "Stop"
        Write-Host "Replace completed!"
    }

    #Check need install
    if (!$service){
        $exeService = $workPath + "\" + $winswName + ".exe"
        if(Test-Path -LiteralPath $exeService){
            Write-Host "Service needs to be installed!"
            $winswExeCommand = "& " + $workPath + "\" + $winswName + ".exe install"
            #$winswExeCommand = $workPath + "\" + $winswName + ".exe"
            Write-Host $winswExeCommand
            #Start-Process $winswExeCommand -ArgumentList "install" -wait -NoNewWindow
            Invoke-Expression -Command $winswExeCommand
            if($lastexitcode -eq 0){
                Write-Host "Service install completed!"
                $service = getService($jarService)
                #Check install again
                if (!$service){
                    Write-Host -ForegroundColor Red "Error find service" $jarService "!"
                    return
                }
            }else{
                throw "Service install failed!"
                return
            }
        }else{
            Write-Host -ForegroundColor Red "Error no winsw exe file" $exeService "to be install!"
            return
        }
    }

    #Start
    if($service.Status -eq "Running"){
        Write-Host "Service already started!"
        return
    }else{
        Write-Host "Service need to be start!"
        #Start-Service $jarService
        $service.Start();
        Start-Sleep -Seconds 2
        Write-Host "Service start completed!"
    }
}

#Check
if([string]::IsNullOrEmpty($RemoteWorkPath)){
    $RemoteWorkPath = $RemoteDeployPath + $env:mainBootName
}
if([string]::IsNullOrEmpty($RemoteJarService)){
    throw "Missing primary parameters 'RemoteJarService'"
}
if([string]::IsNullOrEmpty($RemoteWinswName)){
    $RemoteWinswName = $RemoteJarService
}

#Print
Write-Host "Username:" $Username "Password:" $Password "ComputerName:" $ComputerName
Write-Host "RemoteWorkPath:" $RemoteWorkPath "RemoteJarService:" $RemoteJarService "RemoteWinswName:" $RemoteWinswName

#ISE DEBUG
if ($host.name -match 'ISE'){
    Invoke-Command -Scriptblock $Script -ArgumentList $RemoteWorkPath,$RemoteJarService,$RemoteWinswName
    return
}

#Create credential object
$SecurePassWord = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $Username, $SecurePassWord

#Create session object with this
$Session = New-PSSession -ComputerName $ComputerName -credential $Cred

#Invoke-Command
Invoke-Command -Session $Session -Scriptblock $Script -ArgumentList $RemoteWorkPath,$RemoteJarService,$RemoteWinswName

#Close Session
Remove-PSSession -Session $Session