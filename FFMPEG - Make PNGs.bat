::if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
::	This script will extract the frames of selected videos to an image sequence
::
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-11-13 Version 0.3.1
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
@echo off

:next
    cls
    ::	IF NO MORE FILES ARE LEFT IN THE QUEUE GO TO DONE WARNING
    if "%~1" == "" goto:done
    ::	Placing title
	title FFMPEG - Making PNGs from %~1
    ::  Fancy display of intentions :)
    ::  font = roman from https://devops.datenkollektiv.de/banner.txt/index.html
    echo.
    echo [0m
    echo ╔═════════════════════════════════════════════════════════════════════════════════════════╗
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
    echo.
    echo [101;93m VALIDATE OUTPUT FOLDER... [0m
    ::	Search for a folder with the same name as the expected output, if found go to FOLDER ERROR WARNING
    IF EXIST "%~dp1\%~n1-png" goto:errorfolder

:MAKEFOLDER
    ::	CREATE A FOLDER TO PLACE THE OUTPUT IMAGES
    echo [0m Output folder non present, will create now [0m
    md "%~dp1\%~n1-png%fldsfx%"
	set "fldsfx="

    echo [0m Output folder [30;42m READY [0m
    echo.
    echo [101;93m COUNTING FRAMES... [0m
    
    setlocal enabledelayedexpansion
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
    ::  ACTUAL ENCODING
	echo.
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

    endlocal
	    shift
	    goto:next

:errorfolder
	
	cls
	echo.
	echo  [93m╔══════════════════╗
	echo  [93m║====ATTENTION!====║
	echo  [93m╚══════════════════╝
	echo.
	echo  [93mA folder with the same name as
	echo  [93mthe requested output already exists.
	echo.
	echo [0mWhat shall we do?[0m
	echo [33m[1][0m. Replace its content (WARNING: THE DELETION IS IMMEDIATE AND PERMANENT)
	echo [33m[2][0m. Create a new folder with "(2)" suffix
	echo [33m[3][0m. Stop the encode
	echo [33m[4][0m. Pause the script and let me check (will be activated by default in 10s)
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
	echo.
	echo  [93m╔══════════════════╗
	echo  [93m║====ATTENTION!====║
	echo  [93m╚══════════════════╝
	echo.
	echo  [93mI have detected your indecision
	echo  [93mthe script has been paused while you sort it out![0m
	echo.
	echo.
	pause
	goto:errorfolder

:STOPENCODE
	goto:done

:FOLDERSUFFIX
	set "fldsfx=(2)"
	goto:MAKEFOLDER

:REPLACEFOLDER
	setlocal EnableDelayedExpansion
	echo Now I'm going to delete:
	RMDIR /S "%~dp1\%~n1-png"
	endlocal
	goto:MAKEFOLDER

:error
	
	echo.
	echo  [93m╔══════════════════╗
	echo  [93m║====ATTENTION!====║
	echo  [93m╚══════════════════╝
	echo.
	echo  [93mThere has been an error
	echo  [93mI was unable to identify.
	echo.
	echo  [93mCheck the output folder before trying again![0m
	echo.
	pause

:done
timeout /t 10
exit
