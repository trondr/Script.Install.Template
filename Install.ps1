Set-PSDebug -Strict
function Install
{
    $exitCode = 0

    Write-Host "Installling..."
    $exitCode = StartProcess "%InstallCommand%" "%InstallCommandArguments%"
        
    $exitCode = 1

    return $exitCode
}


function UnInstall
{
    $exitCode = 0
    
    Write-Host "UnInstalling..."
    $exitCode = StartProcess "%UnInstallCommand%" "%UnInstallCommandArguments%"
        
    $exitCode = 1

    return $exitCode
}

###############################################################################
#
#   Logging preference
#
###############################################################################
$global:VerbosePreference = "SilentlyContinue"
$global:DebugPreference = "SilentlyContinue"
$global:WarningPreference = "Continue"
$global:ErrorActionPreference = "Continue"
$global:ProgressPreference = "Continue"
###############################################################################
#
#   Start: Main Script - Do not change
#
###############################################################################
$script = $MyInvocation.MyCommand.Definition
Write-Verbose "Script=$script"
$scriptFolder = Split-Path -parent $script
Write-Verbose "ScriptFolder=$scriptFolder"

###############################################################################
#   Loading script library
###############################################################################
$scriptLibrary = [System.IO.Path]::Combine($scriptFolder ,"Library.ps1")
if((Test-Path $scriptLibrary) -eq $false)
{
    Write-Host -ForegroundColor Red "Script library '$scriptLibrary' not found."
    EXIT 1
}
Write-Verbose "ScriptLibrary=$scriptLibrary"
Write-Verbose "Loading script library '$scriptLibrary'..."
. $scriptLibrary
If ($? -eq $false) 
{ 
    Write-Host -ForegroundColor Red "Failed to load library '$scriptLibrary'. Error: $($error[0])"; break 
    EXIT 1
};
###############################################################################
#   Loading script install library
###############################################################################
$scriptInstallLibraryScript = [System.IO.Path]::Combine($scriptFolder , "Tools","Script.Install.Library.ps1")
if((Test-Path $scriptInstallLibraryScript) -eq $false)
{
    Write-Host -ForegroundColor Red "Script library '$scriptInstallLibraryScript' not found."
    EXIT 1
}
Write-Verbose "ScriptInstallLibraryScript=$scriptInstallLibraryScript"
Write-Verbose "Loading install library script '$scriptInstallLibraryScript'..."
. $scriptInstallLibraryScript
If ($? -eq $false) 
{ 
    Write-Host -ForegroundColor Red "Failed to load library '$scriptLibrary'. Error: $($error[0])"; break 
    EXIT 1
};
###############################################################################
#   Loading script install tools C# library
###############################################################################
Write-Verbose "Loading script install tools C# library..."
$assembly = LoadLibrary(CombinePaths($scriptFolder , "Tools", "Script.Install.Tools.Library", "Common.Logging.dll"))
$assembly = LoadLibrary(CombinePaths($scriptFolder , "Tools", "Script.Install.Tools.Library", "Script.Install.Tools.Library.dll"))

$action = GetAction($args)
Write-Verbose "Action=$action"
Write-Host "Executing Install.ps1..."
Write-Host "Executing install action '$installAction'..."
switch($action)
{
    "Install"
    {
        $exitCode = ExecuteAction([scriptblock]$function:Install)
    }

    "UnInstall"
    {
        $exitCode = ExecuteAction([scriptblock]$function:UnInstall)
    }
}
Write-Host "Finished executing Install.ps1. Exit code: $exitCode"
EXIT $exitCode
###############################################################################
#
#   End: Main Script - Do not change
#
###############################################################################
