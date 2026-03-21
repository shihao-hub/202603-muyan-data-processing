@echo off
set TEST_PASSED=1
echo 测试日志系统...
echo.

echo 1. 检查日志目录:
if exist "..\logs\" (
  echo   [OK] logs目录存在
) else (
  echo   [INFO] logs目录不存在
)

echo.
echo 2. 测试日志文件创建:
call ..\launcher.bat --verbose 2>&1 >nul
if exist "..\logs\launcher_*.log" (
  echo   [OK] 日志文件创建成功
  echo   最新日志:
  for /f "delims=" %%f in ('dir /b /o-d ..\logs\launcher_*.log') do (
    echo   - %%f
    goto :log_found
  )
) else (
  echo   [FAIL] 日志文件创建失败
  set TEST_PASSED=0
)
:log_found

echo.
echo 测试完成
if %TEST_PASSED% == 1 (
  exit /b 0
) else (
  exit /b 1
)