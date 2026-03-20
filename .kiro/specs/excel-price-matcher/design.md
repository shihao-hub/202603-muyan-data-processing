# Design Document

## 1. 系统架构

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLI Entry Point                         │
│                      (main.py / __main__.py)                    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Core Pipeline                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │  Parser  │→ │ Matcher  │→ │ Aggregator│→ │ Exporter │        │
│  │  解析器   │  │  匹配器   │  │  整合器   │  │  导出器   │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
└─────────────────────────────────────────────────────────────────┘
        │               │               │               │
        ▼               ▼               ▼               ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│   Models    │ │  Strategies │ │   Config    │ │    Logger   │
│   数据模型   │ │   匹配策略   │ │    配置     │ │ structlog   │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
```

## 2. 模块设计

### 2.1 目录结构

```
material_matcher/
├── __init__.py
├── __main__.py           # CLI 入口
├── cli.py                # 命令行参数解析
├── config.py             # 配置管理
├── models/
│   ├── __init__.py
│   ├── material.py       # 材料数据模型
│   └── price.py          # 价格数据模型
├── parser/
│   ├── __init__.py
│   ├── base.py           # 解析器基类
│   ├── source_parser.py  # 源文件解析器
│   └── template_parser.py # 模板解析器
├── matcher/
│   ├── __init__.py
│   ├── base.py           # 匹配器基类
│   ├── exact_matcher.py  # 精确匹配
│   ├── traditional_matcher.py  # 传统算法匹配
│   ├── llm_matcher.py    # LLM 语义匹配
│   └── pipeline.py       # 匹配管道
├── aggregator/
│   ├── __init__.py
│   └── price_aggregator.py  # 价格整合
├── exporter/
│   ├── __init__.py
│   └── excel_exporter.py    # Excel 导出
└── utils/
    ├── __init__.py
    ├── text_similarity.py   # 文本相似度算法
    └── ollama_client.py     # Ollama API 客户端
```

### 2.2 模块职责

| 模块 | 职责 |
|------|------|
| `cli` | 解析命令行参数，初始化配置，启动处理流程 |
| `config` | 管理配置文件、列名映射、阈值设置 |
| `models` | 定义材料和价格的数据结构 |
| `parser` | 解析 Excel 文件，自动识别表头，提取数据 |
| `matcher` | 实现多层匹配策略 |
| `aggregator` | 整合匹配结果，合并价格数据 |
| `exporter` | 按模板样式输出 Excel 文件 |
| `utils` | 通用工具函数 |

## 3. 数据模型

### 3.1 Material（材料）

```python
from dataclasses import dataclass, field
from typing import Optional
from enum import Enum

class MatchMethod(Enum):
    EXACT = "exact"
    TRADITIONAL = "traditional"
    LLM = "llm"
    NONE = "none"

@dataclass
class PriceQuote:
    """单个报价"""
    supplier: str          # 供应商/报价单位
    price: float          # 不含税单价
    source_file: str      # 来源文件

@dataclass
class Material:
    """材料信息"""
    # 基础信息
    id: str                              # 唯一标识（序号）
    name: str                            # 材料名称
    specification: Optional[str] = None  # 规格型号
    unit: Optional[str] = None           # 单位
    quantity: Optional[float] = None     # 数量

    # 价格信息
    base_price: Optional[float] = None   # 基准价格（调价/预算单价）
    quotes: list[PriceQuote] = field(default_factory=list)  # 报价列表

    # 匹配信息
    match_method: MatchMethod = MatchMethod.NONE
    match_confidence: float = 0.0
    matched_name: Optional[str] = None   # 匹配到的名称

    # 来源信息
    source_file: str = ""
    source_sheet: str = ""
    source_row: int = 0

    # 其他
    remarks: Optional[str] = None        # 备注
    control_price: Optional[float] = None  # 过控建议价
```

### 3.2 MatchResult（匹配结果）

```python
@dataclass
class MatchResult:
    """匹配结果"""
    material_a: Material      # 源材料（工料机汇总）
    material_b: Material      # 匹配材料（询价表）
    method: MatchMethod       # 匹配方法
    confidence: float         # 置信度
    algorithm: Optional[str] = None  # 使用的具体算法
