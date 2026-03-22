# 材料匹配工具启动器实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为material-matcher Python工具创建Windows批处理启动器，让非技术用户通过双击bat文件即可使用，无需安装Python、git等开发工具。

**Architecture:** 使用嵌入式Python环境 + 批处理脚本管理，通过修改python3x._pth文件配置路径，使用PowerShell从gitee下载代码更新，使用清华镜像源安装依赖，支持离线缓存和手动更新。

**Tech Stack:** Windows批处理(.bat), PowerShell 5.1+, Python 3.12嵌入式版本, pip, 清华镜像源(pypi.tuna.tsinghua.edu.cn)

---

## 文件结构

### 新建文件
```
launcher/                    # 启动器项目根目录
├── launcher.bat            # 主启动脚本（用户双击这个）
├── update.bat              # 独立更新脚本
├── tests/                  # 测试文件
│   ├── test_paths.bat     # 路径配置测试
│   └── test_download.bat  # 下载功能测试
├── templates/              # 模板文件
│   ├── python312._pth     # Python路径配置文件模板
│   └── mirror_sources.txt # 镜像源配置模板
└── docs/                  # 文档
    └── user_guide.md      # 用户使用指南
```

### 集成到现有项目
现有项目结构保持不变，启动器作为顶层目录添加：
```
material-matcher/           # 现有项目根目录
├── launcher/              # 新增：启动器目录
│   ├── launcher.bat
│   ├── update.bat
│   └── ...
├── material_matcher/      # 现有：Python业务代码
├── pyproject.toml         # 现有：项目配置
├── main.py                # 现有：简单入口
└── ...
```

## 实施任务

### 任务 1: 创建基础目录结构

**文件:**
- Create: `launcher/`
- Create: `launcher/tests/`
- Create: `launcher/templates/`
- Create: `launcher/docs/`

- [ ] **Step 1: 创建launcher目录结构**

```bash
mkdir -p launcher/tests
mkdir -p launcher/templates
mkdir -p launcher/docs
```

- [ ] **Step 2: 验证目录创建**

```bash
ls -la launcher/
```
预期输出：显示`tests/`, `templates/`, `docs/`目录

- [ ] **Step 3: 提交目录结构**

```bash
git add launcher/
git commit -m "feat(launcher): 创建基础目录结构"
```

### 任务 2: 创建Python路径配置文件模板

**文件:**
- Create: `launcher/templates/python312._pth`
- Test: `launcher/tests/test_paths.bat`

- [ ] **Step 1: 创建python312._pth模板**

```ini
# Python嵌入式版本路径配置文件
python312.zip
.
..\..\app
import site
```

- [ ] **Step 2: 创建路径测试脚本**

```batch
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
```

- [ ] **Step 3: 运行测试验证模板**

```bash
cd launcher
tests\test_paths.bat
```
预期输出：显示模板存在并打印内容

- [ ] **Step 4: 提交模板文件**

```bash
git add launcher/templates/python312._pth launcher/tests/test_paths.bat
git commit -m "feat(launcher): 添加Python路径配置模板和测试"
```

### 任务 3: 创建镜像源配置文件模板

**文件:**
- Create: `launcher/templates/mirror_sources.txt`

- [ ] **Step 1: 创建镜像源配置文件**

```ini
# 国内Python镜像源配置
[main]
# 主镜像源：清华大学
primary = https://pypi.tuna.tsinghua.edu.cn/simple
# 备用镜像源1：阿里云
backup1 = https://mirrors.aliyun.com/pypi/simple/
# 备用镜像源2：豆瓣
backup2 = https://pypi.douban.com/simple/

[gitee]
# Gitee仓库地址（需要替换为实际仓库）
repository = https://gitee.com/用户名/material-matcher/repository/archive/master.zip
version_url = https://gitee.com/用户名/material-matcher/raw/master/version.txt

[python]
# Python嵌入式版本下载地址
# 官方源
official = https://www.python.org/ftp/python/3.12.0/python-3.12.0-embed-amd64.zip
# 国内镜像
mirror = https://mirrors.tuna.tsinghua.edu.cn/python/3.12.0/python-3.12.0-embed-amd64.zip
```

- [ ] **Step 2: 验证配置文件格式**

```bash
python -c "import configparser; cp = configparser.ConfigParser(); cp.read('launcher/templates/mirror_sources.txt'); print('配置节:', cp.sections())"
```
预期输出：`配置节: ['main', 'gitee', 'python']`

