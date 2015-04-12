function Install
{
    $exitCode = 0

    #Install code here

    return $exitCode
}


function UnInstall
{
    $exitCode = 0

    #UnInstall code here

    return $exitCode
}

###############################################################################
#
#   Main Script - Do not change
#
###############################################################################
$script = $MyInvocation.MyCommand.Definition
Write-Verbose "Script=$script"
$scriptFolder = split-path -parent $script
Write-Verbose "ScriptFolder=$scriptFolder"
$libraryScript = [System.IO.Path]::Combine($scriptFolder ,"Library.ps1")
Write-Verbose "LibraryScript=$libraryScript"
Write-Verbose "Loading install library script '$libraryScript'..."
. $libraryScript
$scriptInstallLibraryScript = [System.IO.Path]::Combine($scriptFolder , "Tools","Script.Install.Library.ps1")
Write-Verbose "ScriptInstallLibraryScript=$scriptInstallLibraryScript"
Write-Verbose "Loading install library script '$scriptInstallLibraryScript'..."
. $scriptInstallLibraryScript
# Get install action
#$installAction = GetInstallAction()

Write-Host "Executing Install.ps1..."

Write-Host "Executing install action '$installAction'..."

Write-Host "TODO: Implement execution of install action and set exit code"

Write-Host "Finished executing Install.ps1"

EXIT $ExitCode