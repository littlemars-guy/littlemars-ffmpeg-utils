::What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007

::Extract audio only and convert to flac
@echo off

:again
title FFMPEG - Extracting from "%~1" and converting to flac

if exist "%~dp1%~n1.flac" goto:errorfileexisting
goto:analisys

:analisys
set "file=%~1"
set "codec=unknown"
set "bits=unknown"

rem Get codec name
setlocal EnableDelayedExpansion
set "ffprobe=ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1 "%file%""
for /F "delims=" %%I in ('!ffprobe!') do set "codec=%%I"

rem Get bits per sample
set "ffprobe=ffprobe -v error -select_streams a:0 -show_entries stream=bits_per_sample -of default=noprint_wrappers=1 "%file%""
for /F "delims=" %%I in ('!ffprobe!') do set "bits=%%I"

if /i "%bits:~-2%"=="32" (
    goto :errorbits32
) else (
    goto :encode
)

:encode
ffmpeg ^
	-i "%~1" ^
	-vn ^
	-c:a flac ^
	"%~dp1%~n1.flac"
	
if NOT ["%errorlevel%"]==["0"] goto:error
endlocal
echo [92m%~n1 Done![0m
title FFMPEG - Extraction of audio from "%~1" completed!
goto:next

:next
shift
if "%~1" == "" goto:end
goto:again

:errorfileexisting

echo [93mThere was an error. A file with the same name as the requested conversion already exists. Check the output folder![0m
pause
exit 0

:errorbits32

echo [93mThere was an error. The input file audio codec has a bit depth of 32 bits and thus is incompatible with the FLAC encoder.[0m
pause
exit 0

:error

echo [93mThere was an error. Please check your input file.[0m
pause
exit 0

:end

cls
echo [92mEncoding succesful. This window will close after 5 seconds.[0m
timeout /t 1 > nul
cls
echo [92mEncoding succesful. This window will close after 4 seconds.[0m
timeout /t 1 > nul
cls
echo [92mEncoding succesful. This window will close after 3 seconds.[0m
timeout /t 1 > nul
cls
echo [92mEncoding succesful. This window will close after 2 seconds.[0m
timeout /t 1 > nul
cls
echo [92mEncoding succesful. This window will close after 1 seconds.[0m
timeout /t 1 > nul
exit 0