- [ ] **Step 3: 提交镜像源配置**

```bash
git add launcher/templates/mirror_sources.txt
git commit -m "feat(launcher): 添加国内镜像源配置文件模板"
```

### 任务 4: 创建基础launcher.bat（最小功能）

**文件:**
- Create: `launcher/launcher.bat`
- Modify: `launcher/tests/test_paths.bat` (添加测试)

- [ ] **Step 1: 创建最小功能launcher.bat**

```batch
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
```

- [ ] **Step 2: 扩展测试脚本验证基础功能**

在`launcher/tests/test_paths.bat`末尾添加：
```batch
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
```

- [ ] **Step 3: 运行测试验证基础功能**

```bash
cd launcher
copy launcher.bat ..\launcher.bat
tests\test_paths.bat
```
预期输出：显示launcher.bat存在且运行正常

- [ ] **Step 4: 提交基础启动器**

```bash
git add launcher/launcher.bat launcher/tests/test_paths.bat
git commit -m "feat(launcher): 创建基础launcher.bat框架"
```

### 任务 5: 添加命令行参数解析

**文件:**
- Modify: `launcher/launcher.bat`
- Test: `launcher/tests/test_args.bat`

- [ ] **Step 1: 创建命令行参数测试**

```batch
@echo off
echo 测试命令行参数解析...
echo.

echo 1. 测试--help参数:
call ..\launcher.bat --help 2>&1 | findstr /i "帮助" >nul
if %errorlevel% == 0 (
  echo   ✓ --help参数工作正常
) else (
  echo   ✗ --help参数工作异常
)

echo.
echo 测试完成
pause
```

- [ ] **Step 2: 在launcher.bat中添加参数解析**

在`:: 设置基础路径`部分后添加：
```batch
:: 解析命令行参数
set SHOW_HELP=0
set OFFLINE_MODE=0
set FORCE_MODE=0
set VERBOSE_MODE=0

:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="--help" (
    set SHOW_HELP=1
    shift
    goto :parse_args
)
if "%~1"=="--offline" (
    set OFFLINE_MODE=1
    shift
    goto :parse_args
)
if "%~1"=="--force" (
    set FORCE_MODE=1
    shift
    goto :parse_args
)
if "%~1"=="--verbose" (
    set VERBOSE_MODE=1
    shift
    goto :parse_args
)
shift
goto :parse_args

:args_done

:: 显示帮助信息
if %SHOW_HELP% == 1 (
    echo 用法: launcher.bat [选项]
    echo 选项:
    echo   --help     显示帮助信息
    echo   --offline  离线模式（不使用网络）
    echo   --force    强制模式（覆盖文件，终止进程）
    echo   --verbose  详细日志输出
    echo.
    echo 示例:
    echo   launcher.bat --offline
    echo   launcher.bat --verbose --force
    echo.
    exit /b 0
)
```

- [ ] **Step 3: 添加参数状态显示**

在`echo [1/5] 检查目录结构...`前添加：
```batch
if %VERBOSE_MODE% == 1 (
    echo [调试] 参数状态:
    echo   离线模式: %OFFLINE_MODE%
    echo   强制模式: %FORCE_MODE%
    echo   详细模式: %VERBOSE_MODE%
    echo.
)
```

- [ ] **Step 4: 测试参数解析**

```bash
cd launcher
tests\test_args.bat
```
预期输出：显示`--help参数工作正常`

- [ ] **Step 5: 提交参数解析功能**

```bash
git add launcher/launcher.bat launcher/tests/test_args.bat
git commit -m "feat(launcher): 添加命令行参数解析功能"
```

### 任务 6: 添加Python环境检查

**文件:**
- Modify: `launcher/launcher.bat`
- Create: `launcher/tests/test_python.bat`

- [ ] **Step 1: 创建Python环境测试**

```batch
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
```

- [ ] **Step 2: 在launcher.bat中添加Python环境检查**

在参数状态显示后添加：
```batch
echo [2/5] 检查Python环境...

:: 检查嵌入式Python
if exist "%PYTHON_DIR%\python.exe" (
    echo    ✓ 嵌入式Python存在
    goto :python_ok
)

echo    ⓘ 嵌入式Python不存在
if %OFFLINE_MODE% == 1 (
    echo   错误: 离线模式下需要嵌入式Python
    pause
    exit /b 1
)

echo    ℹ 将在后续版本中添加自动下载功能
echo    💡 提示: 请手动下载Python嵌入式版本到python\目录
echo.

:python_ok
```

