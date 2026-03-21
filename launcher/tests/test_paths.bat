@echo off
echo 测试Python路径配置...
echo.
echo 1. 检查模板文件是否存在:
if exist "templates\python312._pth" (
  echo   ✓ python312._pth模板存在
) else (
  echo   ✗ python312._pth模板不存在
)

echo.
echo 2. 检查模板内容:
type "templates\python312._pth"
echo.
pause

echo.
echo 3. 测试基础launcher.bat:
cd ..
if exist "launcher.bat" (
  echo   ✓ launcher.bat存在
  echo   运行测试...
  call launcher.bat --help 2>&1 | findstr /i "错误" >nul
  if errorlevel 1 (
    echo   ✓ launcher.bat运行正常
  ) else (
    echo   ✗ launcher.bat运行出错
  )
) else (
  echo   ✗ launcher.bat不存在
)