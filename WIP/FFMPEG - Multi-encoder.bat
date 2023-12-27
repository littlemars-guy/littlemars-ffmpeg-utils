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
::  2023-12-27 Version 0.3
::      - Added presets: libx264_low, NVENC_h264_low, libx264_ultralow, NVENC_h264_ultralow,
::      libx265_HQ, NVENC_h265_HQ, libx265_medium, NVENC_h265_medium, libx265_low, NVENC_h265_low,
::      libx265_ultralow, NVENC_h265_ultralow, ProResProxy, ProResLT, ProResStandard, ProRes422HQ, 
::      ProRes4444, ProRes4444XQ
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

set file_count=0

:again
	set /A file_count+=1
	if NOT DEFINED jump goto :next

:jump
    timeout /t 2 > nul
    shift
    if "%~1" == "" goto :done
    set input_name=%~n1
    set input=%~1

:next
    set jump=yes
    set input_name=%~n1
    set input=%~1
    set OUTPUT_DIR=%~dp1
	set OUTPUT_NAME=%~n1
    if defined choice goto:%choice%

    echo [37mLet's start by choosing some settings:[0m
    echo.
    echo [101;93m CODECS [0m
	echo.
    
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
    IF ERRORLEVEL 9 cls && goto:custom_settings
    IF ERRORLEVEL 8 goto:NVENC_h264_ultralow
    IF ERRORLEVEL 7 goto:libx264_ultralow
    IF ERRORLEVEL 6 goto:NVENC_h264_low
    IF ERRORLEVEL 5 goto:libx264_low
    IF ERRORLEVEL 4 goto:NVENC_h264_medium
    IF ERRORLEVEL 3 goto:libx264_medium
    IF ERRORLEVEL 2 goto:NVENC_h264_HQ
    IF ERRORLEVEL 1 goto:libx264_HQ

    :libx264_HQ
        set choice=libx264_HQ
        set count=2
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
        set count=2
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
            -i "%input%" ^
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
        set count=2
        set OUTPUT_DIR=%~dp1
        set OUTPUT_NAME=%~n1
        set preset=h264CRF22
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
            -profile:v high -%level%% ^
            -pix_fmt yuv420p ^
            -c:a %codec_audio% ^
            -map_metadata 0 ^
            -movflags use_metadata_tags ^
            -movflags +faststart ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :NVENC_h264_medium
        set choice=NVENC_h264_medium
        set count=2
        set preset=NVENCh264_10M
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
            -i "%input%" ^
            -map 0:a -map 0:v:0 ^
            -c:v h264_nvenc ^
            -b:v 9M -maxrate 12M -bufsize 20M ^
            -rc-lookahead 4 -keyint_min 1 ^
            -qdiff 20 -qcomp 0.9 ^
            -g 300 ^
            -preset medium -tune hq ^
            -profile:v high -%level% ^
            -pix_fmt yuv420p ^
            -c:a %codec_audio% ^
            -map_metadata 0 ^
            -movflags use_metadata_tags ^
            -movflags +faststart ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :libx264_low
        set choice=libx264_low
        set count=2
        set preset=h264CRF28
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mp4
        CALL :VALIDATE_OUTPUT
        :encode_libx264_low
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
            -crf 28 -maxrate 5M -bufsize 10M ^
            -preset fast -tune film ^
            -profile:v high -%level% ^
            -pix_fmt yuv420p ^
            -c:a %codec_audio% ^
            -map_metadata 0 ^
            -movflags use_metadata_tags ^
            -movflags +faststart ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :NVENC_h264_low
        set choice=NVENC_h264_low
        set count=2
        set preset=NVENCh264_5M
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mp4
        CALL :VALIDATE_OUTPUT
        :encode_NVENC_h264_low
        CALL :VALIDATE_AUDIO
        echo.
        echo [101;93m ENCODING... [0m
        echo Input: %input%
        echo Output: %OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%
        echo.
        ffmpeg ^
            -hide_banner -loglevel warning -stats ^
            -hwaccel auto ^
            -i "%input%" ^
            -map 0:a -map 0:v:0 ^
            -c:v h264_nvenc ^
            -b:v 4M -maxrate 5M -bufsize 10M ^
            -rc-lookahead 4 -keyint_min 1 ^
            -qdiff 20 -qcomp 0.9 ^
            -g 300 ^
            -preset fast -tune hq ^
            -profile:v high -%level% ^
            -pix_fmt yuv420p ^
            -c:a %codec_audio% ^
            -map_metadata 0 ^
            -movflags use_metadata_tags ^
            -movflags +faststart ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :libx264_ultralow
        set choice=libx264_ultralow
        set count=2
        set preset=h264CRF32
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mp4
        CALL :VALIDATE_OUTPUT
        :encode_libx264_ultralow
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
            --crf 32 -maxrate 2M -bufsize 4M ^
            -preset fast -tune film ^
            -profile:v high -%level% ^
            -pix_fmt yuv420p ^
            -c:a %codec_audio% ^
            -map_metadata 0 ^
            -movflags use_metadata_tags ^
            -movflags +faststart ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :NVENC_h264_ultralow
        set choice=NVENC_h264_ultralow
        set count=2
        set preset=NVENCh264_2M
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mp4
        CALL :VALIDATE_OUTPUT
        :encode_NVENC_h264_low
        CALL :VALIDATE_AUDIO
        echo.
        echo [101;93m ENCODING... [0m
        echo Input: %input%
        echo Output: %OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%
        echo.
        ffmpeg ^
            -hide_banner -loglevel warning -stats ^
            -hwaccel auto ^
            -i "%input%" ^
            -map 0:a -map 0:v:0 ^
            -c:v h264_nvenc ^
            -b:v 2M -maxrate 3M -bufsize 6M ^
            -rc-lookahead 4 -keyint_min 1 ^
            -qdiff 20 -qcomp 0.9 ^
            -g 300 ^
            -preset fast -tune hq ^
            -profile:v high -%level% ^
            -pix_fmt yuv420p ^
            -c:a %codec_audio% ^
            -map_metadata 0 ^
            -movflags use_metadata_tags ^
            -movflags +faststart ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

:set_h265
    cls
    echo.
	echo ╔══════════════════════════════════════════════╗
	echo ║ oooo          .oooo.       .ooo     oooooooo ║
	echo ║ `888        .dP""Y88b    .88'      dP""""""" ║
	echo ║  888 .oo.         ]8P'  d88'      d88888b.   ║
	echo ║  888P"Y88b      .d8P'  d888P"Ybo.     `Y88b  ║
	echo ║  888   888    .dP'     Y88[   ]88       ]88  ║
	echo ║  888   888  .oP     .o `Y88   88P o.   .88P  ║
	echo ║ o888o o888o 8888888888  `88bod8'  `8bd88P'   ║
	echo ╚══════════════════════════════════════════════╝  
	echo.
    echo NOTE:  NVENC presets only work on systems equipped with NVIDIA GPU
    echo        from series GeForce 600 (March 2012) onward.
	echo.
    echo [37mYou have selected the h265 codec.[0m
    echo [37mChoose a preset or customize parameters:[0m
    echo.
    echo [101;93m PRESETS [0m
	echo. && echo.
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
    CHOICE /C 123456789 /T 10 /D 1 /M "Enter your choice:"
    :: Note - list ERRORLEVELS in decreasing order
    IF ERRORLEVEL 10 cls && goto:next
    IF ERRORLEVEL 9 cls && goto:custom_settings
    IF ERRORLEVEL 8 goto:NVENC_h265_ultralow
    IF ERRORLEVEL 7 goto:libx265_ultralow
    IF ERRORLEVEL 6 goto:NVENC_h265_low
    IF ERRORLEVEL 5 goto:libx264_low
    IF ERRORLEVEL 4 goto:NVENC_h265_medium
    IF ERRORLEVEL 3 goto:libx265_medium
    IF ERRORLEVEL 2 goto:NVENC_h265_HQ
    IF ERRORLEVEL 1 goto:libx265_HQ

    :libx265_HQ
        set choice=libx265_HQ
        set count=2
        set preset=h265CRF16_10
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mp4
        CALL :VALIDATE_OUTPUT
        :encode_libx265_HQ
        CALL :VALIDATE_AUDIO
        :encode_libx265_HQ_run
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
            -c:v libx265 ^
            -x265-params log-level=0 ^
            -crf 16 ^
            -preset slow -tune grain ^
            -profile:v main10 ^
            -pix_fmt yuv420p10le ^
            -c:a %codec_audio% ^
            -map_metadata 0 ^
            -movflags use_metadata_tags ^
            -movflags +faststart ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :NVENC_h265_HQ
        set choice=NVENC_h265_HQ
        set count=2
        set preset=NVENCh265_20M
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mp4
        CALL :VALIDATE_OUTPUT
        :encode_NVENC_h265_HQ
        CALL :VALIDATE_AUDIO
        :NVENC_h265_HQ_run
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
            -c:v hevc_nvenc ^
            -rc constqp ^
            -qmin 16 -qmax 51 -qp 20 ^
            -maxrate 20M ^
            -rc-lookahead 4 -keyint_min 1 ^
            -qdiff 20 -qcomp 0.9 ^
            -g 300 ^
            -preset p7 -tune hq ^
            -profile:v main10 -tier high ^
            -pix_fmt p010le ^
            -c:a %codec_audio% ^
            -map_metadata 0 ^
            -movflags use_metadata_tags ^
            -movflags +faststart ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :libx265_medium
        set choice=libx265_medium
        set count=2
        set preset=h265CRF22_10
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mp4
        CALL :VALIDATE_OUTPUT
        :encode_libx265_medium
        CALL :VALIDATE_AUDIO
        :encode_libx265_medium_run
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
            -c:v libx265 ^
            -x265-params log-level=0 ^
            -crf 22 ^
            -preset medium -tune grain ^
            -profile:v main10 ^
            -pix_fmt yuv420p10le ^
            -c:a %codec_audio% ^
            -map_metadata 0 ^
            -movflags use_metadata_tags ^
            -movflags +faststart ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :NVENC_h265_medium
        set choice=NVENC_h265_medium
        set count=2
        set preset=NVENCh265_10M
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mp4
        CALL :VALIDATE_OUTPUT
        :encode_NVENC_h265_medium
        CALL :VALIDATE_AUDIO
        :NVENC_h265_medium_run
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
            -c:v hevc_nvenc ^
            -rc constqp ^
            -b:v 8M -maxrate 10M -bufsize 20M ^
            -maxrate 20M ^
            -rc-lookahead 4 -keyint_min 1 ^
            -qdiff 20 -qcomp 0.9 ^
            -g 300 ^
            -preset p4 -tune hq ^
            -profile:v main ^
            -pix_fmt yuv420p ^
            -c:a %codec_audio% ^
            -map_metadata 0 ^
            -movflags use_metadata_tags ^
            -movflags +faststart ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :libx265_low
        set choice=libx265_low
        set count=2
        set preset=h265CRF28
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mp4
        CALL :VALIDATE_OUTPUT
        :encode_libx265_low
        CALL :VALIDATE_AUDIO
        :encode_libx265_low_run
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
            -c:v libx265 ^
            -x265-params log-level=0 ^
            -crf 28 -maxrate 5M -bufsize 10M ^
            -preset fast ^
            -profile:v main ^
            -pix_fmt yuv420p ^
            -c:a %codec_audio% ^
            -map_metadata 0 ^
            -movflags use_metadata_tags ^
            -movflags +faststart ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :NVENC_h265_low
        set choice=NVENC_h265_low
        set count=2
        set preset=NVENCh265_5M
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mp4
        CALL :VALIDATE_OUTPUT
        :encode_NVENC_h265_low
        CALL :VALIDATE_AUDIO
        :NVENC_h265_low_run
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
            -c:v hevc_nvenc ^
            -rc constqp ^
            -b:v 4M -maxrate 5M -bufsize 10M ^
            -maxrate 20M ^
            -rc-lookahead 4 -keyint_min 1 ^
            -qdiff 20 -qcomp 0.9 ^
            -g 300 ^
            -preset fast -tune hq ^
            -profile:v main ^
            -pix_fmt yuv420p ^
            -c:a %codec_audio% ^
            -map_metadata 0 ^
            -movflags use_metadata_tags ^
            -movflags +faststart ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :libx265_ultralow
        set choice=libx265_ultralow
        set count=2
        set preset=h265CRF32
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mp4
        CALL :VALIDATE_OUTPUT
        :encode_libx265_ultralow
        CALL :VALIDATE_AUDIO
        :encode_libx265_ultralow_run
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
            -c:v libx265 ^
            -x265-params log-level=0 ^
            -crf 32 -maxrate 2M -bufsize 4M ^
            -preset fast ^
            -profile:v main ^
            -pix_fmt yuv420p ^
            -c:a %codec_audio% ^
            -map_metadata 0 ^
            -movflags use_metadata_tags ^
            -movflags +faststart ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :NVENC_h265_ultralow
        set choice=NVENC_h265_ultralow
        set count=2
        set preset=NVENCh265_2M
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mp4
        CALL :VALIDATE_OUTPUT
        :encode_NVENC_h265_ultralow
        CALL :VALIDATE_AUDIO
        :NVENC_h265_ultralow_run
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
            -c:v hevc_nvenc ^
            -rc constqp ^
            -b:v 2M -maxrate 3M -bufsize 6M ^
            -maxrate 20M ^
            -rc-lookahead 4 -keyint_min 1 ^
            -qdiff 20 -qcomp 0.9 ^
            -g 300 ^
            -preset fast -tune hq ^
            -profile:v main ^
            -pix_fmt yuv420p ^
            -c:a %codec_audio% ^
            -map_metadata 0 ^
            -movflags use_metadata_tags ^
            -movflags +faststart ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

:set_ProRes
    cls
    echo.
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
    echo NOTE:  FFMPEG can encode ProRes only up to 10bit precision,
    echo    if you need 12bits you should use another software.
	echo.
    echo [37mYou have selected the h265 codec.[0m
    echo [37mChoose a preset or customize parameters:[0m
    echo.
    echo [101;93m FLAVOURS [0m
	echo. && echo.
	echo [1mSelect the desired ProRes flavour:[0m
	echo [33m[1][0m. Proxy
	echo [33m[2][0m. LT
	echo [33m[3][0m. 422 Standard
	echo [33m[4][0m. 422 HQ
	echo [33m[5][0m. 4444
	echo [33m[6][0m. 4444 XQ
    echo [33m[B][0m. Go back...
	echo.
    CHOICE /C 123456 /T 10 /D 1 /M "Enter your choice:"
	:: Note - list ERRORLEVELS in decreasing order
	IF ERRORLEVEL 6 GOTO:PR4444XQ
	IF ERRORLEVEL 5 GOTO:PR4444
	IF ERRORLEVEL 4 GOTO:PR422HQ
	IF ERRORLEVEL 3 GOTO:PRStandard
	IF ERRORLEVEL 2 GOTO:PRlt
	IF ERRORLEVEL 1 GOTO:PRProxy 

    :PRProxy
        set choice=PRProxy
        set count=2
        set preset=[ProRes Proxy]
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mov
        CALL :VALIDATE_OUTPUT
        :encode_PRProxy
        CALL :VALIDATE_AUDIO
        :PRProxy_run
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
			-c:v prores_ks -profile:v 0 -quant_mat proxy -vendor apl0 ^
			-qscale:v 13 -bits_per_mb 250 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 -movflags use_metadata_tags ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end
    
    :PRlt
        set choice=PRlt
        set count=2
        set preset=[ProRes lt]
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mov
        CALL :VALIDATE_OUTPUT
        :encode_PRlt
        CALL :VALIDATE_AUDIO
        :PRlt_run
        echo.
        echo [101;93m ENCODING... [0m
        echo Input: %input_name%
        echo Output: %OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%
        echo.
        ffmpeg ^
			-hide_banner -loglevel warning -stats ^
			-i "%input%" ^
			-map 0:a -map 0:v:0 ^
			-c:v prores_ks -profile:v 1 -quant_mat lt -vendor apl0 ^
			-qscale:v 11 -bits_per_mb 525 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 -movflags use_metadata_tags ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :PRStandard
        set choice=PRStandard
        set count=2
        set preset=[ProRes 422]
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mov
        CALL :VALIDATE_OUTPUT
        :encode_PRStandard
        CALL :VALIDATE_AUDIO
        :PRStandard_run
        echo.
        echo [101;93m ENCODING... [0m
        echo Input: %input_name%
        echo Output: %OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%
        echo.
        ffmpeg ^
			-hide_banner -loglevel warning -stats ^
			-i "%input%" ^
			-map 0:a -map 0:v:0 ^
			-c:v prores_ks -profile:v 2 -qscale:v 8 -quant_mat auto -vendor apl0 ^
			-bits_per_mb 875 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 -movflags use_metadata_tags ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :PR422HQ
        set choice=PR422HQ
        set count=2
        set preset=[ProRes 422HQ]
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mov
        CALL :VALIDATE_OUTPUT
        :encode_PR422HQ
        CALL :VALIDATE_AUDIO
        :PR422HQ_run
        echo.
        echo [101;93m ENCODING... [0m
        echo Input: %input_name%
        echo Output: %OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%
        echo.
        ffmpeg ^
			-hide_banner -loglevel warning -stats ^
			-i "%input%" ^
			-map 0:a -map 0:v:0 ^
			-c:v prores_ks -profile:v 3 -qscale:v 4 -quant_mat auto -vendor apl0 ^
			-bits_per_mb 1350 ^
			-pix_fmt yuv422p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 -movflags use_metadata_tags ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :PR4444
        set choice=PR4444
        set count=2
        set preset=[ProRes 4444]
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mov
        CALL :VALIDATE_OUTPUT
        :encode_PR4444
        CALL :VALIDATE_AUDIO
        :PR4444_run
        echo.
        echo [101;93m ENCODING... [0m
        echo Input: %input_name%
        echo Output: %OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%
        echo.
        ffmpeg ^
			-hide_banner -loglevel warning -stats ^
			-i "%input%" ^
			-map 0:a -map 0:v:0 ^
			-c:v prores_ks -profile:v 4 -quant_mat auto -vendor apl0 ^
			-bits_per_mb 8000 ^
			-pix_fmt yuva444p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 -movflags use_metadata_tags ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end

    :PR4444XQ
        set choice=PR4444XQ
        set count=2
        set preset=[ProRes 4444XQ]
        set OUTPUT_SFX=
        set OUTPUT_EXT=.mov
        CALL :VALIDATE_OUTPUT
        :encode_PR4444XQ
        CALL :VALIDATE_AUDIO
        :PR4444XQ_run
        echo.
        echo [101;93m ENCODING... [0m
        echo Input: %input_name%
        echo Output: %OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%
        echo.
        ffmpeg ^
			-hide_banner -loglevel warning -stats ^
			-i "%input%" ^
			-map 0:a -map 0:v:0 ^
			-c:v prores_ks -profile:v 5 -quant_mat auto -vendor apl0 ^
			-bits_per_mb 8000 ^
			-pix_fmt yuva444p10le ^
			-c:a %codec_audio% ^
			-map_metadata 0 -movflags use_metadata_tags ^
            "%OUTPUT_DIR%%OUTPUT_NAME%-%preset%%OUTPUT_SFX%%OUTPUT_EXT%"
        goto:end        

:VALIDATE_OUTPUT
        ::  Get FPS
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams v:0 -show_entries stream^=r_frame_rate -of default^=nokey^=1:noprint_wrappers^=1 "%input%"') do set "framerate=%%I"
        
        for /f "tokens=1,2 delims=/" %%a in ("%framerate%") do (
            set /a num1=%%a
            set /a num2=%%b
        )

        set /a fps=num1/num2+1

        IF %fps% LEQ 30 set "level=level 4.1"
        IF %fps% GTR 30 set "level=level 4.2"

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
	::	mp4
    IF %OUTPUT_EXT%==.mp4 goto:VALIDATE_AUDIO_MP4
    IF %OUTPUT_EXT%==.mov goto:VALIDATE_AUDIO_MOV
    
    :VALIDATE_AUDIO_MP4
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "%input%"') do set "codec=%%I"

        if /i "%codec%"=="pcm_alaw" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && EXIT /B
        if /i "%codec%"=="pcm_f32be" set codec_audio="pcm_s32be" && echo Audio codec [30;41m %codec% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && EXIT /B
        if /i "%codec%"=="pcm_f32le" set codec_audio="pcm_s32le" && echo Audio codec [30;41m %codec% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && EXIT /B
        if /i "%codec%"=="pcm_f64be" set codec_audio="pcm_s64be" && echo Audio codec [30;41m %codec% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && EXIT /B
        if /i "%codec%"=="pcm_f32le" set codec_audio="pcm_s64le" && echo Audio codec [30;41m %codec% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && EXIT /B
        if /i "%codec%"=="pcm_mulaw" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && EXIT /B
            
        if /i "%codec%"=="vorbis" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec% [0m is incompatible, will be converted to uncompressed PCM_s16le && EXIT /B
        if /i "%codec%"=="wmav1" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec% [0m is incompatible, will be converted to uncompressed PCM_s16le && EXIT /B
        if /i "%codec%"=="wmav2" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec% [0m is incompatible, will be converted to uncompressed PCM_s16le && EXIT /B

        echo Audio codec [30;42m %codec% [0m is compatible, audio will be copied && set codec_audio=copy && exit /B

    :VALIDATE_AUDIO_MOV
            for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "%input%"') do set "codec=%%I"

            if /i "%codec%"=="opus" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec% [0m is incompatible, will be converted to uncompressed PCM_s16le && EXIT /B
            if /i "%codec%"=="vorbis" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec% [0m is incompatible, will be converted to uncompressed PCM_s16le && EXIT /B
            if /i "%codec%"=="wmav1" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec% [0m is incompatible, will be converted to uncompressed PCM_s16le && EXIT /B
            if /i "%codec%"=="wmav2" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec% [0m is incompatible, will be converted to uncompressed PCM_s16le && EXIT /B

            echo Audio codec [30;42m %codec:~11% [0m is compatible, audio will be copied && set codec_audio=copy && EXIT /B

        )
    :flac
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=bits_per_raw_sample -of default^=noprint_wrappers^=1:nokey^=1 "%input%"') do set "bits_per_raw_sample=%%I"
        set bits=%bits_per_raw_sample%
        set codec_audio="pcm_s%bits%le"
        echo Audio codec [30;41m %codec% [0m is incompatible, will be converted to uncompressed PCM_s%bits%le
        echo MIND THAT flac IS compatible with MP4
        goto:%choice%_run

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

    set OUTPUT_SFX=
	goto:again

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

