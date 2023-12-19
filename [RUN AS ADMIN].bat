@echo off
chcp 65001
cls
setlocal enabledelayedexpansion

echo Welcome
echo This script will install the littlemars-ffmpeg-utils on your system
echo.

REM Set the repository URL for littlemars-ffmpeg-utils
set LITTLEMARS_REPO_URL=https://github.com/littlemars-guy/littlemars-ffmpeg-utils/archive/main.zip

REM Set the installation folder for littlemars-ffmpeg-utils
set "LITTLEMARS_INSTALL_FOLDER=%~dp0"

REM Set the SendTo folder
set "SENDTO_FOLDER=%APPDATA%\Microsoft\Windows\SendTo"

REM  Check if FFMPEG is already installed
where ffmpeg >nul 2>nul
if %errorlevel% equ 0 (
    echo FFMPEG is already installed. Skipping installation.
    goto :SkipInstallation
)

REM Set the URL for FFmpeg download
set FFMPEG_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip

REM Set the installation folder for FFmpeg
set "FFMPEG_INSTALL_FOLDER=%~dp0"
set "FFMPEG_PATH_FOLDER=%~dp0\ffmpeg-master-latest-win64-gpl\bin"

REM Check if FFmpeg is already installed
if not exist "%FFMPEG_PATH_FOLDER%\ffmpeg.exe" (
    echo FFmpeg is not installed. Downloading and extracting...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('%FFMPEG_URL%', 'ffmpeg.zip'); Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('ffmpeg.zip', '%FFMPEG_INSTALL_FOLDER%'); Remove-Item 'ffmpeg.zip'"
    echo FFmpeg installed successfully.
) else (
    echo FFmpeg is already installed.
)

REM Add FFmpeg folder to the PATH variable
setx PATH "%PATH%;%FFMPEG_PATH_FOLDER%" /M

:SkipInstallation

REM Remove previous scripts installation to free space for update
RD /S /Q "%LITTLEMARS_INSTALL_FOLDER%\littlemars-ffmpeg-utils-main"

REM Remove existing shortcuts in the SendTo folder that link to downloaded scripts
for %%i in ("%SENDTO_FOLDER%\*.lnk") do (
    set "TARGET_SCRIPT=!LITTLEMARS_INSTALL_FOLDER!\littlemars-ffmpeg-utils-main\%%~nxi"
    if exist "!TARGET_SCRIPT!" (
        del "%%i"
        echo Removed existing shortcut: %%i
    )
)

REM Download and extract the littlemars-ffmpeg-utils ZIP file
powershell -Command "(New-Object Net.WebClient).DownloadFile('%LITTLEMARS_REPO_URL%', 'littlemars.zip'); Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('littlemars.zip', '%LITTLEMARS_INSTALL_FOLDER%'); Remove-Item 'littlemars.zip'"

REM Remove unnecessary files
del "%LITTLEMARS_INSTALL_FOLDER%\littlemars-ffmpeg-utils-main\.gitignore"
del "%LITTLEMARS_INSTALL_FOLDER%\littlemars-ffmpeg-utils-main\.gitattributes"
del "%LITTLEMARS_INSTALL_FOLDER%\littlemars-ffmpeg-utils-main\LICENSE"

REM Iterate through each script in the littlemars-ffmpeg-utils installation folder
for %%i in ("%LITTLEMARS_INSTALL_FOLDER%\littlemars-ffmpeg-utils-main\*.bat") do (
    REM Create a shortcut for each script in the SendTo folder
    set "SCRIPT_NAME=%%~nxi"
    set "SHORTCUT_NAME=!SCRIPT_NAME:.bat=.lnk!"
    set "SHORTCUT_PATH=!SENDTO_FOLDER!\!SHORTCUT_NAME!"

    powershell -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut('!SHORTCUT_PATH!'); $s.TargetPath='!LITTLEMARS_INSTALL_FOLDER!\littlemars-ffmpeg-utils-main\!SCRIPT_NAME!'; $s.Save()"

    echo Created shortcut: !SHORTCUT_PATH!
)

echo Installation completed
echo For usage guide and tips refer to the readme.md file in the script directory
echo or go to github.com/littlemars-guy/littlemars-ffmpeg-utils

pause