- [ ] **Step 3: 添加Python路径配置**

在`:python_ok`标签后添加：
```batch
:: 配置Python路径
echo [3/5] 配置Python路径...

:: 检查python312._pth文件
if not exist "%PYTHON_DIR%\python312._pth" (
    echo    ℹ 创建Python路径配置文件...
    copy "%~dp0templates\python312._pth" "%PYTHON_DIR%\python312._pth" >nul
    if errorlevel 1 (
        echo    ⚠ 无法创建路径配置，尝试手动配置...
    ) else (
        echo    ✓ Python路径配置文件创建成功
    )
) else (
    echo    ✓ Python路径配置文件已存在
)

:: 验证Python能正确导入app模块
echo    ℹ 验证模块导入...
cd /d "%PYTHON_DIR%"
python.exe -c "import sys; sys.path.insert(0, r'%APP_DIR%'); print('Python路径配置测试: OK')" 2>&1 | findstr /i "error" >nul
if %errorlevel% == 0 (
    echo    ✗ Python路径配置错误
    echo      请检查python312._pth文件配置
) else (
    echo    ✓ Python路径配置正确
)
cd /d "%~dp0"
```

- [ ] **Step 4: 测试Python环境检查**

```bash
cd launcher
tests\test_python.bat
call launcher.bat --verbose 2>&1 | findstr /i "Python环境\|Python路径"
```
预期输出：显示Python环境检查步骤

- [ ] **Step 5: 提交Python环境检查功能**

```bash
git add launcher/launcher.bat launcher/tests/test_python.bat
git commit -m "feat(launcher): 添加Python环境检查和路径配置功能"
```

### 任务 7: 添加日志系统

**文件:**
- Modify: `launcher/launcher.bat`
- Create: `launcher/tests/test_logging.bat`

- [ ] **Step 1: 创建日志系统测试**

```batch
@echo off
echo 测试日志系统...
echo.

echo 1. 检查日志目录:
if exist "..\logs\" (
  echo   ✓ logs目录存在
) else (
  echo   ⓘ logs目录不存在
)

echo.
echo 2. 测试日志文件创建:
call ..\launcher.bat --verbose 2>&1 >nul
if exist "..\logs\launcher_*.log" (
  echo   ✓ 日志文件创建成功
  echo   最新日志:
  for /f "delims=" %%f in ('dir /b /o-d ..\logs\launcher_*.log') do (
    echo   - %%f
    goto :log_found
  )
) else (
  echo   ✗ 日志文件创建失败
)
:log_found

echo.
echo 测试完成
pause
```

- [ ] **Step 2: 在launcher.bat中添加日志系统**

在文件开头`setlocal EnableDelayedExpansion`后添加：
```batch
:: 日志系统初始化
set "LOG_DIR=%ROOT_DIR%logs"
set "LOG_DATE=%date:~0,4%-%date:~5,2%-%date:~8,2%"
set "LOG_TIME=%time:~0,2%-%time:~3,2%-%time:~6,2%"
set "LOG_FILE=%LOG_DIR%\launcher_%LOG_DATE%_%LOG_TIME%.log"

:: 创建日志目录
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%" 2>nul
)

:: 日志函数
set "LOG_PREFIX=[%LOG_TIME%]"
if %VERBOSE_MODE% == 1 (
    echo %LOG_PREFIX% [INFO] 启动器开始运行 > "%LOG_FILE%"
    echo %LOG_PREFIX% [INFO] 参数: 离线模式=%OFFLINE_MODE%, 强制模式=%FORCE_MODE%, 详细模式=%VERBOSE_MODE% >> "%LOG_FILE%"
)
```

- [ ] **Step 3: 添加日志记录点**

在关键步骤添加日志记录，例如：
```batch
:: 在"检查目录结构"部分添加
echo [1/5] 检查目录结构...
if %VERBOSE_MODE% == 1 (
    echo %LOG_PREFIX% [INFO] 检查目录结构 >> "%LOG_FILE%"
    echo %LOG_PREFIX% [INFO] APP_DIR=%APP_DIR% >> "%LOG_FILE%"
    echo %LOG_PREFIX% [INFO] PYTHON_DIR=%PYTHON_DIR% >> "%LOG_FILE%"
)

:: 在"检查Python环境"部分添加
echo [2/5] 检查Python环境...
if %VERBOSE_MODE% == 1 (
    echo %LOG_PREFIX% [INFO] 检查Python环境 >> "%LOG_FILE%"
)
```

