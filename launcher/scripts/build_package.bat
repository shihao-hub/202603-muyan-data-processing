@echo off
chcp 65001 >nul
echo.
echo ========================================
echo   Launcher Package Tool v0.1.0
echo ========================================
echo.

set "BUILD_DIR=..\..\build"
set "RELEASE_DIR=%BUILD_DIR%\releases"
set "VERSION=0.1.0"
set "PACKAGE_NAME=material-matcher-launcher-v%VERSION%"

echo [1/5] Preparing build environment...
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"

echo    [OK] Build directory: %BUILD_DIR%
echo.

echo [2/5] Collecting launcher files...
set "PACKAGE_ROOT=%BUILD_DIR%\%PACKAGE_NAME%"
if exist "%PACKAGE_ROOT%" rmdir /s /q "%PACKAGE_ROOT%"
mkdir "%PACKAGE_ROOT%"

:: Copy launcher core files
echo   Copying launcher scripts...
copy "..\launcher.bat" "%PACKAGE_ROOT%\" >nul
copy "..\update.bat" "%PACKAGE_ROOT%\" >nul

echo   Copying template files...
mkdir "%PACKAGE_ROOT%\templates"
copy "..\templates\python312._pth" "%PACKAGE_ROOT%\templates\" >nul
copy "..\templates\mirror_sources.txt" "%PACKAGE_ROOT%\templates\" >nul

echo   Copying user docs...
mkdir "%PACKAGE_ROOT%\docs"
copy "..\docs\user_guide.md" "%PACKAGE_ROOT%\docs\" >nul

echo    [OK] File collection complete
echo.

echo [3/5] Creating directory structure...
mkdir "%PACKAGE_ROOT%\logs" 2>nul
mkdir "%PACKAGE_ROOT%\cache" 2>nul
mkdir "%PACKAGE_ROOT%\cache\downloads" 2>nul
mkdir "%PACKAGE_ROOT%\cache\dependencies" 2>nul
mkdir "%PACKAGE_ROOT%\config" 2>nul

echo    [OK] Directory structure created
echo.

echo [4/5] Creating README file...
echo # Material Matcher Launcher v%VERSION% > "%PACKAGE_ROOT%\README.txt"
echo. >> "%PACKAGE_ROOT%\README.txt"
echo Usage: >> "%PACKAGE_ROOT%\README.txt"
echo 1. Extract this zip to any directory >> "%PACKAGE_ROOT%\README.txt"
echo 2. Double-click launcher.bat to start >> "%PACKAGE_ROOT%\README.txt"
echo. >> "%PACKAGE_ROOT%\README.txt"
echo For detailed guide, see docs\user_guide.md >> "%PACKAGE_ROOT%\README.txt"
echo. >> "%PACKAGE_ROOT%\README.txt"
echo Build time: %date% %time% >> "%PACKAGE_ROOT%\README.txt"

echo    [OK] README created
echo.

echo [5/5] Creating zip package...
cd "%BUILD_DIR%"
powershell -Command "Compress-Archive -Path '%PACKAGE_NAME%' -DestinationPath '%RELEASE_DIR%\%PACKAGE_NAME%.zip' -Force" 2>nul
if errorlevel 1 (
    echo    [FAIL] Package failed
) else (
    echo    [OK] Package complete: %RELEASE_DIR%\%PACKAGE_NAME%.zip
    echo.
    echo   File size:
    for %%F in ("%RELEASE_DIR%\%PACKAGE_NAME%.zip") do echo    - %%~zF bytes
)

echo.
echo ========================================
echo   Package Complete
echo ========================================
echo.
pause