@echo off
setlocal enabledelayedexpansion

:: =========================================================
:: VRChat Stream Server Launcher with Cloudflare Tunnel
:: See readme.md for full setup (OBS, MediaMTX, VB-Cable, Cloudflared)
:: =========================================================

title VRChat Stream Launcher

:: --- Base path: use script directory so it works from shortcuts or any CWD ---
set "BASEDIR=%~dp0"
if "%BASEDIR:~-1%"=="\" set "BASEDIR=%BASEDIR:~0,-1%"

:: --- Paths to executables ---
set "mediamtxdir=%BASEDIR%\mediamtx\mediamtx.exe"
set "cloudflareddir=%BASEDIR%\Cloudflared\cloudflared.exe"

:: --- Verify MediaMTX exists ---
:check_mediamtx
if not exist "%mediamtxdir%" (
    echo MediaMTX not found at: %mediamtxdir%
    echo Expected layout: %BASEDIR%\mediamtx\mediamtx.exe
    set /p "mediamtxdir=Enter full path to mediamtx.exe: "
    if "!mediamtxdir!"=="" (
        echo No path entered. Exiting.
        pause
        exit /b 1
    )
    if not exist "!mediamtxdir!" (
        echo Path invalid or file missing. Try again.
        goto check_mediamtx
    )
)

:: --- Verify Cloudflared exists ---
:check_cloudflared
if not exist "%cloudflareddir%" (
    echo Cloudflared not found at: %cloudflareddir%
    echo Expected layout: %BASEDIR%\Cloudflared\cloudflared.exe
    set /p "cloudflareddir=Enter full path to cloudflared.exe: "
    if "!cloudflareddir!"=="" (
        echo No path entered. Exiting.
        pause
        exit /b 1
    )
    if not exist "!cloudflareddir!" (
        echo Path invalid or file missing. Try again.
        goto check_cloudflared
    )
)

:: --- MediaMTX working directory (so mediamtx.yml is found) ---
for %%I in ("%mediamtxdir%") do set "mediamtxworkdir=%%~dpI"
if "%mediamtxworkdir:~-1%"=="\" set "mediamtxworkdir=%mediamtxworkdir:~0,-1%"

:: --- Start MediaMTX ---
echo Starting MediaMTX from %mediamtxworkdir%...
start "" /d "%mediamtxworkdir%" "%mediamtxdir%"
timeout /t 3 /nobreak >nul
echo MediaMTX started. Test locally at: http://127.0.0.1:8888/live/vrchat/index.m3u8
echo.

:: --- Temporary tunnel (runs in this window, no log file) ---
echo Starting temporary Cloudflare tunnel...
echo.
echo ================================================================================
echo   FOR VRChat / OBS - YOUR FULL STREAM URL IS:
echo.
echo   [the https URL in the box below] + /live/vrchat/index.m3u8
echo.
echo   Example: https://xxxxx.trycloudflare.com/live/vrchat/index.m3u8
echo.
echo   Copy the URL from the box below, then add /live/vrchat/index.m3u8 to the end.
echo ================================================================================
echo.
echo Close this window when you are done streaming to stop the tunnel.
echo.
"%cloudflareddir%" tunnel --url http://localhost:8888

:end
echo.
pause
exit /b 0
