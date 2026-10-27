@echo off
setlocal enabledelayedexpansion
title NEUROPLAY - GitHub Uploader

echo ===============================================================================
echo                      UPLOAD NEUROPLAY TO GITHUB
echo ===============================================================================
echo.

:: Ensure Git is in PATH
set PATH=C:\Users\HP\AppData\Local\Programs\Git\cmd;%PATH%

:: Verify Git is accessible
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Git is not detected on your system.
    echo Please install Git from https://git-scm.com/
    pause
    exit /b 1
)

cd /d "%~dp0"

echo Current Git Branch: main
echo.
set /p REPO_URL="Paste your GitHub Repository URL (e.g. https://github.com/username/neuroplay.git): "

if "%REPO_URL%"=="" (
    echo.
    echo [ERROR] No URL provided. Exiting...
    pause
    exit /b 1
)

echo.
echo [*] Setting up remote origin...
git remote remove origin 2>nul
git remote add origin %REPO_URL%

echo [*] Pushing branch 'main' to GitHub...
echo.
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo ===============================================================================
    echo [SUCCESS] NEUROPLAY has been successfully uploaded to your GitHub repository!
    echo ===============================================================================
) else (
    echo.
    echo ===============================================================================
    echo [NOTE] If GitHub asked you to sign in, complete the browser login prompt.
    echo If it failed due to authentication, you can also paste a Personal Access Token.
    echo ===============================================================================
)

echo.
pause
