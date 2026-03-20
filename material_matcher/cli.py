"""CLI 入口"""
import click
from pathlib import Path

from .config import get_config
from .utils.logging import setup_logging, get_logger
from .parser import SourceParser, InquiryParser
from .matcher import MatchPipeline
from .aggregator import PriceAggregator
from .exporter import ExcelExporter


@click.command()
@click.option('--file1', '-a', required=True, type=click.Path(exists=True),
              help='源文件A（工料机汇总表）')
@click.option('--file2', '-b', required=True, type=click.Path(exists=True),
              help='源文件B（询价材料表）')
@click.option('--template', '-t', type=click.Path(exists=True),
              help='输出样式模板文件（可选）')
@click.option('--output', '-o', default='matched_prices.xlsx',
              help='输出文件路径')
@click.option('--similarity', '-s', default=0.7, type=float,
              help='匹配相似度阈值（默认0.7）')
@click.option('--strategies', default='1-3',
              help='匹配策略层级 (1=精确, 2=传统算法, 3=LLM，默认1-3)')
@click.option('--verbose', '-v', is_flag=True,
              help='详细日志输出')
@click.option('--config', '-c', type=click.Path(exists=True),
              help='配置文件路径（可选）')
def main(file1, file2, template, output, similarity, strategies, verbose, config):
    """材料价格匹配工具

    匹配两个 Excel 文件中规格名称一致的材料，整合价格数据并输出。
    """
    # 初始化日志
    logger = setup_logging(verbose)
    logger = get_logger(__name__)

    logger.info("tool_started",
                file1=file1, file2=file2,
                strategies=strategies, output=output)

    try:
        # 加载配置
        cfg = get_config()
        if config:
            from .config import Config, set_config
            cfg = Config.load(config)
            set_config(cfg)
            logger.info("config_loaded", config=config)

        # 解析文件
        logger.info("parsing_files")
        parser_a = SourceParser()
        parser_b = InquiryParser()

        materials_a = parser_a.parse(file1)
        materials_b = parser_b.parse(file2)

        logger.info("files_parsed",
                    source_count=len(materials_a),
                    inquiry_count=len(materials_b))

        if not materials_a:
            logger.error("no_materials_in_source", file=file1)
            return

        if not materials_b:
            logger.error("no_materials_in_inquiry", file=file2)
            return

        # 执行匹配
        logger.info("matching_started")
        pipeline = MatchPipeline(strategies)
        match_results = pipeline.match(materials_a, materials_b)

        # 整合价格
        logger.info("aggregating_prices")
        aggregator = PriceAggregator()
        aggregated = aggregator.aggregate(materials_a, match_results)

        # 导出
        logger.info("exporting_results", output=output)
        exporter = ExcelExporter(template)
        exporter.export(aggregated, output)

        logger.info("tool_completed",
                   output=output,
                   total=len(aggregated),
                   matched=sum(1 for a in aggregated if a.match_status != "unmatched"))

    except Exception as e:
        logger.error("tool_failed", error=str(e), exc_info=verbose)
        raise


if __name__ == '__main__':
    main()
