::	This script will remux its input to a mp4 with DAR set in metadata. No re-encoding will occour.
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
::	2023-12-06 Version 0.3.3
::		- Moved banners to :banner and :info subroutines
::	2023-11-18 Version 0.3.2
::		- Fixed next file check happening before shift
::	2023-11-16 Version 0.3.1
::		- Added "-map 0" after input to select all tracks
::	2023-11-13 Version 0.3
::		New banner! YAY!
::		General clean up
::	2023-11-10 Version 0.2
::		Added basic presets and prompt to input custom A/R
::	-----------------------------------------------------------------------------------------------

echo off
chcp 65001
cls
CALL:banner
echo.
CALL:info
echo.
CALL:info
::	User input
	echo.
	echo [37mBut first you have to specify the desired output aspect ratio:[0m
	echo.
	echo [33m[1][0m. 16:9 (1,78:1)
	echo [33m[2][0m. 4:3 (1,33:1)
	echo [33m[3][0m. 5:4  (1,25:1)
	echo [33m[4][0m. custom (will ask in a moment)
	echo.
	
	CHOICE /C 1234 /M "Enter your choice:"
	:: Note - list ERRORLEVELS in decreasing order
	IF ERRORLEVEL 4 GOTO:custom_ar
	IF ERRORLEVEL 3 set aspect_ratio="5/4" && goto:manage_origin
	IF ERRORLEVEL 2 set aspect_ratio="4/3" && goto:manage_origin
	IF ERRORLEVEL 1 set aspect_ratio="16/9" && goto:manage_origin

	:custom_ar
	set aspect_ratio=""
	set /p aspect_ratio=Enter your desired aspect ratio (such as WIDTH/HEIGHT ex.: "16/9"), then press enter.
	if not defined aspect_ratio goto:custom_ar

	echo(%aspect_ratio%|findstr /r /x "[0123456789]*/[0123456789]*" > nul || echo [93mInput should be NUMBER/NUMBER, example: 16/9[0m && echo. && goto:custom_ar

	goto:manage_origin

	:manage_origin
	echo [37mOne last thing, I need you to specify what to do with the originals:[0m
	echo.
	echo [33m[1][0m. Overwrite originals. BEWARE! DELETED FILES WON'T BE RECOVERABLE VIA RECYCLE BIN
	echo [33m[2][0m. Keep both, the new files will have the "-wide" suffix
	echo [33m[3][0m. Write new ones in a folder named "-wide"
	echo [33m[4][0m. Move originals to a new folder named "-old"
	echo.
	
	CHOICE /C 1234 /M "Enter your choice:"
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
		if "%~1" == "" goto:done
		::	Check if output file already exists	
		if exist "%~1-wide%~x1" goto:errorfile
		::	Let's go!
		cls
		CALL:banner
		echo.
		CALL:info
		echo.
		echo [101;93m CONVERTING TO %aspect_ratio%... [0m
		echo.
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-stats ^
			-i "%~1" ^
			-map 0 ^
			-c copy ^
			-aspect %aspect_ratio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1-wide%~x1"

		if NOT ["%errorlevel%"]==["0"] goto:error
		::delete original
		setlocal EnableDelayedExpansion
		DEL "%input%""
		endlocal
		:: Done!
		echo [92m%~n1 Done![0m
		title FFMPEG - We did it!
		timeout /t 2
		shift
		if "%~1" == "" goto:done
		goto:overwrite_next

:KEEPBOTH
	goto:keepboth_next

	:keepboth_next
		::	Placing title
		title FFMPEG - Adapting DAR of %~nx1 to 16:9
		set input=%~1
		if "%~1" == "" goto:done
		::	Check if output file already exists	
		if exist "%~1-wide%~x1" goto:errorfile
		::	Let's go!
		cls
		CALL:banner
		echo.
		CALL:info
		echo.
		echo [101;93m CONVERTING TO %aspect_ratio%... [0m
		echo.
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-stats ^
			-i "%~1" ^
			-map 0 ^
			-c copy ^
			-aspect %aspect_ratio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1-wide%~x1"

		if NOT ["%errorlevel%"]==["0"] goto:error
		:: Done!
		echo [92m%~n1 Done![0m
		title FFMPEG - We did it!
		timeout /t 2
		shift
		if "%~1" == "" goto:done
		goto:keepboth_next
	
:FOLDERWIDE
	goto:folderwide_next

	:folderwide_next
	::	Placing title
		title FFMPEG - Adapting DAR of %~nx1 to 16:9
		set input=%~1
		if "%~1" == "" goto:done
	::	Check if output folder already exists, create if missing
		set folder_wide=_wide
		if not exist "%~dp1%folder_wide%"  mkdir "%~dp1%folder_wide%"
	::	Check if output file already exists	
		if exist "%~dp1%folder_wide%%~n1-wide%~x1" goto:errorfile
	::	Let's go!
		cls
		CALL:banner
		echo.
		CALL:info
		echo.
		echo [101;93m CONVERTING TO %aspect_ratio%... [0m
		echo.
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-stats ^
			-i "%~1" ^
			-map 0 ^
			-c copy ^
			-aspect %aspect_ratio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%folder_wide%/%~n1-wide%~x1"

		if NOT ["%errorlevel%"]==["0"] goto:error
		:: Done!
		echo [92m%~n1 Done![0m
		title FFMPEG - We did it!
		timeout /t 2
		shift
		if "%~1" == "" goto:done
		goto:folderwide_next
	
:FOLDEROLD
	goto:folderold_next

	:folderold_next
	::	Placing title
		title FFMPEG - Adapting DAR of %~nx1 to 16:9
		set input=%~1
		if "%~1" == "" goto:done
	::	Check if output folder already exists, create if missing
		set folder_old=_old
		if not exist "%~dp1%folder_old%"  mkdir "%~dp1%folder_old%"
	::	Check if output file already exists	
		if exist "%~1-wide%~x1" goto:errorfile
	::	Let's go!
		cls
		CALL:banner
		echo.
		CALL:info
		echo.
		echo [101;93m CONVERTING TO %aspect_ratio%... [0m
		echo.
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-stats ^
			-i "%~1" ^
			-map 0 ^
			-c copy ^
			-aspect %aspect_ratio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1-wide%~x1"

		if NOT ["%errorlevel%"]==["0"] goto:error
		::	Move original to -old folder
		move "%~1" "%~dp1%folder_old%"
		::	Done!
		echo [92m%~n1 Done![0m
		title FFMPEG - We did it!
		timeout /t 2
		shift
		if "%~1" == "" goto:done
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

:done
	cls
	CALL:banner
	echo.
	echo [92mEncoding succesful. This window will close after 5 seconds.[0m
	timeout /t 1 > nul
	cls
	CALL:banner
	echo.
	echo [92mEncoding succesful. This window will close after 4 seconds.[0m
	timeout /t 1 > nul
	cls
	CALL:banner
	echo.
	echo [92mEncoding succesful. This window will close after 3 seconds.[0m
	timeout /t 1 > nul
	cls
	CALL:banner
	echo.
	echo [92mEncoding succesful. This window will close after 2 seconds.[0m
	timeout /t 1 > nul
	cls
	CALL:banner
	echo.
	echo [92mEncoding succesful. This window will close after 1 seconds.[0m
	timeout /t 1 > nul
	exit 0

:banner
	echo ╔══════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
	echo ║  ooooo ooooooooooooo o8o  .oooooo..o      .oooooo.      .oooooo.   ooooo      ooo ooooo      ooo       .o.       ║
	echo ║  `888' 8'   888   `8 `YP d8P'    `Y8     d8P'  `Y8b    d8P'  `Y8b  `888b.     `8' `888b.     `8'      .888.      ║
	echo ║   888       888       '  Y88bo.         888           888      888  8 `88b.    8   8 `88b.    8      .8"888.     ║
	echo ║   888       888           `"Y8888o.     888           888      888  8   `88b.  8   8   `88b.  8     .8' `888.    ║
	echo ║   888       888               `"Y88b    888     ooooo 888      888  8     `88b.8   8     `88b.8    .88ooo8888.   ║
	echo ║   888       888          oo     .d8P    `88.    .88'  `88b    d88'  8       `888   8       `888   .8'     `888.  ║
	echo ║  o888o     o888o         8""88888P'      `Y8bood8P'    `Y8bood8P'  o8o        `8  o8o        `8  o88o     o8888o ║
	echo ║                                                                                                                  ║
	echo ║  oooooooooo.  oooooooooooo    oooooo   oooooo     oooo ooooo ooooo ooooo ooooo ooooo oooooooooo.   oooooooooooo  ║
	echo ║  `888'   `Y8b `888'     `8     `888.    `888.     .8'  `888' `888' `888' `888' `888' `888'   `Y8b  `888'     `8  ║
	echo ║   888     888  888              `888.   .8888.   .8'    888   888   888   888   888   888      888  888          ║
	echo ║   888oooo888'  888oooo8          `888  .8'`888. .8'     888   888   888   888   888   888      888  888oooo8     ║
	echo ║   888    `88b  888    "           `888.8'  `888.8'      888   888   888   888   888   888      888  888    "     ║
	echo ║   888    .88P  888       o         `888'    `888'       888   888   888   888   888   888     d88'  888       o  ║
	echo ║  o888bood8P'  o888ooooood8          `8'      `8'       o888o o888o o888o o888o o888o o888bood8P'   o888ooooood8  ║
	echo ╚══════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
	echo              - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	exit /B

:info
	echo NOTE: This script will only change the display aspet ratio info in metadata, it will not re-encode the input. Some
	echo       software (such as premiere pro) might not recognize these  metadata and will display the video based off its
	echo       storage / pixel aspect ratio.
	exit /B