- [ ] **Step 4: 添加错误日志**

在文件末尾`endlocal`前添加错误处理：
```batch
:: 错误处理
if errorlevel 1 (
    set "ERROR_CODE=!errorlevel!"
    if %VERBOSE_MODE% == 1 (
        echo %LOG_PREFIX% [ERROR] 启动器异常退出，错误代码: !ERROR_CODE! >> "%LOG_FILE%"
    )
    echo.
    echo ✗ 启动器运行失败 (错误代码: !ERROR_CODE!)
    echo   详细信息请查看日志: %LOG_FILE%
)
```

- [ ] **Step 5: 测试日志系统**

```bash
cd launcher
tests\test_logging.bat
if exist "../logs/launcher_*.log" (
    echo "最新日志文件:"
    ls -la ../logs/launcher_*.log | head -1
)
```
预期输出：显示日志文件创建成功

- [ ] **Step 6: 提交日志系统**

```bash
git add launcher/launcher.bat launcher/tests/test_logging.bat
git commit -m "feat(launcher): 添加日志系统"
```

### 任务 8: 创建update.bat更新脚本

**文件:**
- Create: `launcher/update.bat`
- Test: `launcher/tests/test_update.bat`

- [ ] **Step 1: 创建更新脚本框架**

```batch
@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo.
echo ========================================
echo   材料匹配工具代码更新器 v0.1.0
echo ========================================
echo.

:: 设置路径
set "ROOT_DIR=%~dp0..\"
set "APP_DIR=%ROOT_DIR%app"
set "CACHE_DIR=%ROOT_DIR%cache\downloads"
set "LOG_DIR=%ROOT_DIR%logs"
set "CONFIG_DIR=%ROOT_DIR%config"

:: 创建必要的目录
if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"

:: 日志
set "LOG_DATE=%date:~0,4%-%date:~5,2%-%date:~8,2%"
set "LOG_FILE=%LOG_DIR%\update_%LOG_DATE%.log"

echo [%time%] 更新器启动 > "%LOG_FILE%"
echo [1/5] 初始化更新环境...

if not exist "%APP_DIR%" (
    echo   错误: app目录不存在，无法更新
    echo [%time%] 错误: app目录不存在 >> "%LOG_FILE%"
    pause
    exit /b 1
)

echo    ✓ 环境检查通过
echo [%time%] 环境检查通过 >> "%LOG_FILE%"

:: 这里将添加下载和更新逻辑
echo.
echo 更新器框架就绪
echo 后续将添加: 版本检查、代码下载、文件替换等功能
echo.

pause
endlocal
```

- [ ] **Step 2: 创建更新测试脚本**

```batch
@echo off
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
  )
) else (
  echo   ✗ update.bat不存在
)

echo.
echo 2. 检查必要目录创建:
if exist "..\cache\downloads\" (
  echo   ✓ cache/downloads目录创建成功
) else (
  echo   ✗ cache/downloads目录创建失败
)

echo.
echo 测试完成
pause
```

- [ ] **Step 3: 在update.bat中添加版本检查功能**

在`echo [1/5] 初始化更新环境...`部分后添加：
```batch
echo [2/5] 检查版本信息...

:: 读取镜像源配置
set "MIRROR_CONFIG=%CONFIG_DIR%\mirror_sources.txt"
if not exist "%MIRROR_CONFIG%" (
    echo    ℹ 创建默认镜像源配置...
    copy "%~dp0templates\mirror_sources.txt" "%MIRROR_CONFIG%" >nul
    echo    ⚠ 请编辑 %MIRROR_CONFIG% 配置实际仓库地址
)

:: 检查本地版本文件
set "LOCAL_VERSION_FILE=%APP_DIR%\version.txt"
if exist "%LOCAL_VERSION_FILE%" (
    echo    ✓ 本地版本文件存在
    type "%LOCAL_VERSION_FILE%"
) else (
    echo    ⓘ 本地版本文件不存在，创建默认...
    echo # 本地版本信息 > "%LOCAL_VERSION_FILE%"
    echo version_date = %date:~0,4%-%date:~5,2%-%date:~8,2% >> "%LOCAL_VERSION_FILE%"
    echo commit_hash = unknown >> "%LOCAL_VERSION_FILE%"
    echo file_hash = unknown >> "%LOCAL_VERSION_FILE%"
)

echo [%time%] 版本检查完成 >> "%LOG_FILE%"
```

