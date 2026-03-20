# Task Breakdown

## Phase 1: 项目初始化

### Task 1.1: 创建项目结构
- [ ] 创建 `material_matcher/` 目录结构
- [ ] 初始化 `pyproject.toml`，添加依赖
- [ ] 创建各模块的 `__init__.py`
- [ ] 配置 `.gitignore`

### Task 1.2: 配置日志系统
- [ ] 实现 `setup_logging()` 函数
- [ ] 配置 structlog 处理器链
- [ ] 测试日志输出格式

---

## Phase 2: 数据模型

### Task 2.1: 定义核心模型
- [ ] 创建 `models/material.py`
- [ ] 实现 `Material` dataclass
- [ ] 实现 `PriceQuote` dataclass
- [ ] 实现 `MatchMethod` 枚举

### Task 2.2: 定义匹配结果模型
- [ ] 创建 `models/match_result.py`
- [ ] 实现 `MatchResult` dataclass

---

## Phase 3: 配置系统

### Task 3.1: 配置加载
- [ ] 创建 `config.yaml` 默认配置
- [ ] 实现 `Config` 类
- [ ] 实现配置文件加载逻辑
- [ ] 实现列名映射功能

---

## Phase 4: Excel 解析器

### Task 4.1: 解析器基类
- [ ] 创建 `parser/base.py`
- [ ] 实现 `_detect_header_row()` 表头检测
- [ ] 实现 `_find_column()` 列查找
- [ ] 实现 `_merge_headers()` 多行表头合并

### Task 4.2: 源文件解析器
- [ ] 创建 `parser/source_parser.py`
- [ ] 实现工料机汇总文件解析
- [ ] 处理合并单元格
- [ ] 添加单元测试

### Task 4.3: 询价表解析器
- [ ] 创建 `parser/inquiry_parser.py`
- [ ] 实现多 Sheet 遍历
- [ ] 实现多报价列提取（单位1-3，价格1-3）
- [ ] 添加单元测试

---

## Phase 5: 匹配算法

### Task 5.1: 精确匹配器
- [ ] 创建 `matcher/exact_matcher.py`
- [ ] 实现字符串标准化（去空格、统一大小写）
- [ ] 实现精确匹配逻辑

### Task 5.2: 传统算法匹配器
- [ ] 创建 `matcher/traditional_matcher.py`
- [ ] 实现 Levenshtein 相似度
- [ ] 实现 Jaccard 相似度
- [ ] 实现 Jaro-Winkler 相似度
- [ ] 实现加权综合评分
- [ ] 添加单元测试

### Task 5.3: LLM 语义匹配器
- [ ] 创建 `matcher/llm_matcher.py`
- [ ] 实现 Ollama API 调用
- [ ] 设计并实现匹配提示词
- [ ] 实现响应解析
- [ ] 实现超时重试机制
- [ ] 添加单元测试

### Task 5.4: 匹配管道
- [ ] 创建 `matcher/pipeline.py`
- [ ] 实现策略配置解析（`--strategies` 参数）
- [ ] 实现按顺序执行的匹配流程
- [ ] 实现匹配结果记录

---

## Phase 6: 价格整合

### Task 6.1: 价格聚合器
- [ ] 创建 `aggregator/price_aggregator.py`
- [ ] 实现价格数据合并逻辑
- [ ] 实现差价计算
- [ ] 处理无匹配材料的情况

---

## Phase 7: Excel 导出

### Task 7.1: Excel 导出器
- [ ] 创建 `exporter/excel_exporter.py`
- [ ] 实现按模板样式输出
- [ ] 实现多报价横向排列
- [ ] 添加匹配状态列
- [ ] 保留表头格式

---

## Phase 8: CLI 接口

### Task 8.1: 命令行工具
- [ ] 创建 `cli.py`
- [ ] 实现所有命令行参数
- [ ] 实现 `--file1`, `--file2` 必需参数
- [ ] 实现 `--template`, `--output` 可选参数
- [ ] 实现 `--similarity` 阈值参数
- [ ] 实现 `--strategies` 策略范围参数
- [ ] 实现 `--verbose` 详细日志参数

### Task 8.2: 主流程集成
- [ ] 创建 `__main__.py`
- [ ] 集成解析器 → 匹配器 → 聚合器 → 导出器流程
- [ ] 添加进度条显示
- [ ] 添加错误处理

---

## Phase 9: 测试与验证

### Task 9.1: 单元测试
- [ ] 解析器测试
- [ ] 匹配算法测试
- [ ] 配置加载测试

### Task 9.2: 集成测试
- [ ] 使用实际 Excel 文件测试完整流程
- [ ] 验证输出格式
- [ ] 验证匹配准确率

---

## 优先级排序

| 优先级 | 任务 | 预估复杂度 |
|--------|------|-----------|
| P0 | 1.1, 1.2, 2.1 | 低 |
| P0 | 3.1, 4.1, 4.2 | 中 |
| P1 | 4.3, 5.1, 5.2 | 中 |
| P1 | 5.4, 6.1, 7.1 | 中 |
| P2 | 5.3 (LLM) | 高 |
| P2 | 8.1, 8.2 | 中 |
| P3 | 9.1, 9.2 | 中 |

---

## 执行建议

1. **先实现 P0 任务**：搭建骨架，确保基本流程可运行
2. **使用 `--strategies 1-2`**：跳过 LLM，先用传统算法验证流程
3. **最后集成 LLM**：等整体流程稳定后再添加 ollama 支持
