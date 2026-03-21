@echo off
set TEST_PASSED=1
echo 测试更新脚本框架...
echo.

echo 1. 检查update.bat是否存在:
if exist "update.bat" (
  echo   ✓ update.bat存在
  echo   运行测试...
  call update.bat 2>&1 | findstr /i "更新器\|错误" >nul
  if errorlevel 1 (
    echo   ✓ update.bat运行正常
  ) else (
    echo   ✗ update.bat运行出错
    set TEST_PASSED=0
  )
) else (
  echo   ✗ update.bat不存在
  set TEST_PASSED=0
)

echo.
echo 2. 检查必要目录创建:
if exist "..\cache\downloads\" (
  echo   ✓ cache/downloads目录创建成功
) else (
  echo   ✗ cache/downloads目录创建失败
  set TEST_PASSED=0
)

echo.
echo 测试完成
if %TEST_PASSED% == 1 (
  exit /b 0
) else (
  exit /b 1
)