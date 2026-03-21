@echo off
set TEST_PASSED=1
echo 测试命令行参数解析...
echo.

echo 1. 测试--help参数:
call ..\launcher.bat --help 2>&1 | findstr /i "帮助" >nul
if %errorlevel% == 0 (
  echo   ✓ --help参数工作正常
) else (
  echo   ✗ --help参数工作异常
  set TEST_PASSED=0
)

echo.
echo 测试完成
if %TEST_PASSED% == 1 (
  exit /b 0
) else (
  exit /b 1
)