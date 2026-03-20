# Requirements Document

## Introduction

设计并实现一个 Python CLI 工具，用于匹配两个 Excel 文件中规格名称相近的建筑材料，并将匹配后的材料价格按指定样式排列输出。该工具需要处理材料名称不完全一致的情况，通过传统算法和本地 ollama 的 qwen2.5:0.5b 模型进行语义分析和匹配。

## Requirements

### Requirement 1: CLI 命令行接口

**User Story:** 作为用户，我希望通过命令行参数指定输入文件和配置，以便灵活使用工具处理不同的数据文件。

#### Acceptance Criteria

1. WHEN 用户执行命令时 THEN 系统 SHALL 支持 `--file1` 参数指定第一个输入文件（工料机汇总表）
2. WHEN 用户执行命令时 THEN 系统 SHALL 支持 `--file2` 参数指定第二个输入文件（询价材料表）
3. WHEN 用户执行命令时 THEN 系统 SHALL 支持 `--template` 参数指定输出样式参考文件
4. WHEN 用户执行命令时 THEN 系统 SHALL 支持 `--output` 参数指定输出文件路径（默认为 `matched_prices.xlsx`）
5. WHEN 用户执行命令时 THEN 系统 SHALL 支持 `--similarity` 参数指定匹配相似度阈值（默认 0.7）
6. WHEN 用户执行命令时 THEN 系统 SHALL 支持 `--verbose` 参数启用详细日志输出
7. WHEN 用户执行命令时 THEN 系统 SHALL 支持 `--strategies` 参数控制匹配策略层级（如 `1`、`1-2`、`1-3`，默认 `1-3`）
8. IF 用户未提供必需参数 THEN 系统 SHALL 显示帮助信息并退出

### Requirement 2: Excel 文件解析

**User Story:** 作为用户，我希望工具能够自动解析不同结构的 Excel 文件，提取材料信息和价格数据。

#### Acceptance Criteria

1. WHEN 读取工料机汇总文件时 THEN 系统 SHALL 自动识别数据表头（跳过标题行）
2. WHEN 读取询价材料表时 THEN 系统 SHALL 支持多 Sheet 解析
3. WHEN 解析文件时 THEN 系统 SHALL 提取以下字段：序号、材料名称、规格型号、单位、数量
4. WHEN 解析询价材料表时 THEN 系统 SHALL 提取所有报价单位及其价格（单位1-3、价格1-3）
5. IF 文件格式无法识别 THEN 系统 SHALL 记录错误日志并提示用户
6. WHEN 遇到合并单元格时 THEN 系统 SHALL 正确处理并保留原始数据

### Requirement 3: 材料名称语义匹配

**User Story:** 作为用户，我希望工具能够智能匹配名称不完全相同但实际为同一材料的记录，以便准确对比价格。

#### 匹配策略层次

系统 SHALL 按以下顺序依次尝试匹配，任一层级匹配成功即停止：

1. **精确匹配** - 字符串完全一致
2. **传统算法匹配** - 快速、稳定、离线计算
   - Levenshtein 编辑距离（归一化）
   - Jaccard 相似度
   - Jaro-Winkler 相似度
   - 综合加权打分
3. **LLM 语义匹配** - 处理语义等价但字面差异大的情况
   - ollama qwen2.5:0.5b

#### Acceptance Criteria

1. WHEN 匹配材料时 THEN 系统 SHALL 首先进行精确字符串匹配
2. IF 精确匹配失败 THEN 系统 SHALL 依次使用传统算法计算相似度
   - Levenshtein：计算归一化编辑距离，阈值 0.8
   - Jaccard：基于字符集合计算重叠度，阈值 0.7
   - Jaro-Winkler：对短字符串效果好的相似度算法，阈值 0.85
   - 综合：取多种算法的最高分或加权平均
3. IF 传统算法相似度低于阈值 THEN 系统 SHALL 调用本地 ollama qwen2.5:0.5b 进行语义分析
4. WHEN 调用 ollama 时 THEN 系统 SHALL 构造包含材料名称和规格的匹配提示词
5. WHEN 语义匹配时 THEN 系统 SHALL 返回相似度分数（0-1 范围）
6. IF 相似度分数超过阈值 THEN 系统 SHALL 将两条记录标记为匹配
7. WHEN 匹配完成时 THEN 系统 SHALL 记录匹配方式（exact/traditional/llm）和置信度到日志
8. IF ollama 服务不可用 THEN 系统 SHALL 仅使用传统算法，记录警告日志
9. WHEN 规格型号不同但材料名称相同时 THEN 系统 SHALL 优先按规格分组后匹配
10. WHEN 用户指定匹配策略范围时 THEN 系统 SHALL 支持 `--strategies` 参数控制使用的匹配策略层级
    - `--strategies 1` 只使用精确匹配
    - `--strategies 1-2` 使用精确匹配 + 传统算法（不调用 LLM）
    - `--strategies 1-3` 或默认：使用全部三层策略
