::	if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
::
::	This scpript will encode inputs to .mp4s with libx264 dual pass at 5mbps with 256kbps AAC audio
::
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-11-10 Version 0.2
::		Minor formatting	
::		Updated script description and license disclaimer
::		Added changelog
::	-----------------------------------------------------------------------------------------------
@echo off
chcp 65001
cls

:next
	title FFMPEG - Converting "%~1" to 5mbps h264 video with 256kbps AAC audio

    :: Check if output file already exists
	    if exist "%~1_5mps_h264_256k_aac.mp4" goto:errorfile
	    if "%~1" == "" goto:done

    ::	Let's go!
	    echo.
	    echo [92m╔══════════════════════════════════════════════════════╗
	    echo [92m║============== CONVERSION IN PROGRESS ================║
	    echo [92m╚══════════════════════════════════════════════════════╝[0m
		color 0E
		echo.
		echo.
		echo.
		echo [101;93m ENCODING PASS 1... [0m
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
			-b:v 4M ^
			-maxrate 5M ^
			-bufsize 10M ^
			-pix_fmt yuv420p ^
			-c:a aac ^
            -b:a 256k ^
            -map_metadata 0 ^
			-movflags use_metadata_tags ^
            -movflags +faststart ^
			-pass 1 -f mp4 ^
            NUL

		cls
	    echo.
	    echo [92m╔══════════════════════════════════════════════════════╗
	    echo [92m║============== CONVERSION IN PROGRESS ================║
	    echo [92m╚══════════════════════════════════════════════════════╝[0m
		color 0E
		echo.
		echo.
		echo.
		echo [101;93m ENCODING PASS 2... [0m
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
			-b:v 4M ^
			-maxrate 5M ^
			-bufsize 10M ^
			-pix_fmt yuv420p ^
			-c:a aac ^
            -b:a 256k ^
            -map_metadata 0 ^
			-movflags use_metadata_tags ^
            -movflags +faststart ^
			-pass 2 ^
            "%~dp1%~n1_5mps_h264_256k_aac.mp4"

			goto:end

:errorfile
	
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
	pause
	goto:end

:error
	
	echo [93mThere was an error. Please check your input file.[0m
	pause
	exit 0

:end
    if NOT ["%errorlevel%"]==["0"] goto:error
	echo [92m%~n1 Done![0m
	title FFMPEG - We did it!

	if "%~1" == "" goto:done
	
	timeout /t 3
	
	shift
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
