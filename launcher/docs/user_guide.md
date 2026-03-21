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