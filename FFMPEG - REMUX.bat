::	This script will remux without transcoding its input to the desired output container.
::	
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---ADDITIONAL INFO-----------------------------------------------------------------------------
::  Fancy font is "roman" from https://devops.datenkollektiv.de/banner.txt/index.html
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-12-14 Version 0.3.1
::		- Instead of exit /b, error subroutines now call goto:eof
::	2023-12-14 Version 0.3
::		- Added TS musxer
::		- Added AVI muxer
::		- Full rewrite, now multi-file input gets interpreted correctly
::	2023-12-07 Version 0.2
::		- Added MOV muxer
::	2023-12-06 Version 0.1
::		- Added MP4 muxer
::		- Initial release
::	-----------------------------------------------------------------------------------------------
::	This script will remux without transcoding its input to the desired output container.
::	
::	---LICENSE-------------------------------------------------------------------------------------
::	What follows is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007
::
::	---ADDITIONAL INFO-----------------------------------------------------------------------------
::  Fancy font is "roman" from https://devops.datenkollektiv.de/banner.txt/index.html
::
::	---CHANGELOG-----------------------------------------------------------------------------------
::	2023-12-13 Version 0.1
::		- Initial release
::	-----------------------------------------------------------------------------------------------
if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )

@echo off
setlocal EnableDelayedExpansion
chcp 65001
cls

set file_count=0

:again
set /A file_count+=1
if NOT DEFINED jump goto:next

:jump
    set OUTPUT_SFX=
    timeout /t 2 > nul
    shift
    if "%~1" == "" goto:done

