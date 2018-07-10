#ServerName

param($ComputerName)
#$ComputerName="*"

if(-Not $ComputerName){
    if($env:Computer){
        $ComputerName = $env:Computer
    }else{
        Write-Host "Missing argument 'ComputerName', cant run this script!"
        return
    }
}


#Starting WinRM

$service = Get-Service "WinRM"
if (!$service)
{
    Write-Host -ForegroundColor Red "WinRM not exist!" 
    return
}
if($service.Status -eq "Running")
{
    Write-Host "WinRM already start" 
}
else
{
    Write-Host "Starting WinRM..."
    Start-Service "WinRM"
}


#Get TrustedHosts

$TrustedHosts = Get-Item wsman:\localhost\Client\TrustedHosts

if($TrustedHosts.Value)
{
    $TrustedHostList = $TrustedHosts.Value.Split(",")
}
else
{
    $TrustedHostList = @()
}


if($TrustedHostList -contains $ComputerName)
{
    Write-Host "TrustedHosts already has this remote host:" $ComputerName
    return
}


#Add TrustedHosts

$TrustedHostList += $ComputerName
$TrustedHosts = $TrustedHostList -join ','

Write-Host "TrustedHosts will be set to:" $TrustedHosts

Set-Item wsman:\localhost\Client\TrustedHosts -value $TrustedHosts
