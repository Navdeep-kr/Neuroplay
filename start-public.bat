@echo off
setlocal enabledelayedexpansion
title NEUROPLAY - Public Production Server

echo ===============================================================================
echo                      NEUROPLAY PRODUCTION SERVER
echo ===============================================================================
echo.

:: Detect local IPv4 Address for mobile/LAN access
for /f "tokens=4" %%a in ('route print ^| findstr 0.0.0.0 ^| findstr /v "0.0.0.0.*0.0.0.0" 2^>nul') do (
    set LOCAL_IP=%%a
    goto :found_ip
)
:found_ip

echo [*] Server is binding to all network interfaces (0.0.0.0:3000)
echo.
echo     Local PC Access:     http://localhost:3000
if not "%LOCAL_IP%"=="" (
echo     LAN / Mobile Access: http://%LOCAL_IP%:3000
echo     Direct Flutter App:  http://%LOCAL_IP%:3000/app/
)
echo.
echo [*] Press Ctrl+C at any time to stop the server.
echo ===============================================================================
echo.

:: Launch default browser
start "" "http://localhost:3000"

:: Start production server
cd /d "%~dp0website"
pnpm start
