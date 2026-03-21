@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo.
echo ========================================
echo   材料匹配工具启动器 v0.1.0
echo ========================================
echo.

:: 设置基础路径
set "ROOT_DIR=%~dp0..\"
set "PYTHON_DIR=%ROOT_DIR%python"
set "APP_DIR=%ROOT_DIR%app"

echo [1/5] 检查目录结构...
if not exist "%APP_DIR%" (
    echo   错误: app目录不存在
    echo   请确保工具完整解压
    pause
    exit /b 1
)

echo    ✓ 基础目录检查通过
echo.

:: 这里将添加更多功能
echo 启动器基础框架就绪
echo 后续将添加: Python环境管理、依赖安装、代码更新等功能
echo.

pause
endlocal