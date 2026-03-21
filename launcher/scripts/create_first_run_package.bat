@echo off
chcp 65001 >nul
echo.
echo ========================================
echo   First Run Package Builder v0.1.0
echo ========================================
echo.

set "BUILD_DIR=..\..\build"
set "RELEASE_DIR=%BUILD_DIR%\releases"
set "VERSION=0.1.0"
set "PACKAGE_NAME=material-matcher-first-run-v%VERSION%"

echo [1/4] Preparing first run package...
set "PACKAGE_ROOT=%BUILD_DIR%\%PACKAGE_NAME%"
if exist "%PACKAGE_ROOT%" rmdir /s /q "%PACKAGE_ROOT%"
mkdir "%PACKAGE_ROOT%"

echo   Copying launcher scripts...
copy "..\launcher.bat" "%PACKAGE_ROOT%\" >nul
copy "..\update.bat" "%PACKAGE_ROOT%\" >nul

echo   Creating necessary directories...
mkdir "%PACKAGE_ROOT%\logs" 2>nul
mkdir "%PACKAGE_ROOT%\cache" 2>nul
mkdir "%PACKAGE_ROOT%\cache\downloads" 2>nul
mkdir "%PACKAGE_ROOT%\config" 2>nul

echo    [OK] Base files prepared
echo.

echo [2/4] Creating first run config file...
echo # First Run Config > "%PACKAGE_ROOT%\config\first_run.ini"
echo [setup] >> "%PACKAGE_ROOT%\config\first_run.ini"
echo needs_python = true >> "%PACKAGE_ROOT%\config\first_run.ini"
echo needs_dependencies = true >> "%PACKAGE_ROOT%\config\first_run.ini"
echo auto_download = true >> "%PACKAGE_ROOT%\config\first_run.ini"

echo    [OK] Config file created
echo.

echo [3/4] Creating first run README...
echo # Material Matcher - First Run Package v%VERSION% > "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo. >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo Welcome to Material Matcher! >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo. >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo This first run package contains: >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 1. Launcher scripts (launcher.bat, update.bat) >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 2. Base directory structure >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 3. Config template >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo. >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo First time setup steps: >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 1. Extract this zip to any directory >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 2. Double-click launcher.bat >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 3. First run will automatically download Python and dependencies (internet required) >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 4. Wait for download to complete, program will start automatically >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"

echo    [OK] README created
echo.

echo [4/4] Packaging...
cd "%BUILD_DIR%"
powershell -Command "Compress-Archive -Path '%PACKAGE_NAME%' -DestinationPath '%RELEASE_DIR%\%PACKAGE_NAME%.zip' -Force" 2>nul
if errorlevel 1 (
    echo    [FAIL] Package failed
) else (
    echo    [OK] First run package created: %RELEASE_DIR%\%PACKAGE_NAME%.zip
    echo.
    echo   Package contents:
    dir "%PACKAGE_ROOT%" /b
)

echo.
pause