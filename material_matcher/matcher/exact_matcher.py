"""精确字符串匹配器"""
import re

from ..utils.logging import get_logger


logger = get_logger(__name__)


class ExactMatcher:
    """精确字符串匹配"""

    def match(self, name_a: str, name_b: str) -> tuple[bool, float]:
        """
        精确匹配（忽略空格、统一大小写）

        Returns:
            (is_match, confidence) - 匹配结果和置信度
        """
        normalized_a = self._normalize(name_a)
        normalized_b = self._normalize(name_b)

        is_match = normalized_a == normalized_b
        confidence = 1.0 if is_match else 0.0

        logger.debug("exact_match",
                     name_a=name_a, name_b=name_b,
                     normalized_a=normalized_a, normalized_b=normalized_b,
                     is_match=is_match)

        return is_match, confidence

    def _normalize(self, text: str) -> str:
        """标准化文本"""
        if not text:
            return ""
        # 转小写、去空格、去除特殊字符
        text = text.lower().strip()
        text = re.sub(r'\s+', '', text)  # 去除所有空白
        return text
