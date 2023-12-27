::	This script will convert its input to a ProRes encoded .mov file.
::	
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---ADDITIONAL INFO-----------------------------------------------------------------------------
::	More info abot this project: https://github.com/littlemars-guy/littlemars-ffmpeg-utils
::
::  Fancy font is "roman" from: https://devops.datenkollektiv.de/banner.txt/index.html
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-12-19 Version 0.5
::		- Revised :abort and :done routines for compactness and integrate :banner + :info routines
::	2023-11-23 Version 0.4.3
::		- Fixed ProRes LT will now correctly add the [ProRes LT] suffix to encoded files, instead
::		of {ProRes LT}
::	2023-11-20 Version 0.4.2
::		- Updated VALIDATE_OUTPUT subroutine for better handling of rename function when output is
::		already existing.
::	2023-11-18 Version 0.4.1
::		- Minor tweaks
::	2023-11-18 Version 0.4
::		- Added ProRes LT encoding subroutine
::		- Added VALIDATE_OUTPUT subroutine to check for presence of files with the same name of output
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
::if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )

@echo off
setlocal EnableDelayedExpansion
chcp 65001
set OUTPUT_EXT=.mov
cls

:next
	title FFMPEG - Converting %~nx1 to ProRes
	CALL:banner
	echo.
	CALL:info
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
	
	CHOICE /C 123456 /M "Enter your choice:"
	:: Note - list ERRORLEVELS in decreasing order
	IF ERRORLEVEL 6 GOTO:PR4444XQ
	IF ERRORLEVEL 5 GOTO:PR4444
	IF ERRORLEVEL 4 GOTO:PR422HQ
	IF ERRORLEVEL 3 GOTO:PRStandard
	IF ERRORLEVEL 2 GOTO:PRlt
	IF ERRORLEVEL 1 GOTO:PRProxy 

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
		echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
		echo.
		CALL:info
		echo.
		set ProRes=[ProRes Proxy]
		set choice=PRProxy
		set input=%~1
		set count=2
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_SFX=
		CALL :VALIDATE_OUTPUT
		echo.
		echo [101;93m ENCODING... [0m
		echo Input: %~nx1
		echo Output: %OUTPUT_NAME%-%ProRes%%OUTPUT_SFX%%OUTPUT_EXT%
		echo.

		::	Get codec name
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"

		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s16le" && goto:encode_%choice%
		set codec_audio=copy
		goto:encode_%choice%

		::	Get bits per sample
		::bits_per_sample
		::for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "bits=%%I"

		:encode_PRProxy 
		ffmpeg ^
			-hide_banner -loglevel warning -stats ^
			-hwaccel auto ^
			-i "%input%" ^
			-map 0:a -map 0:v:0 ^
			-c:v prores_ks -profile:v 0 -quant_mat proxy -vendor apl0 ^
			-qscale:v 13 -bits_per_mb 250 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 -movflags use_metadata_tags ^
			"%~dp1%~n1-%ProRes%%OUTPUT_SFX%%OUTPUT_EXT%"
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
		echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
		echo.
		CALL:info
		echo.
		set ProRes=[ProRes lt]
		set choice=PRlt
		set input=%~1
		set count=2
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_SFX=
		CALL :VALIDATE_OUTPUT
		echo.
		echo [101;93m ENCODING... [0m
		echo Input: %~nx1
		echo Output: %OUTPUT_NAME%-%ProRes%%OUTPUT_SFX%%OUTPUT_EXT%
		echo.

		::	Get codec name
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"

		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s16le" && goto:encode_%choice%
		set codec_audio=copy
		goto:encode_%choice%

		::	Get bits per sample
		::bits_per_sample
		::for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "bits=%%I"

		:encode_PRlt
		ffmpeg ^
			-hide_banner -loglevel warning -stats ^
			-i "%input%" ^
			-map 0:a -map 0:v:0 ^
			-c:v prores_ks -profile:v 1 -quant_mat lt -vendor apl0 ^
			-qscale:v 11 -bits_per_mb 525 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 -movflags use_metadata_tags ^
			"%~dp1%~n1-%ProRes%%OUTPUT_SFX%%OUTPUT_EXT%"
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
		echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
		echo.
		CALL:info
		echo.
		set ProRes=[ProRes 422]
		set choice=PRStandard
		set input=%~1
		set count=2
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_SFX=
		CALL :VALIDATE_OUTPUT
		echo.
		echo [101;93m ENCODING... [0m
		echo Input: %~nx1
		echo Output: %OUTPUT_NAME%-%ProRes%%OUTPUT_SFX%%OUTPUT_EXT%
		echo.

		::	Get codec name
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"
        
		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s24le" && goto:encode_%choice%
		set codec_audio=copy
		goto:encode_%choice%

		::	Get bits per sample
		::bits_per_sample
		::for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "bits=%%I"
        
		:encode_PRStandard
		ffmpeg ^
			-hide_banner -loglevel warning -stats ^
			-i "%input%" ^
			-map 0:a -map 0:v:0 ^
			-c:v prores_ks -profile:v 2 -qscale:v 8 -quant_mat auto -vendor apl0 ^
			-bits_per_mb 875 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 -movflags use_metadata_tags ^
			"%~dp1%~n1-%ProRes%%OUTPUT_SFX%%OUTPUT_EXT%"
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
		echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
		echo.
		CALL:info
		echo.
		set ProRes=[ProRes 422HQ]
		set choice=PR422HQ
		set input=%~1
		set count=2
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_SFX=
		CALL :VALIDATE_OUTPUT
		echo.
		echo [101;93m ENCODING... [0m
		echo Input: %~nx1
		echo Output: %OUTPUT_NAME%-%ProRes%%OUTPUT_SFX%%OUTPUT_EXT%
		echo.

		::	Get codec name
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"
        
		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s24le" && goto:encode_%choice%
		set codec_audio=copy
		goto:encode_%choice%

		::	Get bits per sample
		::bits_per_sample
		::for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "bits=%%I"
        
		:encode_PR422HQ
		ffmpeg ^
			-hide_banner -loglevel warning -stats ^
			-i "%input%" ^
			-map 0:a -map 0:v:0 ^
			-c:v prores_ks -profile:v 3 -qscale:v 4 -quant_mat auto -vendor apl0 ^
			-bits_per_mb 1350 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 -movflags use_metadata_tags ^
			"%~dp1%~n1-%ProRes%%OUTPUT_SFX%%OUTPUT_EXT%"
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
		echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
		echo.
		CALL:info
		echo.
		set ProRes=[ProRes 4444]
		set choice=PR4444
		set input=%~1
		set count=2
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_SFX=
		CALL :VALIDATE_OUTPUT
		echo.
		echo [101;93m ENCODING... [0m
		echo Input: %~nx1
		echo Output: %OUTPUT_NAME%-%ProRes%%OUTPUT_SFX%%OUTPUT_EXT%
		echo.

		::	Get codec name
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"
        
		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s24le" && goto:encode_%choice%
		set codec_audio=copy
		goto:encode_%choice%

		::	Get bits per sample
		::bits_per_sample
		::for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "bits=%%I"
        
		:encode_PR4444
		ffmpeg ^
			-hide_banner -loglevel warning -stats ^
			-i "%input%" ^
			-map 0:a -map 0:v:0 ^
			-c:v prores_ks -profile:v 4 -quant_mat auto -vendor apl0 ^
			-bits_per_mb 8000 ^
			-pix_fmt yuva444p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 -movflags use_metadata_tags ^
			"%~dp1%~n1-%ProRes%%OUTPUT_SFX%%OUTPUT_EXT%"
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
		echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
		echo.
		CALL:info
		echo.
		set ProRes=[ProRes 4444XQ]
		set choice=PR4444XQ
		set input=%~1
		set count=2
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_SFX=
		CALL :VALIDATE_OUTPUT
		echo.
		echo [101;93m ENCODING... [0m
		echo Input: %~nx1
		echo Output: %OUTPUT_NAME%-%ProRes%%OUTPUT_SFX%%OUTPUT_EXT%
		echo.

		::	Get codec name
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "codec=%%I"
        
		if /i "%codec:~11%"=="Opus" set codec_audio="pcm_s24le" && goto:encode_%choice%
		set codec_audio=copy
		goto:encode_%choice%

		::	Get bits per sample
		::bits_per_sample
		::for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%~1"') do set "bits=%%I"
        
		:encode_PR4444XQ
		ffmpeg ^
			-hide_banner -loglevel warning -stats ^
			-i "%input%" ^
			-map 0:a -map 0:v:0 ^
			-c:v prores_ks -profile:v 5 -quant_mat auto -vendor apl0 ^
			-bits_per_mb 8000 ^
			-pix_fmt yuva444p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 -movflags use_metadata_tags ^
			"%~dp1%~n1-%ProRes%%OUTPUT_SFX%%OUTPUT_EXT%"

			if NOT ["%errorlevel%"]==["0"] goto:error
			
			set OUTPUT_SFX=""
			timeout /t 2 > nul
			shift
			if "%~1" == "" goto:done
			goto:PR4444XQ

	:VALIDATE_OUTPUT
		echo.
		set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%-%ProRes%%OUTPUT_EXT%"
		echo [101;93m VALIDATING OUTPUT... [0m
			IF EXIST %OUTPUT_FILE% (
				echo Output [30;41m UNAVAILABLE [0m && goto:errorfile
			) ELSE ( 
				echo Output [30;42m AVAILABLE [0m && EXIT /B
			)
	:errorfile
		set OUTPUT_SFX= (%count%)
		set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%-%ProRes%%OUTPUT_SFX%%OUTPUT_EXT%"
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
		echo [33m[2][0m. Rename output %OUTPUT_NAME%-%ProRes%[30;43m-(%count%)[0m.%OUTPUT_EXT%[0m
		echo [33m[3][0m. Abort the operation (will be auto-selected in 30s)
		echo.
	
		CHOICE /C 123 /T 30 /D 3 /M "Enter your choice:"
		:: Note - list ERRORLEVELS in decreasing order
		IF ERRORLEVEL 3 goto :abort
		IF ERRORLEVEL 2 EXIT /B
		IF ERRORLEVEL 1 set "OUTPUT_SFX=" && EXIT /B

:error
	
	echo [93mThere was an error. Please check your input file.[0m
	pause
	exit 0

:done
	set countdown=5
	CALL:end_cycle
	:end_cycle
		cls
		CALL:banner
		echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo.
		echo [92mEncoding succesful. This window will close after %countdown% seconds.[0m
		set /A countdown-=1
		timeout /t 1 > nul
		if "%countdown%"=="0" exit 0
		goto:end_cycle

:abort
	
	set countdown=5
	CALL:abort_cycle
	:abort_cycle
		cls
		CALL:banner
		echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo.
		echo [93mProcess aborted.[0m
		set /A countdown-=1
		timeout /t 1 > nul
		if "%countdown%"=="0" exit 0
		goto:abort_cycle

:banner
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

:info
	echo NOTE:  FFMPEG can encode ProRes only up to 10bit precision, if you need 12bits you should use another software.