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


#Enable PSRemoting
Write-Host "Enable PSRemoting...".

Enable-PSRemoting -Force