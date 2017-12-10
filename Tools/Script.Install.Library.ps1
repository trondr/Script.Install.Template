
# Helper functions used by Install.ps1 main script

function ExecuteAction([scriptblock]$action)
{
    if(IsTerminalServer -and IsAdministrator) { ChangeUserInstall }
    
    $exitCode = & $action

    if(IsTerminalServer -and IsAdministrator) { ChangeUserExecute }

    return $exitCode
}

function StartProcess([string]$command, [string]$commandArguments, [string]$workingDirectory, [bool] $waitForExit)
{
    If ((Test-Path $command) -eq $false)
    {
       Write-Host -ForegroundColor Red "ERROR: File not found: $command" -BackgroundColor Red
       return 1
    }
    Write-Verbose "Command: $command"
    Write-Verbose "Command Arguments: $commandArguments"
    Write-Verbose "Working Directory: $workingDirectory"
    Write-Verbose "Wait For Exit: $waitForExit"
    Write-Host "Executing: $command $commandArguments"
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.WorkingDirectory = $workingDirectory
    $startInfo.Arguments = $commandArguments
    $startInfo.FileName = $command        
    $process = [System.Diagnostics.Process]::Start($startInfo)
    if($waitForExit -eq $true)
    {
        $process.WaitForExit()
    }    
    $exitCode = $process.ExitCode
    Write-Host "Exit: $command $commandArguments : $exitCode"
    return $exitCode   
}

function IsLocal([string]$path)
{
    $uri = New-Object System.Uri($path)
    if($uri.IsUnc)
    {
        Write-Verbose "Path is remote: $path"
        return $false
    }
    $drive = Split-Path -Qualifier $path
    $logicalDisk = Gwmi Win32_LogicalDisk -filter "DriveType = 4 AND DeviceID = '$drive'"
    if($logicalDisk -eq $null)
    {
        Write-Verbose "Path is remote: $path"
        return $false
    }
    Write-Verbose "Path is local: $path"
    return $true
}

function LoadLibrary([string]$libraryFilePath)
{
    if( [System.IO.File]::Exists($libraryFilePath) -eq $false )
    {
        Write-Error "Failed to load library. Library file not found: '$libraryFilePath'."
		return $null
    }
    $libraryTargetFilePath = $libraryFilePath
    $isLocal = IsLocal($libraryFilePath)
    if($isLocal -eq $false)
    {
       #Library is remote, prepare to copy it localy before loading it.
       $libraryFileName = [System.IO.Path]::GetFileName($libraryFilePath)
       $libraryFolderName = [System.IO.Path]::GetFileNameWithoutExtension($libraryFilePath)
       $libraryTargetFolder = CombinePaths($Env:TEMP, $libraryFolderName)
       if(! (Test-Path $libraryTargetFolder) )
       {
            [System.IO.Directory]::CreateDirectory($libraryTargetFolder)
       }
       $libraryTargetFilePath = CombinePaths($libraryTargetFolder, $libraryFileName)
       [System.IO.File]::Copy($libraryFilePath, $libraryTargetFilePath, $true)
    }
    $library = [System.Reflection.Assembly]::LoadFrom($libraryTargetFilePath)
    if($library -eq $null)
    {
        Write-Host -ForegroundColor Red "Failed to load library: '$libraryTargetFilePath'."
    }
    return $library
}

function CombinePaths
{
    if($args -eq $null)
    {
        Write-Error "CombinePaths was called with no arguments"
        return $null
    }
    $combinedPath = [string]::Join([System.IO.Path]::DirectorySeparatorChar, [string[]]$args[0]) 
    Write-Verbose "CombinedPath=$combinedPath"
    return $combinedPath
}
#$combinedPaths = CombinePaths("arg1","arg2","arg3")
#Write-Host $combinedPaths

function IsTerminalServer
{
	try
	{
		$terminalServerSettings = Get-WmiObject Win32_TerminalServiceSetting -Namespace "root\CIMv2\TerminalServices" | Select-Object -first 1
		if($terminalServerSettings.TerminalServerMode -eq 1)
		{
			return $true
		}
        else
        {
            return $false
        }
	}
	catch
	{
		return $false
	}
}
#TEST: IsTerminalServer

function IsAdministrator
{	
	$isAdministrator = $false
	$windowsIdentity=[System.Security.Principal.WindowsIdentity]::GetCurrent()
  	$windowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($windowsIdentity)
  	$administratorRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
  	$isAdministrator=$windowsPrincipal.IsInRole($administratorRole)    
	return $isAdministrator
}
#TEST: IsAdministrator

function ChangeUserExecute
{
	$changeExe = CombinePaths($Env:windir, "System32", "change.exe")
	if([System.IO.File]::Exists($changeExe))
	{
		[System.Diagnostics.Process]::Start($changeExe,"Change User /Execute")
	}	
}

function ChangeUserInstall
{
	$changeExe = CombinePaths($Env:windir, "System32", "change.exe")
	if([System.IO.File]::Exists($changeExe))
	{
		[System.Diagnostics.Process]::Start($changeExe,"Change User /Install")
	}
}