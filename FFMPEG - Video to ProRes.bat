::	This script will convert its input to a ProRes encoded .mov file.
::	
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-14-10 Version 0.2.5
::		Reworked loop behavior when encoding multiple files
::		Updated banners
::	2023-14-10 Version 0.2.1
::		Partial banner update
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
	echo           ╔═══════════════════════════════════════════════════════════════════╗
	echo           ║  ooooooooo.                      ooooooooo.                       ║ 
	echo           ║  `888   `Y88.                    `888   `Y88.                     ║ 
	echo           ║   888   .d88' oooo d8b  .ooooo.   888   .d88'  .ooooo.   .oooo.o  ║ 
	echo           ║   888ooo88P'  `888""8P d88' `88b  888ooo88P'  d88' `88b d88(  "8  ║ 
	echo           ║   888          888     888   888  888`88b.    888ooo888 `"Y88b.   ║ 
	echo           ║   888          888     888   888  888  `88b.  888    .o o.  )88b  ║ 
	echo           ║  o888o        d888b    `Y8bod8P' o888o  o888o `Y8bod8P' 8""888P'  ║
	echo           ╚═══════════════════════════════════════════════════════════════════╝
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	echo.
	echo	NOTE:  this script can encode ProRes only up to 10bit precision, if you need
	echo		   12bits you should use another encoder.
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
	IF ERRORLEVEL 5 set choice="PR4444XQ" && GOTO:PR4444XQ
	IF ERRORLEVEL 4 set choice="PR4444" && GOTO:PR4444
	IF ERRORLEVEL 3 set choice="PR422HQ" && GOTO:PR422HQ
	IF ERRORLEVEL 2 set choice="PRStandard" && GOTO:PRStandard
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
		echo [101;93m ENCODING... [0m
		echo Input: %~1
		echo Output: %~dp1%~n1_ProResProxy.mov
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
			-c:v prores_ks ^
			-profile:v 0 ^
			-quant_mat auto ^
			-vendor apl0 ^
			-bits_per_mb 250 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProResProxy.mov"
			if NOT ["%errorlevel%"]==["0"] goto:error
			
			if "%~1" == "" goto:done
	
			timeout /t 3
			shift
			goto:PRProxy

	:PRStandard
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
		echo ║        .o     .oooo.     .oooo.                                       ║
		echo ║      .d88   .dP""Y88b  .dP""Y88b                                      ║
		echo ║    .d'888         ]8P'       ]8P'                                     ║
		echo ║  .d'  888       .d8P'      .d8P'                                      ║
		echo ║  88ooo888oo   .dP'       .dP'                                         ║
		echo ║       888   .oP     .o .oP     .o                                     ║
		echo ║      o888o  8888888888 8888888888                                     ║
		echo ╚═══════════════════════════════════════════════════════════════════════╝
		echo.
		echo [101;93m ENCODING... [0m
		echo Input: %~1
		echo Output: %~dp1%~n1_ProRes422.mov
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
			-c:v prores_ks ^
			-profile:v 2 ^
			-quant_mat auto ^
			-vendor apl0 ^
			-bits_per_mb 875 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProRes422.mov"
			if NOT ["%errorlevel%"]==["0"] goto:error
			
			if "%~1" == "" goto:done
	
			timeout /t 3
			shift
			goto:PRStandard
				
	:PR422HQ
		cls
		echo ╔═════════════════════════════════════════════════════════════════════╗
		echo ║  ooooooooo.                      ooooooooo.                         ║ 
		echo ║  `888   `Y88.                    `888   `Y88.                       ║ 
		echo ║   888   .d88' oooo d8b  .ooooo.   888   .d88'  .ooooo.   .oooo.o    ║ 
		echo ║   888ooo88P'  `888""8P d88' `88b  888ooo88P'  d88' `88b d88(  "8    ║ 
		echo ║   888          888     888   888  888`88b.    888ooo888 `"Y88b.     ║ 
		echo ║   888          888     888   888  888  `88b.  888    .o o.  )88b    ║ 
		echo ║  o888o        d888b    `Y8bod8P' o888o  o888o `Y8bod8P' 8""888P'    ║
		echo ║                                                                     ║
		echo ║        .o     .oooo.     .oooo.      ooooo   ooooo   .oooooo.       ║
		echo ║      .d88   .dP""Y88b  .dP""Y88b     `888'   `888'  d8P'  `Y8b      ║
		echo ║    .d'888         ]8P'       ]8P'     888     888  888      888     ║
		echo ║  .d'  888       .d8P'      .d8P'      888ooooo888  888      888     ║
		echo ║  88ooo888oo   .dP'       .dP'         888     888  888      888     ║
		echo ║       888   .oP     .o .oP     .o     888     888  `88b    d88b     ║
		echo ║      o888o  8888888888 8888888888    o888o   o888o  `Y8bood8P'Ybd'  ║
		echo ╚═════════════════════════════════════════════════════════════════════╝
		echo.		
		echo [101;93m ENCODING... [0m
		echo Input: %~1
		echo Output: %~dp1%~n1_ProRes422HQ.mov
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
			-c:v prores_ks ^
			-profile:v 3 ^
			-quant_mat auto ^
			-vendor apl0 ^
			-bits_per_mb 1350 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProRes422HQ.mov"
			if NOT ["%errorlevel%"]==["0"] goto:error
			
			if "%~1" == "" goto:done
	
			timeout /t 3
			shift
			goto:PR422HQ
				
	:PR4444
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
		echo ║        .o         .o         .o         .o                         ║
		echo ║      .d88       .d88       .d88       .d88                         ║
		echo ║    .d'888     .d'888     .d'888     .d'888                         ║
		echo ║  .d'  888   .d'  888   .d'  888   .d'  888                         ║
		echo ║  88ooo888oo 88ooo888oo 88ooo888oo 88ooo888oo                       ║
		echo ║       888        888        888        888                         ║
		echo ║      o888o      o888o      o888o      o888o                        ║
		echo ╚════════════════════════════════════════════════════════════════════╝
		echo.
		echo [101;93m ENCODING... [0m
		echo Input: %~1
		echo Output: %~dp1%~n1_ProRes4444.mov
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
			-c:v prores_ks ^
			-profile:v 4 ^
			-quant_mat auto ^
			-vendor apl0 ^
			-bits_per_mb 8000 ^
			-pix_fmt yuva444p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProRes4444.mov"
			if NOT ["%errorlevel%"]==["0"] goto:error
			
			if "%~1" == "" goto:done
	
			timeout /t 3
			shift
			goto:PR4444
				
	:PR4444XQ
		cls
		echo ╔═════════════════════════════════════════════════════════════════════════════════╗
		echo ║  ooooooooo.                      ooooooooo.                                     ║ 
		echo ║  `888   `Y88.                    `888   `Y88.                                   ║ 
		echo ║   888   .d88' oooo d8b  .ooooo.   888   .d88'  .ooooo.   .oooo.o                ║ 
		echo ║   888ooo88P'  `888""8P d88' `88b  888ooo88P'  d88' `88b d88(  "8                ║ 
		echo ║   888          888     888   888  888`88b.    888ooo888 `"Y88b.                 ║ 
		echo ║   888          888     888   888  888  `88b.  888    .o o.  )88b                ║ 
		echo ║  o888o        d888b    `Y8bod8P' o888o  o888o `Y8bod8P' 8""888P'                ║
		echo ║                                                                                 ║
		echo ║        .o         .o         .o         .o      ooooooo  ooooo   .oooooo.       ║
		echo ║      .d88       .d88       .d88       .d88       `8888    d8'   d8P'  `Y8b      ║
		echo ║    .d'888     .d'888     .d'888     .d'888         Y888..8P    888      888     ║
		echo ║  .d'  888   .d'  888   .d'  888   .d'  888          `8888'     888      888     ║
		echo ║  88ooo888oo 88ooo888oo 88ooo888oo 88ooo888oo       .8PY888.    888      888     ║
		echo ║       888        888        888        888        d8'  `888b   `88b    d88b     ║
		echo ║      o888o      o888o      o888o      o888o     o888o  o88888o  `Y8bood8P'Ybd'  ║
		echo ╚═════════════════════════════════════════════════════════════════════════════════╝
		echo.
		echo [101;93m ENCODING... [0m
		echo Input: %~1
		echo Output: %~dp1%~n1_ProRes4444XQ.mov
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
			-c:v prores_ks ^
			-profile:v 5 ^
			-quant_mat auto ^
			-vendor apl0 ^
			-bits_per_mb 8000 ^
			-pix_fmt yuva444p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 ^
			-movflags use_metadata_tags ^
			"%~dp1%~n1_ProRes4444XQ.mov"

			if NOT ["%errorlevel%"]==["0"] goto:error
			
			if "%~1" == "" goto:done
	
			timeout /t 3
			shift
			goto:PR4444XQ


:errorfile
	
	cls
	echo [93m╔═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
	echo [93m║        .o.       ooooooooooooo ooooooooooooo oooooooooooo ooooo      ooo ooooooooooooo ooooo   .oooooo.   ooooo      ooo  ║
	echo [93m║       .888.      8'   888   `8 8'   888   `8 `888'     `8 `888b.     `8' 8'   888   `8 `888'  d8P'  `Y8b  `888b.     `8'  ║
	echo [93m║      .8"888.          888           888       888          8 `88b.    8       888       888  888      888  8 `88b.    8   ║
	echo [93m║     .8' `888.         888           888       888oooo8     8   `88b.  8       888       888  888      888  8   `88b.  8   ║
	echo [93m║    .88ooo8888.        888           888       888    "     8     `88b.8       888       888  888      888  8     `88b.8   ║
	echo [93m║   .8'     `888.       888           888       888       o  8       `888       888       888  `88b    d88'  8       `888   ║
	echo [93m║  o88o     o8888o     o888o         o888o     o888ooooood8 o8o        `8      o888o     o888o  `Y8bood8P'  o8o        `8   ║
    echo [93m╚═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝                                                                                                                    
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