@echo off
chcp 65001 >nul
echo.
echo ========================================
echo   启动器测试套件 v0.1.0
echo ========================================
echo.

set TEST_COUNT=0
set PASS_COUNT=0
set FAIL_COUNT=0

:: 测试1: 路径配置测试
echo [1/6] 运行路径配置测试...
call test_paths.bat
if %errorlevel% == 0 (
    echo    ✓ 路径配置测试通过
    set /a PASS_COUNT+=1
) else (
    echo    ✗ 路径配置测试失败
    set /a FAIL_COUNT+=1
)
set /a TEST_COUNT+=1
echo.

:: 测试2: 参数解析测试
echo [2/6] 运行参数解析测试...
call test_args.bat
if %errorlevel% == 0 (
    echo    ✓ 参数解析测试通过
    set /a PASS_COUNT+=1
) else (
    echo    ✗ 参数解析测试失败
    set /a FAIL_COUNT+=1
)
set /a TEST_COUNT+=1
echo.

:: 测试3: Python环境测试
echo [3/6] 运行Python环境测试...
call test_python.bat
if %errorlevel% == 0 (
    echo    ✓ Python环境测试通过
    set /a PASS_COUNT+=1
) else (
    echo    ✗ Python环境测试失败
    set /a FAIL_COUNT+=1
)
set /a TEST_COUNT+=1
echo.

:: 测试4: 日志系统测试
echo [4/6] 运行日志系统测试...
call test_logging.bat
if %errorlevel% == 0 (
    echo    ✓ 日志系统测试通过
    set /a PASS_COUNT+=1
) else (
    echo    ✗ 日志系统测试失败
    set /a FAIL_COUNT+=1
)
set /a TEST_COUNT+=1
echo.

:: 测试5: 更新脚本测试
echo [5/6] 运行更新脚本测试...
call test_update.bat
if %errorlevel% == 0 (
    echo    ✓ 更新脚本测试通过
    set /a PASS_COUNT+=1
) else (
    echo    ✗ 更新脚本测试失败
    set /a FAIL_COUNT+=1
)
set /a TEST_COUNT+=1
echo.

:: 测试6: 应用启动测试
echo [6/6] 运行应用启动测试...
call test_launch.bat
if %errorlevel% == 0 (
    echo    ✓ 应用启动测试通过
    set /a PASS_COUNT+=1
) else (
    echo    ✗ 应用启动测试失败
    set /a FAIL_COUNT+=1
)
set /a TEST_COUNT+=1
echo.

echo ========================================
echo   测试结果汇总
echo ========================================
echo   总测试数: %TEST_COUNT%
echo   通过数: %PASS_COUNT%
echo   失败数: %FAIL_COUNT%
echo.
if %FAIL_COUNT% == 0 (
    echo   所有测试通过！
) else (
    echo   有 %FAIL_COUNT% 个测试失败
)
echo.

pause