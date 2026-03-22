"""源文件解析器 - 解析工料机汇总表"""
from typing import Optional
import pandas as pd

from ..models.material import Material
from ..config import get_config
from ..utils.logging import get_logger
from .base import BaseParser


logger = get_logger(__name__)


class SourceParser(BaseParser):
    """解析工料机汇总文件"""

    HEADER_KEYWORDS = ['序号', '材料名称']

    def parse(self, file_path: str) -> list[Material]:
        """解析源文件"""
        config = get_config()
        col_patterns = config.column_mapping.get('source', {})

        xl = pd.ExcelFile(file_path)
        materials = []

        for sheet in xl.sheet_names:
            logger.info("parsing_source_file", file=file_path, sheet=sheet)

            df = pd.read_excel(file_path, sheet_name=sheet, header=None)

            # 检测表头行
            header_row = self._detect_header_row(df, self.HEADER_KEYWORDS)
            headers = df.iloc[header_row].tolist()
            data_df = df.iloc[header_row + 1:]

            # 映射列索引
            col_map = {
                'id': self._find_column(headers, col_patterns.get('id', [])),
                'name': self._find_column(headers, col_patterns.get('name', [])),
                'specification': self._find_column(headers, col_patterns.get('specification', [])),
                'unit': self._find_column(headers, col_patterns.get('unit', [])),
                'quantity': self._find_column(headers, col_patterns.get('quantity', [])),
                'base_price': self._find_column(headers, col_patterns.get('base_price', [])),
            }

            logger.debug("columns_mapped", col_map=col_map)

            # 提取数据
            for i, row in data_df.iterrows():
                name_val = self._safe_get(row, col_map.get('name'))
                if not name_val:  # 跳过空行
                    continue

                material = Material(
                    id=self._safe_get(row, col_map.get('id')) or str(i),
                    name=name_val,
                    specification=self._safe_get(row, col_map.get('specification')),
                    unit=self._safe_get(row, col_map.get('unit')),
                    quantity=self._safe_float(row, col_map.get('quantity')),
                    base_price=self._safe_float(row, col_map.get('base_price')),
                    source_file=file_path,
                    source_sheet=sheet,
                    source_row=int(i)
                )
                materials.append(material)

        logger.info("source_file_parsed", count=len(materials))
        return materials
