# Helper functions used by Install.ps1 main script

function ExecuteAction([scriptblock]$action)
{
    if(IsTerminalServer -and IsAdministrator) { ChangeUserInstall }
    
    $exitCode = & $action

    if(IsTerminalServer -and IsAdministrator) { ChangeUserExecute }

    return $exitCode
}

function ValidateFileExists
{
    Param(
        [ValidateNotNullOrEmpty()]
        [String]
        $FileName=$(throw "FileName is mandatory, please provide a value."),
        [String]
        $Message
    )
    if([System.IO.File]::Exists($FileName) -eq $false)
    {
        $(throw "$Message Error: File '$FileName' does not exist.")
    }    
}
#TEST : ValidateFileExists "c:\temp\notes.txt"

function ValidateDirectoryExists
{
    Param(
        [ValidateNotNullOrEmpty()]
        [String]
        $DirectoryName=$(throw "DirectoryName is mandatory, please provide a value."),
        [String]
        $Message
    )
    if([System.IO.Directory]::Exists($DirectoryName) -eq $false)
    {
        $(throw "$Message. Error: Directory '$DirectoryName' does not exist.")
    }    
}
#TEST : ValidateDirectoryExists "c:\temp2"

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

function GetLocalTempLibRootFolder
{
    $localTempLibRootFolder = [System.IO.Path]::Combine($Env:TEMP,"ScrILib")
    if([System.IO.Directory]::Exists($localTempLibRootFolder) -eq $false)
    {
        $directory = [System.IO.Directory]::CreateDirectory($localTempLibRootFolder)
    }
    Write-Verbose "LocalTempLibRootFolder=$localTempLibRootFolder"
    return $localTempLibRootFolder
}
#TEST: GetLocalTempLibRootFolder

function GetLocalTempLibFolder
{
    $localTempLibFolder = [System.IO.Path]::Combine($(GetLocalTempLibRootFolder),"$(Get-Random)")
    if([System.IO.Directory]::Exists($localTempLibFolder) -eq $false)
    {
        $directory = [System.IO.Directory]::CreateDirectory($localTempLibFolder)
    }
    Write-Verbose "LocalTempLibFolder=$localTempLibFolder"
    return $localTempLibFolder
}
#TEST: GetLocalTempLibFolder

function CleanupPreviousLoadedLibraries
{
    $subDirectories = [System.IO.Directory]::GetDirectories($(GetLocalTempLibRootFolder))
    $filteredSubDirectories = $subDirectories | Where-Object { $_ -match "\d+"}
    ForEach($subDirectory in $filteredSubDirectories)
    {
        try
        {
            Write-Verbose "Cleanup previous loaded libraries in '$subDirectory' ..."
            [System.IO.Directory]::Delete($subDirectory,$true)
        }
        catch
        {
            #Ignore errors
        }
    }
}
#TEST: CleanupPreviousLoadedLibraries

function GetLocalLibraryTargetFilePath
{
    Param(
        [ValidateNotNullOrEmpty()]        
        [String]
        $LibraryFilePath=$(throw "Library path not specified.")
    )
    $libraryFileName = [System.IO.Path]::GetFileName($libraryFilePath)
    $libraryFolderName = [System.IO.Path]::GetFileNameWithoutExtension($libraryFilePath)
    $libraryTargetFolder = CombinePaths($(GetLocalTempLibFolder), $libraryFolderName)
    if([System.IO.Directory]::Exists($libraryTargetFolder) -eq $false)
    {
        $directory = [System.IO.Directory]::CreateDirectory($libraryTargetFolder)
    }
    $libraryTargetFilePath = CombinePaths($libraryTargetFolder, $libraryFileName)
    Write-Verbose "LibraryTargetFilePath=$libraryTargetFilePath"
    return $libraryTargetFilePath
}
#TEST: GetLocalLibraryTargetFilePath