```

## 4. 匹配算法设计

### 4.1 匹配流程

```
┌─────────────────────────────────────────────────────────────────┐
│                        Match Pipeline                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Material A ──► ┌─────────────┐                                │
│                 │   Exact     │ ──Match──► Result               │
│  Material B ──► │   Matcher   │                                │
│                 └─────────────┘                                │
│                       │ No Match                               │
│                       ▼                                        │
│                 ┌─────────────┐                                │
│                 │ Traditional │ ──Match──► Result               │
│                 │   Matcher   │                                │
│                 └─────────────┘                                │
│                       │ No Match                               │
│                       ▼                                        │
│                 ┌─────────────┐                                │
│                 │    LLM      │ ──Match──► Result               │
│                 │   Matcher   │                                │
│                 └─────────────┘                                │
│                       │ No Match                               │
│                       ▼                                        │
│                  No Match                                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 精确匹配器 (ExactMatcher)

```python
class ExactMatcher:
    """精确字符串匹配"""

    def match(self, name_a: str, name_b: str) -> tuple[bool, float]:
        """
        精确匹配（忽略首尾空格，统一大小写）

        Returns:
            (is_match, confidence) - 匹配结果和置信度
        """
        normalized_a = self._normalize(name_a)
        normalized_b = self._normalize(name_b)

        if normalized_a == normalized_b:
            return True, 1.0
        return False, 0.0

    def _normalize(self, text: str) -> str:
        """标准化文本"""
        return text.strip().lower()
```

### 4.3 传统算法匹配器 (TraditionalMatcher)

```python
class TraditionalMatcher:
    """传统文本相似度算法"""

    ALGORITHMS = {
        'levenshtein': {
            'func': self._levenshtein_similarity,
            'threshold': 0.8,
            'weight': 0.3
        },
        'jaccard': {
            'func': self._jaccard_similarity,
            'threshold': 0.7,
            'weight': 0.3
        },
        'jaro_winkler': {
            'func': self._jaro_winkler_similarity,
            'threshold': 0.85,
            'weight': 0.4
        }
    }

    def match(self, name_a: str, name_b: str) -> tuple[bool, float, str]:
        """
        使用传统算法匹配

        Returns:
            (is_match, confidence, algorithm_name)
        """
        scores = {}

        for algo_name, config in self.ALGORITHMS.items():
            score = config['func'](name_a, name_b)
            scores[algo_name] = score

            # 单算法达到阈值即返回
            if score >= config['threshold']:
                return True, score, algo_name

        # 加权综合得分
        weighted_score = sum(
            scores[name] * config['weight']
            for name, config in self.ALGORITHMS.items()
        )

        if weighted_score >= 0.75:
            return True, weighted_score, 'weighted'

        return False, weighted_score, 'weighted'

    def _levenshtein_similarity(self, a: str, b: str) -> float:
        """归一化编辑距离相似度"""
        # 使用 python-Levenshtein 库
        import Levenshtein
        return Levenshtein.ratio(a, b)

    def _jaccard_similarity(self, a: str, b: str) -> float:
        """Jaccard 相似度（基于字符集合）"""
        set_a = set(a)
        set_b = set(b)
        intersection = len(set_a & set_b)
        union = len(set_a | set_b)
        return intersection / union if union > 0 else 0.0

    def _jaro_winkler_similarity(self, a: str, b: str) -> float:
        """Jaro-Winkler 相似度"""
        import Levenshtein
        return Levenshtein.jaro_winkler(a, b)
```

### 4.4 LLM 语义匹配器 (LLMMatcher)

