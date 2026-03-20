"""LLM 语义匹配器"""
import json
import re
import time
from typing import Optional

import requests

from ..config import get_config
from ..utils.logging import get_logger


logger = get_logger(__name__)


class LLMMatcher:
    """基于 Ollama 的语义匹配"""

    def __init__(self, model: Optional[str] = None, base_url: Optional[str] = None):
        config = get_config()
        ollama_config = config.ollama

        self.model = model or ollama_config.get('model', 'qwen2.5:0.5b')
        self.base_url = base_url or ollama_config.get('base_url', 'http://localhost:11434')
        self.timeout = ollama_config.get('timeout', 30)
        self.max_retries = ollama_config.get('max_retries', 3)

    def match(self, name_a: str, name_b: str) -> tuple[bool, float]:
        """
        使用 LLM 进行语义匹配

        Returns:
            (is_match, confidence)
        """
        if not name_a or not name_b:
            return False, 0.0

        prompt = self._build_prompt(name_a, name_b)

        for attempt in range(self.max_retries):
            try:
                response = self._call_ollama(prompt)
                is_match, confidence = self._parse_response(response)

                logger.debug("llm_match",
                           name_a=name_a, name_b=name_b,
                           is_match=is_match, confidence=confidence)

                return is_match, confidence

            except Exception as e:
                logger.warning("ollama_call_failed",
                              attempt=attempt + 1,
                              error=str(e))
                if attempt < self.max_retries - 1:
                    time.sleep(1)  # 重试前等待
                else:
                    return False, 0.0

        return False, 0.0

    def is_available(self) -> bool:
        """检查 Ollama 服务是否可用"""
        try:
            response = requests.get(
                f"{self.base_url}/api/tags",
                timeout=5
            )
            return response.status_code == 200
        except Exception:
            return False

    def _build_prompt(self, a: str, b: str) -> str:
        """构建提示词"""
        return f"""判断以下两个材料名称是否指代同一种建筑材料。

材料A: {a}
材料B: {b}

请只回复 JSON 格式：
{{"is_same": true/false, "confidence": 0.0-1.0, "reason": "简短原因"}}"""

    def _call_ollama(self, prompt: str) -> str:
        """调用 Ollama API"""
        response = requests.post(
            f"{self.base_url}/api/generate",
            json={
                "model": self.model,
                "prompt": prompt,
                "stream": False
            },
            timeout=self.timeout
        )
        response.raise_for_status()
        return response.json().get("response", "")

    def _parse_response(self, response: str) -> tuple[bool, float]:
        """解析 LLM 响应"""
        try:
            # 提取 JSON
            json_match = re.search(r'\{[^}]+\}', response)
            if json_match:
                result = json.loads(json_match.group())
                is_same = result.get("is_same", False)
                confidence = result.get("confidence", 0.0)

                # 检查阈值
                config = get_config()
                llm_threshold = config.thresholds.get('llm', 0.7)

                return is_same and confidence >= llm_threshold, confidence

        except json.JSONDecodeError:
            logger.warning("llm_response_parse_failed", response=response)

        return False, 0.0
