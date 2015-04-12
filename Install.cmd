@Echo Off

@Echo Extracting script install Toolsities...
@Set ToolsFolder="%~dp0Tools"
@Set LocallToolsFolder=%temp%\Script.Install.Tools
"%ToolsFolder%\7zip\7za.exe" x "%ToolsFolder%\Script.Install.Tools.zip" -o"%LocallToolsFolder%" -y

@REM RunInNativeMode=True: Run PowerShell script in 64 bit process on 64 bit OS
@REM RunInNativeMode=False: Run PowerShell script in 32 bit process on 64 bit OS
@Set RunInNativeMode=True
@Set HideArgumentsInLogs=True
@REM PowerShell logging preferences
@Set VerbosePreference=Continue
@Set DebugPreference=SilentlyContinue
@Set WarningPreference=Continue
@Set ErrorActionPreference=Continue
@Set ProgressPreference=Continue

@Echo Running setup...
"%LocallToolsFolder%\Script.Install.Tools.exe" RunPowerShellScript /powerShellScriptFile="%~dp0\Install.ps1" /arguments={'%1';'%2';'%3';'%4';'%5';'%6';'%7';'%8';'%9'} /runInNativeMode="%RunInNativeMode%" /hideArguments="%HideArgumentsInLogs%" /verbosePreference="%VerbosePreference%" /debugPreference="%DebugPreference%" /warningPreference="%WarningPreference%" /errorActionPreference="%ErrorActionPreference%" /progressPreference="%ProgressPreference%" 
@Set ErrorCode=%ERRORLEVEL%
@Echo Cleaning up...
IF NOT "%LocallToolsFolder%" == "" Rmdir "%LocallToolsFolder%" /S /Q
@Echo ErrorCode=%ErrorCode%
@Exit /B %ErrorCode%