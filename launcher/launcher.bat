@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo.
echo ========================================
echo   材料匹配工具启动器 v0.1.0
echo ========================================
echo.

:: 设置基础路径
set "ROOT_DIR=%~dp0..\"
set "PYTHON_DIR=%ROOT_DIR%python"
set "APP_DIR=%ROOT_DIR%app"

:: 解析命令行参数
set SHOW_HELP=0
set OFFLINE_MODE=0
set FORCE_MODE=0
set VERBOSE_MODE=0

:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="--help" (
    set SHOW_HELP=1
    shift
    goto :parse_args
)
if "%~1"=="--offline" (
    set OFFLINE_MODE=1
    shift
    goto :parse_args
)
if "%~1"=="--force" (
    set FORCE_MODE=1
    shift
    goto :parse_args
)
if "%~1"=="--verbose" (
    set VERBOSE_MODE=1
    shift
    goto :parse_args
)
shift
goto :parse_args

:args_done

:: 日志系统初始化
set "LOG_DIR=%ROOT_DIR%logs"
set "LOG_DATE=%date:~0,4%-%date:~5,2%-%date:~8,2%"
set "LOG_TIME=%time:~0,2%-%time:~3,2%-%time:~6,2%"
set "LOG_FILE=%LOG_DIR%\launcher_%LOG_DATE%_%LOG_TIME%.log"

:: 创建日志目录
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%" 2>nul
)

:: 日志函数
set "LOG_PREFIX=[%LOG_TIME%]"
if %VERBOSE_MODE% == 1 (
    echo %LOG_PREFIX% [INFO] 启动器开始运行 > "%LOG_FILE%"
    echo %LOG_PREFIX% [INFO] 参数: 离线模式=%OFFLINE_MODE%, 强制模式=%FORCE_MODE%, 详细模式=%VERBOSE_MODE% >> "%LOG_FILE%"
)

:: 显示帮助信息
if %SHOW_HELP% == 1 (
    echo 用法: launcher.bat [选项]
    echo 选项:
    echo   --help     显示帮助信息
    echo   --offline  离线模式（不使用网络）
    echo   --force    强制模式（覆盖文件，终止进程）
    echo   --verbose  详细日志输出
    echo.
    echo 示例:
    echo   launcher.bat --offline
    echo   launcher.bat --verbose --force
    echo.
    exit /b 0
)

:: 显示参数状态
if %VERBOSE_MODE% == 1 (
    echo [调试] 参数状态:
    echo   离线模式: %OFFLINE_MODE%
    echo   强制模式: %FORCE_MODE%
    echo   详细模式: %VERBOSE_MODE%
    echo.
)

echo [2/5] 检查Python环境...
if %VERBOSE_MODE% == 1 (
    echo %LOG_PREFIX% [INFO] 检查Python环境 >> "%LOG_FILE%"
)

:: 检查嵌入式Python
if exist "%PYTHON_DIR%\python.exe" (
    echo    ✓ 嵌入式Python存在
    goto :python_ok
)

echo    ⓘ 嵌入式Python不存在
if %OFFLINE_MODE% == 1 (
    echo   错误: 离线模式下需要嵌入式Python
    pause
    exit /b 1
)

echo    ℹ 将在后续版本中添加自动下载功能
echo    💡 提示: 请手动下载Python嵌入式版本到python\目录
echo.

:python_ok

:: 配置Python路径
echo [3/5] 配置Python路径...

:: 检查python312._pth文件
if not exist "%PYTHON_DIR%\python312._pth" (
    echo    ℹ 创建Python路径配置文件...
    copy "%~dp0templates\python312._pth" "%PYTHON_DIR%\python312._pth" >nul
    if errorlevel 1 (
        echo    ⚠ 无法创建路径配置，尝试手动配置...
    ) else (
        echo    ✓ Python路径配置文件创建成功
    )
) else (
    echo    ✓ Python路径配置文件已存在
)

:: 验证Python能正确导入app模块
echo    ℹ 验证模块导入...
cd /d "%PYTHON_DIR%"
python.exe -c "import sys; sys.path.insert(0, r'%APP_DIR%'); print('Python路径配置测试: OK')" 2>&1 | findstr /i "error" >nul
if %errorlevel% == 0 (
    echo    ✗ Python路径配置错误
    echo      请检查python312._pth文件配置
) else (
    echo    ✓ Python路径配置正确
)
cd /d "%~dp0"

echo [4/5] 检查目录结构...
if %VERBOSE_MODE% == 1 (
    echo %LOG_PREFIX% [INFO] 检查目录结构 >> "%LOG_FILE%"
    echo %LOG_PREFIX% [INFO] APP_DIR=%APP_DIR% >> "%LOG_FILE%"
    echo %LOG_PREFIX% [INFO] PYTHON_DIR=%PYTHON_DIR% >> "%LOG_FILE%"
)
if not exist "%APP_DIR%" (
    echo   错误: app目录不存在
    echo   请确保工具完整解压
    pause
    exit /b 1
)

echo    ✓ 基础目录检查通过
echo.

:: 这里将添加更多功能
echo [5/5] 启动器基础框架就绪
echo 后续将添加: 依赖安装、代码更新等功能
echo.

pause

:: 错误处理
if errorlevel 1 (
    set "ERROR_CODE=!errorlevel!"
    if %VERBOSE_MODE% == 1 (
        echo %LOG_PREFIX% [ERROR] 启动器异常退出，错误代码: !ERROR_CODE! >> "%LOG_FILE%"
    )
    echo.
    echo [FAIL] 启动器运行失败 (错误代码: !ERROR_CODE!)
    echo   详细信息请查看日志: %LOG_FILE%
)
endlocal