```python
class LLMMatcher:
    """基于 Ollama 的语义匹配"""

    def __init__(self, model: str = "qwen2.5:0.5b", base_url: str = "http://localhost:11434"):
        self.model = model
        self.base_url = base_url

    def match(self, name_a: str, name_b: str) -> tuple[bool, float]:
        """
        使用 LLM 进行语义匹配

        Returns:
            (is_match, confidence)
        """
        prompt = self._build_prompt(name_a, name_b)

        try:
            response = self._call_ollama(prompt)
            return self._parse_response(response)
        except Exception as e:
            logger.error("ollama_call_failed", error=str(e))
            return False, 0.0

    def _build_prompt(self, a: str, b: str) -> str:
        """构建提示词"""
        return f"""判断以下两个材料名称是否指代同一种建筑材料。

材料A: {a}
材料B: {b}

请只回复 JSON 格式：
{{"is_same": true/false, "confidence": 0.0-1.0, "reason": "简短原因"}}"""

    def _call_ollama(self, prompt: str) -> str:
        """调用 Ollama API"""
        import requests

        response = requests.post(
            f"{self.base_url}/api/generate",
            json={
                "model": self.model,
                "prompt": prompt,
                "stream": False
            },
            timeout=30
        )
        return response.json().get("response", "")

    def _parse_response(self, response: str) -> tuple[bool, float]:
        """解析 LLM 响应"""
        import json
        try:
            # 提取 JSON
            import re
            json_match = re.search(r'\{[^}]+\}', response)
            if json_match:
                result = json.loads(json_match.group())
                return result.get("is_same", False), result.get("confidence", 0.0)
        except json.JSONDecodeError:
            pass
        return False, 0.0
```

### 4.5 匹配管道 (MatchPipeline)

```python
class MatchPipeline:
    """匹配策略管道"""

    def __init__(self, strategies: str = "1-3"):
        """
        Args:
            strategies: "1", "1-2", "1-3"
        """
        self.matchers = self._build_matchers(strategies)

    def _build_matchers(self, strategies: str) -> list:
        """根据策略配置构建匹配器"""
        matchers = []

        if '1' in strategies:
            matchers.append(('exact', ExactMatcher()))
        if '2' in strategies:
            matchers.append(('traditional', TraditionalMatcher()))
        if '3' in strategies:
            matchers.append(('llm', LLMMatcher()))

        return matchers

    def match(self, materials_a: list[Material], materials_b: list[Material]) -> list[MatchResult]:
        """执行匹配"""
        results = []

        for mat_a in logger.progress("matching", materials_a):
            best_match = None
            best_confidence = 0.0

            for mat_b in materials_b:
                if mat_b.match_method != MatchMethod.NONE:
                    continue  # 跳过已匹配的

                for matcher_name, matcher in self.matchers:
                    is_match, confidence, *extra = matcher.match(
                        mat_a.name,
                        mat_b.name
                    )

                    if is_match and confidence > best_confidence:
                        best_match = mat_b
                        best_confidence = confidence
                        best_method = matcher_name

                        logger.info(
                            "material_matched",
                            name_a=mat_a.name,
                            name_b=mat_b.name,
                            method=matcher_name,
                            confidence=confidence
                        )

                        if matcher_name == 'exact':
                            break  # 精确匹配，直接使用

            if best_match:
                results.append(MatchResult(
                    material_a=mat_a,
                    material_b=best_match,
                    method=MatchMethod(best_method),
                    confidence=best_confidence
                ))
                best_match.match_method = MatchMethod(best_method)

        return results
```

## 5. Excel 解析设计

### 5.1 解析器基类

```python
from abc import ABC, abstractmethod
import pandas as pd

class BaseParser(ABC):
    """解析器基类"""

    @abstractmethod
    def parse(self, file_path: str) -> list[Material]:
        """解析文件，返回材料列表"""
        pass

    def _detect_header_row(self, df: pd.DataFrame, keywords: list[str]) -> int:
        """自动检测表头行"""
        for i, row in df.iterrows():
            row_str = ' '.join(str(v) for v in row.values if pd.notna(v))
            if any(kw in row_str for kw in keywords):
                return i
        return 0

    def _find_column(self, headers: list, patterns: list[str]) -> Optional[int]:
        """根据模式查找列索引"""
        for i, h in enumerate(headers):
            if pd.isna(h):
                continue
            h_str = str(h).lower()
            for pattern in patterns:
                if pattern.lower() in h_str:
                    return i
        return None
```

### 5.2 源文件解析器

