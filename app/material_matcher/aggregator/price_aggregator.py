"""价格整合器"""
from typing import Optional

from ..models.material import Material, MatchResult, AggregatedMaterial
from ..utils.logging import get_logger


logger = get_logger(__name__)


class PriceAggregator:
    """价格整合器"""

    def aggregate(
        self,
        materials_a: list[Material],
        match_results: list[MatchResult]
    ) -> list[AggregatedMaterial]:
        """
        整合价格数据

        Args:
            materials_a: 源文件A的材料列表
            match_results: 匹配结果列表

        Returns:
            整合后的材料列表
        """
        # 构建匹配索引 {material_a.id: MatchResult}
        match_map = {r.material_a.id: r for r in match_results}

        aggregated = []
        for mat_a in materials_a:
            # 无匹配结果，跳过
            if mat_a.id not in match_map:
                continue

            result = match_map[mat_a.id]
            mat_b = result.material_b

            agg = AggregatedMaterial(
                id=mat_a.id,
                name=mat_a.name,
                specification=mat_a.specification,
                unit=mat_a.unit,
                quantity=mat_a.quantity,
                budget_price=mat_a.base_price,
                quotes=mat_b.quotes.copy(),
                control_price=mat_b.control_price,
                match_status=result.method.value,
                match_confidence=result.confidence,
                remarks=mat_b.remarks,
            )

            # 计算差价（预算材料单价 - 过控建议价）
            if agg.budget_price and agg.control_price:
                agg.price_diff = round(agg.budget_price - agg.control_price, 2)

            aggregated.append(agg)

        # 统计
        matched = sum(1 for a in aggregated if a.match_status != "unmatched")
        logger.info("aggregation_completed",
                   total=len(aggregated),
                   matched=matched,
                   unmatched=len(aggregated) - matched)

        return aggregated
