::if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
::	This script will extract audio from source and save it as a new FLAC file
::
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-11-16 Version 0.3
::		- Added "-map 0:a" after input to select all audio tracks
::	2023-11-10 Version 0.2
::		Minor formatting
::		Updated script description and license disclaimer
::		Added changelog
::	-----------------------------------------------------------------------------------------------

@echo off
chcp 65001
cls

:again
	title FFMPEG - Extracting audio from "%~1" to flac

goto:analisys

:analisys
	set file=%~1
	set codec=""
	set bits=""

	if /i "%choice%"=="yes" (
    	goto :encode
	) else (
	    goto :get_codec
	)

	::	Get audio codec name
	:get_codec
	setlocal EnableDelayedExpansion
	set "ffprobe=ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1 "%file%""
	for /F "delims=" %%I in ('!ffprobe!') do set "codec=%%I"

	if /i "%codec:~6%"=="FLAC" (
	    goto :error_already_flac
	) else (
	    goto :encode
	)

:get_bits_per_sample
	::	Get audio bits per sample
	set "ffprobe=ffprobe -v error -select_streams a:0 -show_entries stream=bits_per_sample -of default=noprint_wrappers=1 "%file%""
	for /F "delims=" %%I in ('!ffprobe!') do set "bits=%%I"

	if /i "%bits:~-2%"=="32" (
	    goto :errorbits32
	) else (
		goto :encode
	)

:encode
	if exist "%~dp1%~n1.flac" goto:errorfileexisting
		echo.
		echo.
		echo.
		echo [101;93m ENCODING... [0m
		echo.
ffmpeg ^
		-hide_banner ^
		-loglevel warning ^
		-stats ^
		-i "%~1" ^
		-map 0:a ^
		-vn ^
		-c:a flac ^
		-compression_level 12 -exact_rice_parameters 1 ^
		-map_metadata 0 ^
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
	echo [93mThere was an error. The input file audio track is already encoded in FLAC.[0m
	echo [93mDo you want to extract it to a separate file?[0m

	echo [33m[1][0m. yes (save option for subsequent files in queue)
	echo [33m[2][0m. yes (just once)
	echo [33m[3][0m. no
	echo.

	CHOICE /t 10 /C 123 /D 1 /M "Enter your choice:"
	:: Note - ERRORLEVELS are listed in decreasing order
	IF ERRORLEVEL 3 goto:abort
	IF ERRORLEVEL 2 goto:encode
	IF ERRORLEVEL 1 set choice=yes && goto:get_bits_per_sample

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
	echo [93mProcess aborted.[0m
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