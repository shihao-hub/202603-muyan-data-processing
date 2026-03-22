"""数据模型"""
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional


class MatchMethod(Enum):
    """匹配方法"""
    EXACT = "exact"
    TRADITIONAL = "traditional"
    LLM = "llm"
    NONE = "none"


@dataclass
class PriceQuote:
    """单个报价"""
    supplier: str = ""           # 供应商/报价单位
    price: float = 0.0           # 不含税单价
    source_file: str = ""        # 来源文件

    def __repr__(self):
        return f"PriceQuote(supplier={self.supplier!r}, price={self.price})"


@dataclass
class Material:
    """材料信息"""
    # 基础信息
    id: str = ""                              # 唯一标识（序号）
    name: str = ""                            # 材料名称
    specification: Optional[str] = None       # 规格型号
    unit: Optional[str] = None                # 单位
    quantity: Optional[float] = None         # 数量

    # 价格信息
    base_price: Optional[float] = None        # 基准价格（调价/预算单价）
    quotes: list[PriceQuote] = field(default_factory=list)  # 报价列表

    # 匹配信息
    match_method: MatchMethod = MatchMethod.NONE
    match_confidence: float = 0.0
    matched_name: Optional[str] = None        # 匹配到的名称

    # 来源信息
    source_file: str = ""
    source_sheet: str = ""
    source_row: int = 0

    # 其他
    remarks: Optional[str] = None             # 备注
    control_price: Optional[float] = None     # 过控建议价

    def __repr__(self):
        return f"Material(id={self.id!r}, name={self.name!r}, spec={self.specification!r})"


@dataclass
class MatchResult:
    """匹配结果"""
    material_a: Material      # 源材料（工料机汇总）
    material_b: Material      # 匹配材料（询价表）
    method: MatchMethod       # 匹配方法
    confidence: float         # 置信度
    algorithm: Optional[str] = None  # 使用的具体算法


@dataclass
class AggregatedMaterial:
    """整合后的材料数据"""
    # 基础信息（来自源文件A）
    id: str = ""
    name: str = ""
    specification: Optional[str] = None
    unit: Optional[str] = None
    quantity: Optional[float] = None
    budget_price: Optional[float] = None      # 预算材料单价（调价）

    # 报价信息（来自匹配的询价表）
    quotes: list[PriceQuote] = field(default_factory=list)
    control_price: Optional[float] = None     # 过控建议价

    # 匹配信息
    match_status: str = "unmatched"           # "exact" / "traditional" / "llm" / "unmatched"
    match_confidence: float = 0.0

    # 计算字段
    price_diff: Optional[float] = None        # 预算与概算差价

    # 其他
    remarks: Optional[str] = None

    def __repr__(self):
        return f"AggregatedMaterial(id={self.id!r}, name={self.name!r}, status={self.match_status!r})"
