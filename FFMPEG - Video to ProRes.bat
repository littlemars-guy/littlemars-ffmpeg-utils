::	This script will convert its input to a ProRes encoded .mov file.
::	
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---ADDITIONAL INFO-----------------------------------------------------------------------------
::  Fancy font is "roman" from https://devops.datenkollektiv.de/banner.txt/index.html
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-11-18 Version 0.4.1
::		- Minor tweaks
::	2023-11-18 Version 0.4
::		- Added ProRes LT encoding routine
::		- Added VALIDATE_OUTPUT routine to check for presence of files with the same name of output
::		- General formatting to provide better clarity both in reading the code and running the script
::	2023-11-16 Version 0.3.1
::		- Added "-map 0" after input to select all tracks
::	2023-11-15 Version 0.3
::		- Corrected bug: in loop function, when shifting to next file, the check would happen
::		before shifting causing an error with ffmpeg trying to convert a file that didn't exist
::		- Introduced "-qscale:v (integer)" option to prevent overload of "-bits_per_mb (integer)"
::	2023-11-14 Version 0.2.5
::		- Reworked loop behavior when encoding multiple files
::		- Updated banners
::	2023-11-14 Version 0.2.1
::		- Partial banner update
::	2023-11-11 Version 0.2
::		- Minor formatting
::		- Updated script description and license disclaimer
::		- Added changelog
::	-----------------------------------------------------------------------------------------------
@echo off
chcp 65001
cls