```python
class SourceParser(BaseParser):
    """解析工料机汇总文件"""

    HEADER_KEYWORDS = ['序号', '材料名称']
    COLUMN_PATTERNS = {
        'id': ['序号'],
        'name': ['材料名称', '名称'],
        'specification': ['规格', '型号', '规格型号'],
        'unit': ['单位'],
        'quantity': ['数量', '暂估量', '工程量'],
        'base_price': ['调价', '预算', '单价']
    }

    def parse(self, file_path: str) -> list[Material]:
        """解析源文件"""
        xl = pd.ExcelFile(file_path)
        materials = []

        for sheet in xl.sheet_names:
            df = pd.read_excel(file_path, sheet_name=sheet, header=None)

            # 检测表头行
            header_row = self._detect_header_row(df, self.HEADER_KEYWORDS)
            headers = df.iloc[header_row].tolist()
            data_df = df.iloc[header_row + 1:]

            # 映射列索引
            col_map = {
                key: self._find_column(headers, patterns)
                for key, patterns in self.COLUMN_PATTERNS.items()
            }

            logger.info(
                "file_parsed",
                file=file_path,
                sheet=sheet,
                header_row=header_row,
                columns=col_map
            )

            # 提取数据
            for i, row in data_df.iterrows():
                if pd.isna(row.iloc[col_map.get('id', 0)]):
                    continue

                material = Material(
                    id=str(row.iloc[col_map['id']]) if col_map.get('id') else str(i),
                    name=str(row.iloc[col_map['name']]) if col_map.get('name') else '',
                    specification=self._safe_get(row, col_map.get('specification')),
                    unit=self._safe_get(row, col_map.get('unit')),
                    quantity=self._safe_float(row, col_map.get('quantity')),
                    base_price=self._safe_float(row, col_map.get('base_price')),
                    source_file=file_path,
                    source_sheet=sheet,
                    source_row=i
                )
                materials.append(material)

        return materials
```

### 5.3 询价表解析器

```python
class InquiryParser(BaseParser):
    """解析询价材料表（含多个报价）"""

    HEADER_KEYWORDS = ['序号', '名称', '报价单位']

    def parse(self, file_path: str) -> list[Material]:
        """解析询价表"""
        xl = pd.ExcelFile(file_path)
        materials = []

        for sheet in xl.sheet_names:
            df = pd.read_excel(file_path, sheet_name=sheet, header=None)

            # 跳过空 Sheet
            if df.empty:
                continue

            header_row = self._detect_header_row(df, self.HEADER_KEYWORDS)

            # 询价表可能有多行表头
            headers_row1 = df.iloc[header_row].tolist()
            headers_row2 = df.iloc[header_row + 1].tolist() if len(df) > header_row + 1 else []

            # 合并表头
            headers = self._merge_headers(headers_row1, headers_row2)

            data_df = df.iloc[header_row + 2:]  # 询价表通常有2行表头

            # 查找报价列（单位1-3，价格1-3）
            quote_columns = self._find_quote_columns(headers)

            for i, row in data_df.iterrows():
                material = self._parse_row(row, headers, col_map, quote_columns)
                if material:
                    material.source_file = file_path
                    material.source_sheet = sheet
                    material.source_row = i
                    materials.append(material)

        return materials

    def _find_quote_columns(self, headers: list) -> list[dict]:
        """查找报价列对（单位+价格）"""
        quotes = []
        for i in range(1, 4):  # 支持3个报价
            unit_col = self._find_column(headers, [f'单位{i}'])
            price_col = self._find_column(headers, [f'不含税', f'单价'])
            if price_col is not None:
                quotes.append({
                    'supplier_col': unit_col,
                    'price_col': price_col,
                    'index': i
                })
        return quotes
```

## 6. CLI 接口设计

