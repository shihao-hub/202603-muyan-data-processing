"""匹配管道"""
from typing import Optional

from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn

from ..models.material import Material, MatchMethod, MatchResult
from ..config import get_config
from ..utils.logging import get_logger
from .exact_matcher import ExactMatcher
from .traditional_matcher import TraditionalMatcher
from .llm_matcher import LLMMatcher


logger = get_logger(__name__)


class MatchPipeline:
    """匹配策略管道"""

    def __init__(self, strategies: str = "1-3"):
        """
        Args:
            strategies: "1", "1-2", "1-3"
        """
        self.matchers = self._build_matchers(strategies)
        self.strategies = strategies

        logger.info("match_pipeline_init", strategies=strategies,
                   matchers=[m[0] for m in self.matchers])

    def _build_matchers(self, strategies: str) -> list:
        """根据策略配置构建匹配器"""
        matchers = []

        if '1' in strategies:
            matchers.append(('exact', ExactMatcher()))
        if '2' in strategies:
            matchers.append(('traditional', TraditionalMatcher()))
        if '3' in strategies:
            llm_matcher = LLMMatcher()
            if llm_matcher.is_available():
                matchers.append(('llm', llm_matcher))
            else:
                logger.warning("ollama_not_available", msg="LLM matcher disabled")

        return matchers

    def match(
        self,
        materials_a: list[Material],
        materials_b: list[Material]
    ) -> list[MatchResult]:
        """执行匹配"""
        results = []
        matched_b_ids = set()  # 记录已匹配的 material_b 的 id

        total_a = len(materials_a)
        logger.info("matching_started",
                   total_a=total_a,
                   total_b=len(materials_b),
                   strategies=self.strategies)

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TaskProgressColumn(),
        ) as progress:
            task = progress.add_task("[cyan]匹配中...", total=total_a)

            for mat_a in materials_a:
                best_match = None
                best_confidence = 0.0
                best_method = None
                best_algorithm = None

                # 构建匹配用的文本（名称 + 规格，避免重复）
                text_a = mat_a.name
                if mat_a.specification and mat_a.specification != mat_a.name:
                    text_a = f"{mat_a.name} {mat_a.specification}"

                # 遍历材料B寻找最佳匹配
                for mat_b in materials_b:
                    if id(mat_b) in matched_b_ids:
                        continue  # 跳过已匹配的材料B

                    # 构建材料B的匹配文本（避免重复）
                    text_b = mat_b.name
                    if mat_b.specification and mat_b.specification != mat_b.name:
                        text_b = f"{mat_b.name} {mat_b.specification}"

                    # 依次尝试各匹配器
                    for matcher_name, matcher in self.matchers:
                        if matcher_name == 'exact':
                            is_match, confidence = matcher.match(text_a, text_b)
                            algorithm = 'exact'
                        elif matcher_name == 'traditional':
                            is_match, confidence, algorithm = matcher.match(
                                text_a, text_b
                            )
                        elif matcher_name == 'llm':
                            is_match, confidence = matcher.match(
                                text_a, text_b
                            )
                            algorithm = 'llm'
                        else:
                            continue

                        if is_match and confidence > best_confidence:
                            best_match = mat_b
                            best_confidence = confidence
                            best_method = matcher_name
                            best_algorithm = algorithm

                            # 精确匹配，直接使用
                            if matcher_name == 'exact':
                                break

                    # 如果精确匹配成功，跳出循环
                    if best_method == 'exact':
                        break

                # 记录匹配结果
                if best_match:
                    result = MatchResult(
                        material_a=mat_a,
                        material_b=best_match,
                        method=MatchMethod(best_method),
                        confidence=best_confidence,
                        algorithm=best_algorithm
                    )
                    results.append(result)
                    matched_b_ids.add(id(best_match))

                    mat_a.match_method = MatchMethod(best_method)
                    mat_a.match_confidence = best_confidence
                    mat_a.matched_name = best_match.name

                    logger.info("material_matched",
                               name_a=mat_a.name,
                               name_b=best_match.name,
                               method=best_method,
                               confidence=round(best_confidence, 3))

                progress.advance(task)

        # 统计
        matched_count = len(results)
        unmatched_count = total_a - matched_count

        logger.info("matching_completed",
                   total=total_a,
                   matched=matched_count,
                   unmatched=unmatched_count,
                   match_rate=round(matched_count / total_a * 100, 1) if total_a > 0 else 0)

        return results
