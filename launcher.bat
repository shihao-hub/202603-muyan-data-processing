@echo off
setlocal EnableDelayedExpansion

echo.
echo ========================================
echo   材料匹配工具启动器 v0.1.0
echo ========================================
echo.

:: 设置基础路径
set "ROOT_DIR=%~dp0"
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
:: 非启动器参数，追加到 APP_ARGS
set "APP_ARGS=%APP_ARGS% %~1"
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

echo [1/6] 检查目录结构...
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

echo    [OK] 基础目录检查通过
echo.

echo [2/6] 检查Python环境...
if %VERBOSE_MODE% == 1 (
    echo %LOG_PREFIX% [INFO] 检查Python环境 >> "%LOG_FILE%"
)

:: 检查嵌入式Python
if exist "%PYTHON_DIR%\python.exe" (
    echo    [OK] 嵌入式Python存在
    goto :python_ok
)

echo    [INFO] 嵌入式Python不存在
if %OFFLINE_MODE% == 1 (
    echo   错误: 离线模式下需要嵌入式Python
    pause
    exit /b 1
)

echo    [INFO] 将在后续版本中添加自动下载功能
echo    [提示] 请手动下载Python嵌入式版本到python目录
echo.

:python_ok

:: 配置Python路径
echo [3/6] 配置Python路径...

:: 检测Python版本
cd /d "%PYTHON_DIR%"
for /f "tokens=2" %%i in ('python.exe --version 2^>^&1') do set "PYTHON_VERSION=%%i"
cd /d "%~dp0"

:: 解析版本号（如 3.13.0 -> 313）
for /f "tokens=1,2 delims=." %%a in ("!PYTHON_VERSION!") do (
    set "PY_VER_NO_DOT=%%a%%b"
)

if !VERBOSE_MODE! == 1 (
    echo !LOG_PREFIX! [INFO] 检测到Python版本: !PYTHON_VERSION! >> "!LOG_FILE!"
    echo !LOG_PREFIX! [INFO] 版本号: !PY_VER_NO_DOT! >> "!LOG_FILE!"
)

:: 检查对应版本的._pth文件
set "PTH_FILE=%PYTHON_DIR%\python!PY_VER_NO_DOT!._pth"
if not exist "!PTH_FILE!" (
    echo    [INFO] 创建Python路径配置文件（版本 !PY_VER_NO_DOT!）...

    :: 逐行创建pth文件
    > "%PYTHON_DIR%\python!PY_VER_NO_DOT!._pth" (
        echo python!PY_VER_NO_DOT!.zip
        echo .
        echo ..\app
        echo import site
    )


    echo    [OK] Python路径配置文件创建成功
) else (
    echo    [OK] Python路径配置文件已存在
)

echo    [INFO] 验证模块导入...
cd /d "%PYTHON_DIR%"
%PYTHON_DIR%\python.exe -c "import sys; sys.path.insert(0, r'%APP_DIR%'); print('Python路径配置测试: OK')" 2>&1 | findstr /i "error" >nul
if %errorlevel% == 0 (
    echo    [FAIL] Python路径配置错误
    echo      请检查python312._pth文件配置
) else (
    echo    [OK] Python路径配置正确
)
cd /d "%~dp0"

echo [4/6] 检查并安装依赖...

:: 切换到 Python 目录
cd /d "%PYTHON_DIR%"
if errorlevel 1 (
    echo    [FAIL] 无法切换到 Python 目录: %PYTHON_DIR%
    pause
    exit /b 1
)

:: 检查 pip 是否安装
echo    [INFO] 检查 pip...
python.exe -c "import pip; print('OK')" 2>nul | findstr "OK" >nul
if errorlevel 1 (
    echo    [INFO] pip 未安装，正在安装...

    :: 使用 PowerShell 下载 get-pip.py
    echo    [INFO] 正在下载 get-pip.py...
    powershell -Command "try { Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'get-pip.py' -UseBasicParsing; exit 0 } catch { exit 1 }"

    if not exist "get-pip.py" (
        echo    [FAIL] 无法下载 get-pip.py，请检查网络连接
        cd /d "%~dp0"
        pause
        exit /b 1
    )

    echo    [INFO] 正在安装 pip...
    python.exe get-pip.py --no-warn-script-location

    if errorlevel 1 (
        echo    [FAIL] pip 安装失败
        cd /d "%~dp0"
        pause
        exit /b 1
    )

    del "get-pip.py" 2>nul
    echo    [OK] pip 安装成功
) else (
    echo    [OK] pip 已安装
)

