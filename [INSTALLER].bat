::	This script will install the littlemars' FFMPEG utils suite
::
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---ADDITIONAL INFO-----------------------------------------------------------------------------
::  More info abot this project: https://github.com/littlemars-guy/littlemars-ffmpeg-utils
::
::  Fancy font is "smisome1" from: https://devops.datenkollektiv.de/banner.txt/index.html
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-11-19 Version 0.1
::		- Initial release
::
::	---Debug Utils (will be removed in future releases---------------------------------------------
::  if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
::	-----------------------------------------------------------------------------------------------

@echo off
chcp 65001
cls
setlocal enabledelayedexpansion

REM Set the repository URL for littlemars-ffmpeg-utils
set LITTLEMARS_REPO_URL=https://github.com/littlemars-guy/littlemars-ffmpeg-utils/archive/main.zip

REM Set the installation folder for littlemars-ffmpeg-utils
set "LITTLEMARS_INSTALL_FOLDER=%~dp0"
echo [92mInstallation folder:[0m %LITTLEMARS_INSTALL_FOLDER%

REM Set the SendTo folder
set "SENDTO_FOLDER=%APPDATA%\Microsoft\Windows\SendTo"

echo.
CALL :banner
echo.
CALL :info
echo.
echo.
CALL :check_your_privileges

REM  Check if FFMPEG is already installed
where ffmpeg >nul 2>nul
if %errorlevel% equ 0 (
    echo [92mFFMPEG is already installed. Skipping installation.[0m
    echo.
    goto :SkipInstallation
)

REM Set the URL for FFmpeg download
set FFMPEG_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip

REM Set the installation folder for FFmpeg
set "FFMPEG_INSTALL_FOLDER=%~dp0"
set "FFMPEG_PATH_FOLDER=%~dp0\ffmpeg-master-latest-win64-gpl\bin"

REM Check if FFmpeg is already installed
if not exist "%FFMPEG_PATH_FOLDER%\ffmpeg.exe" (
    echo [92mFFmpeg is not installed. Downloading and extracting...[0m
    powershell -Command "(New-Object Net.WebClient).DownloadFile('%FFMPEG_URL%', 'ffmpeg.zip'); Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('ffmpeg.zip', '%FFMPEG_INSTALL_FOLDER%'); Remove-Item 'ffmpeg.zip'"
    echo.
) else (
    echo [92mFFmpeg is already installed.[0m
    echo.
)

REM Add FFmpeg folder to the PATH variable
setx PATH "%PATH%;%FFMPEG_PATH_FOLDER%" /M
echo [92mFFmpeg installed successfully.[0m

:SkipInstallation

REM Remove existing shortcuts in the SendTo folder that link to downloaded scripts
for %%i in ("%SENDTO_FOLDER%\*.lnk") do (
    set "TARGET_SCRIPT=!LITTLEMARS_INSTALL_FOLDER!\littlemars-ffmpeg-utils-main\Scripts\%%~ni.bat"
    if exist "!TARGET_SCRIPT!" (
        del "%%i"
        echo [92mRemoved existing shortcut:[0m %%~ni
    )
)

echo.

REM Remove previous scripts installation to free space for update
if EXIST "%LITTLEMARS_INSTALL_FOLDER%\littlemars-ffmpeg-utils-main" RD /S /Q "%LITTLEMARS_INSTALL_FOLDER%\littlemars-ffmpeg-utils-main"

REM Download and extract the littlemars-ffmpeg-utils ZIP file
powershell -Command "(New-Object Net.WebClient).DownloadFile('%LITTLEMARS_REPO_URL%', 'littlemars.zip'); Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('littlemars.zip', '%LITTLEMARS_INSTALL_FOLDER%'); Remove-Item 'littlemars.zip'"

REM Remove unnecessary files
del "%LITTLEMARS_INSTALL_FOLDER%\littlemars-ffmpeg-utils-main\.gitignore"
del "%LITTLEMARS_INSTALL_FOLDER%\littlemars-ffmpeg-utils-main\.gitattributes"
del "%LITTLEMARS_INSTALL_FOLDER%\littlemars-ffmpeg-utils-main\LICENSE"
del "%LITTLEMARS_INSTALL_FOLDER%\littlemars-ffmpeg-utils-main\[INSTALLER].bat"
RD /S /Q "%LITTLEMARS_INSTALL_FOLDER%\littlemars-ffmpeg-utils-main\WIP

REM Iterate through each script in the littlemars-ffmpeg-utils installation folder
for %%i in ("%LITTLEMARS_INSTALL_FOLDER%\littlemars-ffmpeg-utils-main\Scripts\*.bat") do (
    REM Create a shortcut for each script in the SendTo folder
    set "SCRIPT_NAME=%%~nxi"
    set "SHORTCUT_NAME=!SCRIPT_NAME:.bat=.lnk!"
    set "SHORTCUT_PRINT_NAME=%%~ni"
    set "SHORTCUT_PATH=!SENDTO_FOLDER!\!SHORTCUT_NAME!"

    powershell -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut('!SHORTCUT_PATH!'); $s.TargetPath='!LITTLEMARS_INSTALL_FOLDER!\littlemars-ffmpeg-utils-main\!SCRIPT_NAME!'; $s.Save()"

    echo [92mCreated shortcut:[0m !SHORTCUT_PRINT_NAME!
)

echo.
echo [92mInstallation completed!
echo For usage guide and tips refer to the readme.md file in the script directory
echo or go to github.com/littlemars-guy/littlemars-ffmpeg-utils
echo.
echo Press any key to exit[92m
pause > nul
exit 0


:check_your_privileges
    REM Check if the script is currently running as admin
    net session >nul 2>&1
    if %errorLevel% == 0 (
        exit /b
    ) else (
        echo [101;93m WARNING:[40m The script is NOT running as administrator.[0m
        echo.
        echo [92mThis script requires administrator privileges to function properly.
        echo Relaunch by right-clicking the script and selecting  ‘Run as admin’.
        echo.
        echo Press any key to close this window.[0m
	    pause > nul
        exit 0
    )

:banner
    echo [92m   ___       ___       ___       ___       ___       ___       ___
    echo   /\__\     /\  \     /\__\     /\  \     /\  \     /\__\     /\  \
    echo  /:/\__\   /::\  \   /:/  /    /::\  \   /::\  \   /::L_L_   /::\  \
    echo /:/:/\__\ /::\:\__\ /:/__/    /:/\:\__\ /:/\:\__\ /:/L:\__\ /::\:\__\
    echo \::/:/  / \:\:\/  / \:\  \    \:\ \/__/ \:\/:/  / \/_/:/  / \:\:\/  /
    echo  \::/  /   \:\/  /   \:\__\    \:\__\    \::/  /    /:/  /   \:\/  /
    echo   \/__/     \/__/     \/__/     \/__/     \/__/     \/__/     \/__/[0m
	::  echo.
    ::  echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	exit /B

:info
    echo.
    echo [92mThis script will install the littlemars-ffmpeg-utils on your system
    echo.
	echo NOTE: 	Work in Progress - This Project is under active development
	echo 	This repository is currently in active development and is 
	echo 	not considered stable. Use at your own risk.
    echo.
    echo The scripts will be installed to:
    echo [0m!LITTLEMARS_INSTALL_FOLDER![92m
    echo.
    echo If this is not your desired destination, close this window, move the
    echo installer to the preferred destination and launch from there.
    echo.
    echo [92mIf you are sure and want to proceed, press any key to continue.[0m
	pause > nul
	EXIT /B
