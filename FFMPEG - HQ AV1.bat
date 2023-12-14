::	This scpript will encode input videos into .mkv with libsvtav1 at crf 51, audio will be copied
::	if possible, otherwise reencoded to Opus 256kbps.
::
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---ADDITIONAL INFO-----------------------------------------------------------------------------
::  Fancy font is "roman" from https://devops.datenkollektiv.de/banner.txt/index.html
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-12-14 Version 0.2.1
::		- Removed notification sounds that coused errors
::	2023-12-14 Version 0.2
::		- Full rewrite of multi-file input management
::		- Rewrote error and abort subroutines
::		- Updated disclaimer
::	2023-12-13 Version 0.1
::		- Initial relase
::	-----------------------------------------------------------------------------------------------
::if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )

@echo off
chcp 65001
setlocal EnableDelayedExpansion
cls

set file_count=0

:again
	set /A file_count+=1
	if NOT DEFINED jump goto :next

:jump
    timeout /t 2 > nul
    shift
    if "%~1" == "" goto :done

:next
	cls
	title FFMPEG - Converting "%~1" to 20mbps h264 video with 320kbps AAC audio 
	CALL:banner
	echo.
	CALL:info
	echo.
	set jump=yes
	set count=2
	set OUTPUT_DIR=%~dp1
	set OUTPUT_NAME=%~n1
	set OUTPUT_ENC=-av1
	set OUTPUT_SFX=
	set OUTPUT_EXT=.mkv

	:VALIDATE_OUTPUT
		echo.
		set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_ENC%%OUTPUT_EXT%"
		echo [101;93m VALIDATING OUTPUT... [0m
			IF EXIST %OUTPUT_FILE% (
				echo Output [30;41m UNAVAILABLE [0m && goto :errorfile
			) ELSE ( 
				echo Output [30;42m AVAILABLE [0m && goto :encode
			)

	::	:VALIDATE_AUDIO
		::	Get codec name
        ::	for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"
		::	if /i "%codec:~11%"=="wmav1" echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to aac && set codec_audio=aac -b:a 320k && goto :encode
		::	if /i "%codec:~11%"=="wmav2" echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to aac && set codec_audio=aac -b:a 320k && goto :encode
		::	echo Audio codec [30;42m %codec:~11% [0m is compatible, audio will be copied && set codec_audio=copy && goto :encode

	:errorfile
		set OUTPUT_SFX= (%count%)
		set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_ENC%%OUTPUT_SFX%%OUTPUT_EXT%"
		IF EXIST %OUTPUT_FILE% (
  	      set /A count+=1 && set OUTPUT_SFX= (%count%) && goto :errorfile
 	   ) ELSE ( 
			goto :error_choice
		)

	:error_choice
		echo.
		echo [93mA file with the same name as the requested conversion output already exists.
		echo [1mSelect the desired action:[0m
		echo [33m[1][0m. Overwrite output (will ask again for confirmation)
		echo [33m[2][0m. Rename output %OUTPUT_NAME%%OUTPUT_ENC%[30;43m-(%count%)[0m%OUTPUT_EXT%[0m
		echo [33m[3][0m. Abort the operation (will be auto-selected in 30s)
		echo.
	
		CHOICE /C 123 /T 30 /D 3 /M "Enter your choice:"
		:: Note - list ERRORLEVELS in decreasing order
		IF ERRORLEVEL 3 goto :abort
		IF ERRORLEVEL 2 goto :VALIDATE_AUDIO
		IF ERRORLEVEL 1 EXIT /B

	:encode
		echo.
		echo [101;93m ENCODING... [0m
		ffmpeg ^
			-hide_banner -loglevel warning -stats ^
    	    -hwaccel auto ^
			-i "%~1" ^
			-map 0:a -map 0:v:0 ^
			-vf "scale=-2:min'(1080,ih)'" ^
			-c:v libsvtav1 -preset 13 -svtav1-params tune=0:keyint=10s:scd=1:lookahead=120 ^
    	    -crf 51 ^
			-pix_fmt yuv420p ^
			-c:a libopus -b:a 128k -application audio -apply_phase_inv 1 -cutoff 0 ^
    	    -map_metadata 0 -movflags use_metadata_tags ^
    	    -movflags +faststart ^
			"%~dp1%~n1%OUTPUT_ENC%%OUTPUT_SFX%%OUTPUT_EXT%"

	if NOT ["%errorlevel%"]==["0"] set print_error_level=%errorlevel% && goto :error	

	echo [92m%~n1 Done![0m

	goto :again


:error
	echo [93mThere was an error. Please check your input file.[0m
	echo Errorlevel is %print_error_level%
	pause
	goto :eof

:done
	set countdown=5
	CALL :end_cycle
	:end_cycle
		cls
		CALL :banner
		echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo.
		echo [92mEncoding succesful. This window will close after %countdown% seconds.[0m
		set /A countdown-=1
		timeout /t 1 > nul
		if "%countdown%"=="0" exit 0
		goto :end_cycle

:abort
	set countdown=5
	CALL :abort_cycle
	:abort_cycle
		cls
		CALL :banner
		echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo.
		echo [93mProcess aborted.[0m
		set /A countdown-=1
		timeout /t 1 > nul
		if "%countdown%"=="0" exit 0
		goto :abort_cycle

:banner
	echo ╔══════════════════════════════════════╗
	echo ║       .o.   .oooo.       .ooo    .o  ║
	echo ║      .888.     `888.     .8'   o888  ║
	echo ║     .8"888.     `888.   .8'     888  ║
	echo ║    .8' `888.     `888. .8'      888  ║
	echo ║   .88ooo8888.     `888.8'       888  ║
	echo ║  .8'     `888.     `888'        888  ║
	echo ║ o88o     o8888o     `8'        o888o ║
	echo ╚══════════════════════════════════════╝ 
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	exit /B

:info
	echo INFO:	Video will be transcoded to AV1 crf51.
	echo		Audio will be copied if possible, otherwise re-encoded to Opus 128k.
	exit /B