:next
	title FFMPEG - Converting %~nx1 to ProRes
	echo ╔═══════════════════════════════════════════════════════════════════╗
	echo ║  ooooooooo.                      ooooooooo.                       ║ 
	echo ║  `888   `Y88.                    `888   `Y88.                     ║ 
	echo ║   888   .d88' oooo d8b  .ooooo.   888   .d88'  .ooooo.   .oooo.o  ║ 
	echo ║   888ooo88P'  `888""8P d88' `88b  888ooo88P'  d88' `88b d88(  "8  ║ 
	echo ║   888          888     888   888  888`88b.    888ooo888 `"Y88b.   ║ 
	echo ║   888          888     888   888  888  `88b.  888    .o o.  )88b  ║ 
	echo ║  o888o        d888b    `Y8bod8P' o888o  o888o `Y8bod8P' 8""888P'  ║
	echo ╚═══════════════════════════════════════════════════════════════════╝
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo NOTE:  this script can encode ProRes only up to 10bit precision, if you need
	echo        12bits you should use another encoder.
	echo.
	echo [101;93m ENCODER SELECTION [0m

:ENCODER
	echo [1mSelect the desired ProRes flavour:[0m
	echo [33m[1][0m. Proxy
	echo [33m[2][0m. LT
	echo [33m[3][0m. 422 Standard
	echo [33m[4][0m. 422 HQ
	echo [33m[5][0m. 4444
	echo [33m[6][0m. 4444 XQ
	echo.
	
	CHOICE /C 12345 /M "Enter your choice:"
	:: Note - list ERRORLEVELS in decreasing order
	IF ERRORLEVEL 6 set choice="PR4444XQ" && GOTO:PR4444XQ
	IF ERRORLEVEL 5 set choice="PR4444" && GOTO:PR4444
	IF ERRORLEVEL 4 set choice="PR422HQ" && GOTO:PR422HQ
	IF ERRORLEVEL 3 set choice="PRStandard" && GOTO:PRStandard
	IF ERRORLEVEL 2 set choice="PRlt" && GOTO:PRlt
	IF ERRORLEVEL 1 set choice="PRProxy" && GOTO:PRProxy

	:PRProxy
		cls
		echo ╔═══════════════════════════════════════════════════════════════════════╗
		echo ║  ooooooooo.                      ooooooooo.                           ║ 
		echo ║  `888   `Y88.                    `888   `Y88.                         ║ 
		echo ║   888   .d88' oooo d8b  .ooooo.   888   .d88'  .ooooo.   .oooo.o      ║ 
		echo ║   888ooo88P'  `888""8P d88' `88b  888ooo88P'  d88' `88b d88(  "8      ║ 
		echo ║   888          888     888   888  888`88b.    888ooo888 `"Y88b.       ║ 
		echo ║   888          888     888   888  888  `88b.  888    .o o.  )88b      ║ 
		echo ║  o888o        d888b    `Y8bod8P' o888o  o888o `Y8bod8P' 8""888P'      ║
		echo ║                                                                       ║
		echo ║  ooooooooo.   ooooooooo.     .oooooo.   ooooooo  ooooo oooooo   oooo  ║  
		echo ║  `888   `Y88. `888   `Y88.  d8P'  `Y8b   `8888    d8'   `888.   .8'   ║  
		echo ║   888   .d88'  888   .d88' 888      888    Y888..8P      `888. .8'    ║  
		echo ║   888ooo88P'   888ooo88P'  888      888     `8888'        `888.8'     ║  
		echo ║   888          888`88b.    888      888    .8PY888.        `888'      ║  
		echo ║   888          888  `88b.  `88b    d88'   d8'  `888b        888       ║  
		echo ║  o888o        o888o  o888o  `Y8bood8P'  o888o  o88888o     o888o      ║  
		echo ╚═══════════════════════════════════════════════════════════════════════╝
		echo.
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_ENC=_ProResProxy
		CALL :VALIDATE_OUTPUT
		echo.
		echo [101;93m ENCODING... [0m
		echo Input: %~1
		echo Output: %OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_ENC%%OUTPUT_SFX%.mov
		echo.

		::	Get codec name
        setlocal EnableDelayedExpansion
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"

		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s16le" && goto:encode_proxy
		set codec_audio=copy
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
			-map 0 ^
			-c:v prores_ks ^
			-profile:v 0 ^
			-quant_mat proxy ^
			-vendor apl0 ^
			-qscale:v 13 ^
			-bits_per_mb 250 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProResProxy%OUTPUT_SFX%.mov"
			if NOT ["%errorlevel%"]==["0"] goto:error
			
			set OUTPUT_SFX=""
			timeout /t 2 > nul
			shift
			if "%~1" == "" goto:done
			goto:PRProxy

	:PRlt
		cls
		echo ╔═══════════════════════════════════════════════════════════════════╗
		echo ║  ooooooooo.                      ooooooooo.                       ║ 
		echo ║  `888   `Y88.                    `888   `Y88.                     ║ 
		echo ║   888   .d88' oooo d8b  .ooooo.   888   .d88'  .ooooo.   .oooo.o  ║ 
		echo ║   888ooo88P'  `888""8P d88' `88b  888ooo88P'  d88' `88b d88(  "8  ║ 
		echo ║   888          888     888   888  888`88b.    888ooo888 `"Y88b.   ║ 
		echo ║   888          888     888   888  888  `88b.  888    .o o.  )88b  ║ 
		echo ║  o888o        d888b    `Y8bod8P' o888o  o888o `Y8bod8P' 8""888P'  ║
		echo ║                                                                   ║
		echo ║  ooooo        ooooooooooooo                                       ║
		echo ║  `888'        8'   888   `8                                       ║ 
		echo ║   888              888                                            ║ 
		echo ║   888              888                                            ║ 
		echo ║   888              888                                            ║ 
		echo ║   888       o      888                                            ║ 
		echo ║  o888ooooood8     o888o                                           ║
		echo ╚═══════════════════════════════════════════════════════════════════╝
		echo.
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_ENC=_ProResLT
		CALL :VALIDATE_OUTPUT
		echo.
		echo [101;93m ENCODING... [0m
		echo Input: %~1
		echo Output: %OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_ENC%%OUTPUT_SFX%.mov
		echo.

		::	Get codec name
        setlocal EnableDelayedExpansion
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"

		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s16le" && goto:encode_proxy
		set codec_audio=copy
		goto:encode_lt

		::	Get bits per sample
		:bits_per_sample
		for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "bits=%%I"

		:encode_lt
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-stats ^
			-i "%~1" ^
			-map 0 ^
			-c:v prores_ks ^
			-profile:v 1 ^
			-quant_mat lt ^
			-vendor apl0 ^
			-qscale:v 11 ^
			-bits_per_mb 525 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProResLT%OUTPUT_SFX%.mov"
			if NOT ["%errorlevel%"]==["0"] goto:error
			
			set OUTPUT_SFX=""
			timeout /t 2 > nul
			shift
			if "%~1" == "" goto:done
			goto:PRlt

	:PRStandard
		cls
		echo ╔═══════════════════════════════════════════════════════════════════╗
		echo ║  ooooooooo.                      ooooooooo.                       ║ 
		echo ║  `888   `Y88.                    `888   `Y88.                     ║ 
		echo ║   888   .d88' oooo d8b  .ooooo.   888   .d88'  .ooooo.   .oooo.o  ║ 
		echo ║   888ooo88P'  `888""8P d88' `88b  888ooo88P'  d88' `88b d88(  "8  ║ 
		echo ║   888          888     888   888  888`88b.    888ooo888 `"Y88b.   ║ 
		echo ║   888          888     888   888  888  `88b.  888    .o o.  )88b  ║ 
		echo ║  o888o        d888b    `Y8bod8P' o888o  o888o `Y8bod8P' 8""888P'  ║
		echo ║                                                                   ║
		echo ║        .o     .oooo.     .oooo.                                   ║
		echo ║      .d88   .dP""Y88b  .dP""Y88b                                  ║
		echo ║    .d'888         ]8P'       ]8P'                                 ║
		echo ║  .d'  888       .d8P'      .d8P'                                  ║
		echo ║  88ooo888oo   .dP'       .dP'                                     ║
		echo ║       888   .oP     .o .oP     .o                                 ║
		echo ║      o888o  8888888888 8888888888                                 ║
		echo ╚═══════════════════════════════════════════════════════════════════╝
		echo.
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_ENC=_ProRes422
		CALL :VALIDATE_OUTPUT
		echo.
		echo [101;93m ENCODING... [0m
		echo Input: %~1
		echo Output: %OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_ENC%%OUTPUT_SFX%.mov
		echo.

		::	Get codec name
        setlocal EnableDelayedExpansion
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"
        
		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s16le" && goto:encode_422
		set codec_audio=copy
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
			-map 0 ^
			-c:v prores_ks ^
			-profile:v 2 ^
			-qscale:v 8 ^
			-quant_mat auto ^
			-vendor apl0 ^
			-bits_per_mb 875 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProRes422%OUTPUT_SFX%.mov"
			if NOT ["%errorlevel%"]==["0"] goto:error
			
			set OUTPUT_SFX=""
			timeout /t 2 > nul
			shift
			if "%~1" == "" goto:done
			goto:PRStandard
				
	:PR422HQ
		cls
		echo ╔════════════════════════════════════════════════════════════════════╗
		echo ║  ooooooooo.                      ooooooooo.                        ║ 
		echo ║  `888   `Y88.                    `888   `Y88.                      ║ 
		echo ║   888   .d88' oooo d8b  .ooooo.   888   .d88'  .ooooo.   .oooo.o   ║ 
		echo ║   888ooo88P'  `888""8P d88' `88b  888ooo88P'  d88' `88b d88(  "8   ║ 
		echo ║   888          888     888   888  888`88b.    888ooo888 `"Y88b.    ║ 
		echo ║   888          888     888   888  888  `88b.  888    .o o.  )88b   ║ 
		echo ║  o888o        d888b    `Y8bod8P' o888o  o888o `Y8bod8P' 8""888P'   ║
		echo ║                                                                    ║
		echo ║        .o     .oooo.     .oooo.      ooooo   ooooo   .oooooo.      ║
		echo ║      .d88   .dP""Y88b  .dP""Y88b     `888'   `888'  d8P'  `Y8b     ║
		echo ║    .d'888         ]8P'       ]8P'     888     888  888      888    ║
		echo ║  .d'  888       .d8P'      .d8P'      888ooooo888  888      888    ║
		echo ║  88ooo888oo   .dP'       .dP'         888     888  888      888    ║
		echo ║       888   .oP     .o .oP     .o     888     888  `88b    d88b    ║
		echo ║      o888o  8888888888 8888888888    o888o   o888o  `Y8bood8P'Ybd' ║
		echo ╚════════════════════════════════════════════════════════════════════╝
		echo.
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_ENC=_ProRes422HQ
		CALL :VALIDATE_OUTPUT
		echo.
		echo [101;93m ENCODING... [0m
		echo Input: %~1
		echo Output: %OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_ENC%%OUTPUT_SFX%.mov
		echo.

		::	Get codec name
        setlocal EnableDelayedExpansion
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"
        
		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s16le" && goto:encode_422HQ
		set codec_audio=copy
		goto:encode_422HQ

		::	Get bits per sample
		:bits_per_sample
		for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "bits=%%I"
        
		:encode_422HQ
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-stats ^
			-i "%~1" ^
			-map 0 ^
			-c:v prores_ks ^
			-profile:v 3 ^
			-qscale:v 4 ^
			-quant_mat auto ^
			-vendor apl0 ^
			-bits_per_mb 1350 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProRes422HQ%OUTPUT_SFX%.mov"
			if NOT ["%errorlevel%"]==["0"] goto:error
			
			set OUTPUT_SFX=""
			timeout /t 2 > nul
			shift
			if "%~1" == "" goto:done
			goto:PR422HQ
				
	:PR4444
		cls
		echo ╔═══════════════════════════════════════════════════════════════════╗
		echo ║  ooooooooo.                      ooooooooo.                       ║ 
		echo ║  `888   `Y88.                    `888   `Y88.                     ║ 
		echo ║   888   .d88' oooo d8b  .ooooo.   888   .d88'  .ooooo.   .oooo.o  ║ 
		echo ║   888ooo88P'  `888""8P d88' `88b  888ooo88P'  d88' `88b d88(  "8  ║ 
		echo ║   888          888     888   888  888`88b.    888ooo888 `"Y88b.   ║ 
		echo ║   888          888     888   888  888  `88b.  888    .o o.  )88b  ║ 
		echo ║  o888o        d888b    `Y8bod8P' o888o  o888o `Y8bod8P' 8""888P'  ║
		echo ║                                                                   ║
		echo ║        .o         .o         .o         .o                        ║
		echo ║      .d88       .d88       .d88       .d88                        ║
		echo ║    .d'888     .d'888     .d'888     .d'888                        ║
		echo ║  .d'  888   .d'  888   .d'  888   .d'  888                        ║
		echo ║  88ooo888oo 88ooo888oo 88ooo888oo 88ooo888oo                      ║
		echo ║       888        888        888        888                        ║
		echo ║      o888o      o888o      o888o      o888o                       ║
		echo ╚═══════════════════════════════════════════════════════════════════╝
		echo.
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_ENC=_ProRes4444
		CALL :VALIDATE_OUTPUT
		echo.
		echo [101;93m ENCODING... [0m
		echo Input: %~1
		echo Output: %OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_ENC%%OUTPUT_SFX%.mov
		echo.

		::	Get codec name
        setlocal EnableDelayedExpansion
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"
        
		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s16le" && goto:encode_4444
		set codec_audio=copy
		goto:encode_4444

		::	Get bits per sample
		:bits_per_sample
		for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "bits=%%I"
        
		:encode_4444
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-stats ^
			-i "%~1" ^
			-map 0 ^
			-c:v prores_ks ^
			-profile:v 4 ^
			-quant_mat auto ^
			-vendor apl0 ^
			-bits_per_mb 8000 ^
			-pix_fmt yuva444p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProRes4444%OUTPUT_SFX%.mov"
			if NOT ["%errorlevel%"]==["0"] goto:error
			
			set OUTPUT_SFX=""
			timeout /t 2 > nul
			shift
			if "%~1" == "" goto:done
			goto:PR4444
				
	:PR4444XQ
		cls
		echo ╔════════════════════════════════════════════════════════════════════════════════╗
		echo ║  ooooooooo.                      ooooooooo.                                    ║ 
		echo ║  `888   `Y88.                    `888   `Y88.                                  ║ 
		echo ║   888   .d88' oooo d8b  .ooooo.   888   .d88'  .ooooo.   .oooo.o               ║ 
		echo ║   888ooo88P'  `888""8P d88' `88b  888ooo88P'  d88' `88b d88(  "8               ║ 
		echo ║   888          888     888   888  888`88b.    888ooo888 `"Y88b.                ║ 
		echo ║   888          888     888   888  888  `88b.  888    .o o.  )88b               ║ 
		echo ║  o888o        d888b    `Y8bod8P' o888o  o888o `Y8bod8P' 8""888P'               ║
		echo ║                                                                                ║
		echo ║        .o         .o         .o         .o      ooooooo  ooooo   .oooooo.      ║
		echo ║      .d88       .d88       .d88       .d88       `8888    d8'   d8P'  `Y8b     ║
		echo ║    .d'888     .d'888     .d'888     .d'888         Y888..8P    888      888    ║
		echo ║  .d'  888   .d'  888   .d'  888   .d'  888          `8888'     888      888    ║
		echo ║  88ooo888oo 88ooo888oo 88ooo888oo 88ooo888oo       .8PY888.    888      888    ║
		echo ║       888        888        888        888        d8'  `888b   `88b    d88b    ║
		echo ║      o888o      o888o      o888o      o888o     o888o  o88888o  `Y8bood8P'Ybd' ║
		echo ╚════════════════════════════════════════════════════════════════════════════════╝
		echo.
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_ENC=_ProRes4444XQ
		CALL :VALIDATE_OUTPUT
		echo.
		echo [101;93m ENCODING... [0m
		echo Input: %~1
		echo Output: %OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_ENC%%OUTPUT_SFX%.mov
		echo.

		::	Get codec name
        setlocal EnableDelayedExpansion
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"
        
		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s16le" && goto:encode_4444XQ
		set codec_audio=copy
		goto:encode_4444XQ

		::	Get bits per sample
		:bits_per_sample
		for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "bits=%%I"
        
		:encode_4444XQ
		ffmpeg ^
			-hide_banner ^
			-loglevel warning ^
			-stats ^
			-i "%~1" ^
			-map 0 ^
			-c:v prores_ks ^
			-profile:v 5 ^
			-quant_mat auto ^
			-vendor apl0 ^
			-bits_per_mb 8000 ^
			-pix_fmt yuva444p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProRes4444XQ%OUTPUT_SFX%.mov"

			if NOT ["%errorlevel%"]==["0"] goto:error
			
			set OUTPUT_SFX=""
			timeout /t 2 > nul
			shift
			if "%~1" == "" goto:done
			goto:PR4444XQ



:error
	
	echo [93mThere was an error. Please check your input file.[0m
	pause
	exit 0

:done
	cls
	echo ╔═══════════════════════════════════════════════════════════════════╗
	echo ║  ooooooooo.                      ooooooooo.                       ║ 
	echo ║  `888   `Y88.                    `888   `Y88.                     ║ 
	echo ║   888   .d88' oooo d8b  .ooooo.   888   .d88'  .ooooo.   .oooo.o  ║ 
	echo ║   888ooo88P'  `888""8P d88' `88b  888ooo88P'  d88' `88b d88(  "8  ║ 
	echo ║   888          888     888   888  888`88b.    888ooo888 `"Y88b.   ║ 
	echo ║   888          888     888   888  888  `88b.  888    .o o.  )88b  ║ 
	echo ║  o888o        d888b    `Y8bod8P' o888o  o888o `Y8bod8P' 8""888P'  ║
	echo ╚═══════════════════════════════════════════════════════════════════╝
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo [92mEncoding succesful. This window will close after 5 seconds.[0m
	timeout /t 1 > nul
	cls
	echo ╔═══════════════════════════════════════════════════════════════════╗
	echo ║  ooooooooo.                      ooooooooo.                       ║ 
	echo ║  `888   `Y88.                    `888   `Y88.                     ║ 
	echo ║   888   .d88' oooo d8b  .ooooo.   888   .d88'  .ooooo.   .oooo.o  ║ 
	echo ║   888ooo88P'  `888""8P d88' `88b  888ooo88P'  d88' `88b d88(  "8  ║ 
	echo ║   888          888     888   888  888`88b.    888ooo888 `"Y88b.   ║ 
	echo ║   888          888     888   888  888  `88b.  888    .o o.  )88b  ║ 
	echo ║  o888o        d888b    `Y8bod8P' o888o  o888o `Y8bod8P' 8""888P'  ║
	echo ╚═══════════════════════════════════════════════════════════════════╝
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo [92mEncoding succesful. This window will close after 4 seconds.[0m
	timeout /t 1 > nul
	cls
	echo ╔═══════════════════════════════════════════════════════════════════╗
	echo ║  ooooooooo.                      ooooooooo.                       ║ 
	echo ║  `888   `Y88.                    `888   `Y88.                     ║ 
	echo ║   888   .d88' oooo d8b  .ooooo.   888   .d88'  .ooooo.   .oooo.o  ║ 
	echo ║   888ooo88P'  `888""8P d88' `88b  888ooo88P'  d88' `88b d88(  "8  ║ 
	echo ║   888          888     888   888  888`88b.    888ooo888 `"Y88b.   ║ 
	echo ║   888          888     888   888  888  `88b.  888    .o o.  )88b  ║ 
	echo ║  o888o        d888b    `Y8bod8P' o888o  o888o `Y8bod8P' 8""888P'  ║
	echo ╚═══════════════════════════════════════════════════════════════════╝
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo [92mEncoding succesful. This window will close after 3 seconds.[0m
	timeout /t 1 > nul
	cls
	echo ╔═══════════════════════════════════════════════════════════════════╗
	echo ║  ooooooooo.                      ooooooooo.                       ║ 
	echo ║  `888   `Y88.                    `888   `Y88.                     ║ 
	echo ║   888   .d88' oooo d8b  .ooooo.   888   .d88'  .ooooo.   .oooo.o  ║ 
	echo ║   888ooo88P'  `888""8P d88' `88b  888ooo88P'  d88' `88b d88(  "8  ║ 
	echo ║   888          888     888   888  888`88b.    888ooo888 `"Y88b.   ║ 
	echo ║   888          888     888   888  888  `88b.  888    .o o.  )88b  ║ 
	echo ║  o888o        d888b    `Y8bod8P' o888o  o888o `Y8bod8P' 8""888P'  ║
	echo ╚═══════════════════════════════════════════════════════════════════╝
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo [92mEncoding succesful. This window will close after 2 seconds.[0m
	timeout /t 1 > nul
	cls
	echo ╔═══════════════════════════════════════════════════════════════════╗
	echo ║  ooooooooo.                      ooooooooo.                       ║ 
	echo ║  `888   `Y88.                    `888   `Y88.                     ║ 
	echo ║   888   .d88' oooo d8b  .ooooo.   888   .d88'  .ooooo.   .oooo.o  ║ 
	echo ║   888ooo88P'  `888""8P d88' `88b  888ooo88P'  d88' `88b d88(  "8  ║ 
	echo ║   888          888     888   888  888`88b.    888ooo888 `"Y88b.   ║ 
	echo ║   888          888     888   888  888  `88b.  888    .o o.  )88b  ║ 
	echo ║  o888o        d888b    `Y8bod8P' o888o  o888o `Y8bod8P' 8""888P'  ║
	echo ╚═══════════════════════════════════════════════════════════════════╝
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo [92mEncoding succesful. This window will close after 1 seconds.[0m
	timeout /t 1 > nul
	exit 0

:VALIDATE_OUTPUT
	set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_ENC%.mov"
	echo [101;93m VALIDATING OUTPUT... [0m
	IF EXIST %OUTPUT_FILE% (
    	echo Output [30;41m UNAVAILABLE [0m && goto:errorfile
 		) ELSE ( 
    	echo Output [30;42m AVAILABLE [0m && EXIT /B
	)
:errorfile
	echo.
	echo [93mA file with the same name as the requested conversion output already exists.
	echo [1mSelect the desired action:[0m
	echo [33m[1][0m. Overwrite output (will ask again for confirmation)
	echo [33m[2][0m. Rename output %OUTPUT_NAME%%OUTPUT_ENC%[30;43m-(2)[0m.mov[0m
	echo [33m[3][0m. Abort the operation (will be auto-selected in 10s)
	echo.
	
	CHOICE /C 123 /T 10 /D 3 /M "Enter your choice:"
	:: Note - list ERRORLEVELS in decreasing order
	IF ERRORLEVEL 3 goto :abort
	IF ERRORLEVEL 2 set OUTPUT_SFX="(2)"
	IF ERRORLEVEL 1 EXIT /B

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