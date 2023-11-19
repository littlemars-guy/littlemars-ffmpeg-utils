if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
::
::	This script will encode inputs to .mp4s h264 5mbps with 256kbps AAC audio
::
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-11-20 Version 0.4
::		- Added VALIDATE_OUTPUT subroutine
::		- Extended timeout for :ERROR_CHOICE from 10s to 30s
::	2023-11-16 Version 0.3.2
::		- Corrected behavior when shifting to next file
::	2023-11-16 Version 0.3.1
::		- Partial banner update: added license disclaimer and info section
::	2023-11-14 Version 0.3
::		- Changed encoding approach from 2-pass to crf28 + maxrate 5M, should be faster
::	2023-11-10 Version 0.2
::		- Minor formatting	
::		- Updated script description and license disclaimer
::		- Added changelog
::	-----------------------------------------------------------------------------------------------
::@echo off
chcp 65001
cls

:next
	title FFMPEG - Converting "%~1" to 5mbps h264 video with 256kbps AAC audio

    :: Check if output file already exists
	set count=2
	set OUTPUT_DIR=%~dp1
	set OUTPUT_NAME=%~n1
	set OUTPUT_ENC=_5mps_h264_256k_aac
	set OUTPUT_SFX=
	set OUTPUT_EXT=.mp4
	
	:VALIDATE_OUTPUT
		echo.
		set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_ENC%%OUTPUT_EXT%"
		echo [101;93m VALIDATING OUTPUT... [0m
			IF EXIST %OUTPUT_FILE% (
				echo Output [30;41m UNAVAILABLE [0m && goto:errorfile
			) ELSE ( 
				echo Output [30;42m AVAILABLE [0m && goto:encode
			)
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
		echo [33m[2][0m. Rename output %OUTPUT_NAME%%OUTPUT_ENC%[30;43m-(%count%)[0m.%OUTPUT_EXT%[0m
		echo [33m[3][0m. Abort the operation (will be auto-selected in 30s)
		echo.
	
		CHOICE /C 123 /T 30 /D 3 /M "Enter your choice:"
		:: Note - list ERRORLEVELS in decreasing order
		IF ERRORLEVEL 3 goto :abort
		IF ERRORLEVEL 2 goto :encode
		IF ERRORLEVEL 1 EXIT /B

	:encode
	    echo.
	    echo [92m╔══════════════════════════════════════════════════════╗
	    echo [92m║============== CONVERSION IN PROGRESS ================║
	    echo [92m╚══════════════════════════════════════════════════════╝[0m
		echo.
 		echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
		echo.
		echo INFO: This script will encode inputs to .mp4s h264 5mbps with 256kbps AAC audio
		echo.
		echo [101;93m ENCODING... [0m
		echo.
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-stats ^
            -hwaccel auto ^
			-i "%~1" ^
			-map 0 ^
            -c:v libx264 ^
            -x264opts opencl ^
            -preset slow ^
            -tune fastdecode ^
            -profile:v high ^
			-crf 28 ^
			-maxrate 5M ^
			-bufsize 10M ^
			-pix_fmt yuv420p ^
			-c:a aac ^
            -b:a 256k ^
            -map_metadata 0 ^
			-movflags use_metadata_tags ^
            -movflags +faststart ^
            "%~dp1%~n1_5mps_h264_256k_aac%OUTPUT_SFX%.mp4"
	
    if NOT ["%errorlevel%"]==["0"] goto:error
	
	echo [92m%~n1 Done![0m
	shift
	if "%~1" == "" goto:done
	timeout /t 3 > nul
	goto:next

:error
	
	echo [93mThere was an error. Please check your input file.[0m
	pause
	exit 0

:end
    if NOT ["%errorlevel%"]==["0"] goto:error
	echo [92m%~n1 Done![0m
	title FFMPEG - We did it!
	shift
	if "%~1" == "" goto:done
	timeout /t 3 > nul
	goto:next

:done
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