:: 检查项目依赖是否已安装（检查 click 作为标记）
echo    [INFO] 检查项目依赖
python.exe -c "import click; print('OK')" 2>nul | findstr "OK" >nul
if errorlevel 1 (
    echo    [INFO] 正在安装项目依赖

    if not exist "%ROOT_DIR%pyproject.toml" (
        echo    [FAIL] 未找到 pyproject.toml
        cd /d "%~dp0"
        pause
        exit /b 1
    )

    :: 先安装构建依赖
    echo    [INFO] 安装构建依赖 (hatchling)
    python.exe -m pip install hatchling editables --no-warn-script-location --quiet

    echo    [INFO] 安装项目依赖，这可能需要几分钟...
    python.exe -m pip install -e "%ROOT_DIR:~0,-1%" --no-warn-script-location --quiet

    if errorlevel 1 (
        echo    [FAIL] 依赖安装失败，请手动执行: pip install -e .
        cd /d "%~dp0"
        pause
        exit /b 1
    )

    echo    [OK] 项目依赖安装成功
) else (
    echo    [OK] 项目依赖已安装
)

cd /d "%~dp0"

echo.
echo [5/6] 启动材料匹配工具...
echo.

:: 切换到Python目录执行
cd /d "%PYTHON_DIR%"

if %VERBOSE_MODE% == 1 (
    echo %LOG_PREFIX% [INFO] 切换到Python目录: %PYTHON_DIR% >> "%LOG_FILE%"
    echo %LOG_PREFIX% [INFO] 启动应用命令: "%PYTHON_DIR%\python.exe" -m material_matcher.cli %* >> "%LOG_FILE%"
)

:: 检查应用是否存在
%PYTHON_DIR%\python.exe -c "import sys; sys.path.insert(0, r'%APP_DIR%'); try: import material_matcher; print('应用检查: OK'); except ImportError as e: print('应用检查: FAIL -', e); exit(1)" 2>&1 | findstr /i "OK" >nul
if errorlevel 1 (
    echo    [FAIL] 应用模块导入失败
    echo      请确保app目录包含material_matcher模块
    pause
    exit /b 1
)

echo    [OK] 应用模块检查通过
echo    启动材料匹配工具...
echo    ========================================
echo.

:: 检查是否有应用参数
if "%APP_ARGS%"=="" (
    echo.
    echo 用法: launcher.bat [选项]
    echo.
    echo 必需参数:
    echo   -a, --file1 PATH    源文件A（工料机汇总表）
    echo   -b, --file2 PATH    源文件B（询价材料表）
    echo.
    echo 可选参数:
    echo   -t, --template PATH 输出样式模板文件
    echo   -o, --output PATH   输出文件路径
    echo.
    echo 示例:
    echo   launcher.bat -a input.xlsx -b inquiry.xlsx
    echo   launcher.bat --file1 data.xlsx --file2 prices.xlsx --output result.xlsx
    echo.
    echo 查看完整帮助:
    echo   launcher.bat --help
    echo.
    pause
    exit /b 0
)

:: 执行实际应用（先切换到项目根目录以便正确解析相对路径）
cd /d "%~dp0"
"%PYTHON_DIR%\python.exe" -m material_matcher.cli %APP_ARGS%

:: 记录执行结果
set "APP_EXIT_CODE=%errorlevel%"
if %VERBOSE_MODE% == 1 (
    echo %LOG_PREFIX% [INFO] 应用执行完成，退出代码: !APP_EXIT_CODE! >> "%LOG_FILE%"
)

cd /d "%~dp0"

echo.
echo ========================================
if %APP_EXIT_CODE% == 0 (
    echo    [SUCCESS] 材料匹配工具执行完成
) else (
    echo    [WARN] 材料匹配工具退出代码: %APP_EXIT_CODE%
)

echo [6/6] 清理和完成...
if %VERBOSE_MODE% == 1 (
    echo %LOG_PREFIX% [INFO] 启动器执行完成 >> "%LOG_FILE%"
    echo   日志文件: %LOG_FILE%
)
echo.

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
pause