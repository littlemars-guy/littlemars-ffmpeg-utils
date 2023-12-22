::	This script will extract audio from source and save it as a new FLAC file
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---ADDITIONAL INFO-----------------------------------------------------------------------------
::	More info abot this project: https://github.com/littlemars-guy/littlemars-ffmpeg-utils
::
::	Fancy font is "roman" from: https://devops.datenkollektiv.de/banner.txt/index.html
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-12-19 Version 0.5.1
::		- Minor formatting
::	2023-12-14 Version 0.5
::		- Full rewrite of multi-file input management
::		- Rewrote error and abort subroutines
::	2023-12-04 Version 0.4.2
::		- Minor formatting
::	2023-11-25 Version 0.4.1
::		- Changed "choice" variable to "same_codec" for better clarity
::	2023-11-19 Version 0.4
::		- Added VALIDATE_OUTPUT subroutine
::		- Extended timeout for :ERROR_CHOICE from 10s to 30s
::		- Updated banner
::	2023-11-16 Version 0.3
::		- Added "-map 0:a" after input to select all audio tracks
::	2023-11-10 Version 0.2
::		Minor formatting
::		Updated script description and license disclaimer
::		Added changelog
::	-----------------------------------------------------------------------------------------------
::
::	---Debug Utils (will be removed in future releases---------------------------------------------
::	if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
::	-----------------------------------------------------------------------------------------------
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
	set file=%~1
	set codec=
	set bits=
	set OUTPUT_DIR=%~dp1
	set OUTPUT_NAME=%~n1
	set OUTPUT_EXT=.flac
	set %OUTPUT_SFX%=
	set count=2
	CALL :make_log
	set jump=yes
	cls
	title FFMPEG - Extracting audio from "%~1" to flac
	echo.[0m
	CALL :banner

	CALL :make_log

:analisys
	::	Have we already been here?
	if /i "%same_codec%"=="yes" (
    	goto :VALIDATE_OUTPUT
	) else (
	    goto :get_codec
	)

	:get_codec
		set "ffprobe=ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1 "%file%""
		for /F "delims=" %%I in ('!ffprobe!') do set "codec=%%I"

	if /i "%codec:~6%"=="FLAC" (
	    goto :error_already_flac
	) else (
	    goto :VALIDATE_OUTPUT
	)

	:get_bits_per_sample
		::	Get audio bits per sample
		set "ffprobe=ffprobe -v error -select_streams a:0 -show_entries stream=bits_per_sample -of default=noprint_wrappers=1 "%file%""
		for /F "delims=" %%I in ('!ffprobe!') do set "bits=%%I"

	if /i "%bits:~-2%"=="32" (
	    goto :errorbits32
	) else (
		goto :VALIDATE_OUTPUT
	)

:VALIDATE_OUTPUT
	echo.
	set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_EXT%"
	echo [101;93m VALIDATING OUTPUT... [0m
		IF EXIST %OUTPUT_FILE% (
   			echo Output [30;41m UNAVAILABLE [0m && goto :errorfile
 		) ELSE ( 
    		echo Output [30;42m AVAILABLE [0m && goto :encode
		)
:errorfile
	set OUTPUT_SFX= (%count%)
	set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_SFX%%OUTPUT_EXT%"
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
	echo [33m[2][0m. Rename output %OUTPUT_NAME%[30;43m-(%count%)[0m%OUTPUT_EXT%[0m
	echo [33m[3][0m. Abort the operation (will be auto-selected in 30s)
	echo.
	
	CHOICE /C 123 /T 30 /D 3 /M "Enter your choice:"
	:: Note - list ERRORLEVELS in decreasing order
	IF ERRORLEVEL 3 goto :abort
	IF ERRORLEVEL 2 goto :encode
	IF ERRORLEVEL 1 EXIT /B

:encode
	echo.
	echo.
	echo.
	echo [101;93m ENCODING... [0m
	echo File #%file_count%
	echo Input: %~nx1
	echo Output: %OUTPUT_NAME%%OUTPUT_SFX%%OUTPUT_EXT%
	echo.
	ffmpeg ^
		-hide_banner ^
		-loglevel warning ^
		-stats ^
		-i "%~1" ^
		-map 0:a ^
		-vn ^
		-c:a flac ^
		-compression_level 12 ^
		-exact_rice_parameters 1 ^
		-map_metadata 0 ^
		-write_id3v2 1 ^
		"%~dp1%~n1%OUTPUT_SFX%%OUTPUT_EXT%"
	
	CALL :log

	if NOT ["%errorlevel%"]==["0"] set print_error_level=%errorlevel% && goto :error	

	echo [92m%~n1 Done![0m
	goto :again

:error_already_flac
	
	echo [93mThere was an error. Looks like the input file audio track is already encoded in FLAC.[0m
	echo [93mDo you want to extract it to a separate file?[0m

	echo [33m[1][0m. yes (save option for subsequent files in queue)
	echo [33m[2][0m. yes (just this time)
	echo [33m[3][0m. no
	echo.

	CHOICE /t 10 /C 123 /D 1 /M "Enter your choice:"
	:: Note - ERRORLEVELS are listed in decreasing order
	IF ERRORLEVEL 3 goto :abort
	IF ERRORLEVEL 2 goto :encode
	IF ERRORLEVEL 1 set same_codec=yes && goto :get_bits_per_sample

:errorbits32
	echo [93mThere was an error. The input file audio codec has a bit depth of 32 bits and thus is incompatible with the FLAC encoder.[0m
	pause
	exit 0

:error
	echo [93mThere was an error. Please check your input file.[0m
	echo Errorlevel is %print_error_level%
	if EXIST %~dp1%~n1%OUTPUT_SFX%%OUTPUT_EXT% del %~dp1%~n1%OUTPUT_SFX%%OUTPUT_EXT%
	pause
	exit /B

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

:make_log
	if DEFINED jump exit /B
	for /f "tokens=1-4 delims=/ " %%i in ("%date%") do (
    	set dow=%%h
    	set month=%%i
    	set day=%%j
    	set year=%%k
		)
	SET datestr=%month%_%day%_%year%
	SET log_file=%OUTPUT_DIR%flac_log-%datestr%.log

	echo ENCODED FILES: >> %log_file%
	echo. >> %log_file%
	exit /B

:log
	echo %OUTPUT_FILE% >> %log_file%
	exit /B

:banner
	echo ╔═════════════════════════════════════════════════════════╗
	echo ║  oooooooooooo ooooo              .o.         .oooooo.   ║
	echo ║  `888'     `8 `888'             .888.       d8P'  `Y8b  ║
	echo ║   888          888             .8"888.     888          ║
	echo ║   888oooo8     888            .8' `888.    888          ║
	echo ║   888    "     888           .88ooo8888.   888          ║
	echo ║   888          888       o  .8'     `888.  `88b    ooo  ║
	echo ║  o888o        o888ooooood8 o88o     o8888o  `Y8bood8P'  ║
	echo ╚═════════════════════════════════════════════════════════╝
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	exit /B
