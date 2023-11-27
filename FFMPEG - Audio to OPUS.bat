::	This script will extract audio from source and save it as a new OPUS file
::
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---ADDITIONAL INFO-----------------------------------------------------------------------------
::  Fancy font is "roman" from https://devops.datenkollektiv.de/banner.txt/index.html
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-11-23 Version 0.1
::		- Initial release -- [based on Audio to FLAC v0.4] --
::	-----------------------------------------------------------------------------------------------
::if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
@echo off
chcp 65001
cls
setlocal EnableDelayedExpansion

:again
	set file=%~1
	set OUTPUT_DIR=%~dp1
	set OUTPUT_NAME=%~n1
	set %OUTPUT_SFX%=""
	set OUTPUT_EXT=opus
	set count=2
	title FFMPEG - Extracting audio from %file% to opus
	echo.[0m
	echo ╔═══════════════════════════════════════════════════════╗
	echo ║    .oooooo.   ooooooooo.   ooooo     ooo  .oooooo..o  ║
	echo ║   d8P'  `Y8b  `888   `Y88. `888'     `8' d8P'    `Y8  ║
	echo ║  888      888  888   .d88'  888       8  Y88bo.       ║
	echo ║  888      888  888ooo88P'   888       8   `"Y8888o.   ║
	echo ║  888      888  888          888       8       `"Y88b  ║
	echo ║  `88b    d88'  888          `88.    .8'  oo     .d8P  ║
	echo ║   `Y8bood8P'  o888o           `YbodP'    8""88888P'   ║
	echo ╚═══════════════════════════════════════════════════════╝ 
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	IF DEFINED choice (goto:analisys) ELSE (goto:preset_selection)
	echo [101;93m PRESET SELECTION [0m

:preset_selection
	echo [1mSelect the desired encoding preset:[0m
	echo [33m[1][0m. [MUSIC] - High Quality, High Bitrate, Multi-channel (Optimized for music reproduction)
	echo [33m[2][0m. [VOIP] - Low Quality, Low Bitrate, MONO (Optimized for low space consumption voice memos)
	echo [33m[3][0m. [MEDIUM] - Somewhat in between, Multi-channel
	echo.
	
	CHOICE /C 123 /M "Enter your choice:"
	:: Note - list ERRORLEVELS in decreasing order
	IF ERRORLEVEL 3 set choice="medium" && set Preset=[Opus] && GOTO:analisys
	IF ERRORLEVEL 2 set choice="VOIP" && set Preset=[Opus-VOIP] && GOTO:analisys
	IF ERRORLEVEL 1 set choice="MUSIC" && set Preset=[Opus-MUSIC] && GOTO:analisys

:analisys
	::	Have we already been here?
	if /i "%same_codec_remember%"=="yes" (
    	goto :VALIDATE_OUTPUT
	) else (
	    goto :get_codec
	)

	:get_codec
		::	Reset variables before analisys
		set codec=""
		::	Get codec name
		set "ffprobe=ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1 "%file%""
		for /F "delims=" %%I in ('!ffprobe!') do set "codec=%%I"

	if /i "%codec:~6%"=="Opus" (
	    goto :error_same_codec
	) else (
	    goto :VALIDATE_OUTPUT
	)

:VALIDATE_OUTPUT
	echo.
	set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%-%Preset%.%OUTPUT_EXT%"
	echo [101;93m VALIDATING OUTPUT... [0m
		IF EXIST %OUTPUT_FILE% (
   			echo Output [30;41m UNAVAILABLE [0m && goto:errorfile
 		) ELSE ( 
    		echo Output [30;42m AVAILABLE [0m && goto:encode
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
	if "%choice%"=="MUSIC" goto:music
	if "%choice%"=="VOIP" goto:voip
	if "%choice%"=="medium" goto:medium
	echo.
	echo.
	echo.
	echo [101;93m ENCODING... [0m
	echo.
	:music
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-stats -i "%~1" ^
			-map 0:a ^
			-vn ^
			-c:a libopus ^
			-b:a 256k ^
			-application audio ^
			-apply_phase_inv 1 ^
			-cutoff 0 ^
			-map_metadata 0 ^
			-write_id3v2 1 ^
			"%~dp1%~n1-%Preset%%OUTPUT_SFX%.%OUTPUT_EXT%"

		goto:next

	:voip
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-stats -i "%~1" ^
			-map 0:a ^
			-vn ^
			-c:a libopus ^
			-b:a 64k ^
			-application voip ^
			-apply_phase_inv 0 ^
			-cutoff 20000 ^
			-ac 1 ^
			-map_metadata 0 ^
			-write_id3v2 1 ^
			"%~dp1%~n1-%Preset%%OUTPUT_SFX%.%OUTPUT_EXT%"
		
		goto:next

	:medium
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-stats -i "%~1" ^
			-map 0:a ^
			-vn ^
			-c:a libopus ^
			-b:a 128k ^
			-application audio ^
			-apply_phase_inv 1 ^
			-cutoff 0 ^
			-map_metadata 0 ^
			-write_id3v2 1 ^
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
	
	cls
	echo.[0m
	echo ╔═══════════════════════════════════════════════════════╗
	echo ║    .oooooo.   ooooooooo.   ooooo     ooo  .oooooo..o  ║
	echo ║   d8P'  `Y8b  `888   `Y88. `888'     `8' d8P'    `Y8  ║
	echo ║  888      888  888   .d88'  888       8  Y88bo.       ║
	echo ║  888      888  888ooo88P'   888       8   `"Y8888o.   ║
	echo ║  888      888  888          888       8       `"Y88b  ║
	echo ║  `88b    d88'  888          `88.    .8'  oo     .d8P  ║
	echo ║   `Y8bood8P'  o888o           `YbodP'    8""88888P'   ║
	echo ╚═══════════════════════════════════════════════════════╝ 
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo.
	echo [30;41mProcess aborted.[0m
	echo.
	echo [93mThis window will close after 5 seconds.[0m
	timeout /t 1 > nul
	cls
	echo.[0m
	echo ╔═══════════════════════════════════════════════════════╗
	echo ║    .oooooo.   ooooooooo.   ooooo     ooo  .oooooo..o  ║
	echo ║   d8P'  `Y8b  `888   `Y88. `888'     `8' d8P'    `Y8  ║
	echo ║  888      888  888   .d88'  888       8  Y88bo.       ║
	echo ║  888      888  888ooo88P'   888       8   `"Y8888o.   ║
	echo ║  888      888  888          888       8       `"Y88b  ║
	echo ║  `88b    d88'  888          `88.    .8'  oo     .d8P  ║
	echo ║   `Y8bood8P'  o888o           `YbodP'    8""88888P'   ║
	echo ╚═══════════════════════════════════════════════════════╝ 
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo.
	echo [30;41mProcess aborted.[0m
	echo.
	echo [93mThis window will close after 4 seconds.[0m
	timeout /t 1 > nul
	cls
	echo.[0m
	echo ╔═══════════════════════════════════════════════════════╗
	echo ║    .oooooo.   ooooooooo.   ooooo     ooo  .oooooo..o  ║
	echo ║   d8P'  `Y8b  `888   `Y88. `888'     `8' d8P'    `Y8  ║
	echo ║  888      888  888   .d88'  888       8  Y88bo.       ║
	echo ║  888      888  888ooo88P'   888       8   `"Y8888o.   ║
	echo ║  888      888  888          888       8       `"Y88b  ║
	echo ║  `88b    d88'  888          `88.    .8'  oo     .d8P  ║
	echo ║   `Y8bood8P'  o888o           `YbodP'    8""88888P'   ║
	echo ╚═══════════════════════════════════════════════════════╝ 
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo.
	echo [30;41mProcess aborted.[0m
	echo.
	echo [93mThis window will close after 3 seconds.[0m
	timeout /t 1 > nul
	cls
	echo.[0m
	echo ╔═══════════════════════════════════════════════════════╗
	echo ║    .oooooo.   ooooooooo.   ooooo     ooo  .oooooo..o  ║
	echo ║   d8P'  `Y8b  `888   `Y88. `888'     `8' d8P'    `Y8  ║
	echo ║  888      888  888   .d88'  888       8  Y88bo.       ║
	echo ║  888      888  888ooo88P'   888       8   `"Y8888o.   ║
	echo ║  888      888  888          888       8       `"Y88b  ║
	echo ║  `88b    d88'  888          `88.    .8'  oo     .d8P  ║
	echo ║   `Y8bood8P'  o888o           `YbodP'    8""88888P'   ║
	echo ╚═══════════════════════════════════════════════════════╝ 
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo.
	echo [30;41mProcess aborted.[0m
	echo.
	echo [93mThis window will close after 2 seconds.[0m
	timeout /t 1 > nul
	cls
	echo.[0m
	echo ╔═══════════════════════════════════════════════════════╗
	echo ║    .oooooo.   ooooooooo.   ooooo     ooo  .oooooo..o  ║
	echo ║   d8P'  `Y8b  `888   `Y88. `888'     `8' d8P'    `Y8  ║
	echo ║  888      888  888   .d88'  888       8  Y88bo.       ║
	echo ║  888      888  888ooo88P'   888       8   `"Y8888o.   ║
	echo ║  888      888  888          888       8       `"Y88b  ║
	echo ║  `88b    d88'  888          `88.    .8'  oo     .d8P  ║
	echo ║   `Y8bood8P'  o888o           `YbodP'    8""88888P'   ║
	echo ╚═══════════════════════════════════════════════════════╝ 
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo.
	echo [30;41mProcess aborted.[0m
	echo.
	echo [93mThis window will close after 1 seconds.[0m
	timeout /t 1 > nul
	exit 0


:end
	
	cls
	echo.[0m
	echo ╔═══════════════════════════════════════════════════════╗
	echo ║    .oooooo.   ooooooooo.   ooooo     ooo  .oooooo..o  ║
	echo ║   d8P'  `Y8b  `888   `Y88. `888'     `8' d8P'    `Y8  ║
	echo ║  888      888  888   .d88'  888       8  Y88bo.       ║
	echo ║  888      888  888ooo88P'   888       8   `"Y8888o.   ║
	echo ║  888      888  888          888       8       `"Y88b  ║
	echo ║  `88b    d88'  888          `88.    .8'  oo     .d8P  ║
	echo ║   `Y8bood8P'  o888o           `YbodP'    8""88888P'   ║
	echo ╚═══════════════════════════════════════════════════════╝ 
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo.
	echo [92mEncoding succesful. This window will close after 5 seconds.[0m
	timeout /t 1 > nul
	cls
	echo.[0m
	echo ╔═══════════════════════════════════════════════════════╗
	echo ║    .oooooo.   ooooooooo.   ooooo     ooo  .oooooo..o  ║
	echo ║   d8P'  `Y8b  `888   `Y88. `888'     `8' d8P'    `Y8  ║
	echo ║  888      888  888   .d88'  888       8  Y88bo.       ║
	echo ║  888      888  888ooo88P'   888       8   `"Y8888o.   ║
	echo ║  888      888  888          888       8       `"Y88b  ║
	echo ║  `88b    d88'  888          `88.    .8'  oo     .d8P  ║
	echo ║   `Y8bood8P'  o888o           `YbodP'    8""88888P'   ║
	echo ╚═══════════════════════════════════════════════════════╝ 
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo.
	echo [92mEncoding succesful. This window will close after 4 seconds.[0m
	timeout /t 1 > nul
	cls
	echo.[0m
	echo ╔═══════════════════════════════════════════════════════╗
	echo ║    .oooooo.   ooooooooo.   ooooo     ooo  .oooooo..o  ║
	echo ║   d8P'  `Y8b  `888   `Y88. `888'     `8' d8P'    `Y8  ║
	echo ║  888      888  888   .d88'  888       8  Y88bo.       ║
	echo ║  888      888  888ooo88P'   888       8   `"Y8888o.   ║
	echo ║  888      888  888          888       8       `"Y88b  ║
	echo ║  `88b    d88'  888          `88.    .8'  oo     .d8P  ║
	echo ║   `Y8bood8P'  o888o           `YbodP'    8""88888P'   ║
	echo ╚═══════════════════════════════════════════════════════╝ 
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo.
	echo [92mEncoding succesful. This window will close after 3 seconds.[0m
	timeout /t 1 > nul
	cls
	echo.[0m
	echo ╔═══════════════════════════════════════════════════════╗
	echo ║    .oooooo.   ooooooooo.   ooooo     ooo  .oooooo..o  ║
	echo ║   d8P'  `Y8b  `888   `Y88. `888'     `8' d8P'    `Y8  ║
	echo ║  888      888  888   .d88'  888       8  Y88bo.       ║
	echo ║  888      888  888ooo88P'   888       8   `"Y8888o.   ║
	echo ║  888      888  888          888       8       `"Y88b  ║
	echo ║  `88b    d88'  888          `88.    .8'  oo     .d8P  ║
	echo ║   `Y8bood8P'  o888o           `YbodP'    8""88888P'   ║
	echo ╚═══════════════════════════════════════════════════════╝ 
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo.
	echo [92mEncoding succesful. This window will close after 2 seconds.[0m
	timeout /t 1 > nul
	cls
	echo.[0m
	echo ╔═══════════════════════════════════════════════════════╗
	echo ║    .oooooo.   ooooooooo.   ooooo     ooo  .oooooo..o  ║
	echo ║   d8P'  `Y8b  `888   `Y88. `888'     `8' d8P'    `Y8  ║
	echo ║  888      888  888   .d88'  888       8  Y88bo.       ║
	echo ║  888      888  888ooo88P'   888       8   `"Y8888o.   ║
	echo ║  888      888  888          888       8       `"Y88b  ║
	echo ║  `88b    d88'  888          `88.    .8'  oo     .d8P  ║
	echo ║   `Y8bood8P'  o888o           `YbodP'    8""88888P'   ║
	echo ╚═══════════════════════════════════════════════════════╝ 
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo.
	echo [92mEncoding succesful. This window will close after 1 seconds.[0m
	timeout /t 1 > nul
	exit 0