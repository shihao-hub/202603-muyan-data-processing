"""询价表解析器 - 解析询价材料表（含多个报价）"""
from typing import Optional
import pandas as pd

from ..models.material import Material, PriceQuote
from ..config import get_config
from ..utils.logging import get_logger
from .base import BaseParser


logger = get_logger(__name__)


class InquiryParser(BaseParser):
    """解析询价材料表"""

    HEADER_KEYWORDS = ['序号', '名称', '报价单位']

    def parse(self, file_path: str) -> list[Material]:
        """解析询价表"""
        config = get_config()
        col_patterns = config.column_mapping.get('inquiry', {})

        xl = pd.ExcelFile(file_path)
        materials = []

        for sheet in xl.sheet_names:
            logger.info("parsing_inquiry_file", file=file_path, sheet=sheet)

            df = pd.read_excel(file_path, sheet_name=sheet, header=None)

            # 跳过空 Sheet
            if df.empty or len(df) < 3:
                logger.warning("skipping_empty_sheet", sheet=sheet)
                continue

            # 检测表头行
            header_row = self._detect_header_row(df, self.HEADER_KEYWORDS)

            # 询价表可能有多行表头（2-3行），需要合并
            headers_row1 = df.iloc[header_row].tolist()
            headers_row2 = df.iloc[header_row + 1].tolist() if len(df) > header_row + 1 else []

            # 合并表头
            headers = self._merge_headers(headers_row1, headers_row2)

            # 查找基础列
            col_map = {
                'id': self._find_column(headers, col_patterns.get('id', [])),
                'name': self._find_column(headers, col_patterns.get('name', [])),
                'specification': self._find_column(headers, col_patterns.get('specification', [])),
                'unit': self._find_column(headers, col_patterns.get('unit', [])),
                'control_price': self._find_column(headers, ['过控建议价']),
            }

            # 查找报价列对（单位1-3，价格1-3）
            quote_columns = self._find_quote_columns(headers)

            logger.debug("columns_mapped", col_map=col_map, quote_count=len(quote_columns))

            # 从第 header_row + 2 行开始读取数据
            data_start = header_row + 2
            if data_start >= len(df):
                continue

            data_df = df.iloc[data_start:]

            for i, row in data_df.iterrows():
                name_val = self._safe_get(row, col_map.get('name'))
                if not name_val:  # 跳过空行
                    continue

                # 提取报价
                quotes = []
                for qc in quote_columns:
                    supplier = self._safe_get(row, qc['supplier_col'])
                    price = self._safe_float(row, qc['price_col'])
                    if supplier and price:
                        quotes.append(PriceQuote(
                            supplier=supplier,
                            price=price,
                            source_file=file_path
                        ))

                material = Material(
                    id=self._safe_get(row, col_map.get('id')) or str(i),
                    name=name_val,
                    specification=self._safe_get(row, col_map.get('specification')),
                    unit=self._safe_get(row, col_map.get('unit')),
                    control_price=self._safe_float(row, col_map.get('control_price')),
                    quotes=quotes,
                    source_file=file_path,
                    source_sheet=sheet,
                    source_row=int(i)
                )
                materials.append(material)

        logger.info("inquiry_file_parsed", count=len(materials))
        return materials

    def _merge_headers(self, row1: list, row2: list) -> list:
        """合并多行表头"""
        import re
        result = []
        for i in range(max(len(row1), len(row2))):
            val1 = str(row1[i]) if i < len(row1) and not pd.isna(row1[i]) else ""
            val2 = str(row2[i]) if i < len(row2) and not pd.isna(row2[i]) else ""

            # 如果第二行包含更具体的编号（如"单位1"、"单位2"），优先使用第二行
            # 否则优先使用第一行，最后尝试拼接
            has_numbering = bool(re.search(r'单位\d|序号\d|列\d', val2))
            if has_numbering and val2:
                merged = val2
            elif val1:
                merged = val1
            elif val2:
                merged = val2
            else:
                merged = ""
            result.append(merged)
        return result

    def _find_quote_columns(self, headers: list) -> list[dict]:
        """查找报价列对（单位+价格）"""
        quotes = []

        # 查找单位1、单位2、单位3 对应的价格列
        for i in range(1, 4):
            # 查找单位列
            unit_col = None
            for idx, h in enumerate(headers):
                if pd.isna(h):
                    continue
                h_str = str(h)
                if f'单位{i}' in h_str or (i == 1 and '单位1' in h_str):
                    unit_col = idx
                    break

            # 查找价格列（通常在单位列的后面1-2列）
            price_col = None
            if unit_col is not None:
                # 向后查找"不含税"或"单价"
                for offset in [1, 2, 3]:
                    check_idx = unit_col + offset
                    if check_idx < len(headers):
                        h = headers[check_idx]
                        if not pd.isna(h) and ('不含税' in str(h) or '单价' in str(h)):
                            price_col = check_idx
                            break

            if unit_col is not None:
                quotes.append({
                    'supplier_col': unit_col,
                    'price_col': price_col,
                    'index': i
                })

        return quotes
