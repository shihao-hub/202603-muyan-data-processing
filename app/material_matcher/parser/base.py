"""解析器基类"""
from abc import ABC, abstractmethod
from typing import Optional
import pandas as pd


class BaseParser(ABC):
    """解析器基类"""

    HEADER_KEYWORDS = []  # 子类覆盖

    @abstractmethod
    def parse(self, file_path: str):
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

    def _safe_get(self, row: pd.Series, col_idx: Optional[int]) -> Optional[str]:
        """安全获取单元格值"""
        if col_idx is None:
            return None
        val = row.iloc[col_idx] if col_idx < len(row) else None
        return str(val) if pd.notna(val) else None

    def _safe_float(self, row: pd.Series, col_idx: Optional[int]) -> Optional[float]:
        """安全获取数值"""
        if col_idx is None:
            return None
        val = row.iloc[col_idx] if col_idx < len(row) else None
        if pd.isna(val):
            return None
        try:
            return float(val)
        except (ValueError, TypeError):
            return None
