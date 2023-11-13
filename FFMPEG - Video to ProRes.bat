::	This script will convert its input to a ProRes encoded .mov file.
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
	title FFMPEG - Converting %~nx1 to ProRes
	:: Check if output file already exists
	if exist "%~1.mov" goto:errorfile
	if "%~1" == "" goto:done
	::	Let's go!
	echo.
	echo [92m╔══════════════════════════════════════════════════════╗
	echo [92m║========== CONVERTING THE PRORES OUT OF IT! ==========║
	echo [92m╚══════════════════════════════════════════════════════╝[0m
	echo.
	echo [101;93m ENCODER SELECTION [0m

:ENCODER
	echo [1mSelect the desired ProRes flavour:[0m
	echo [33m[1][0m. Proxy
	echo [33m[2][0m. 422 Standard
	echo [33m[3][0m. 422 HQ
	echo [33m[4][0m. 4444
	echo [33m[5][0m. 4444 XQ
	echo.
	
	CHOICE /C 12345 /M "Enter your choice:"
	:: Note - list ERRORLEVELS in decreasing order
	IF ERRORLEVEL 5 GOTO:PR4444XQ
	IF ERRORLEVEL 4 GOTO:PR4444
	IF ERRORLEVEL 3 GOTO:PR422HQ
	IF ERRORLEVEL 2 GOTO:PRStandard
	IF ERRORLEVEL 1 GOTO:PRProxy

	:PRProxy
		echo [101;93m ENCODING... [0m
		echo. && echo.

		::	Get codec name
        setlocal EnableDelayedExpansion
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"
        
		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s16le" && goto:encode_proxy
		set codec=copy
		goto:encode_proxy

		::	Get bits per sample
		:bits_per_sample
		for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "bits=%%I"

		:encode_proxy
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-stats ^
			-i "%~1" ^
			-c:v prores_ks ^
			-profile:v 0 ^
			-vendor apl0 ^
			-bits_per_mb 8000 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProResProxy.mov"
			GOTO:ENDOFPRORES

	:PRStandard
		
		echo [101;93m ENCODING... [0m
		echo. && echo.

		::	Get codec name
        setlocal EnableDelayedExpansion
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"
        
		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s16le" && goto:encode_422
		set codec=copy
		goto:encode_422

		::	Get bits per sample
		:bits_per_sample
		for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "bits=%%I"
        
		:encode_422
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-stats ^
			-i "%~1" ^
			-c:v prores_ks ^
			-profile:v 2 ^
			-vendor apl0 ^
			-bits_per_mb 8000 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProRes422.mov"
			GOTO:ENDOFPRORES
				
	:PR422HQ
		
		echo [101;93m ENCODING... [0m
		echo. && echo.

		::	Get codec name
        setlocal EnableDelayedExpansion
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"
        
		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s16le" && goto:encode_422HQ
		set codec=copy
		goto:encode_422HQ

		::	Get bits per sample
		:bits_per_sample
		for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "bits=%%I"
        
		:encode_422HQ
		ffmpeg ^
			-i "%~1" ^
			-c:v prores_ks ^
			-profile:v 3 ^
			-vendor apl0 ^
			-bits_per_mb 8000 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProRes422HQ.mov"
			GOTO:ENDOFPRORES
				
	:PR4444
		
		echo [101;93m ENCODING... [0m
		echo. && echo.

		::	Get codec name
        setlocal EnableDelayedExpansion
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"
        
		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s16le" && goto:encode_4444
		set codec=copy
		goto:encode_4444

		::	Get bits per sample
		:bits_per_sample
		for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "bits=%%I"
        
		:encode_4444
		ffmpeg ^
			-i "%~1" ^
			-c:v prores_ks ^
			-profile:v 4 ^
			-vendor apl0 ^
			-bits_per_mb 8000 ^
			-pix_fmt yuva444p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProRes4444.mov"
			GOTO:ENDOFPRORES
				
	:PR4444XQ
		
		echo [101;93m ENCODING... [0m
		echo. && echo.

		::	Get codec name
        setlocal EnableDelayedExpansion
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"
        
		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s16le" && goto:encode_4444XQ
		set codec=copy
		goto:encode_4444XQ

		::	Get bits per sample
		:bits_per_sample
		for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "bits=%%I"
        
		:encode_4444XQ
		ffmpeg ^
			-i "%~1" ^
			-c:v prores_ks ^
			-profile:v 5 ^
			-vendor apl0 ^
			-bits_per_mb 8000 ^
			-pix_fmt yuva444p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProRes4444XQ.mov"
			GOTO:ENDOFPRORES

	:ENDOFPRORES
	if NOT ["%errorlevel%"]==["0"] goto:error
	echo [92m%~n1 Done![0m
	title FFMPEG - We did it!

	if "%~1" == "" goto:done
	
	timeout /t 3
	
	shift
	goto:next


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
	goto:done
:error
	
	echo [93mThere was an error. Please check your input file.[0m
	pause
	exit 0

:done
timeout /t 10
exit