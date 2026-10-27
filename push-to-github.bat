@echo off
setlocal
title NEUROPLAY - Push to GitHub

:: Ensure Git is in PATH
set "PATH=C:\Users\HP\AppData\Local\Programs\Git\cmd;%PATH%"

echo ===============================================================================
echo                      NEUROPLAY - PUSH TO GITHUB
echo ===============================================================================
echo.
echo [*] Target Repository: https://github.com/Navdeep-kr/Neuroplay.git
echo.
git remote remove origin 2>nul
git remote add origin https://github.com/Navdeep-kr/Neuroplay.git
git branch -M main

echo [*] Pushing project to GitHub...
echo (A GitHub login window may pop up in your browser. Please click "Sign in / Authorize")
echo.

git push -u origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===============================================================================
    echo [SUCCESS] Your project has been uploaded to GitHub successfully!
    echo View it at: https://github.com/Navdeep-kr/Neuroplay
    echo ===============================================================================
) else (
    echo.
    echo [!] Push failed or was cancelled. If you see an authentication prompt, please sign in.
)

echo.
pause