function LoadLibrary([string]$libraryFilePath)
{
    if( [System.IO.File]::Exists($libraryFilePath) -eq $false )
    {
        Write-Host "Failed to load library. Library file not found: '$libraryFilePath'." -ForegroundColor Red
		return $null
    }
    $libraryTargetFilePath = $libraryFilePath
    $isLocal = IsLocal($libraryFilePath)
    if($isLocal -eq $false)
    {
       CleanupPreviousLoadedLibraries
       $libraryTargetFilePath = GetLocalLibraryTargetFilePath -LibraryFilePath $libraryFilePath
       [System.IO.File]::Copy($libraryFilePath, $libraryTargetFilePath, $true)
    }
    $library = [System.Reflection.Assembly]::LoadFrom($libraryTargetFilePath)
    if($library -eq $null)
    {
        Write-Host "Failed to load library: '$libraryTargetFilePath'." -ForegroundColor Red
    }
    return $library
}
#LoadLibrary "\\testserver\Temp\Common.Logging.dll"

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
	$exitCode = StartProcess "$(GetChangeExe)" "User /Execute" $null $true    
}

function ChangeUserInstall
{
	$exitCode = StartProcess "$(GetChangeExe)" "User /Install" $null $true
}

function GetSystemFolder
{
    $systemFolder = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::System)
    Write-Verbose "SystemFolder=$systemFolder"
    ValidateDirectoryExists -DirectoryName $systemFolder
    return $systemFolder
}
#TEST GetSystemFolder

function GetMsiExecExe
{
    $msiexecExe = [System.IO.Path]::Combine($(GetSystemFolder), "msiexec.exe")
    Write-Verbose "MsiExecExe=$msiexecExe"
    ValidateFileExists -FileName $msiexecExe
    return $msiexecExe
}
#TEST GetMsiExecExe

function GetChangeExe
{
    $changeExe = [System.IO.Path]::Combine($(GetSystemFolder), "change.exe")
    Write-Verbose "ChangeExe=$changeExe"
    ValidateFileExists -FileName $changeExe
    return $changeExe
}
#TEST GetChangeExe

function GetVendorInstallFolder
{
    $vendorInstallFolder = [System.IO.Path]::Combine($scriptFolder,"VendorInstall")
    Write-Verbose "VendorInstallFolder=$vendorInstallFolder"
    ValidateDirectoryExists -DirectoryName $vendorInstallFolder
    return $vendorInstallFolder
}
#TEST GetVendorInstallFolder


function GetVendorInstallIni
{
    $vendorInstallIni = [System.IO.Path]::Combine($(GetVendorInstallFolder),"VendorInstall.ini")
    Write-Verbose "VendorInstallIni=$vendorInstallIni"
    ValidateFileExists -FileName $vendorInstallIni
    return $vendorInstallIni
}
#TEST GetVendorInstallIni

function GetVendorInstallIniMsiFileName
{
    $vendorInstallIniMsiFileName = [Script.Install.Tools.Library.IniFileOperations]::Read($(GetVendorInstallIni),"VendorInstall","MsiFile")
    Write-Verbose "VendorInstallIniMsiFileName=$vendorInstallIniMsiFileName"
    if([System.String]::IsNullOrWhiteSpace($vendorInstallIniMsiFileName) -eq $true)
    {
        throw "Msi file not specified in VendorInstall.ini: '$(GetVendorInstallIni)[VendorInstall]MsiFile="
    }
    return $vendorInstallIniMsiFileName
}
#TEST GetVendorInstallIniMsiFileName

function GetVendorInstallIniMsiFilePath
{
    $vendorInstallIniMsiFilePath = [System.IO.Path]::Combine($(GetVendorInstallFolder), $(GetVendorInstallIniMsiFileName))
    Write-Verbose "VendorInstallIniMsiFilePath=$vendorInstallIniMsiFilePath"   
    ValidateFileExists -FileName $vendorInstallIniMsiFilePath -Message "Msi file specified in ini file '$(GetVendorInstallIni)[VendorInstall]MsiFile=$(GetVendorInstallIniMsiFileName)' does not exist in folder '$(GetVendorInstallFolder)'."
    return $vendorInstallIniMsiFilePath
}