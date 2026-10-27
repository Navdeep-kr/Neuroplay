@echo off
setlocal
title NEUROPLAY - Push to GitHub

:: Ensure Git is in PATH
set "PATH=C:\Users\HP\AppData\Local\Programs\Git\cmd;%PATH%"

echo ===============================================================================
echo                      NEUROPLAY - GITHUB UPLOADER
echo ===============================================================================
echo.
echo Please create a new empty repository on https://github.com/new first.
echo (Do NOT initialize it with README, .gitignore, or license)
echo.
set /p REPO_URL="Paste your GitHub Repository URL (e.g., https://github.com/user/repo.git): "

if "%REPO_URL%"=="" (
    echo [ERROR] No URL provided. Exiting...
    pause
    exit /b 1
)

echo.
echo [*] Connecting to %REPO_URL%...
git remote remove origin 2>nul
git remote add origin %REPO_URL%
git branch -M main

echo [*] Pushing project to GitHub...
echo (If prompted, sign in via the GitHub browser pop-up)
echo.
git push -u origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===============================================================================
    echo [SUCCESS] Your project has been uploaded to GitHub!
    echo ===============================================================================
) else (
    echo.
    echo [!] Push failed. Please check the error message above.
)

echo.
pause
