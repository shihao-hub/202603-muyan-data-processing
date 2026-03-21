@echo off
echo 测试应用启动功能...
echo.

echo 1. 测试Python程序启动:
cd ..
if exist "python\python.exe" (
  echo   ✓ Python存在，测试启动命令...
  python\python.exe -c "print('Python测试: OK')" 2>&1 | findstr /i "error" >nul
  if errorlevel 1 (
    echo   ✓ Python启动正常
  ) else (
    echo   ✗ Python启动失败
  )
) else (
  echo   ⓘ Python不存在，跳过启动测试
)

echo.
echo 2. 测试实际应用启动（如果存在）:
if exist "app\material_matcher\cli.py" (
  echo   ✓ 应用代码存在
  echo   测试导入...
  python\python.exe -c "import sys; sys.path.insert(0, 'app'); import material_matcher; print('应用导入: OK')" 2>&1 | findstr /i "error\|OK"
) else (
  echo   ⓘ 应用代码不存在，跳过导入测试
)

echo.
echo 测试完成
pause