:next
    set jump=yes

	CALL:banner
	echo.
	CALL:info
	echo.

    if DEFINED mux goto:%mux% 

	echo [101;93m CONTAINER SELECTION [0m
	echo [1mSelect the desired output container:[0m
	echo [33m[1][0m. .mp4 (MPEG-4 Part 14)
	echo [33m[2][0m. .mov (QuickTime File Format)
	echo [33m[3][0m. .mkv (Matroska)
	echo [33m[4][0m. .avi (Audio Video Interleave)
	echo [33m[5][0m. .ts  (MPEG transport stream )
	echo.
	
	CHOICE /C 12345 /M "Enter your choice:"
	:: Note - list ERRORLEVELS in decreasing order
	IF ERRORLEVEL 5 goto:ts
	IF ERRORLEVEL 4 goto:avi
	IF ERRORLEVEL 3 goto:mkv
	IF ERRORLEVEL 2 goto:mov
	IF ERRORLEVEL 1 goto:mp4

    :mp4
		cls
		set mux=mp4
		set file=%~1
		set INPUT_EXT=%~x1
		set OUTPUT_EXT=.mp4
		set count=2
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_SFX=
		set additional=
		CALL:banner
		echo.
		CALL:info
		echo.
		CALL :VALIDATE_OUTPUT

		::	VALIDATE VIDEO
		for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams v:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "%file%"') do set "video_codec=%%I"
		if /i "%video_codec%"=="prores" goto:error_video_codec

		::	VALIDATE AUDIO
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%file%"') do set "codec=%%I"
	
		if /i "%codec:~11%"=="pcm_alaw" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && goto:mux_mp4
		if /i "%codec:~11%"=="pcm_f32be" set codec_audio="pcm_s32be" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && goto:mux_mp4
		if /i "%codec:~11%"=="pcm_f32le" set codec_audio="pcm_s32le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && goto:mux_mp4
		if /i "%codec:~11%"=="pcm_f64be" set codec_audio="pcm_s64be" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && goto:mux_mp4
		if /i "%codec:~11%"=="pcm_f32le" set codec_audio="pcm_s64le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && goto:mux_mp4
		if /i "%codec:~11%"=="pcm_mulaw" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && goto:mux_mp4
		
		if /i "%codec:~11%"=="vorbis" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && goto:mux_mp4
		if /i "%codec:~11%"=="wmav1" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && goto:mux_mp4
		if /i "%codec:~11%"=="wmav2" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && goto:mux_mp4

		echo Audio codec [30;42m %codec:~11% [0m is compatible, audio will be copied && set codec_audio=copy

		:mux_mp4
	    	echo.
		    echo [101;93m MUXING... [0m
            echo File #%file_count%
	    	echo Input: %~nx1
	    	echo Output: %OUTPUT_NAME%%OUTPUT_SFX%%OUTPUT_EXT%
	    	echo.
	    	ffmpeg ^
    			-hide_banner -loglevel warning -stats ^
	    		-hwaccel auto ^
		    	-i "%~1" ^
    			-map 0 ^
	    		-c:v copy ^
		    	-c:a %codec_audio% ^
			    -map_metadata 0 -movflags use_metadata_tags ^
			    "%OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_SFX%%OUTPUT_EXT%"
			
        	if NOT ["%errorlevel%"]==["0"] set print_error_level=%errorlevel% && goto:error
			
        goto:again
    
    :mov
		cls
        set mux=mov
		set file=%~1
		set INPUT_EXT=%~x1
		set OUTPUT_EXT=.mov
		set count=2
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_SFX=
		set additional=
		::cls
		CALL:banner
		echo.
		CALL:info
		echo.
		CALL :VALIDATE_OUTPUT

		::	VALIDATE VIDEO
		for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams v:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "%file%"') do set "video_codec=%%I"
		if /i "%video_codec%"=="av1" goto:error_video_codec
		if /i "%video_codec%"=="vp9" goto:error_video_codec
		if /i "%video_codec%"=="vp8" goto:error_video_codec
		if /i "%video_codec%"=="realvideo" goto:error_video_codec
		if /i "%video_codec%"=="vp6" goto:error_video_codec
		if /i "%video_codec%"=="huffyuv" goto:error_video_codec

		::	VALIDATE AUDIO
    	for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%file%"') do set "codec=%%I"
	
    	if /i "%codec:~11%"=="flac" goto:flac
		if /i "%codec:~11%"=="opus" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo MIND THAT opus IS compatible with MP4 && goto:mux_mov
		if /i "%codec:~11%"=="vorbis" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && goto:mux_mov
		if /i "%codec:~11%"=="wmav1" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && goto:mux_mov
		if /i "%codec:~11%"=="wmav2" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && goto:mux_mov

		echo Audio codec [30;42m %codec:~11% [0m is compatible, audio will be copied && set codec_audio=copy

		:mux_mov
	    	echo.
		    echo [101;93m MUXING... [0m
            echo File #%file_count%
			echo Input: %~nx1
			echo Output: %OUTPUT_NAME%%OUTPUT_SFX%%OUTPUT_EXT%
			echo.
			ffmpeg ^
				-hide_banner -loglevel warning -stats ^
				-hwaccel auto ^
				-i "%~1" ^
				-map 0 ^
				-c:v copy ^
				-c:a %codec_audio% ^
				-map_metadata 0 -movflags use_metadata_tags ^
				"%OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_SFX%%OUTPUT_EXT%"
		
        	if NOT ["%errorlevel%"]==["0"] set print_error_level=%errorlevel% && goto:error
				
			goto:again
	
    :mkv
		cls
        set mux=mkv
		set file=%~1
		set INPUT_EXT=%~x1
		set OUTPUT_EXT=.mkv
		set count=2
	    set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_SFX=
		set additional=
		::cls
		CALL:banner
		echo.
		CALL:info
		echo.
		CALL :VALIDATE_OUTPUT

		::	VALIDATE VIDEO
		for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams v:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "%file%"') do set "video_codec=%%I"
		if /i "%video_codec%"=="prores" goto:error_video_codec

		::	VALIDATE AUDIO
		::for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%file%"') do set "codec=%%I"

		::if /i "%codec:~11%"=="flac" goto:flac
		::if /i "%codec:~11%"=="opus" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo MIND THAT opus IS compatible with MP4 && goto:mux_mkv
		::if /i "%codec:~11%"=="vorbis" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && goto:mux_mkv
		::if /i "%codec:~11%"=="wmav1" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && goto:mux_mkv
		::if /i "%codec:~11%"=="wmav2" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && goto:mux_mkv

		::echo Audio codec [30;42m %codec:~11% [0m is compatible, audio will be copied && set codec_audio=copy
		set codec_audio=copy

		:mux_mkv
            echo.
            echo [101;93m MUXING... [0m
            echo File #%file_count%
            echo Input: %~nx1
            echo Output: %OUTPUT_NAME%%OUTPUT_SFX%%OUTPUT_EXT%
            echo.
            ffmpeg ^
                -hide_banner -loglevel warning -stats ^
                -hwaccel auto ^
                -i "%~1" ^
                -map 0 ^
                -c:v copy ^
                -c:a %codec_audio% ^
                -map_metadata 0 -movflags use_metadata_tags ^
                "%OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_SFX%%OUTPUT_EXT%"

            if NOT ["%errorlevel%"]==["0"] set print_error_level=%errorlevel% && goto:error
                
            goto:again

    :avi
		cls
		set mux=avi
		set file=%~1
		set INPUT_EXT=%~x1
		set OUTPUT_EXT=.avi
		set count=2
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_SFX=
		set additional=
		CALL:banner
		echo.
		CALL:info
		echo.
		CALL :VALIDATE_OUTPUT

		::	VALIDATE VIDEO
		for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams v:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "%file%"') do set "video_codec=%%I"
		if /i "%video_codec%"=="av1" goto:error_video_codec
		if /i "%video_codec%"=="mvc" goto:error_video_codec
		if /i "%video_codec%"=="prores" goto:error_video_codec
		if /i "%video_codec%"=="h264" set "additional=-bsf:v h264_mp4toannexb"
	
		::	VALIDATE AUDIO
        for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%file%"') do set "codec=%%I"
	
		if /i "%codec:~11%"=="eac3" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && goto:mux_avi
		if /i "%codec:~11%"=="vorbis" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && goto:mux_avi

		echo Audio codec [30;42m %codec:~11% [0m is compatible, audio will be copied && set codec_audio=copy

		:mux_avi
	    	echo.
		    echo [101;93m MUXING... [0m
            echo File #%file_count%
	    	echo Input: %~nx1
	    	echo Output: %OUTPUT_NAME%%OUTPUT_SFX%%OUTPUT_EXT%
	    	echo.
	    	ffmpeg ^
    			-hide_banner -loglevel warning -stats ^
	    		-hwaccel auto ^
		    	-i "%~1" ^
    			-map 0 ^
	    		-c:v copy %additional% ^
		    	-c:a %codec_audio% ^
			    -map_metadata 0 -movflags use_metadata_tags ^
			    "%OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_SFX%%OUTPUT_EXT%"
			
        	if NOT ["%errorlevel%"]==["0"] set print_error_level=%errorlevel% && goto:error
			
        goto:again

    :ts
		cls
        set mux=ts
		set file=%~1
		set INPUT_EXT=%~x1
		set OUTPUT_EXT=.ts
		set count=2
		set OUTPUT_DIR=%~dp1
		set OUTPUT_NAME=%~n1
		set OUTPUT_SFX=
		set additional=
		::cls
		CALL:banner
		echo.
		CALL:info
		echo.
		CALL :VALIDATE_OUTPUT

		::	VALIDATE VIDEO
		for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams v:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "%file%"') do set "video_codec=%%I"
		if /i "%video_codec%"=="av1" goto:error_video_codec
		if /i "%video_codec%"=="dv" goto:error_video_codec
		if /i "%video_codec%"=="vc1" goto:error_video_codec
		if /i "%video_codec%"=="huffyuv" goto:error_video_codec
		if /i "%video_codec%"=="mjpeg" goto:error_video_codec
		if /i "%video_codec%"=="mvc" goto:error_video_codec
		if /i "%video_codec%"=="prores" goto:error_video_codec
		if /i "%video_codec%"=="realvideo" goto:error_video_codec
		if /i "%video_codec%"=="vp6" goto:error_video_codec
		if /i "%video_codec%"=="vp8" goto:error_video_codec
		if /i "%video_codec%"=="vp9" goto:error_video_codec
		if /i "%video_codec%"=="h264" set "additional=-bsf:v h264_mp4toannexb"
		
		::	VALIDATE AUDIO
    	for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1 "%file%"') do set "codec=%%I"
	
		if /i "%codec:~11%"=="alac" goto:flac
    	if /i "%codec:~11%"=="flac" goto:flac
		if /i "%codec:~11%"=="eac3" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && goto:mux_ts
		if /i "%codec:~11%"=="dts" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && goto:mux_ts
		if /i "%codec:~11%"=="vorbis" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && goto:mux_ts
		if /i "%codec:~11%"=="wmav1" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && goto:mux_ts
		if /i "%codec:~11%"=="wmav2" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && goto:mux_ts
		
		if /i "%codec:~11%"=="pcm_alaw" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && goto:mux_ts
		if /i "%codec:~11%"=="pcm_f32be" set codec_audio="pcm_s32be" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && goto:mux_ts
		if /i "%codec:~11%"=="pcm_f32le" set codec_audio="pcm_s32le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && goto:mux_ts
		if /i "%codec:~11%"=="pcm_f64be" set codec_audio="pcm_s64be" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && goto:mux_ts
		if /i "%codec:~11%"=="pcm_f32le" set codec_audio="pcm_s64le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && goto:mux_ts
		if /i "%codec:~11%"=="pcm_mulaw" set codec_audio="pcm_s16le" && echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s16le && echo WARNING: THERE WILL BE LOSSES && goto:mux_ts
		
		echo Audio codec [30;42m %codec:~11% [0m is compatible, audio will be copied && set codec_audio=copy

		:mux_ts
	    	echo.
		    echo [101;93m MUXING... [0m
            echo File #%file_count%
			echo Input: %~nx1
			echo Output: %OUTPUT_NAME%%OUTPUT_SFX%%OUTPUT_EXT%
			echo.
			ffmpeg ^
				-hide_banner -loglevel warning -stats ^
				-hwaccel auto ^
				-i "%~1" ^
				-map 0:v:0 ^
				-c:v copy ^
				-c:a %codec_audio% ^
				-map_metadata 0 -movflags use_metadata_tags ^
				"%OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_SFX%%OUTPUT_EXT%"
		
        	if NOT ["%errorlevel%"]==["0"] set print_error_level=%errorlevel% && goto:error
				
			goto:again

	:flac
		::	Get audio bits per sample
		for /F "delims=" %%I in ('@ffprobe.exe -v error -select_streams a:0 -show_entries stream^=bits_per_raw_sample -of default^=noprint_wrappers^=1 "%file%"') do set "bits_per_raw_sample=%%I"
		set bits=%bits_per_raw_sample:~20%%
		set codec_audio="pcm_s%bits%le"
		echo Audio codec [30;41m %codec:~11% [0m is incompatible, will be converted to uncompressed PCM_s%bits%le
		echo MIND THAT flac IS compatible with MP4 
		goto:mux_mov

:VALIDATE_OUTPUT
    echo.
	IF /I %INPUT_EXT%=="%OUTPUT_EXT%" goto:error_same_container

	echo.
	set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_EXT%"
	echo [101;93m VALIDATING OUTPUT... [0m
		IF EXIST %OUTPUT_FILE% (
			echo Output [30;41m UNAVAILABLE [0m && goto:errorfile
		) ELSE ( 
			echo Output [30;42m AVAILABLE [0m && EXIT /B
		)

	:errorfile
		set OUTPUT_SFX= (%count%)
		set OUTPUT_FILE="%OUTPUT_DIR%%OUTPUT_NAME%%OUTPUT_SFX%%OUTPUT_EXT%"
		IF EXIST %OUTPUT_FILE% (
  	      set /A count+=1 && set OUTPUT_SFX= (%count%) && goto :errorfile
 	   ) ELSE ( 
			EXIT /B
		)

	:error_choice
		echo.
		echo [93mA file with the same name as the requested conversion output already exists.
		echo [1mSelect the desired action:[0m
		echo [33m[1][0m. Overwrite output (will ask again for confirmation)
		echo [33m[2][0m. Rename output %OUTPUT_NAME%[30;43m-(%count%)[0m.%OUTPUT_EXT%[0m
		echo [33m[3][0m. Abort the operation (will be auto-selected in 30s)
		echo.
	
		CHOICE /C 123 /T 30 /D 3 /M "Enter your choice:"
		:: Note - list ERRORLEVELS in decreasing order
		IF ERRORLEVEL 3 goto :abort
		IF ERRORLEVEL 2 goto :%OUTPUT_EXT:~1%
		IF ERRORLEVEL 1 EXIT /B

	:error_same_container
		set countdown=5
		CALL:container_cycle
		:container_cycle
			cls
			CALL:banner
			echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo.
			echo [93mLooks like input is already in a %OUTPUT_EXT% container.[0m
			echo [93m%OUTPUT_NAME%%OUTPUT_SFX%%OUTPUT_EXT% will be skipped.[0m
			echo [93mThis script will automatically proceed to the next file in queue in %countdown%s.[0m
			set /A countdown-=1
			timeout /t 1 > nul
			if "%countdown%"=="0" shift && echo "%~1" && pause && goto:advance 
			goto:container_cycle
			echo.

	:error_video_codec
		set countdown=5
		CALL:video_codec_cycle
		:video_codec_cycle
			cls
			CALL:banner
			echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo.
			echo [93mVideo codec [30;41m %video_codec% [93m is incompatible.[0m
			echo [93m%OUTPUT_NAME%%OUTPUT_SFX%%INPUT_EXT% will be skipped.[0m
			echo [93mThis script will automatically proceed to the next file in queue in %countdown%s.[0m
			set /A countdown-=1
			timeout /t 1 > nul
			if "%countdown%"=="0" goto:advance 
			goto:video_codec_cycle
			echo.

	:advance
		shift
		if "%~1" == "" pause && goto:abort
		if /I "%OUTPUT_EXT%"=".mkv" goto:mkv
		if /I "%OUTPUT_EXT%"=".mov" goto:mov
		if /I "%OUTPUT_EXT%"=".mp4" goto:mp4
		goto:%container%

:error
	echo [93mThere was an error. Please check your input file.[0m
	echo Errorlevel is %print_error_level%
	pause
	goto:eof

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
		if "%countdown%"=="0" goto:eof
		goto:end_cycle

:abort
	set countdown=5
	CALL:abort_cycle
	:abort_cycle
		cls
		CALL:banner
		echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo. && echo.
		echo [93mProcess aborted.[0m
		set /A countdown-=1
		timeout /t 1 > nul
		if "%countdown%"=="0" goto:eof
		goto:abort_cycle

:banner
	echo ╔════════════════════════════════════════════════════════════════════╗
	echo ║  ooooooooo.                                                        ║
	echo ║  `888   `Y88.                                                      ║
	echo ║   888   .d88'  .ooooo.  ooo. .oo.  .oo.   oooo  oooo  oooo    ooo  ║
	echo ║   888ooo88P'  d88' `88b `888P"Y88bP"Y88b  `888  `888   `88b..8P'   ║
	echo ║   888`88b.    888ooo888  888   888   888   888   888     Y888'     ║
	echo ║   888  `88b.  888    .o  888   888   888   888   888   .o8"'88b    ║
	echo ║  o888o  o888o `Y8bod8P' o888o o888o o888o  `V88V"V8P' o88'   888o  ║
	echo ╚════════════════════════════════════════════════════════════════════╝
	echo.
    echo - This script is distributed under the GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007 -
	exit /B

:info
	echo NOTE: 	Not all containers support every audio codec. You'll be warned if transcoding is required.
	echo 		This script prioritizes preserving untouched video tracks.
	echo 		If input video codec mismatches output container, the operation aborts.
	EXIT /B

:eof
exit 0