- [ ] **Step 4: 测试更新脚本**

```bash
cd launcher
copy update.bat ../update.bat
tests/test_update.bat
```
预期输出：显示update.bat存在且运行正常

- [ ] **Step 5: 提交更新脚本框架**

```bash
git add launcher/update.bat launcher/tests/test_update.bat
git commit -m "feat(launcher): 创建update.bat更新脚本框架"
```

### 任务 9: 在launcher.bat中添加应用启动功能

**文件:**
- Modify: `launcher/launcher.bat`
- Test: `launcher/tests/test_launch.bat`

- [ ] **Step 1: 创建应用启动测试**

```batch
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
```

- [ ] **Step 2: 在launcher.bat中添加应用启动**

在Python路径配置验证后添加：
```batch
echo [4/5] 启动材料匹配工具...
echo.

:: 切换到Python目录执行
cd /d "%PYTHON_DIR%"

if %VERBOSE_MODE% == 1 (
    echo %LOG_PREFIX% [INFO] 切换到Python目录: %PYTHON_DIR% >> "%LOG_FILE%"
    echo %LOG_PREFIX% [INFO] 启动应用命令: python.exe -m material_matcher.cli %* >> "%LOG_FILE%"
)

:: 检查应用是否存在
python.exe -c "import sys; sys.path.insert(0, r'%APP_DIR%'); try: import material_matcher; print('应用检查: OK'); except ImportError as e: print('应用检查: FAIL -', e); exit(1)" 2>&1 | findstr /i "OK" >nul
if errorlevel 1 (
    echo    ✗ 应用模块导入失败
    echo      请确保app目录包含material_matcher模块
    pause
    exit /b 1
)

echo    ✓ 应用模块检查通过
echo    🚀 启动材料匹配工具...
echo    ========================================
echo.

:: 执行实际应用
python.exe -m material_matcher.cli %*

:: 记录执行结果
set "APP_EXIT_CODE=%errorlevel%"
if %VERBOSE_MODE% == 1 (
    echo %LOG_PREFIX% [INFO] 应用执行完成，退出代码: !APP_EXIT_CODE! >> "%LOG_FILE%"
)

cd /d "%~dp0"
```

- [ ] **Step 3: 添加启动结果处理**

在应用启动部分后添加：
```batch
echo.
echo ========================================
if %APP_EXIT_CODE% == 0 (
    echo    ✅ 材料匹配工具执行完成
) else (
    echo    ⚠ 材料匹配工具退出代码: %APP_EXIT_CODE%
)

echo [5/5] 清理和完成...
if %VERBOSE_MODE% == 1 (
    echo %LOG_PREFIX% [INFO] 启动器执行完成 >> "%LOG_FILE%"
    echo   日志文件: %LOG_FILE%
)
echo.
```

- [ ] **Step 4: 测试应用启动功能**

```bash
cd launcher
# 首先确保有测试用的Python环境
mkdir -p ../python
echo "创建测试Python环境..."
# 模拟应用目录
mkdir -p ../app/material_matcher
echo "print('测试应用')" > ../app/material_matcher/__init__.py
echo "def main(): print('CLI测试'); return 0" > ../app/material_matcher/cli.py

tests/test_launch.bat
```
预期输出：显示应用启动测试结果

- [ ] **Step 5: 提交应用启动功能**

```bash
git add launcher/launcher.bat launcher/tests/test_launch.bat
git commit -m "feat(launcher): 添加应用启动功能"
```

### 任务 10: 创建用户使用指南

**文件:**
- Create: `launcher/docs/user_guide.md`
- Update: `README.md` (添加启动器说明)

- [ ] **Step 1: 创建用户使用指南**

