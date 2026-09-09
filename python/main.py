"""
Unified entry point for Olist Marketplace NLP Pipeline.
Usage:
    python -m python.main --task all
    python -m python.main --task load_reviews
    python -m python.main --task sentiment
    python -m python.main --task reason
"""

import argparse
import logging
from python.src.review_loader import load_order_reviews
from python.src.sentiment_engine import SentimentAnalysisEngine
from python.src.reason_classifier import build_and_persist_reason_summary

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


def main():
    parser = argparse.ArgumentParser(description="Olist NLP Processing Pipeline")
    parser.add_argument(
        "--task",
        choices=["all", "load_reviews", "sentiment", "reason"],
        default="reason",
        help="Task to execute",
    )
    args = parser.parse_args()

    if args.task in ("all", "load_reviews"):
        logger.info("--- Starting Task: Load Reviews ---")
        load_order_reviews()

    if args.task in ("all", "sentiment"):
        logger.info("--- Starting Task: Sentiment Scoring ---")
        engine = SentimentAnalysisEngine()
        engine.run_pipeline()

    if args.task in ("all", "reason"):
        logger.info("--- Starting Task: Reason Classification ---")
        build_and_persist_reason_summary()

    logger.info("Task %s completed successfully.", args.task)


if __name__ == "__main__":
    main()
