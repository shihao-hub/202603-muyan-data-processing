"""配置管理"""
import yaml
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


DEFAULT_CONFIG = """
column_mapping:
  source:
    id: ['序号']
    name: ['材料名称']
    specification: ['规格', '型号', '规格型号']
    unit: ['单位']
    quantity: ['数量']
    base_price: ['调价', '预算材料单价', '单价']

  inquiry:
    id: ['序号']
    name: ['名称', '名称规格型号', '名称、规格、型号']
    specification: ['规格', '型号']
    unit: ['单位']
    quantity: ['暂估量', '工程量']

thresholds:
  exact: 1.0
  levenshtein: 0.8
  jaccard: 0.7
  jaro_winkler: 0.85
  weighted: 0.75
  llm: 0.7

ollama:
  base_url: http://localhost:11434
  model: qwen2.5:0.5b
  timeout: 30
  max_retries: 3
"""


@dataclass
class Config:
    """配置类"""
    column_mapping: dict
    thresholds: dict
    ollama: dict

    @classmethod
    def load(cls, path: Optional[str] = None) -> "Config":
        """加载配置"""
        if path and Path(path).exists():
            with open(path, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
        else:
            data = yaml.safe_load(DEFAULT_CONFIG)

        return cls(
            column_mapping=data.get('column_mapping', {}),
            thresholds=data.get('thresholds', {}),
            ollama=data.get('ollama', {})
        )


# 全局配置实例
_config: Optional[Config] = None


def get_config() -> Config:
    """获取全局配置"""
    global _config
    if _config is None:
        _config = Config.load()
    return _config


def set_config(config: Config):
    """设置全局配置"""
    global _config
    _config = config
