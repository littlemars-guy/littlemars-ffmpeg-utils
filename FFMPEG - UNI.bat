::	This script will extract audio from source and save it as a new OPUS file
::
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---ADDITIONAL INFO-----------------------------------------------------------------------------
::  More info abot this project: https://github.com/littlemars-guy/littlemars-ffmpeg-utils
::
::  Fancy font is "roman" from: https://devops.datenkollektiv.de/banner.txt/index.html
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-12-23 Version 0.1.1
::		- Rewrote error and abort subroutines
::	2023-11-23 Version 0.1
::		- Initial release
::	-----------------------------------------------------------------------------------------------
::
::	---Debug Utils (will be removed in future releases---------------------------------------------
::	if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
::	-----------------------------------------------------------------------------------------------
@echo off
chcp 65001
cls
setlocal EnableDelayedExpansion
:again
	set file=%~1
	set OUTPUT_DIR=%~dp1
	set OUTPUT_NAME=%~n1
	set OUTPUT_SFX=
	set OUTPUT_EXT=mkv
	set count=2
	CALL :banner
	echo.
	IF DEFINED choice (goto:analisys) ELSE (goto:preset_selection)

	echo [101;93m PRESET SELECTION [0m

:preset_selection
	echo [1mSelect the desired encoding preset:[0m
	echo [33m[1][0m. [FAST] - h264 high compression 480*640 anamorphic, 16:9 container
	echo [33m[2][0m. [SMALL] - Lowest quality/size achievable h265 while still being comprehensible
	echo [33m[3][0m. [BEST] - SLOW, REAL SLOW AV1 encoding, but higher quality for the same filesize
	echo.
	
	CHOICE /C 123 /M "Enter your choice:"
	:: Note - list ERRORLEVELS in decreasing order
	IF ERRORLEVEL 3 set choice=BEST && set Preset=[UNI-BEST] && GOTO:analisys
	IF ERRORLEVEL 2 set choice=SMALL && set Preset=[UNI-SMALL] && GOTO:analisys
	IF ERRORLEVEL 1 set choice=FAST && set Preset=[UNI-FAST] && GOTO:analisys

:analisys
	:: Nothing here for now
	goto:VALIDATE_OUTPUT

:VALIDATE_OUTPUT
	echo.
	set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%-%Preset%.%OUTPUT_EXT%"
	echo [101;93m VALIDATING OUTPUT... [0m
		IF EXIST %OUTPUT_FILE% (
   			echo Output [30;41m UNAVAILABLE [0m && echo. && echo. && goto:errorfile
 		) ELSE ( 
    		echo Output [30;42m AVAILABLE [0m && echo. && echo. && goto:encode
		)
:errorfile
	set OUTPUT_SFX= (%count%)
	set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%-%Preset%%OUTPUT_SFX%.%OUTPUT_EXT%"
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
	echo [33m[2][0m. Rename output %OUTPUT_NAME%-%Preset%[30;43m(%count%)[0m.%OUTPUT_EXT%[0m
	echo [33m[3][0m. Abort the operation (will be auto-selected in 30s)
	echo.
	
	CHOICE /C 123 /T 30 /D 3 /M "Enter your choice:"
	:: Note - list ERRORLEVELS in decreasing order
	IF ERRORLEVEL 3 goto :abort
	IF ERRORLEVEL 2 goto :encode
	IF ERRORLEVEL 1 EXIT /B

:encode
	if %choice%==FAST goto:fast
	if %choice%==SMALL goto:small
	if %choice%==BEST goto:best
	:fast
		echo [101;93m ENCODING PASS 1 ... [0m
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-hwaccel auto ^
			-stats -i "%~1" ^
			-map 0 ^
            -filter:v "scale=480x640" ^
			-aspect 16:9 ^
			-c:v libx264 ^
			-x264opts opencl ^
			-preset slow ^
			-b:v 256k ^
			-maxrate 512k ^
			-bufsize 1024k ^
			-pix_fmt yuv420p ^
			-c:a libopus ^
			-b:a 64k ^
			-application audio ^
			-apply_phase_inv 1 ^
			-cutoff 0 ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			-movflags +faststart ^
			-pass 1 -f %OUTPUT_EXT ^
			NUL

		echo [92mPASS 1 completed successfully, moving on to PASS 2[0m
		echo.
		echo [101;93m ENCODING PASS 2 ... [0m

		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-hwaccel auto ^
			-stats -i "%~1" ^
			-map 0 ^
            -filter:v "scale=480x640" ^
			-aspect 16:9 ^
			-c:v libx264 ^
			-x264opts opencl ^
			-preset slow ^
			-b:v 256k ^
			-maxrate 512k ^
			-bufsize 1024k ^
			-pix_fmt yuv420p ^
			-c:a libopus ^
			-b:a 64k ^
			-application audio ^
			-apply_phase_inv 1 ^
			-cutoff 0 ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			-movflags +faststart ^
			-pass 2 ^
			"%~dp1%~n1-%Preset%%OUTPUT_SFX%.%OUTPUT_EXT%"

		goto:next

	:small
		echo [101;93m ENCODING PASS 1 ... [0m
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-hwaccel auto ^
			-stats -i "%~1" ^
			-map 0 ^
            -filter:v "scale=trunc(oh*a/2)*2:min(720\,iw)" ^
			-c:v libx265 ^
			-x265-params log-level=warning ^
			-preset slow ^
			-b:v 256k ^
			-maxrate 512k ^
			-bufsize 1024k ^
			-pix_fmt yuv420p ^
			-c:a libopus ^
			-b:a 64k ^
			-application audio ^
			-apply_phase_inv 1 ^
			-cutoff 0 ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			-movflags +faststart ^
			-pass 1 -f %OUTPUT_EXT% ^
			NUL

		echo [92mPASS 1 completed successfully, moving on to PASS 2[0m
		echo.
		echo [101;93m ENCODING PASS 2 ... [0m

		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-hwaccel auto ^
			-stats -i "%~1" ^
			-map 0 ^
            -filter:v "scale=trunc(oh*a/2)*2:min(720\,iw)" ^
			-c:v libx265 ^
			-x265-params log-level=warning ^
			-preset slow ^
			-b:v 256k ^
			-maxrate 512k ^
			-bufsize 1024k ^
			-pix_fmt yuv420p ^
			-c:a libopus ^
			-b:a 64k ^
			-application audio ^
			-apply_phase_inv 1 ^
			-cutoff 0 ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			-movflags +faststart ^
			-pass 2 ^
			"%~dp1%~n1-%Preset%%OUTPUT_SFX%.%OUTPUT_EXT%"

		goto:next

	:best
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-hwaccel auto ^
			-stats -i "%~1" ^
			-map 0 ^
            -filter:v "scale=trunc(oh*a/2)*2:min(720\,iw)" ^
			-c:v libsvtav1 ^
			-preset 6 ^
			-svtav1-params tune=0:keyint=10s:scd=1:lookahead=120 ^
			-crf 51 ^
			-pix_fmt yuv420p ^
			-c:a libopus ^
			-b:a 64k ^
			-application audio ^
			-apply_phase_inv 1 ^
			-cutoff 0 ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			-movflags +faststart ^
			"%~dp1%~n1-%Preset%%OUTPUT_SFX%.%OUTPUT_EXT%"
		
		goto:next

:next
	if NOT ["%errorlevel%"]==["0"] goto:error
	echo [92m%~n1 Done![0m

	shift
	if "%~1" == "" goto:end
	goto:again

:error_same_codec
	
	echo [93mThere was an error. The input file audio track is already encoded in OPUS.[0m
	echo [93mDo you want to extract it to a separate file?[0m

	echo [33m[1][0m. yes (save option for subsequent files in queue)
	echo [33m[2][0m. yes (just once)
	echo [33m[3][0m. no
	echo.

	CHOICE /t 10 /C 123 /D 1 /M "Enter your choice:"
	:: Note - ERRORLEVELS are listed in decreasing order
	IF ERRORLEVEL 3 goto:abort
	IF ERRORLEVEL 2 goto:analisys
	IF ERRORLEVEL 1 set same_codec_remember=yes && goto:again

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

:banner
	echo [0m╔══════════════════════════════════════╗
	echo ║  ooooo     ooo ooooo      ooo ooooo  ║
	echo ║  `888'     `8' `888b.     `8' `888'  ║
	echo ║   888       8   8 `88b.    8   888   ║
	echo ║   888       8   8   `88b.  8   888   ║
	echo ║   888       8   8     `88b.8   888   ║
	echo ║   `88.    .8'   8       `888   888   ║
	echo ║     `YbodP'    o8o        `8  o888o  ║
	echo ╚══════════════════════════════════════╝
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	exit /b 0