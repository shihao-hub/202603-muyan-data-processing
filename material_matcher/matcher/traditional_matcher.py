"""传统算法匹配器"""
import re
from typing import Optional

from ..config import get_config
from ..utils.logging import get_logger


logger = get_logger(__name__)


class TraditionalMatcher:
    """传统文本相似度算法"""

    def __init__(self):
        config = get_config()
        self.thresholds = config.thresholds

        # 算法权重
        self.weights = {
            'levenshtein': 0.3,
            'jaccard': 0.3,
            'jaro_winkler': 0.4
        }

    def match(self, name_a: str, name_b: str) -> tuple[bool, float, str]:
        """
        使用传统算法匹配

        Returns:
            (is_match, confidence, algorithm_name)
        """
        if not name_a or not name_b:
            return False, 0.0, 'none'

        # 计算各算法相似度
        scores = {
            'levenshtein': self._levenshtein_similarity(name_a, name_b),
            'jaccard': self._jaccard_similarity(name_a, name_b),
            'jaro_winkler': self._jaro_winkler_similarity(name_a, name_b),
        }

        logger.debug("traditional_scores",
                    name_a=name_a, name_b=name_b,
                    scores=scores)

        # 单算法达到阈值即返回
        for algo, threshold_key in [
            ('levenshtein', 'levenshtein'),
            ('jaccard', 'jaccard'),
            ('jaro_winkler', 'jaro_winkler'),
        ]:
            threshold = self.thresholds.get(threshold_key, 0.8)
            if scores[algo] >= threshold:
                return True, scores[algo], algo

        # 加权综合得分
        weighted_score = sum(
            scores[algo] * weight
            for algo, weight in self.weights.items()
        )

        weighted_threshold = self.thresholds.get('weighted', 0.75)
        if weighted_score >= weighted_threshold:
            return True, weighted_score, 'weighted'

        return False, weighted_score, 'weighted'

    def _levenshtein_similarity(self, a: str, b: str) -> float:
        """归一化编辑距离相似度"""
        try:
            import Levenshtein
            return Levenshtein.ratio(a, b)
        except ImportError:
            # 如果没有 Levenshtein 库，使用简单的实现
            return self._simple_levenshtein(a, b)

    def _simple_levenshtein(self, a: str, b: str) -> float:
        """简单编辑距离实现"""
        if not a and not b:
            return 1.0
        if not a or not b:
            return 0.0

        m, n = len(a), len(b)
        dp = [[0] * (n + 1) for _ in range(m + 1)]

        for i in range(m + 1):
            dp[i][0] = i
        for j in range(n + 1):
            dp[0][j] = j

        for i in range(1, m + 1):
            for j in range(1, n + 1):
                cost = 0 if a[i-1] == b[j-1] else 1
                dp[i][j] = min(dp[i-1][j] + 1, dp[i][j-1] + 1, dp[i-1][j-1] + cost)

        distance = dp[m][n]
        max_len = max(m, n)
        return 1 - distance / max_len if max_len > 0 else 1.0

    def _jaccard_similarity(self, a: str, b: str) -> float:
        """Jaccard 相似度（基于字符集合）"""
        if not a and not b:
            return 1.0
        if not a or not b:
            return 0.0

        # 使用字符 bigrams 更好地处理中文
        set_a = set(self._get_ngrams(a, 2))
        set_b = set(self._get_ngrams(b, 2))

        intersection = len(set_a & set_b)
        union = len(set_a | set_b)
        return intersection / union if union > 0 else 0.0

    def _get_ngrams(self, text: str, n: int = 2) -> list:
        """获取 n-grams"""
        return [text[i:i+n] for i in range(len(text) - n + 1)]

    def _jaro_winkler_similarity(self, a: str, b: str) -> float:
        """Jaro-Winkler 相似度"""
        try:
            import Levenshtein
            return Levenshtein.jaro_winkler(a, b)
        except ImportError:
            return self._simple_jaro(a, b)

    def _simple_jaro(self, a: str, b: str) -> float:
        """简单的 Jaro 相似度"""
        if not a and not b:
            return 1.0
        if not a or not b:
            return 0.0

        len_a, len_b = len(a), len(b)
        match_distance = max(len_a, len_b) // 2 - 1
        if match_distance < 0:
            match_distance = 0

        a_matches = [False] * len_a
        b_matches = [False] * len_b

        matches = 0
        transpositions = 0

        for i in range(len_a):
            start = max(0, i - match_distance)
            end = min(i + match_distance + 1, len_b)

            for j in range(start, end):
                if b_matches[j] or a[i] != b[j]:
                    continue
                a_matches[i] = True
                b_matches[j] = True
                matches += 1
                break

        if matches == 0:
            return 0.0

        k = 0
        for i in range(len_a):
            if not a_matches[i]:
                continue
            while not b_matches[k]:
                k += 1
            if a[i] != b[k]:
                transpositions += 1
            k += 1

        jaro = (matches/len_a + matches/len_b + (matches - transpositions/2)/matches) / 3
        return jaro
