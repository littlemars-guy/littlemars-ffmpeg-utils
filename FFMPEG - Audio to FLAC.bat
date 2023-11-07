::What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
::Extract audio only and convert to flac
@echo off

:again
title FFMPEG - Extracting from "%~1" and converting to flac

goto:analisys

:analisys
set "file=%~1"
set "codec=unknown"
set "bits=unknown"

if %choice%="yes" goto:get_bits_per_sample

rem Get audio codec name
setlocal EnableDelayedExpansion
set "ffprobe=ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1 "%file%""
for /F "delims=" %%I in ('!ffprobe!') do set "codec=%%I"

if /i "%codec:~6%"=="FLAC" (
    goto :error_already_flac
) else (
    goto :encode
)

:get_bits_per_sample
rem Get audio bits per sample
set "ffprobe=ffprobe -v error -select_streams a:0 -show_entries stream=bits_per_sample -of default=noprint_wrappers=1 "%file%""
for /F "delims=" %%I in ('!ffprobe!') do set "bits=%%I"

if /i "%bits:~-2%"=="32" (
    goto :errorbits32
) else (
    goto :encode
)

:encode
if exist "%~dp1%~n1.flac" goto:errorfileexisting

ffmpeg ^
	-i "%~1" ^
	-vn ^
	-c:a flac ^
	-map_metadata 0 ^
	-movflags use_metadata_tags ^
	-write_id3v2 1 ^
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

:error_already_flac
	
	echo [93mThere was an error. The input file audio codec is already encoded in FLAC.[0m
	echo [93mDo you want to extract it to a separate file?[0m

	echo [33m[1][0m. yes (save option for subsequent files in queue)
	echo [33m[2][0m. yes (just once)
	echo [33m[3][0m. no
	echo.

	CHOICE /t 10 /C 123 /D 1 /M "Enter your choice:"
	:: Note - ERRORLEVELS are listed in decreasing order
	IF ERRORLEVEL 3 goto:abort
	IF ERRORLEVEL 2 goto:encode
	IF ERRORLEVEL 1 set choice=yes && goto:encode

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

:abort

echo [93mConvertion aborted.[0m
cls
echo [93mThis window will close after 5 seconds.[0m
timeout /t 1 > nul
cls
echo [93mThis window will close after 4 seconds.[0m
timeout /t 1 > nul
cls
echo [93mThis window will close after 3 seconds.[0m
timeout /t 1 > nul
cls
echo [93mThis window will close after 2 seconds.[0m
timeout /t 1 > nul
cls
echo [93mThis window will close after 1 seconds.[0m
timeout /t 1 > nul
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