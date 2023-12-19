::if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
::	This script will extract the frames of selected videos to an image sequence
::
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---ADDITIONAL INFO-----------------------------------------------------------------------------
::  Fancy font is "roman" from https://devops.datenkollektiv.de/banner.txt/index.html
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-12-19 Version 0.4
::		Added functin to estimate output file size and abort operation if exceeding free disk space
::		Minor formatting
::	2023-11-16 Version 0.3.1
::		Fixed error in calculation of video duration
::	2023-11-13 Version 0.3
::		New method to count frames: multiplying duration by fps. This boosts speed of calculation
::		instead of using -sount_frames function of FFPROBE
::      New banner
::	2023-11-10 Version 0.2
::		Minor formatting	
::		Updated script description and license disclaimer
::		Added changelog
::	-----------------------------------------------------------------------------------------------
chcp 65001
setlocal EnableDelayedExpansion
@echo off

:next
	set count=2
	set input_file=%~1
    cls
    ::	IF NO MORE FILES ARE LEFT IN THE QUEUE GO TO DONE WARNING
    if "%~1" == "" goto:done

	rem Set the target drive letter
	set TargetDrive=%~d1

	wmic logicaldisk where "DeviceID='%TargetDrive%'" get freespace
	
	set count=0 
	for /F "delims=" %%a in ('wmic logicaldisk where "DeviceID='%TargetDrive%'" get freespace') do ( 
	set freediskspace=%%a 
	set /a count=!count! + 1 
	if !count! GTR 1 goto :freespace
	) 
	:freespace
	echo wsh.echo cdbl(%freediskspace%)/1024 > %temp%.\tmp.vbs 
	for /f %%a in ('cscript //nologo %temp%.\tmp.vbs') do set freediskspace=%%a 
	del %temp%.\tmp.vbs
	
	cls
	
	title FFMPEG - Making PNGs from %~1
	CALL :banner
	echo.
	echo [101;93m COUNTING FRAMES... [0m
    
    ::  Get FPS
    for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams v:0 -show_entries stream^=r_frame_rate -of default^=nokey^=1:noprint_wrappers^=1 "%~1"') do set "framerate=%%I"
    ::  Separation of FRAMES / SECONDS
    for /f "tokens=1,2 delims=/" %%i in ("!framerate!") do set frames=%%i && set seconds=%%j
    ::  Get duration
    for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams v:0 -show_entries format^=duration -of default^=nokey^=1:noprint_wrappers^=1 "%~1"') do set "duration=%%I"
    ::  Truncate duration
    for /f "tokens=1 delims=." %%i in ("!duration!") do set duration_truncated=%%i
    ::  Some math
    set /A duration_rounded="%duration_truncated%+1"
    set /A duration_by_frames="%duration_rounded%*%frames%"
    set /A frame_number="%duration_by_frames%/%seconds%"
    set /a Log="1%frame_number:~1%-%frame_number:~1% -0"
    set /a Len="%Log:0=+1%"
    ::  Dump info to user
    echo [0m Duration: [30;107m %duration_rounded%s [0m
    echo [0m Frames per second: [30;107m %framerate%s [0m
    echo [0m Total number of frames: [30;107m %frame_number% [0m

    echo.
    echo [101;93m VALIDATE OUTPUT FOLDER... [0m

	REM Set the number of frames to extract
	set num_frames=20

	REM Create an output folder with the same name as the input file (without extension)
	::for %%F in ("%input_file%") do set "output_folder=%%~dpnF_temp"
	set "output_folder=%temp%/%~n1_frame_temp"

	REM Resetting temp folder
	if EXIST %output_folder% RD /S /Q "!output_folder!"
	mkdir "!output_folder!"

	REM Use ffprobe to get the duration of the video
	for /f "tokens=*" %%a in ('ffmpeg -i "!input_file!" 2^>^&1 ^| find "Duration"') do set "duration=%%a"
	for /f "tokens=2 delims=:" %%b in ("!duration!") do set "duration=%%b"
	set "duration=!duration: =!"

	REM Calculate the time interval for extracting frames
	set /a "interval=!duration! / !num_frames!"

	REM Extract frames using ffmpeg
	echo [0m Extracting sample for output file size evaluation
	set "temp_frame_size=0"
	for /l %%i in (1,1,!num_frames!) do (
		set /a "time=%%i * !interval!"
		ffmpeg -hide_banner -loglevel warning -hwaccel auto -i "!input_file!" -ss !time! -frames:v 1 -f image2 -vcodec png -map_metadata 0 "!output_folder!\frame%%i%%01d.png"
	)
	
	REM Calculate the total combined size of frames
	for /f "usebackq delims=" %%a in (`powershell -command "& {Get-ChildItem '%output_folder%' -Recurse | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum}"`) do (
    set "temp_frames_size=%%a"
	)

	RD /S /Q "!output_folder!"

	rem Convert bytes to kilobytes and round upwards
	set /a "temp_frames_size/=1024"
	set /a "temp_single_frame_size=%temp_frames_size%/%num_frames%"

	set /a "projected_file_size=%temp_single_frame_size%*%frame_number%"
	set /a "projected_file_size/=1024"
	set /a "projected_file_size+=1024"

	set /a "freediskspace/=1024"

	echo [0m Projected file size: [30;107m %projected_file_size% MB [0m

	if %freediskspace% LEQ %projected_file_size% (
		echo [0m Free disk space: [30;41m %freediskspace% MB [0m is not enough to host output
		goto :abort
	)

	if %freediskspace% GTR %projected_file_size% (
		echo [0m Free disk space: [30;42m %freediskspace% MB [0m
	)

	::	echo Frames extracted successfully in "!output_folder!".
	::	echo Total combined size of frames: %temp_frames_size% kilobytes
	::	echo Projected file size: %projected_file_size% megabytes

	if %freediskspace% LEQ %projected_file_size% echo Not enough space available on device

    ::	Search for a folder with the same name as the expected output, if found go to FOLDER ERROR WARNING
    IF EXIST "%~dp1\%~n1-png" goto:advance_count

:MAKEFOLDER
    ::	CREATE A FOLDER TO PLACE THE OUTPUT IMAGES
	if NOT DEFINED replace_folder echo [0m Output folder non present, will be created now
    md "%~dp1\%~n1-png%dirsfx%"
	set "dirsfx="
	set "replace_folder="

    echo [0m Output folder [30;42m READY [0m

    ::  ACTUAL ENCODING
	echo.
	echo.
	echo [101;93m ENCODING... [0m
	echo.

	ffmpeg ^
		-hide_banner ^
		-loglevel warning ^
		-stats ^
		-hwaccel auto ^
		-y -i "%~1" ^
		-f image2 ^
		-vcodec png ^
		-map_metadata 0 ^
		"%~dp1\%~n1-png\%~n1-%%0%Len%d.png"
    
    IF NOT ["%errorlevel%"]==["0"] goto:error
	echo [92m%~n1 Done![0m
	title FFMPEG - We did it! Extraction of frames as PNGs from "%~1" completed!

	    shift
	    goto:next

:advance_count
		set OUTPUT_SFX= (%count%)
		set OUTPUT_FOLDER="%~dp1\%~n1-png (%count%)"
		IF EXIST %OUTPUT_FOLDER% (
  	      set /A count+=1 && set OUTPUT_SFX= (%count%) && goto :advance_count
 	   ) ELSE ( 
			goto :error_choice
		)
:error_choice
	cls
	CALL :banner
	echo.
	echo  [93mA folder with the same name as the requested output already exists.
	echo.
	echo [0mWhat shall we do?[0m
	echo [33m[1][0m. Replace its content (WILL ASK AGAIN FOR CONFIRMATION)
	echo [33m[2][0m. Create a new folder with "(%count%)" suffix
	echo [33m[3][0m. Stop the encode
	echo [33m[4][0m. Pause the script and let me check (activated by default in 10s)
	echo.
	
	CHOICE /t 10 /C 1234 /CS /D 4 /M "Enter your choice:"
	:: Note - list ERRORLEVELS in decreasing order
	IF ERRORLEVEL 4 GOTO:WAITFORUSER
	IF ERRORLEVEL 3 GOTO:STOPENCODE
	IF ERRORLEVEL 2 GOTO:FOLDERSUFFIX
	IF ERRORLEVEL 1 GOTO:REPLACEFOLDER
	
	goto:ENCODE

:WAITFORUSER
	cls
	CALL :banner
	echo.
	echo  [93mI have detected your indecision, the script has been paused while you sort it out![0m
	echo.
	echo.
	pause
	goto:advance_count

:STOPENCODE
	goto:abort

:FOLDERSUFFIX
	set "dirsfx=(%count%)"
	goto:MAKEFOLDER

:REPLACEFOLDER
	set replace_folder=yes
	echo.
	echo This folder is about to get deleted:
	RMDIR /S "%~dp1\%~n1-png"
	echo.
	goto:MAKEFOLDER

:error
	echo [93mThere was an error. Please check your input file.[0m
	echo Errorlevel is %print_error_level%
	if EXIST %~dp1%~n1%OUTPUT_SFX%%OUTPUT_EXT% del %~dp1%~n1%OUTPUT_SFX%%OUTPUT_EXT%
	pause
	exit /B

:banner
    echo [0m╔═════════════════════════════════════════════════════════════════════════════════════════╗
    echo ║  ooo         ooooo          oooo                                                        ║
    echo ║  `88.       .888'           `888                                                        ║
    echo ║   888b     d'888   .oooo.    888  oooo   .ooooo.     oo.ooooo.  ooo. .oo.    .oooooooo  ║
    echo ║   8 Y88. .P  888  `P  )88b   888 .8P'   d88' `88b     888' `88b `888P"Y88b  888' `88b   ║
    echo ║   8  `888'   888   .oP"888   888888.    888ooo888     888   888  888   888  888   888   ║
    echo ║   8    Y     888  d8(  888   888 `88b.  888    .o     888   888  888   888  `88bod8P'   ║
    echo ║  o8o        o888o `Y888""8o o888o o888o `Y8bod8P'     888bod8P' o888o o888o `8oooooo.   ║
    echo ║                                                       888                   d"     YD   ║
    echo ║                                                      o888o                  "Y88888P'   ║
    echo ╚═════════════════════════════════════════════════════════════════════════════════════════╝
    echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
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
