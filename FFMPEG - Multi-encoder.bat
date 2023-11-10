::What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
::Extract audio only and convert to flac
@echo off
chcp 65001
cls

:next
	echo.
	echo [92m╔══════════════════════════════════════════════════════╗
	echo [92m║====================== WELCOME! ======================║
	echo [92m╚══════════════════════════════════════════════════════╝[0m
	echo.
    echo [37mLet's start by choosing some settings:[0m
    echo.
    echo [101;93m CODECS [0m
	echo. && echo.
    ::
    echo [1mAvailable codecs:[0m
    echo [33m[1][0m. h264 (x264, NVENC)
	echo [33m[2][0m. h265 (x265, NVENC)
    echo [33m[3][0m. AV1 (SVT-AV1)
    echo [33m[4][0m. ProRes
	echo [33m[5][0m. FFV1
	echo.
	::
    CHOICE /C 12345 /M "Enter your choice:"
    :: Note - list ERRORLEVELS in decreasing order
    IF ERRORLEVEL 5 GOTO:set_FFV1
    IF ERRORLEVEL 4 GOTO:set_ProRes
    IF ERRORLEVEL 3 GOTO:set_AV1
    IF ERRORLEVEL 2 GOTO:set_h265
    IF ERRORLEVEL 1 GOTO:set_h264
    
:set_h264
    title FFMPEG - Setting up h264 conversion
    cls
    echo.
    echo [92m╔══════════════════════════════════════════════════════╗
	echo [92m║======================== h264 ========================║
	echo [92m╚══════════════════════════════════════════════════════╝[0m
	echo.
    echo [37mYou have selected the h264 codec.[0m
    echo [37mChoose a preset or customize parameters:[0m
    echo.
    echo [101;93m PRESETS [0m
	echo. && echo.
    ::
    ::  echo [1mSelect the desired codec:[0m
    ::  echo [1mThe default [1] will be automatically selected in 10s[0m
    echo [33m[1][0m. HQ (libx264, preset slow, CRF16) [SLOWEST] [DEFAULT]
    echo [33m[2][0m. HQ (NVENC, 20mbps) [SLOW]
    echo [33m[3][0m. Medium (libx264, preset medium, CRF22)
    echo [33m[4][0m. Medium (NVENC, 10mbps)
	echo [33m[5][0m. Low (libx264, preset fast, CRF 28) [FAST]
    echo [33m[6][0m. Low (NVENC, 5mbps) [FASTER]
    echo [33m[7][0m. Ultralow (libx264, preset fast, 2mbps) [FASTER]
    echo [33m[8][0m. Ultralow (NVENC, 2mbps) [FASTEST]
    echo [33m[8][0m. Go back...
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
                    set tune="hq" && ^
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
                    set tune="film" && ^
                    set bitrate_control="-crf 32 -maxrate 2M -bufsize 4M" && ^
                    set profile="-profile:v high" && ^
                    set level="-level 4.1" && ^
                    set pix_fmt="yuv420p" && ^
                    set output_suffix="-h264CRF32-AAC256k" && ^
                    set extension="mp4" && ^
                    && set extension="mp4" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 6 title FFMPEG - Converting "%~1" NVENC single pass 5mbps && ^
                    set encoder="h264_nvenc" && ^
                    set preset="fast" && ^
                    set tune="hq" && ^
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
                    set tune="film" && ^
                    set bitrate_control="-crf 28 -maxrate 5M -bufsize 10M" && ^
                    set profile="-profile:v high" && ^
                    set level="-level 4.1" && ^
                    set pix_fmt="yuv420p" && ^
                    set output_suffix="-h264CRF28-AAC256k" && ^
                    set extension="mp4" && ^
                    && set extension="mp4" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 4 title FFMPEG - Converting "%~1" NVENC single pass 10mbps && ^
                    set encoder="h264_nvenc" && ^
                    set preset="medium" && ^
                    set tune="hq" && ^
                    set bitrate_control="-b:v 8M -maxrate 10M -bufsize 20M -rc-lookahead 4 -keyint_min 1 -qdiff 20 -qcomp 0.9 -g 300" && ^
                    set profile="-profile:v high" && ^
                    set level="-level 4.1" && ^
                    set pix_fmt="yuv420p" && ^
                    set output_suffix="-NVENCh264_10M-AAC256k" && ^
                    set extension="mp4" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 3 title FFMPEG - Converting "%~1" libx264 medium CRF22 && ^
                    set encoder="libx264 -x264opts opencl" && ^
                    set preset="medium" && ^
                    set tune="hq" && ^
                    set bitrate_control="-crf 22" && ^
                    set profile="-profile:v high" && ^
                    set level="-level 4.1" && ^
                    set pix_fmt="yuv420p" && ^
                    set output_suffix="-h264CRF22-AAC256k" && ^
                    set extension="mp4" && ^
                    && set extension="mp4" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 2 title FFMPEG - Converting "%~1" NVENC single pass 20mbps && ^
                    set encoder="h264_nvenc" && ^
                    set preset="p7" && ^
                    set tune="hq" && ^
                    set bitrate_control="-rc constqp -qmin 17 -qmax 51 -qp 20 -maxrate 20M -rc-lookahead 4 -keyint_min 1 -qdiff 20 -qcomp 0.9 -g 300" && ^
                    set profile="-profile:v high" && ^
                    set level="-level 5.2" && ^
                    set pix_fmt="yuv420p" && ^
                    set output_suffix="-NVENCh264_20M-AAC256k" && ^
                    set extension="mp4" && ^
                    set title_pass2= "" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 1 title FFMPEG - Converting "%~1" to High Quality h264 video with 256kbps AAC audio && ^
                    set encoder="libx264 -x264opts opencl" && ^
                    set preset="slow" && ^
                    set tune="film" && ^
                    set bitrate_control="-crf 16" && ^
                    set profile="-profile:v high" && ^
                    set level="-level 5.2" && ^
                    set pix_fmt="yuv420p" && ^
                    set output_suffix="-h264CRF16-AAC256k" && ^
                    set extension="mp4" && ^
                    && set extension="mp4" && ^
                    goto:encode_single_pass

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
    echo [33m[9][0m. Custom settings
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
                    set tune="hq" && ^
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
                    set tune="film" && ^
                    set bitrate_control="-crf 32 -maxrate 2M -bufsize 4M" && ^
                    set profile="-profile:v high" && ^
                    set level="" && ^
                    set pix_fmt="yuv420p10le" && ^
                    set output_suffix="-h265CRF32-AAC256k" && ^
                    set extension="mp4" && ^
                    && set extension="mp4" && ^
                    goto:encode_single_pass
    IF ERRORLEVEL 6 title FFMPEG - Converting "%~1" NVENC single pass 5mbps && ^
                    set encoder="hevc_nvenc" && ^
                    set preset="fast" && ^
                    set tune="hq" && ^
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
                    && set extension="mp4" && ^
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
                    && set extension="mp4" && ^
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
                    && set extension="mp4" && ^
                    goto:encode_single_pass

:set_AV1
    title AV1 encoding is Work In Progess, will be added in future releases
    echo AV1 encoding is not implemented yet, will be in future releases.
    echo Press any key to return to main menu
    pause >NUL
    goto:next
:set_ProRes
    title ProRes encoding is Work In Progess
    echo ProRes encoding is not implemented yet, will be in future releases.
    echo Press any key to return to main menu
    pause >NUL
    goto:next
:set_FFV1
    title FFV1 encoding is Work In Progess
    echo FFV1 encoding is not implemented yet, will be in future releases.
    echo Press any key to return to main menu
    pause >NUL
    goto:next
:encode_single_pass
    ffmpeg ^
        -hide banner ^
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
        -hide banner ^
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
        -hide banner ^
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


