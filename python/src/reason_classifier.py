"""
Multi-label Portuguese Reason Classifier.
Classifies free-text reviews into operational and product failure root causes
using negation-aware lexical matching.
"""

import re
import unicodedata
import logging
from typing import List, Dict
import pandas as pd
from sqlalchemy import text
from python.src.db import DatabaseManager

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


def normalize_portuguese(text_input: str) -> str:
    if not isinstance(text_input, str):
        return ""
    # Strip accents and normalize case
    normalized = unicodedata.normalize("NFKD", text_input)
    ascii_text = "".join(c for c in normalized if not unicodedata.combining(c))
    return ascii_text.lower().strip()


class PortugueseReasonClassifier:
    """
    Rule-based multi-label reason classifier with negation window lookback.
    """

    NEGATORS = {"nao", "nem", "nunca", "jamais"}

    def __init__(self):
        # Independent category pattern definitions
        self.rules = {
            "Late or Delayed Delivery": [
                r"\b(atraso|atrasou|atrasada|demorou|demorando|demorado)\b",
                r"\b(nao chegou|nao recebi|nao entregue|nao veio)\b",
                r"\b(prazo expirado|fora do prazo|esperando entrega)\b",
            ],
            "Damaged or Defective Item": [
                r"\b(quebrado|estragado|danificado|avariado|defeito|defeituoso|rachado)\b",
                r"\b(nao funciona|parou de funcionar|veio quebrado)\b",
            ],
            "Wrong or Incomplete Product": [
                r"\b(produto errado|veio errado|modelo errado|cor errada|tamanho errado)\b",
                r"\b(incompleto|faltando|veio faltando|faltou peca|faltou item)\b",
            ],
            "Poor Quality / Not as Described": [
                r"\b(pessima qualidade|ruim|muito fraco|material ruim|inferior)\b",
                r"\b(diferente da foto|nao condiz|propaganda enganosa)\b",
            ],
            "Refund or Order Cancellation": [
                r"\b(devolucao|devolver|cancelar|cancelamento|estorno|reembolso)\b",
                r"\b(quero meu dinheiro|troca)\b",
            ],
            "Delighted / Strong Recommendation": [
                r"\b(excelente|perfeito|maravilhoso|parabens|otimo|adoramos|adorei)\b",
                r"\b(super recomendo|recomendo muito|recomendo)\b",
            ],
            "Fast & Early Delivery": [
                r"\b(chegou antes|entrega rapida|super rapido|muito rapido|antes do prazo)\b",
            ],
            "Satisfied / As Described": [
                r"\b(conforme o anuncio|conforme anunciado|bem embalado|tudo certo)\b",
                r"\b(bom produto|otimo produto|atendeu as expectativas)\b",
            ],
        }

    def classify_text(self, raw_text: str) -> List[str]:
        norm_text = normalize_portuguese(raw_text)
        if not norm_text:
            return []

        tokens = norm_text.split()
        matched_reasons = []

        for category, patterns in self.rules.items():
            matched = False
            for pat in patterns:
                for match in re.finditer(pat, norm_text):
                    # Check for negation in 3-token lookback window
                    start_char = match.start()
                    preceding_tokens = norm_text[:start_char].strip().split()
                    lookback_window = preceding_tokens[-3:] if len(preceding_tokens) >= 3 else preceding_tokens
                    
                    is_negated = any(tok in self.NEGATORS for tok in lookback_window)

                    # For praise categories, negation disqualifies the match
                    if "Delighted" in category or "Fast" in category or "Satisfied" in category:
                        if not is_negated:
                            matched = True
                            break
                    else:
                        matched = True
                        break
                if matched:
                    break
            if matched:
                matched_reasons.append(category)

        return matched_reasons


def build_and_persist_reason_summary():
    db_mgr = DatabaseManager()
    query = """
        SELECT r.review_id, r.review_comment_message, s.sentiment_label
        FROM order_reviews r
        JOIN review_sentiment s ON s.review_id = r.review_id
        WHERE r.review_comment_message IS NOT NULL
          AND TRIM(r.review_comment_message) != '';
    """

    logger.info("Fetching customer reviews with sentiment scores from database...")
    with db_mgr.connect() as conn:
        df = pd.read_sql(query, conn)

    logger.info("Loaded %d comments. Running reason classifier...", len(df))
    classifier = PortugueseReasonClassifier()

    records = []
    for _, row in df.iterrows():
        reasons = classifier.classify_text(row["review_comment_message"])
        for reason in reasons:
            records.append({
                "review_id": row["review_id"],
                "sentiment_label": row["sentiment_label"],
                "reason": reason,
            })

    reasons_df = pd.DataFrame(records)
    logger.info("Extracted %d total reason tags. Aggregating summary...", len(reasons_df))

    # Aggregate by (sentiment_label, reason)
    summary = (
        reasons_df.groupby(["sentiment_label", "reason"])
        .size()
        .reset_index(name="review_count")
    )

    sentiment_totals = df.groupby("sentiment_label").size().to_dict()
    summary["pct_of_sentiment"] = summary.apply(
        lambda r: round((r["review_count"] / sentiment_totals.get(r["sentiment_label"], 1)) * 100, 1),
        axis=1,
    )

    logger.info("Updating review_reason_summary table...")
    with db_mgr.connect() as conn:
        conn.execute(text("TRUNCATE TABLE review_reason_summary;"))
        conn.commit()
        summary.to_sql(
            "review_reason_summary",
            con=conn,
            if_exists="append",
            index=False,
        )
        conn.commit()

    logger.info("Successfully updated review_reason_summary (%d categories).", len(summary))


if __name__ == "__main__":
    build_and_persist_reason_summary()
