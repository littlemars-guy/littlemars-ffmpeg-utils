::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::	if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
::	This script will remux its input to a mp4 with DAR set to 16:9 in metadata. No re-encoding will occour.
echo off
chcp 65001
cls

::	User input
	echo.
	echo [92m╔══════════════════════════════════════════════════════╗
	echo [92m║========== IT'S GONNA BE WIIIIIIIIIIIIIIIDE ==========║
	echo [92m╚══════════════════════════════════════════════════════╝[0m
	echo.
	echo [37mBut first I need you to specify the aspect ratio of the output:[0m
	echo.
	echo [33m[1][0m. 16:9 (1,78:1)
	echo [33m[2][0m. 4:3 (1,33:1)
	echo [33m[3][0m. 5:4 (1,25:1)
	echo [33m[4][0m. custom (will ask in a moment)
	echo.
	
	CHOICE /C 12345 /M "Enter your choice:"
	:: Note - list ERRORLEVELS in decreasing order
	IF ERRORLEVEL 4 GOTO:custom_ar
	IF ERRORLEVEL 3 set aspect_ratio="5/4" && goto:manage_origin
	IF ERRORLEVEL 2 set aspect_ratio="4/3" && goto:manage_origin
	IF ERRORLEVEL 1 set aspect_ratio="16/9" && goto:manage_origin

	:custom_ar
	set /p aspect_ratio=Write your desired aspect ratio (in the format WIDTH/HEIGHT ex.: 16/9), then press enter.
	if not defined aspect_ratio goto:custom_ar
	goto:manage_origin

	:manage_origin
	echo [37mOne last thing, I need you to specify what to do with the originals:[0m
	echo.
	echo [33m[1][0m. Overwrite originals. BEWARE! DELETED FILES WON'T BE RECOVERABLE VIA RECYCLE BIN
	echo [33m[2][0m. Keep both, the new files will have the "-wide" suffix
	echo [33m[3][0m. Write new ones in a folder named "-wide"
	echo [33m[4][0m. Move originals to a new folder named "-old"
	echo.
	
	CHOICE /C 12345 /M "Enter your choice:"
	:: Note - list ERRORLEVELS in decreasing order
	IF ERRORLEVEL 4 GOTO:FOLDEROLD
	IF ERRORLEVEL 3 GOTO:FOLDERWIDE
	IF ERRORLEVEL 2 GOTO:KEEPBOTH
	IF ERRORLEVEL 1 GOTO:OVERWRITE



:OVERWRITE
	goto:overwrite_next

	:overwrite_next
		::	Placing title
		title FFMPEG - Adapting DAR of %~nx1 to 16:9
		set input=%~1
		goto:overwrite_CONVERT
	::	Check if extension is .mp4
	::	set extension=%~x1
	::	if %extension%==.mp4 goto:overwrite_defcodec
	::	if %extension%==.mov goto:overwrite_defcodec
	::	if %extension%==.mkv goto:overwrite_defcodec
	::	if %extension%==.avi goto:overwrite_defcodec
	::
	::	goto:errorUnrecognizedContainer


	::	:overwrite_defcodec
	::	Define video codec
	::	for /F "delims=" %%I in ('@ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "detect=%%I"
	::
	::	set codec=%detect:~11%
	::
	::	if %codec%==h264 set rotatemeta="-aspect 16/9" && goto:overwrite_CONVERTh26x
	::	if %codec%==h265 set rotatemeta="h265_metadata=sample_aspect_ratio=16/9" && goto:overwrite_CONVERTh26x
	::	if %codec%==mpeg2 set rotatemeta="mpeg2_metadata=display_aspect_ratio=16/9" && goto:overwrite_CONVERTh26x
	::	if %extension%==.mkv goto:overwrite_CONVERTmkv
	::	if %extension%==.avi goto:overwrite_RemuxMKV
	::	goto:errorcodec

	:overwrite_CONVERT
		if "%~1" == "" goto:done
		::	Check if output file already exists	
		if exist "%~1-wide%~x1" goto:errorfile

		::	Let's go!
		echo.
		echo [92m╔══════════════════════════════════════════════════════╗
		echo [92m║========== IT'S GONNA BE WIIIIIIIIIIIIIIIDE ==========║
		echo [92m╚══════════════════════════════════════════════════════╝[0m
		echo.

		ffmpeg ^
			-i "%~1" ^
			-c copy ^
			-aspect 16/9 ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1-wide%~x1"

			GOTO:overwrite_endofencode

	:overwrite_endofencode
		if NOT ["%errorlevel%"]==["0"] goto:error
		
		::delete original
		setlocal EnableDelayedExpansion
		DEL "%input%""
		endlocal

		:: Done!
		echo [92m%~n1 Done![0m
		title FFMPEG - We did it!

		if "%~1" == "" goto:done

		timeout /t 2

		shift
		goto:overwrite_next


:KEEPBOTH
	goto:keepboth_next

	:keepboth_next
		::	Placing title
		title FFMPEG - Adapting DAR of %~nx1 to 16:9
		set input=%~1
		goto:keepboth_convert

	:keepboth_convert
		if "%~1" == "" goto:done
		::	Check if output file already exists	
		if exist "%~1-wide%~x1" goto:errorfile

		::	Let's go!
		echo.
		echo [92m╔══════════════════════════════════════════════════════╗
		echo [92m║========== IT'S GONNA BE WIIIIIIIIIIIIIIIDE ==========║
		echo [92m╚══════════════════════════════════════════════════════╝[0m
		echo.

		ffmpeg ^
			-i "%~1" ^
			-c copy ^
			-aspect 16/9 ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1-wide%~x1"

			GOTO:keepboth_endofencode

	:keepboth_endofencode
		if NOT ["%errorlevel%"]==["0"] goto:error
		
		:: Done!
		echo [92m%~n1 Done![0m
		title FFMPEG - We did it!

		if "%~1" == "" goto:done

		timeout /t 2

		shift
		goto:keepboth_next
	
:FOLDERWIDE
	goto:folderwide_next

	:folderwide_next
	::	Placing title
		title FFMPEG - Adapting DAR of %~nx1 to 16:9
		set input=%~1
		goto:folderwide_convert

	:folderwide_convert
		if "%~1" == "" goto:done
	::	Check if output folder already exists, create if missing
		set folder_wide=_wide
		if not exist "%~dp1%folder_wide%"  mkdir "%~dp1%folder_wide%"
	::	Check if output file already exists	
		if exist "%~dp1%folder_wide%%~n1-wide%~x1" goto:errorfile

	::	Let's go!
		echo.
		echo [92m╔══════════════════════════════════════════════════════╗
		echo [92m║========== IT'S GONNA BE WIIIIIIIIIIIIIIIDE ==========║
		echo [92m╚══════════════════════════════════════════════════════╝[0m
		echo.

		ffmpeg ^
			-i "%~1" ^
			-c copy ^
			-aspect 16/9 ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%folder_wide%/%~n1-wide%~x1"

			GOTO:folderwide_endofencode

	:folderwide_endofencode
		if NOT ["%errorlevel%"]==["0"] goto:error
		
		:: Done!
		echo [92m%~n1 Done![0m
		title FFMPEG - We did it!

		if "%~1" == "" goto:done

		timeout /t 2

		shift
		goto:folderwide_next
	
:FOLDEROLD
	goto:folderold_next

	:folderold_next
	::	Placing title
		title FFMPEG - Adapting DAR of %~nx1 to 16:9
		set input=%~1
		goto:folderold_convert

	:folderold_convert
		if "%~1" == "" goto:done
	::	Check if output folder already exists, create if missing
		set folder_old=_old
		if not exist "%~dp1%folder_old%"  mkdir "%~dp1%folder_old%"
	::	Check if output file already exists	
		if exist "%~1-wide%~x1" goto:errorfile

	::	Let's go!
		echo.
		echo [92m╔══════════════════════════════════════════════════════╗
		echo [92m║========== IT'S GONNA BE WIIIIIIIIIIIIIIIDE ==========║
		echo [92m╚══════════════════════════════════════════════════════╝[0m
		echo.

		ffmpeg ^
			-i "%~1" ^
			-c copy ^
			-aspect 16/9 ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1-wide%~x1"

			GOTO:folderold_endofencode

	:folderold_endofencode
		if NOT ["%errorlevel%"]==["0"] goto:error
		::	Move original to -old folder
		move "%~1" "%~dp1%folder_old%"
		::	Done!
		echo [92m%~n1 Done![0m
		title FFMPEG - We did it!

		if "%~1" == "" goto:done

		timeout /t 2

		shift
		goto:folderold_next

:errorUnrecognizedContainer
	 
	cls
	echo.
	echo  [93m╔══════════════════╗
	echo  [93m║====ATTENTION!====║
	echo  [93m╚══════════════════╝
	echo.
	echo  [93mUnrecognized extension
	echo  [93mThis script can only operate on .mp4, .mov, .mkv and .avi inputs.
	echo.
	echo  [93mCheck the input file before trying again!
	echo.
	echo  [93mPress any key to close this window.[0m
	pause > nul
	exit

:errorfile
	 
	cls
	echo.
	echo  [93m╔══════════════════╗
	echo  [93m║====ATTENTION!====║
	echo  [93m╚══════════════════╝
	echo.
	echo  [93mA file with the same name as
	echo  [93mthe requested conversion output already exists.
	echo.
	echo  [93mCheck the output folder before trying again!
	echo.
	echo  [93mPress any key to close this window.[0m
	pause > nul
	exit

:errorcodec
	 
	cls
	echo.
	echo  [93m╔══════════════════╗
	echo  [93m║====ATTENTION!====║
	echo  [93m╚══════════════════╝
	echo.
	echo  [93mI was unable to determine the nature of the
	echo  [93mcodec used in the given file.
	echo.
	echo  [93mCheck the input file before trying again!
	echo.
	echo  [93mPress any key to close this window.[0m
	pause > nul
	exit

:error
	 
	echo [93mThere was an error. Please check your input file.[0m
	pause
	exit 0

:end
 
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