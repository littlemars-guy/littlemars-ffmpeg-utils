::What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
::Extract audio only and convert to flac
@echo off
chcp 65001
cls

:again
	title FFMPEG - Converting "%~1" to 20mbps h264 video with 320kbps AAC audio

    :: Check if output file already exists
	    if exist "%~1_5mps_h264_256k_aac.mp4" goto:errorfile
	    if "%~1" == "" goto:done

    ::	Let's go!
	    echo.
	    echo [92m╔══════════════════════════════════════════════════════╗
	    echo [92m║========== REVVING UP FOR h264 COMPRESSION ===========║
	    echo [92m╚══════════════════════════════════════════════════════╝[0m
	    echo.
        echo [101;93m ENCODING... [0m
		echo. && echo.

		ffmpeg ^
            -hwaccel auto ^
			-i "%~1" ^
			-map 0 ^
            -c:v libx264 ^
            -x264opts opencl ^
            -preset slow ^
            -tune film ^
            -profile:v high ^
			-b:v 20M ^
			-maxrate 25M ^
			-bufsize 50M ^
			-pix_fmt yuv420p ^
			-c:a aac ^
            -b:a 320k ^
            -map_metadata 0 ^
			-movflags use_metadata_tags ^
            -movflags +faststart ^
			-pass 1 -f mp4 ^
            NUL

        ffmpeg ^
            -hwaccel auto ^
			-i "%~1" ^
			-map 0 ^
            -c:v libx264 ^
            -x264opts opencl ^
            -preset slow ^
            -tune film ^
            -profile:v high ^
			-b:v 20M ^
			-maxrate 25M ^
			-bufsize 50M ^
			-pix_fmt yuv420p ^
			-c:a aac ^
            -b:a 320k ^
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

