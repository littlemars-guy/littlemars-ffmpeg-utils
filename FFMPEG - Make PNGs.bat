:: this script will extract the frames of selected videos to an image sequence
@echo off
chcp 65001
cls

:next
	title FFMPEG - Making PNGs from %~1
	::SEARCH FOR A FOLDER WITH THE SAME NAME AS THE EXPECTED OUTPUT, IF FOUND GO TO FOLDER ERROR WARNING
    IF EXIST "%~dp1\%~n1-png" goto:errorfolder
	::IF NO MORE FILES ARE LEFT IN THE QUEUE GO TO DONE WARNING
    if "%~1" == "" goto:done

::CREATE A FOLDER TO PLACE THE OUTPUT IMAGES
:MAKEFOLDER
    md "%~dp1\%~n1-png%fldsfx%"
	set "fldsfx="
    goto:ENCODE

setlocal EnableDelayedExpansion

:ENCODE
	::FFPROBE - obtain number of frames contained in video
	cls
	echo Counting frames...

    for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams v:0 -count_frames -show_entries stream^=nb_read_frames -print_format default^=nokey^=1:noprint_wrappers^=1 "%~1"') do set "framecount=%%I"

	::SIMPLE MATH - get number of digits in frame number value and store in %Len variable
	set /a Log=1%framecount:~1%-%framecount:~1% -0
	set /a Len=%Log:0=+1%

	::ACTUAL ENCODING
	echo Encoding...
	
    ffmpeg ^
		-hwaccel auto ^
		-y -i "%~1" ^
		-f image2 ^
		-vcodec png ^
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
	echo [33m[2][0m. Create a new folder with "-new" suffix
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
	set "fldsfx=-new"
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