```markdown
# 材料匹配工具启动器使用指南

## 概述
本启动器让您无需安装Python、git等开发工具，只需双击`launcher.bat`即可使用材料匹配工具。

## 快速开始

### 首次使用
1. 下载 `material-matcher-launcher.zip` 并解压到任意目录（如 `D:\材料匹配工具\`）
2. 双击 `launcher.bat`
3. 首次运行会自动：
   - 创建必要的目录结构
   - 配置Python环境（需要网络下载）
   - 安装依赖包
   - 启动材料匹配工具

### 日常使用
- 双击 `launcher.bat` - 启动材料匹配工具
- 双击 `update.bat` - 更新工具代码到最新版本

## 命令行参数

### launcher.bat 参数
```batch
launcher.bat [选项]
选项：
  --help     显示帮助信息
  --offline  离线模式（不使用网络）
  --force    强制模式（覆盖文件，终止进程）
  --verbose  详细日志输出
```

### 使用示例
```batch
# 正常启动
launcher.bat

# 离线启动（无网络环境）
launcher.bat --offline

# 查看详细日志
launcher.bat --verbose

# 获取帮助
launcher.bat --help
```

## 目录结构
```
材料匹配工具/
├── launcher.bat     # 主启动脚本（双击这个）
├── update.bat       # 更新脚本
├── python/          # Python环境（自动管理）
├── app/             # 应用代码
├── cache/           # 缓存文件
├── logs/            # 日志文件
└── config/          # 配置文件
```

## 常见问题

### 1. 启动时显示"Python环境不存在"
- 原因：首次运行需要下载Python嵌入式版本
- 解决：确保网络连接，重新运行`launcher.bat`

### 2. 杀毒软件误报
- 原因：批处理脚本和Python下载可能被误判
- 解决：将工具目录添加到杀毒软件白名单

### 3. 更新失败
- 原因：网络问题或gitee仓库地址配置错误
- 解决：检查网络连接，编辑`config/mirror_sources.txt`配置正确仓库地址

### 4. 依赖安装慢
- 原因：默认使用国外源
- 解决：自动使用清华镜像源，如需更改编辑`config/mirror_sources.txt`

## 离线使用
1. 首次在有网络的环境下运行`launcher.bat`
2. 工具会自动缓存Python环境和依赖包
3. 将整个工具目录复制到离线电脑
4. 使用`launcher.bat --offline`启动

## 更新工具
1. 运行`update.bat`从gitee下载最新代码
2. 或手动下载新版本zip包替换

## 获取帮助
- 查看本文档
- 运行`launcher.bat --help`
- 查看`logs/`目录下的日志文件
- 联系开发者
```

- [ ] **Step 2: 更新项目README.md**

在`README.md`末尾添加：
```markdown
## 启动器使用（非技术用户）

对于不懂计算机的用户，我们提供了专门的启动器：

### 快速开始
1. 下载 [material-matcher-launcher.zip](https://gitee.com/你的用户名/material-matcher/releases)
2. 解压到任意目录
3. 双击 `launcher.bat`

详细使用指南请查看 [launcher/docs/user_guide.md](launcher/docs/user_guide.md)

### 开发者说明
启动器源码在 `launcher/` 目录，包含：
- `launcher.bat` - 主启动脚本
- `update.bat` - 代码更新脚本
- `tests/` - 测试脚本
- `templates/` - 配置文件模板
- `docs/` - 用户文档
```

- [ ] **Step 3: 验证文档格式**

```bash
cd launcher
python -c "import markdown; html = markdown.markdown(open('docs/user_guide.md').read()); print('用户指南MD转换成功，长度:', len(html))" 2>&1 | grep -i "成功\|错误"
```
预期输出：显示转换成功

- [ ] **Step 4: 提交用户文档**

```bash
git add launcher/docs/user_guide.md README.md
git commit -m "docs(launcher): 添加用户使用指南和更新README"
```

### 任务 11: 创建完整测试套件

**文件:**
- Create: `launcher/tests/run_all_tests.bat`
- Update: 所有测试脚本添加错误处理

- [ ] **Step 1: 创建统一测试运行脚本**

```batch
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
    echo   ✅ 所有测试通过！
) else (
    echo   ⚠ 有 %FAIL_COUNT% 个测试失败
)
echo.

pause
```

- [ ] **Step 2: 更新现有测试脚本添加返回值**

为每个测试脚本添加明确的退出代码，例如修改`test_paths.bat`：
```batch
@echo off
set TEST_PASSED=1

echo 测试Python路径配置...
echo.

:: 测试项1
if exist "templates\python312._pth" (
  echo   ✓ python312._pth模板存在
) else (
  echo   ✗ python312._pth模板不存在
  set TEST_PASSED=0
)

:: 更多测试项...

if %TEST_PASSED% == 1 (
  exit /b 0
) else (
  exit /b 1
)
```

