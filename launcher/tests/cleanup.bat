@echo off
echo 清理测试环境...
echo.

echo 1. 清理模拟目录:
if exist "..\..\python" (
  echo   删除python目录...
  rmdir /s /q "..\..\python" 2>nul
)

if exist "..\..\app\material_matcher" (
  echo   删除测试应用目录...
  rmdir /s /q "..\..\app\material_matcher" 2>nul
)

echo 2. 清理日志文件（保留最近1天）:
if exist "..\..\logs" (
  forfiles /p "..\..\logs" /m "*.log" /d -1 /c "cmd /c del @file" 2>nul
)

echo.
echo 测试环境清理完成
pause