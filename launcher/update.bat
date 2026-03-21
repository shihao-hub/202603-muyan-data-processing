@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo.
echo ========================================
echo   材料匹配工具代码更新器 v0.1.0
echo ========================================
echo.

:: 设置路径
set "ROOT_DIR=%~dp0..\"
set "APP_DIR=%ROOT_DIR%app"
set "CACHE_DIR=%ROOT_DIR%cache\downloads"
set "LOG_DIR=%ROOT_DIR%logs"
set "CONFIG_DIR=%ROOT_DIR%config"

:: 创建必要的目录
if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"

:: 日志
set "LOG_DATE=%date:~0,4%-%date:~5,2%-%date:~8,2%"
set "LOG_FILE=%LOG_DIR%\update_%LOG_DATE%.log"

echo [%time%] 更新器启动 > "%LOG_FILE%"
echo [1/5] 初始化更新环境...

if not exist "%APP_DIR%" (
    echo   错误: app目录不存在，无法更新
    echo [%time%] 错误: app目录不存在 >> "%LOG_FILE%"
    pause
    exit /b 1
)

echo    ✓ 环境检查通过
echo [%time%] 环境检查完成 >> "%LOG_FILE%"

echo [2/5] 检查版本信息...

:: 读取镜像源配置
set "MIRROR_CONFIG=%CONFIG_DIR%\mirror_sources.txt"
if not exist "%MIRROR_CONFIG%" (
    echo    ℹ 创建默认镜像源配置...
    copy "%~dp0templates\mirror_sources.txt" "%MIRROR_CONFIG%" >nul
    echo    ⚠ 请编辑 %MIRROR_CONFIG% 配置实际仓库地址
)

:: 检查本地版本文件
set "LOCAL_VERSION_FILE=%APP_DIR%\version.txt"
if exist "%LOCAL_VERSION_FILE%" (
    echo    ✓ 本地版本文件存在
    type "%LOCAL_VERSION_FILE%"
) else (
    echo    ⓘ 本地版本文件不存在，创建默认...
    echo # 本地版本信息 > "%LOCAL_VERSION_FILE%"
    echo version_date = %date:~0,4%-%date:~5,2%-%date:~8,2% >> "%LOCAL_VERSION_FILE%"
    echo commit_hash = unknown >> "%LOCAL_VERSION_FILE%"
    echo file_hash = unknown >> "%LOCAL_VERSION_FILE%"
)

echo [%time%] 版本检查完成 >> "%LOG_FILE%"

:: 这里将添加下载和更新逻辑
echo.
echo 更新器框架就绪
echo 后续将添加: 版本检查、代码下载、文件替换等功能
echo.

pause
endlocal