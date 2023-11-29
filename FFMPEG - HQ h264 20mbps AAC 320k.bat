::	This scpript will encode input videos into .mp4s with libx264 at 20mbps with 320kbps AAC audio
::
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-11-29 Version 0.4
::		- Added VALIDATE_AUDIO subroutine to check audio for compatibility with .mp4 container
::		- Minor formatting
::	2023-11-20 Version 0.3
::		- Added VALIDATE_OUTPUT subroutine
::		- Extended timeout for :ERROR_CHOICE from 10s to 30s
::	2023-11-16 Version 0.2.1
::		Corrected behavior when shifting to next file
::	2023-11-10 Version 0.2
::		Minor formatting	
::		Updated script description and license disclaimer
::		Added changelog
::	-----------------------------------------------------------------------------------------------
::if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
@echo off
chcp 65001
cls

:again
	title FFMPEG - Converting "%~1" to 20mbps h264 video with 320kbps AAC audio

    :: Check if output file already exists
	set count=2
	set OUTPUT_DIR=%~dp1
	set OUTPUT_NAME=%~n1
	set OUTPUT_ENC=-h264-20mbps
	set OUTPUT_SFX=
	set OUTPUT_EXT=.mp4
	
	:VALIDATE_OUTPUT
		echo.
		set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_ENC%%OUTPUT_EXT%"
		echo [101;93m VALIDATING OUTPUT... [0m
			IF EXIST %OUTPUT_FILE% (
				echo Output [30;41m UNAVAILABLE [0m && goto:errorfile
			) ELSE ( 
				echo Output [30;42m AVAILABLE [0m && goto:VALIDATE_AUDIO
			)

	:VALIDATE_AUDIO
		::	Get codec name
        setlocal EnableDelayedExpansion
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"

		if /i "%codec:~11%"=="wma" (
    		echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to aac && set codec_audio=aac -b:a 320
		) else (
		    echo Audio codec [30;42m %codec:~11% [0m is compatible, audio will be copied && set codec_audio=copy
		)
	goto:encode

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
		echo.
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
    	    -c:v libx264 -x264opts opencl ^
    	    -crf 18 -maxrate 20M -bufsize 40M ^
    	    -preset slow ^
    	    -tune film ^
    	    -profile:v high ^
		    -level 4.1 ^
			-pix_fmt yuv420p ^
			-c:a %codec_audio% ^
    	    -map_metadata 0 ^
			-movflags use_metadata_tags ^
    	    -movflags +faststart ^
			"%~dp1%~n1-h264-20mbps%OUTPUT_SFX%.mp4"
	
	set OUTPUT_SFX=""

    if NOT ["%errorlevel%"]==["0"] goto:error
	
	echo [92m%~n1 Done![0m
	shift
	if "%~1" == "" goto:done
	timeout /t 3 > nul
	goto:next
::	DUAL PASS (DEPRECATED)
	::	ffmpeg ^
	::		-hwaccel auto ^
	::		-i "%~1" ^
	::		-map 0 ^
	::		-c:v libx264 ^
    ::		-x264opts opencl ^
    ::		-preset slow ^
    ::		-tune film ^
    ::		-profile:v high ^
	::		-b:v 20M ^
	::		-maxrate 25M ^
	::		-bufsize 50M ^
	::		-pix_fmt yuv420p ^
	::		-c:a aac ^
    ::		-b:a 320k ^
    ::		-map_metadata 0 ^
	::		-movflags use_metadata_tags ^
    ::		-movflags +faststart ^
	::		-pass 1 -f mp4 ^
    ::		NUL
	::
    ::	ffmpeg ^
    ::		-hwaccel auto ^
	::		-i "%~1" ^
	::		-map 0 ^
    ::		-c:v libx264 ^
    ::		-x264opts opencl ^
    ::		-preset slow ^
    ::		-tune film ^
    ::		-profile:v high ^
	::		-b:v 20M ^
	::		-maxrate 25M ^
	::		-bufsize 50M ^
	::		-pix_fmt yuv420p ^
	::		-c:a aac ^
    ::		-b:a 320k ^
    ::		-map_metadata 0 ^
	::		-movflags use_metadata_tags ^
    ::		-movflags +faststart ^
	::		-pass 2 ^
    ::		"%~dp1%~n1_20mps_h264_256k_aac.mp4"
	::
	::		goto:end

:error
	
	echo [93mThere was an error. Please check your input file.[0m
	pause
	exit 0

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

:abort
	
	echo [93mProcess aborted.[0m
	cls
	echo [93mThis window will close after 5 seconds.[0m
	timeout /t 1 > nul
	cls
	echo [93mThis window will close after 4 seconds.[0m
	timeout /t 1 > nul
	cls
	echo [93mThis window will close after 3 seconds.[0m
	timeout /t 1 > nul
	cls
	echo [93mThis window will close after 2 seconds.[0m
	timeout /t 1 > nul
	cls
	echo [93mThis window will close after 1 seconds.[0m
	timeout /t 1 > nul
	exit 0