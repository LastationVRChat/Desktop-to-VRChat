@echo off
setlocal enabledelayedexpansion

:: =========================================================
:: VRChat Stream Server Launcher with Cloudflare Tunnel
:: =========================================================

:: Check for MediaMTX
if not exist "C:\vrcstreamserver\mediamtx\mediamtx.exe" (
    set /p mediamtxdir="MediaMTX not found. Enter full path to mediamtx.exe: "
) else (
    set mediamtxdir=C:\vrcstreamserver\mediamtx\mediamtx.exe
)

:: Check for Cloudflared
if not exist "C:\vrcstreamserver\Cloudflared\cloudflared.exe" (
    set /p cloudflareddir="Cloudflared not found. Enter full path to cloudflared.exe: "
) else (
    set cloudflareddir=C:\vrcstreamserver\Cloudflared\cloudflared.exe
)

:: Start MediaMTX
echo Starting MediaMTX...
start "" "%mediamtxdir%"

:: Give MediaMTX a few seconds to initialize
timeout /t 3 /nobreak >nul

:: Ask user about tunnel type
echo.
echo Do you want a temporary or persistent Cloudflare Tunnel?
echo 1. Temporary (random URL every time)
echo 2. Persistent (same URL, Windows service)
set /p tunnelchoice="Enter 1 or 2: "

if "%tunnelchoice%"=="1" (
    echo Starting temporary Cloudflare tunnel...
    :: Start tunnel and capture output to extract HTTPS URL
    for /f "tokens=*" %%i in ('"%cloudflareddir%" tunnel --url http://localhost:8888 2^>^&1') do (
        echo %%i
        echo %%i | findstr /r "https://.*\.trycloudflare\.com" >nul
        if !errorlevel! == 0 (
            set "tunnelurl=%%i"
            :: Copy URL to clipboard
            echo !tunnelurl! | clip
        )
    )
    echo.
    echo Temporary tunnel running. URL copied to clipboard:
    echo !tunnelurl!
) else if "%tunnelchoice%"=="2" (
    echo Persistent tunnel selected.
    set /p tunnelname="Enter a name for your tunnel (e.g., myvrchat): "
    set /p tunnelurl="Enter your desired subdomain (e.g., myvrchat.trycloudflare.com): "

    echo Creating persistent tunnel...
    "%cloudflareddir%" tunnel create %tunnelname%
    "%cloudflareddir%" tunnel route dns %tunnelname% %tunnelurl%
    "%cloudflareddir%" service install

    echo Persistent tunnel setup complete.
    echo Your VRChat HLS URL is:
    echo https://%tunnelurl%/live/vrchat/index.m3u8
    :: Copy to clipboard
    echo https://%tunnelurl%/live/vrchat/index.m3u8 | clip
    echo URL copied to clipboard.
) else (
    echo Invalid option. Exiting.
    pause
    exit /b
)

pause
