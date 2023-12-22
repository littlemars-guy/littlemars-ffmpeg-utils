::	This script provides multiple codec and preset choices to (hopefully) cover all your encoding
::	
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---ADDITIONAL INFO-----------------------------------------------------------------------------
::  More info abot this project: https://github.com/littlemars-guy/littlemars-ffmpeg-utils
::
::  Fancy font is "roman" from: https://devops.datenkollektiv.de/banner.txt/index.html
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-12-02 Version 0.2
::      - Added presets: libx264_HQ, NVENC_h264_HQ, libx264_medium, NVENC_h264_medium
::      - Added VALIDATE_OUTPUT and VALIDATE_AUDIO subroutines
::      - Added entry for Low UNI presets
::		- Added script description and license disclaimer
::		- Added changelog
::		- Minor formatting
::	-----------------------------------------------------------------------------------------------
if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
@echo off
setlocal EnableDelayedExpansion
chcp 65001
cls

:next
    if defined choice goto:%choice%

    echo [37mLet's start by choosing some settings:[0m
    echo.
    echo [101;93m CODECS [0m
	echo. && echo.
    
    echo [1mAvailable codecs:[0m
    echo [33m[1][0m. h264 (x264, NVENC)
	echo [33m[2][0m. h265 (x265, NVENC)
    echo [33m[3][0m. AV1 (SVT-AV1)
    echo [33m[4][0m. ProRes
	echo [33m[5][0m. FFV1
    echo [33m[6][0m. Low UNI presets
	echo.
	
    CHOICE /C 123456 /M "Enter your choice:"
    REM Note - list ERRORLEVELS in decreasing order
    IF ERRORLEVEL 6 GOTO:set_UNI
    IF ERRORLEVEL 5 GOTO:set_FFV1
    IF ERRORLEVEL 4 GOTO:set_ProRes
    IF ERRORLEVEL 3 GOTO:set_AV1
    IF ERRORLEVEL 2 GOTO:set_h265
    IF ERRORLEVEL 1 GOTO:set_h264
    
:set_h264
    title FFMPEG - Setting up h264 conversion
    cls
    echo.
	echo ╔══════════════════════════════════════════════╗
	echo ║ oooo          .oooo.       .ooo         .o   ║
	echo ║ `888        .dP""Y88b    .88'         .d88   ║
	echo ║  888 .oo.         ]8P'  d88'        .d'888   ║
	echo ║  888P"Y88b      .d8P'  d888P"Ybo. .d'  888   ║
	echo ║  888   888    .dP'     Y88[   ]88 88ooo888oo ║
	echo ║  888   888  .oP     .o `Y88   88P      888   ║
	echo ║ o888o o888o 8888888888  `88bod8'      o888o  ║
	echo ╚══════════════════════════════════════════════╝  
	echo.
    echo NOTE:  NVENC presets only work on systems equipped with NVIDIA GPU
    echo        from series GeForce 600 (March 2012) onward.
	echo.
    echo [37mYou have selected the h264 codec.[0m
    echo [37mChoose a preset or customize parameters:[0m
    echo.
    echo [101;93m PRESETS [0m
	echo. && echo.
    echo [33m[1][0m. HQ (libx264, preset slow, CRF16) [SLOWEST] [DEFAULT]
    echo [33m[2][0m. HQ (NVENC, 20mbps) [GPU-SLOW]
    echo [33m[3][0m. Medium (libx264, preset medium, CRF22) [MEDIUM]
    echo [33m[4][0m. Medium (NVENC, 10mbps) [GPU-MEDIUM]
	echo [33m[5][0m. Low (libx264, preset fast, CRF 28) [FAST]
    echo [33m[6][0m. Low (NVENC, 5mbps) [GPU-FAST]
    echo [33m[7][0m. Ultralow (libx264, preset fast, 2mbps) [FASTER]
    echo [33m[8][0m. Ultralow (NVENC, 2mbps) [GPU-FASTEST]
    echo [33m[9][0m. Go back...
	echo.
	::
    CHOICE /C 123456789 /T 10 /D 1 /M "Enter your choice:"
    :: Note - list ERRORLEVELS in decreasing order
    IF ERRORLEVEL 10 cls && goto:next
    IF ERRORLEVEL 9 title FFMPEG - Customize settings to encode "%~1" with h264 && ^
                    cls && ^
                    goto:custom_settings
    IF ERRORLEVEL 8 title FFMPEG - Converting "%~1" NVENC single pass 2mbps && ^
                    set encoder="h264_nvenc" && ^
                    set preset="fast" && ^
                    set tune="-tune hq" && ^
                    set bitrate_control="-b:v 2M -maxrate 3M -bufsize 6M -rc-lookahead 4 -keyint_min 1 -qdiff 20 -qcomp 0.9 -g 300" && ^
                    set profile="-profile:v high" && ^
                    set level="-level 4.1" && ^
                    set pix_fmt="yuv420p" && ^
                    set output_suffix="-NVENCh264_2M-AAC256k" && ^
                    set extension="mp4" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 7 title FFMPEG - Converting "%~1" libx264 fast CRF32 && ^
                    set encoder="libx264 -x264opts opencl" && ^
                    set preset="fast" && ^
                    set tune="-tune film" && ^
                    set bitrate_control="-crf 32 -maxrate 2M -bufsize 4M" && ^
                    set profile="-profile:v high" && ^
                    set level="-level 4.1" && ^
                    set pix_fmt="yuv420p" && ^
                    set output_suffix="-h264CRF32-AAC256k" && ^
                    set extension="mp4" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 6 title FFMPEG - Converting "%~1" NVENC single pass 5mbps && ^
                    set encoder="h264_nvenc" && ^
                    set preset="fast" && ^
                    set tune="-tune hq" && ^
                    set bitrate_control="-b:v 4M -maxrate 5M -bufsize 10M -rc-lookahead 4 -keyint_min 1 -qdiff 20 -qcomp 0.9 -g 300" && ^
                    set profile="-profile:v high" && ^
                    set level="-level 4.1" && ^
                    set pix_fmt="yuv420p" && ^
                    set output_suffix="-NVENCh264_5M-AAC256k" && ^
                    set extension="mp4" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 5 title FFMPEG - Converting "%~1" libx264 fast CRF28 && ^
                    set encoder="libx264 -x264opts opencl" && ^
                    set preset="fast" && ^
                    set tune="-tune film" && ^
                    set bitrate_control="-crf 28 -maxrate 5M -bufsize 10M" && ^
                    set profile="-profile:v high" && ^
                    set level="-level 4.1" && ^
                    set pix_fmt="yuv420p" && ^
                    set output_suffix="-h264CRF28-AAC256k"
                    

    IF ERRORLEVEL 4 goto:NVENC_h264_medium
    IF ERRORLEVEL 3 goto:libx264_medium
    IF ERRORLEVEL 2 goto:NVENC_h264_HQ
    IF ERRORLEVEL 1 goto:libx264_HQ

:libx264_HQ
    set choice=libx264_HQ
    set input_name=%~n1
    set input=%~1
    set count=2
	set OUTPUT_DIR=%~dp1
	set OUTPUT_NAME=%~n1
    set preset=h264CRF16
	set OUTPUT_SFX=
    set OUTPUT_EXT=.mp4
	CALL :VALIDATE_OUTPUT
    :encode_libx264_HQ
    CALL :VALIDATE_AUDIO
	echo.
	echo [101;93m ENCODING... [0m
	echo Input: %input_name%
	echo Output: %OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%
	echo.
    ffmpeg ^
        -hide_banner -loglevel warning -stats ^
        -hwaccel auto ^
	    -i "%input%" ^
        -map 0:a -map 0:v:0 ^
        -c:v libx264 -x264opts opencl ^
        -crf 16 ^
        -preset slow -tune film ^
        -profile:v high -level 5.2 ^
	    -pix_fmt yuv420p ^
	    -c:a %codec_audio% ^
        -map_metadata 0 ^
	    -movflags use_metadata_tags ^
        -movflags +faststart ^
	    "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
    goto:end

:NVENC_h264_HQ
    set choice=NVENC_h264_HQ
    set input_name=%~n1
    set input=%~1
  	set count=2
  	set OUTPUT_DIR=%~dp1
   	set OUTPUT_NAME=%~n1
    set preset=NVENCh264_20M
  	set OUTPUT_SFX=
    set OUTPUT_EXT=.mp4
  	CALL :VALIDATE_OUTPUT
    :encode_NVENC_h264_HQ
    CALL :VALIDATE_AUDIO
   	echo.
  	echo [101;93m ENCODING... [0m
   	echo Input: %~n1
   	echo Output: %OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%
   	echo.
    ffmpeg ^
        -hide_banner -loglevel warning -stats ^
        -hwaccel auto ^
	    -i "%~1" ^
        -map 0:a -map 0:v:0 ^
        -c:v h264_nvenc ^
        -rc constqp ^
        -qmin 17 -qmax 51 -qp 20 ^
        -maxrate 20M ^
        -rc-lookahead 4 -keyint_min 1 ^
        -qdiff 20 -qcomp 0.9 ^
        -g 300 ^
        -preset p7 -tune hq ^
        -profile:v high -level 5.2 ^
	    -pix_fmt yuv420p ^
	    -c:a %codec_audio% ^
        -map_metadata 0 ^
	    -movflags use_metadata_tags ^
        -movflags +faststart ^
	    "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
    goto:end

:libx264_medium
    set choice=libx264_HQ
    set input_name=%~n1
    set input=%~1
    set count=2
	set OUTPUT_DIR=%~dp1
	set OUTPUT_NAME=%~n1
    set preset=h264CRF22-AAC256k
	set OUTPUT_SFX=
    set OUTPUT_EXT=.mp4
	CALL :VALIDATE_OUTPUT
    :encode_libx264_medium
    CALL :VALIDATE_AUDIO
	echo.
	echo [101;93m ENCODING... [0m
	echo Input: %input_name%
	echo Output: %OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%
	echo.
    ffmpeg ^
        -hide_banner -loglevel warning -stats ^
        -hwaccel auto ^
	    -i "%input%" ^
        -map 0:a -map 0:v:0 ^
        -c:v libx264 -x264opts opencl ^
        -crf 22 ^
        -preset medium -tune film ^
        -profile:v high -level 4.1 ^
	    -pix_fmt yuv420p ^
	    -c:a %codec_audio% ^
        -map_metadata 0 ^
	    -movflags use_metadata_tags ^
        -movflags +faststart ^
	    "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
    goto:end

:NVENC_h264_medium
    set choice=NVENC_h264_medium
    set input_name=%~n1
    set input=%~1
  	set count=2
  	set OUTPUT_DIR=%~dp1
   	set OUTPUT_NAME=%~n1
    set preset=NNVENCh264_10M-AAC256k
  	set OUTPUT_SFX=
    set OUTPUT_EXT=.mp4
  	CALL :VALIDATE_OUTPUT
    :encode_NVENC_h264_medium
    CALL :VALIDATE_AUDIO
   	echo.
  	echo [101;93m ENCODING... [0m
   	echo Input: %~n1
   	echo Output: %OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%
   	echo.
    ffmpeg ^
        -hide_banner -loglevel warning -stats ^
        -hwaccel auto ^
	    -i "%~1" ^
        -map 0:a -map 0:v:0 ^
        -c:v h264_nvenc ^
        -b:v 9M -maxrate 12M -bufsize 20M^
        -rc-lookahead 4 -keyint_min 1 ^
        -qdiff 20 -qcomp 0.9 ^
        -g 300 ^
        -preset medium -tune hq ^
        -profile:v high -level 4.1 ^
	    -pix_fmt yuv420p ^
	    -c:a %codec_audio% ^
        -map_metadata 0 ^
	    -movflags use_metadata_tags ^
        -movflags +faststart ^
	    "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
    goto:end

:VALIDATE_OUTPUT
		echo.
		set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_EXT%"
		echo [101;93m VALIDATING OUTPUT... [0m
			IF EXIST %OUTPUT_FILE% (
				echo Output [30;41m UNAVAILABLE [0m && goto:errorfile
			) ELSE ( 
				echo Output [30;42m AVAILABLE [0m && goto:encode_%choice%
			)

	:errorfile
		set OUTPUT_SFX= (%count%)
		set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
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
		echo [33m[2][0m. Rename output %OUTPUT_NAME%-%preset%[30;43m-(%count%)[0m%OUTPUT_EXT%[0m
		echo [33m[3][0m. Abort the operation (will be auto-selected in 30s)
		echo.
	
		CHOICE /C 123 /T 30 /D 3 /M "Enter your choice:"
		:: Note - list ERRORLEVELS in decreasing order
		IF ERRORLEVEL 3 goto:abort
		IF ERRORLEVEL 2 goto:encode_%choice%
		IF ERRORLEVEL 1 EXIT /B

:VALIDATE_AUDIO
		::	Get codec name
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%input%"') do set "codec=%%I"
		if /i "%codec:~11%"=="wmav1" echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to aac && set codec_audio=aac -b:a 320k && EXIT /B
		if /i "%codec:~11%"=="wmav2" echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to aac && set codec_audio=aac -b:a 320k && EXIT /B
		echo Audio codec [30;42m %codec:~11% [0m is compatible, audio will be copied && set codec_audio=copy && EXIT /B

:set_h265
    title FFMPEG - Setting up h265 conversion
    cls
    echo.
    echo [92m╔══════════════════════════════════════════════════════╗
	echo [92m║======================== h265 ========================║
	echo [92m╚══════════════════════════════════════════════════════╝[0m
	echo.
    echo [37mYou have selected the h265 codec.[0m
    echo [37mChoose a preset or customize parameters:[0m
    echo.
    echo [101;93m PRESETS [0m
	echo. && echo.
    ::
    ::  echo [1mSelect the desired codec:[0m
    ::  echo [1mThe default [1] will be automatically selected in 10s[0m
    echo [33m[1][0m. HQ (libx265, preset slow, CRF16) [SLOWEST] [DEFAULT]
    echo [33m[2][0m. HQ (NVENC, 20mbps) [SLOW]
    echo [33m[3][0m. Medium (libx265, preset medium, CRF22)
    echo [33m[4][0m. Medium (NVENC, 10mbps)
	echo [33m[5][0m. Low (libx265, preset fast, CRF 28) [FAST]
    echo [33m[6][0m. Low (NVENC, 5mbps) [FASTER]
    echo [33m[7][0m. Ultralow (libx265, preset fast, 2mbps) [FASTER]
    echo [33m[8][0m. Ultralow (NVENC, 2mbps) [FASTEST]
    echo [33m[9][0m. Custom settings [Work In Progress]
    echo [33m[B][0m. Go back...
	echo.
	::
    CHOICE /C 123456789 /T 10 /D 1 /M "Enter your choice:"
    :: Note - list ERRORLEVELS in decreasing order
    IF ERRORLEVEL 10 cls && goto:next
    IF ERRORLEVEL 9 title FFMPEG - Customize settings to encode "%~1" with h265 && ^
                    cls && ^
                    goto:custom_settings
    IF ERRORLEVEL 8 title FFMPEG - Converting "%~1" NVENC single pass 2mbps && ^
                    set encoder="hevc_nvenc" && ^
                    set preset="fast" && ^
                    set tune="-tune hq" && ^
                    set bitrate_control="-b:v 2M -maxrate 3M -bufsize 6M -rc-lookahead 4 -keyint_min 1 -qdiff 20 -qcomp 0.9 -g 300" && ^
                    set profile="-profile main10 -tier high" && ^
                    set level="" && ^
                    set pix_fmt="yuv420p" && ^
                    set output_suffix="-NVENCh265_2M-AAC256k" && ^
                    set extension="mp4" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 7 title FFMPEG - Converting "%~1" libx264 fast CRF32 && ^
                    set encoder="libx265" && ^
                    set preset="fast" && ^
                    set tune="-tune film" && ^
                    set bitrate_control="-crf 32 -maxrate 2M -bufsize 4M" && ^
                    set profile="-profile:v high" && ^
                    set level="" && ^
                    set pix_fmt="yuv420p10le" && ^
                    set output_suffix="-h265CRF32-AAC256k" && ^
                    set extension="mp4" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 6 title FFMPEG - Converting "%~1" NVENC single pass 5mbps && ^
                    set encoder="hevc_nvenc" && ^
                    set preset="fast" && ^
                    set tune="-tune hq" && ^
                    set bitrate_control="-b:v 4M -maxrate 5M -bufsize 10M -rc-lookahead 4 -keyint_min 1 -qdiff 20 -qcomp 0.9 -g 300" && ^
                    set profile="-profile main10 -tier high" && ^
                    set level="" && ^
                    set pix_fmt="yuv420p10le" && ^
                    set output_suffix="-NVENCh265_5M-AAC256k" && ^
                    set extension="mp4" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 5 title FFMPEG - Converting "%~1" libx265 fast CRF28 && ^
                    set encoder="libx265" && ^
                    set preset="fast" && ^
                    set tune="" && ^
                    set bitrate_control="-crf 28 -maxrate 5M -bufsize 10M" && ^
                    set profile="-profile:v high" && ^
                    set level="" && ^
                    set pix_fmt="yuv420p10le" && ^
                    set output_suffix="-h265CRF28-AAC256k" && ^
                    set extension="mp4" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 4 title FFMPEG - Converting "%~1" NVENC single pass 10mbps && ^
                    set encoder="hevc_nvenc" && ^
                    set preset="p4" && ^
                    set tune="-tune hq" && ^
                    set bitrate_control="-b:v 8M -maxrate 10M -bufsize 20M -rc-lookahead 4 -keyint_min 1 -qdiff 20 -qcomp 0.9 -g 300" && ^
                    set profile="-profile main10 -tier high" && ^
                    set level="" && ^
                    set pix_fmt="yuv420p10le" && ^
                    set output_suffix="-NVENCh265_10M-AAC256k" && ^
                    set extension="mp4" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 3 title FFMPEG - Converting "%~1" libx264 medium CRF22 && ^
                    set encoder="libx265" && ^
                    set preset="medium" && ^
                    set tune="-tune grain" && ^
                    set bitrate_control="-crf 22" && ^
                    set profile="-x265-params profile=main10" && ^
                    set level="" && ^
                    set pix_fmt="yuv420p10le" && ^
                    set output_suffix="-h265CRF22-AAC256k" && ^
                    set extension="mp4" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 2 title FFMPEG - Converting "%~1" NVENC single pass 20mbps && ^
                    set encoder="hevc_nvenc" && ^
                    set preset="p7" && ^
                    set tune="-tune hq" && ^
                    set bitrate_control="-rc constqp -qmin 16 -qmax 51 -qp 20 -maxrate 20M -rc-lookahead 4 -keyint_min 1 -qdiff 20 -qcomp 0.9 -g 300" && ^
                    set profile="-profile main10 -tier high" && ^
                    set level="" && ^
                    set pix_fmt="yuv420p10le" && ^
                    set output_suffix="-NVENCh265_20M-AAC256k" && ^
                    set extension="mp4" && ^
                    set title_pass2= "" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 1 title FFMPEG - Converting "%~1" to High Quality h265 video with 256kbps AAC audio && ^
                    set encoder="libx265" && ^
                    set preset="slow" && ^
                    set profile="-x265-params profile=main10" && ^
                    set tune="-tune grain" && ^
                    set level=""
                    set bitrate_control="-crf 16" && ^
                    set pix_fmt="yuv420p10le" && ^
                    set output_suffix="-h265CRF16-AAC256k" && ^
                    set extension="mp4" && ^
                    goto:encode_single_pass

:set_AV1
    echo AV1 encoding is Work In Progess, will be introduced in future releases.
    echo Press any key to return to main menu
    pause >NUL
    goto:next
:set_ProRes
    echo ProRes encoding is work in progress, will be introduced in future releases.
    echo Press any key to return to main menu
    pause >NUL
    goto:next
:set_FFV1
    echo FFV1 encoding is work in progress, will be introduced in future releases.
    echo Press any key to return to main menu
    pause >NUL
    goto:next
:set_UNI
    echo UNI preset are work in progress
    echo Will be made available in future releases.
    echo Press any key to return to main menu
    pause >NUL
    goto:next
:custom_settings
    echo Custom settings are work in progress, will be introduced in future releases.
    echo Press any key to return to main menu
    pause >NUL
    goto:next
:encode_single_pass
    ffmpeg ^
        -hide_banner ^
        -hwaccel auto ^
		-i "%~1" ^
		-map 0 ^
        -c:v %encoder% ^
        %bitrate_control% ^
        -preset %preset% ^
        %tune% ^
        %profile% ^
	    %level% ^
		-pix_fmt %pix_fmt% ^
		-c:a aac ^
        -b:a 256k ^
        -map_metadata 0 ^
		-movflags use_metadata_tags ^
        -movflags +faststart ^
		"%~dp1%~n1%output_suffix%.%extension%"
        goto:end

:encode_pass1
    ffmpeg ^
        -hide_banner ^
        -hwaccel auto ^
		-i "%~1" ^
		-map 0 ^
        -c:v %encoder% ^
        %bitrate_control% ^
        -preset %preset% ^
        -tune %tune% ^
        -profile:v %profile% ^
	    -level %level% ^
		-pix_fmt %pix_fmt% ^
		-c:a aac ^
        -b:a 256k ^
        -map_metadata 0 ^
		-movflags use_metadata_tags ^
        -movflags +faststart ^
		-pass 1 -f mp4 ^
        NUL
        goto:encode_pass2

:encode_pass2
    title %title_pass2%

    ffmpeg ^
        -hide_banner ^
        -hwaccel auto ^
		-i "%~1" ^
		-map 0 ^
        -c:v %encoder% ^
        %bitrate_control% ^
        -preset %preset% ^
        -tune %tune% ^
        -profile:v %profile% ^
	    -level %level% ^
		-pix_fmt %pix_fmt% ^
		-c:a aac ^
        -b:a 256k ^
        -map_metadata 0 ^
		-movflags use_metadata_tags ^
        -movflags +faststart ^
        -pass 2 ^
		"%~dp1%~n1%output_suffix%.%extension%"
        goto:end

:end
    if NOT ["%errorlevel%"]==["0"] goto:error
	echo [92m%~n1 Done![0m
	title FFMPEG - We did it!

    set OUTPUT_SFX=""
    timeout /t 2 > nul
	shift
	if "%~1" == "" goto:done
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

:error
	
	echo [93mThere was an error. Please check your input file.[0m
	pause
	exit 0

