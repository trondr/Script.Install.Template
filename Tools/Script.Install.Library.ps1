
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