```python
# cli.py
import click
from pathlib import Path

@click.command()
@click.option('--file1', '-a', required=True, type=click.Path(exists=True),
              help='源文件A（工料机汇总表）')
@click.option('--file2', '-b', required=True, type=click.Path(exists=True),
              help='源文件B（询价材料表）')
@click.option('--template', '-t', type=click.Path(exists=True),
              help='输出样式模板文件')
@click.option('--output', '-o', default='matched_prices.xlsx',
              help='输出文件路径')
@click.option('--similarity', '-s', default=0.7, type=float,
              help='匹配相似度阈值')
@click.option('--strategies', default='1-3',
              help='匹配策略层级 (1=精确, 2=传统算法, 3=LLM)')
@click.option('--verbose', '-v', is_flag=True,
              help='详细日志输出')
def main(file1, file2, template, output, similarity, strategies, verbose):
    """材料价格匹配工具"""
    from .config import setup_logging, Config
    from .parser import SourceParser, InquiryParser
    from .matcher import MatchPipeline
    from .aggregator import PriceAggregator
    from .exporter import ExcelExporter

    # 初始化日志
    setup_logging(verbose)

    logger.info("tool_started",
                file1=file1, file2=file2,
                strategies=strategies)

    # 解析文件
    parser_a = SourceParser()
    parser_b = InquiryParser()

    materials_a = parser_a.parse(file1)
    materials_b = parser_b.parse(file2)

    logger.info("files_parsed",
                count_a=len(materials_a),
                count_b=len(materials_b))

    # 执行匹配
    pipeline = MatchPipeline(strategies)
    match_results = pipeline.match(materials_a, materials_b)

    logger.info("matching_completed",
                matched=len(match_results),
                unmatched=len(materials_a) - len(match_results))

    # 整合价格
    aggregator = PriceAggregator()
    aggregated = aggregator.aggregate(materials_a, match_results)

    # 导出
    exporter = ExcelExporter(template)
    exporter.export(aggregated, output)

    logger.info("tool_completed", output=output)

if __name__ == '__main__':
    main()
```

## 7. 配置设计

### 7.1 配置文件 (config.yaml)

```yaml
# 列名映射（可自定义）
column_mapping:
  source:
    id: ['序号']
    name: ['材料名称', '名称']
    specification: ['规格', '型号', '规格型号']
    unit: ['单位']
    quantity: ['数量', '暂估量', '工程量']
    base_price: ['调价', '预算材料单价', '单价']

  inquiry:
    id: ['序号']
    name: ['名称', '名称规格型号', '名称、规格、型号']
    specification: ['规格', '型号']
    unit: ['单位']
    quantity: ['暂估量', '工程量']

# 匹配阈值
thresholds:
  exact: 1.0
  levenshtein: 0.8
  jaccard: 0.7
  jaro_winkler: 0.85
  weighted: 0.75
  llm: 0.7

# Ollama 配置
ollama:
  base_url: http://localhost:11434
  model: qwen2.5:0.5b
  timeout: 30
  max_retries: 3
```

### 7.2 配置加载

```python
# config.py
import yaml
from pathlib import Path
from dataclasses import dataclass

@dataclass
class Config:
    column_mapping: dict
    thresholds: dict
    ollama: dict

    @classmethod
    def load(cls, path: Optional[str] = None) -> 'Config':
        """加载配置"""
        if path and Path(path).exists():
            with open(path, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
        else:
            data = cls._default_config()

        return cls(
            column_mapping=data.get('column_mapping', {}),
            thresholds=data.get('thresholds', {}),
            ollama=data.get('ollama', {})
        )

    @staticmethod
    def _default_config() -> dict:
        """默认配置"""
        return {
            'column_mapping': {...},
            'thresholds': {...},
            'ollama': {...}
        }
```

## 8. 日志设计

```python
# utils/logging.py
import structlog

def setup_logging(verbose: bool = False):
    """配置 structlog"""
    level = "DEBUG" if verbose else "INFO"

    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.dev.ConsoleRenderer(colors=True)
        ],
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )

    # 返回 logger
    return structlog.get_logger()
```

## 9. 依赖清单

```toml
# pyproject.toml
[project]
name = "material-matcher"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = [
    "pandas>=2.0",
    "openpyxl>=3.1",
    "click>=8.0",
    "structlog>=23.0",
    "python-Levenshtein>=0.21",
    "pyyaml>=6.0",
    "requests>=2.28",
    "rich>=13.0",  # 进度条
]

[project.scripts]
material-matcher = "material_matcher.cli:main"
```
