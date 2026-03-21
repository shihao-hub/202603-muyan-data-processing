@echo off
echo 测试Python环境检查...
echo.

echo 1. 测试python.exe检测:
where python.exe >nul 2>&1
if %errorlevel% == 0 (
  python --version
  echo   ✓ 系统Python存在
) else (
  echo   ⓘ 系统Python未安装
)

echo.
echo 2. 测试嵌入式Python路径:
if exist "..\python\python.exe" (
  echo   ✓ 嵌入式Python目录存在
  ..\python\python.exe --version 2>&1 | findstr /i "python" >nul
  if %errorlevel% == 0 (
    echo   ✓ 嵌入式Python可执行
  ) else (
    echo   ✗ 嵌入式Python损坏
  )
) else (
  echo   ⓘ 嵌入式Python目录不存在
)

echo.
echo 测试完成
pause