11. WHEN 指定策略范围时 THEN 系统 SHALL 在日志中记录实际使用的匹配策略

### Requirement 4: 价格数据整合

**User Story:** 作为用户，我希望匹配后的材料价格按指定格式排列，方便对比分析。

#### Acceptance Criteria

1. WHEN 整合价格时 THEN 系统 SHALL 将工料机汇总的"调价(元)"作为基准价格
2. WHEN 整合价格时 THEN 系统 SHALL 将询价材料的多个报价单位价格横向排列
3. WHEN 输出时 THEN 系统 SHALL 包含过控建议价（如有）
4. WHEN 输出时 THEN 系统 SHALL 计算预算与概算差价（如适用）
5. IF 某材料无匹配项 THEN 系统 SHALL 仍输出该材料，价格列标记为空
6. WHEN 输出时 THEN 系统 SHALL 保留原始材料的备注信息

### Requirement 5: 输出格式

**User Story:** 作为用户，我希望输出文件按照指定的样式模板格式化，便于后续审阅和使用。

#### Acceptance Criteria

1. WHEN 生成输出文件时 THEN 系统 SHALL 参考模板文件的列结构
2. WHEN 生成输出文件时 THEN 系统 SHALL 包含以下列：序号、材料名称、规格型号、单位、数量、预算材料单价、各报价单位价格、过控建议价、备注
3. WHEN 生成输出文件时 THEN 系统 SHALL 保留表头格式和样式
4. WHEN 生成输出文件时 THEN 系统 SHALL 添加匹配状态列标识匹配来源
5. IF 模板文件不存在 THEN 系统 SHALL 使用默认输出格式

### Requirement 6: 日志记录

**User Story:** 作为用户，我希望工具输出详细的处理日志，便于排查问题和了解处理进度。

#### Acceptance Criteria

1. WHEN 工具启动时 THEN 系统 SHALL 使用 structlog 记录开始信息
2. WHEN 读取文件时 THEN 系统 SHALL 记录文件名和解析结果统计
3. WHEN 进行匹配时 THEN 系统 SHALL 记录每次匹配的材料名称、匹配策略和相似度
4. WHEN 发生错误时 THEN 系统 SHALL 记录错误详情和堆栈信息
5. WHEN 工具完成时 THEN 系统 SHALL 记录处理统计（总记录数、匹配成功数、失败数）
6. WHEN 使用 `--verbose` 参数时 THEN 系统 SHALL 输出更详细的调试信息
7. WHEN 输出日志时 THEN 系统 SHALL 支持结构化日志格式（JSON）便于后续分析

### Requirement 7: 通用性设计

**User Story:** 作为用户，我希望工具能够适应不同结构的 Excel 文件，而不仅限于当前的文件格式。

#### Acceptance Criteria

1. WHEN 解析文件时 THEN 系统 SHALL 支持配置文件指定列名映射
2. WHEN 解析文件时 THEN 系统 SHALL 自动检测可能的表头行
3. WHEN 列名不匹配时 THEN 系统 SHALL 支持交互式指定列映射
4. WHEN 输出时 THEN 系统 SHALL 支持自定义输出列配置
5. IF 配置文件存在 THEN 系统 SHALL 优先使用配置文件中的设置

### Requirement 8: 性能与容错

**User Story:** 作为用户，我希望工具能够高效处理大量数据，并在出现问题时优雅处理。

#### Acceptance Criteria

1. WHEN 处理超过 1000 条记录时 THEN 系统 SHALL 显示进度条
2. WHEN ollama 调用超时时 THEN 系统 SHALL 自动重试最多 3 次
3. WHEN 单条记录处理失败时 THEN 系统 SHALL 记录错误并继续处理其他记录
4. WHEN 内存使用超过阈值时 THEN 系统 SHALL 支持分批处理模式
5. WHEN 用户中断程序时 THEN 系统 SHALL 保存已处理的结果
