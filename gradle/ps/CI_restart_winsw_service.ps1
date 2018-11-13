Write-Host ====================
Write-Host CODER BY xiaoyao9184
Write-Host TIME 2018-08-02 1.0 beta
Write-Host FILE CI_restart_winsw_service
Write-Host DESC replace and restart winsw service
Write-Host Host in $host.Name
Write-Host ====================
Write-Host Change 2018-11-13 Support exit code
Write-Host ====================

#Default variable
#create default RemoteWorkPath when it empty
$RemoteDeployPath = "D:/Test/boot/"
#Special service name, need to be escaped in jenkins pipeline
$LiteralServiceNameRegex = "\[|\]"


if ($host.name -match 'ISE')
{
    #Test var
    $Username = "administrator"
    $Password = "stay young stay simple"
    $ComputerName = "192.168.1.0_0"
    $RemoteWorkPath = "D:/Test/boot/xy-boot-admin"
    $RemoteServiceName = "xy-boot-admin"
    $RemoteWinswName = "xy-boot-admin"
}
else
{
    #CI var
    $Username = $env:User
    $Password = $env:Password
    $ComputerName = $env:Computer
    $RemoteWorkPath = $env:WorkPath 
    $RemoteServiceName = $env:ServiceName
    $RemoteWinswName = $env:WinswName
}




$Script = {
    param($workPath,$serviceName,$winswName)

    #Definition
    function getService($serviceName)
    {
        if($serviceName -match $LiteralServiceNameRegex){
            return Get-Service | Where-Object {$_.ServiceName -eq $serviceName}
        }else{
            return Get-Service $serviceName -ErrorAction SilentlyContinue
        }
    }

    try {
        #Into
        Write-Host "Navigate to work directory" $workPath
        Set-Location -LiteralPath $workPath
        $workPath = Get-Location
        $workPath = $workPath.toString()

        #Check need replace
        $replaceFlag = $false
        if(Test-Path ./temp/){
            Write-Host "Replace files with the" $workPath/temp/ "directory !"
            $replaceFiles = Get-ChildItem ./temp/
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
        $service = getService($serviceName)
        
        #Replace
        #when service is reunning need to stop for replace
        if($replaceFlag){
            #Stop
            if($service -and ($service.Status -eq "Running")){
                Write-Host "Service needs to be stopped!"
                #Stop-Service $serviceName
                $service.Stop();
                #Start-Sleep -Seconds 5
                $service.WaitForStatus('Stopped')
                Write-Host "Service stop completed!"
                $service = getService($serviceName)
            }

            #Replace
            Write-Host "Replacing file!"
            foreach($f in $replaceFiles){
                $target = $workPath + "/" + $f.Name
                Move-Item -LiteralPath $f.FullName -Destination $target -Force -ErrorAction "Stop"
            }
            Remove-Item ./temp/ -Recurse -ErrorAction "Stop"
            Write-Host "Replace completed!"
        }

        #Check need install
        if (!$service){
            $exeService = $workPath + "/" + $winswName + ".exe"
            if(Test-Path -LiteralPath $exeService){
                Write-Host "Service needs to be installed!"
                $winswExeCommand = "& " + $workPath + "/" + $winswName + ".exe install"
                #$winswExeCommand = $workPath + "/" + $winswName + ".exe"
                Write-Host $winswExeCommand
                #Start-Process $winswExeCommand -ArgumentList "install" -wait -NoNewWindow
                Invoke-Expression -Command $winswExeCommand
                if($lastexitcode -eq 0){
                    Write-Host "Service install completed!"
                    $service = getService($serviceName)
                    #Check install again
                    if (!$service){
                        Write-Host -ForegroundColor Red "Error find service" $serviceName "!"
                        return 1
                    }
                }else{
                    throw "Service install failed!"
                    return 1
                }
            }else{
                Write-Host -ForegroundColor Red "Error no winsw exe file" $exeService "to be install!"
                return 1
            }
        }

        #Start
        if($service.Status -eq "Running"){
            Write-Host "Service already started!"
        }else{
            Write-Host "Service need to be start!"
            #Start-Service $serviceName  
            $service.Start();
            #Start-Sleep -Seconds 2
            $service.WaitForStatus('Running')
            Write-Host "Service start completed!"
        }
    } catch {
        return 1
        exit
    }
    return 0
    exit
}

#Check
if([string]::IsNullOrEmpty($RemoteWorkPath)){
    $RemoteWorkPath = $RemoteDeployPath + $RemoteServiceName
}
if([string]::IsNullOrEmpty($RemoteServiceName)){
    throw "Missing primary parameters 'RemoteServiceName'"
}
if([string]::IsNullOrEmpty($RemoteWinswName)){
    $RemoteWinswName = $RemoteServiceName
}

#Print
Write-Host "Username:" $Username "Password:" $Password "ComputerName:" $ComputerName
Write-Host "RemoteWorkPath:" $RemoteWorkPath "RemoteServiceName:" $RemoteServiceName "RemoteWinswName:" $RemoteWinswName

#ISE DEBUG
if ($host.name -match 'ISE'){
    $code = Invoke-Command -Scriptblock $Script -ArgumentList $RemoteWorkPath,$RemoteServiceName,$RemoteWinswName
    exit $code
}

Write-Host "Create session for remote computer and invoke script"
Write-Host --------------------------------------------------

#Create credential object
$SecurePassWord = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $Username, $SecurePassWord

#Create session object with this
$Session = New-PSSession -ComputerName $ComputerName -credential $Cred

#Invoke-Command
$code = Invoke-Command -Session $Session -Scriptblock $Script -ArgumentList $RemoteWorkPath,$RemoteServiceName,$RemoteWinswName

Write-Host --------------------------------------------------
Write-Host "Delete session for remote computer"

#Close Session
Remove-PSSession -Session $Session

#Exit code
Write-Host "Exit Code:" $code
exit $code