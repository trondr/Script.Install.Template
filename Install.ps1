Param(
    [Parameter(Position=0)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Install","UnInstall")]
    [string]
    $Action=$(throw "Missing command line parameter. First parameter must be an action in the set: Install,UnInstall")
)

Set-PSDebug -Strict

function Init
{    
    $global:logsDirectory =  [System.IO.Path]::GetFullPath([System.IO.Path]::Combine([System.Environment]::GetEnvironmentVariable("Public"),"Logs"))
    if((Test-Path $logsDirectory) -eq $false)
    {
        [System.IO.Directory]::CreateDirectory($logsDirectory)
    }
    return 0
}

function Install
{
    $exitCode = 0
    Write-Host "Installling..."
    #$exitCode = StartProcess "$(GetMsiExecExe)" "/i`"$(GetVendorInstallIniMsiFilePath)`" /qn REBOOT=REALLYSUPPRESS /lv! `"$logsDirectory\Install_$(GetVendorInstallIniMsiFileName).log`"" $null $true    
    return $exitCode
}


function UnInstall
{
    $exitCode = 0
    Write-Host "UnInstalling..."
    #$exitCode = StartProcess "$(GetMsiExecExe)" "/x`"$(GetVendorInstallIniMsiFilePath)`" /qn REBOOT=REALLYSUPPRESS /lv! `"$logsDirectory\UnInstall_$(GetVendorInstallIniMsiFileName).log`"" $null $true
    return $exitCode
}

switch($Action)
{
    "Install"   { $actionScriptBlock = [scriptblock]$function:Install }
    "UnInstall" { $actionScriptBlock = [scriptblock]$function:UnInstall }
    default { 
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        EXIT 1
    }
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
$global:script = $MyInvocation.MyCommand.Definition
Write-Verbose "Script=$script"
$global:scriptFolder = Split-Path -parent $script
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
if($assembly -eq $null)
{
    EXIT 1
}
$assembly = LoadLibrary(CombinePaths($scriptFolder , "Tools", "Script.Install.Tools.Library", "Script.Install.Tools.Library.dll"))
if($assembly -eq $null)
{
    EXIT 1
}
Write-Verbose "Action=$action"
Write-Host "Executing $action action..."
$exitCode = ExecuteAction([scriptblock]$function:Init)
if($exitCode -eq 0)
{
    $exitCode = ExecuteAction([scriptblock]$actionScriptBlock)
}
else
{
    Write-Host -ForegroundColor Red "Init() function failed with error code: $exitCode"
}
Write-Host "Finished executing Install.ps1. Exit code: $exitCode"
EXIT $exitCode
###############################################################################
#
#   End: Main Script - Do not change
#
###############################################################################