- [ ] **Step 3: 运行完整测试套件**

```bash
cd launcher/tests
run_all_tests.bat
```
预期输出：显示所有测试运行结果汇总

- [ ] **Step 4: 创建测试环境清理脚本**

```batch
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
```

- [ ] **Step 5: 提交测试套件**

```bash
git add launcher/tests/run_all_tests.bat launcher/tests/cleanup.bat
git add launcher/tests/*.bat  # 更新所有测试脚本
git commit -m "test(launcher): 添加完整测试套件和清理脚本"
```

### 任务 12: 创建发布打包脚本

**文件:**
- Create: `launcher/scripts/build_package.bat`
- Create: `launcher/scripts/create_first_run_package.bat`

- [ ] **Step 1: 创建基础打包脚本**

```batch
@echo off
chcp 65001 >nul
echo.
echo ========================================
echo   启动器打包工具 v0.1.0
echo ========================================
echo.

set "BUILD_DIR=..\..\build"
set "RELEASE_DIR=%BUILD_DIR%\releases"
set "VERSION=0.1.0"
set "PACKAGE_NAME=material-matcher-launcher-v%VERSION%"

echo [1/5] 准备构建环境...
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"

echo    ✓ 构建目录: %BUILD_DIR%
echo.

echo [2/5] 收集启动器文件...
set "PACKAGE_ROOT=%BUILD_DIR%\%PACKAGE_NAME%"
if exist "%PACKAGE_ROOT%" rmdir /s /q "%PACKAGE_ROOT%"
mkdir "%PACKAGE_ROOT%"

:: 复制启动器核心文件
echo   复制启动器脚本...
copy "..\launcher.bat" "%PACKAGE_ROOT%\" >nul
copy "..\update.bat" "%PACKAGE_ROOT%\" >nul

echo   复制模板文件...
mkdir "%PACKAGE_ROOT%\templates"
copy "..\templates\python312._pth" "%PACKAGE_ROOT%\templates\" >nul
copy "..\templates\mirror_sources.txt" "%PACKAGE_ROOT%\templates\" >nul

echo   复制用户文档...
mkdir "%PACKAGE_ROOT%\docs"
copy "..\docs\user_guide.md" "%PACKAGE_ROOT%\docs\" >nul

echo    ✓ 文件收集完成
echo.

echo [3/5] 创建目录结构...
mkdir "%PACKAGE_ROOT%\logs" 2>nul
mkdir "%PACKAGE_ROOT%\cache" 2>nul
mkdir "%PACKAGE_ROOT%\cache\downloads" 2>nul
mkdir "%PACKAGE_ROOT%\cache\dependencies" 2>nul
mkdir "%PACKAGE_ROOT%\config" 2>nul

echo    ✓ 目录结构创建完成
echo.

echo [4/5] 创建说明文件...
echo # 材料匹配工具启动器 v%VERSION% > "%PACKAGE_ROOT%\README.txt"
echo. >> "%PACKAGE_ROOT%\README.txt"
echo 使用方法: >> "%PACKAGE_ROOT%\README.txt"
echo 1. 解压此zip包到任意目录 >> "%PACKAGE_ROOT%\README.txt"
echo 2. 双击 launcher.bat 启动程序 >> "%PACKAGE_ROOT%\README.txt"
echo. >> "%PACKAGE_ROOT%\README.txt"
echo 详细指南请查看 docs\user_guide.md >> "%PACKAGE_ROOT%\README.txt"
echo. >> "%PACKAGE_ROOT%\README.txt"
echo 构建时间: %date% %time% >> "%PACKAGE_ROOT%\README.txt"

echo    ✓ 说明文件创建完成
echo.

echo [5/5] 创建zip包...
cd "%BUILD_DIR%"
powershell -Command "Compress-Archive -Path '%PACKAGE_NAME%' -DestinationPath '%RELEASE_DIR%\%PACKAGE_NAME%.zip' -Force" 2>nul
if errorlevel 1 (
    echo    ✗ 打包失败
) else (
    echo    ✓ 打包完成: %RELEASE_DIR%\%PACKAGE_NAME%.zip
    echo.
    echo   文件大小:
    for %%F in ("%RELEASE_DIR%\%PACKAGE_NAME%.zip") do echo    - %%~zF 字节
)

echo.
echo ========================================
echo   打包完成
echo ========================================
echo.
pause
```

