
# Helper functions used by Install.ps1 main script

function GetAction([System.Array]$arguments)
{
    Write-Verbose "Getting action"
    $action = "Install"
    if($arguments.Length -gt 0)
    {
        if($arguments[0] -ieq "Install")
        {
            $action = "Install"
        }
        elseif($arguments[0] -ieq "UnInstall")
        {
            $action = "UnInstall"
        }
    }
    else
    {
        Write-Verbose "Command line args was empty"
    }
    return $action
}

function ExecuteAction([scriptblock]$action)
{
    $exitCode = & $action

    return $exitCode
}

function StartProcess([string]$command, [string]$commandArguments, [string]$workingDirectory, [bool] $waitForExit)
{
    If (Test-Path $command)
    {
        $startInfo = New-Object [System.Diagnostics.ProcessStartInfo]
        $startInfo.WorkingDirectory = $workingDirectory
        $startInfo.Arguments = $commandArguments
        $startInfo.FileName = $command        
        $process = [System.Diagnostics.Process]::Start($startInfo)
        if($waitForExit -eq $true)
        {
            $process.WaitForExit()
        }
        $exitCode = $process.ExitCode
        return $exitCode
    }
    Else
    {
        Write-Host "ERROR: File not found: $command" -BackgroundColor Red
        return 1
    }
}