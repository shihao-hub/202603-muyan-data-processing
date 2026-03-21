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