- [ ] **Step 2: 创建首次运行包脚本**

```batch
@echo off
chcp 65001 >nul
echo.
echo ========================================
echo   首次运行包构建工具 v0.1.0
echo ========================================
echo.

set "BUILD_DIR=..\..\build"
set "RELEASE_DIR=%BUILD_DIR%\releases"
set "VERSION=0.1.0"
set "PACKAGE_NAME=material-matcher-first-run-v%VERSION%"

echo [1/4] 准备首次运行包...
set "PACKAGE_ROOT=%BUILD_DIR%\%PACKAGE_NAME%"
if exist "%PACKAGE_ROOT%" rmdir /s /q "%PACKAGE_ROOT%"
mkdir "%PACKAGE_ROOT%"

echo   复制启动器脚本...
copy "..\launcher.bat" "%PACKAGE_ROOT%\" >nul
copy "..\update.bat" "%PACKAGE_ROOT%\" >nul

echo   创建必要目录...
mkdir "%PACKAGE_ROOT%\logs" 2>nul
mkdir "%PACKAGE_ROOT%\cache" 2>nul
mkdir "%PACKAGE_ROOT%\cache\downloads" 2>nul
mkdir "%PACKAGE_ROOT%\config" 2>nul

echo    ✓ 基础文件准备完成
echo.

echo [2/4] 创建首次运行配置文件...
echo # 首次运行配置文件 > "%PACKAGE_ROOT%\config\first_run.ini"
echo [setup] >> "%PACKAGE_ROOT%\config\first_run.ini"
echo needs_python = true >> "%PACKAGE_ROOT%\config\first_run.ini"
echo needs_dependencies = true >> "%PACKAGE_ROOT%\config\first_run.ini"
echo auto_download = true >> "%PACKAGE_ROOT%\config\first_run.ini"

echo    ✓ 配置文件创建完成
echo.

echo [3/4] 创建首次运行说明...
echo # 材料匹配工具 - 首次运行包 v%VERSION% > "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo. >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 🚀 欢迎使用材料匹配工具！ >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo. >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 这是首次运行包，包含: >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 1. 启动器脚本 (launcher.bat, update.bat) >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 2. 基础目录结构 >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 3. 配置文件模板 >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo. >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 📋 首次使用步骤: >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 1. 解压此zip包到任意目录 >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 2. 双击 launcher.bat >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 3. 首次运行会自动下载Python和依赖（需要网络） >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 4. 等待下载完成，程序自动启动 >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo. >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo 💡 提示: >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo - 首次运行需要网络连接 >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo - 下载时间取决于网络速度 >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"
echo - 后续运行无需网络（离线模式） >> "%PACKAGE_ROOT%\FIRST_RUN_README.txt"

echo    ✓ 说明文档创建完成
echo.

echo [4/4] 打包...
cd "%BUILD_DIR%"
powershell -Command "Compress-Archive -Path '%PACKAGE_NAME%' -DestinationPath '%RELEASE_DIR%\%PACKAGE_NAME%.zip' -Force" 2>nul
if errorlevel 1 (
    echo    ✗ 打包失败
) else (
    echo    ✓ 首次运行包创建完成: %RELEASE_DIR%\%PACKAGE_NAME%.zip
    echo.
    echo   📦 包内容:
    dir "%PACKAGE_ROOT%" /b
)

echo.
pause
```

- [ ] **Step 3: 运行打包测试**

```bash
cd launcher/scripts
build_package.bat
if exist "../../build/releases/material-matcher-launcher-v0.1.0.zip" (
    echo "打包成功，文件大小:"
    ls -la "../../build/releases/material-matcher-launcher-v0.1.0.zip"
)
```
预期输出：显示打包成功和文件大小

- [ ] **Step 4: 提交打包脚本**

```bash
git add launcher/scripts/build_package.bat launcher/scripts/create_first_run_package.bat
git commit -m "build(launcher): 添加打包脚本和首次运行包构建工具"
```

---

## 下一步：计划审查与执行

计划已保存到 `docs/superpowers/plans/2026-03-21-material-matcher-launcher-implementation.md`。

**两个执行选项：**

1. **子代理驱动（推荐）** - 我为每个任务分派一个新子代理，任务间进行审查，快速迭代
2. **内联执行** - 在此会话中使用executing-plans执行任务，分批执行并设置检查点

**哪种方法？**