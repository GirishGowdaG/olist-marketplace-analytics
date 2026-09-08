"""
Olist Review REASON TAGGING v2 - now with NEGATION handling.

v1 problem: substring matching counted "nao recomendo" (do NOT recommend) as
praise, and "nao chegou no prazo" leaked into positive. v2 fixes this:

  * Before tagging a PRAISE reason, we check whether its trigger word is
    negated - preceded by "nao"/"nem"/"nunca" within 3 words. If negated,
    the praise does NOT count (and we record it as a dissatisfaction signal).
  * Problem reasons (late, damaged, wrong...) and praise reasons (fast,
    good product, delighted) are tracked separately, so charts can show
    problem-reasons for negative/neutral and praise-reasons for positive.

Multi-label: a review can match several reasons. Percentages are "share of
that sentiment's reviews mentioning the reason" and may overlap.

Writes table `review_reason_summary` (reason x sentiment x counts) for Power BI.
"""

import os
import re
from collections import Counter, defaultdict
from getpass import getpass
from urllib.parse import quote_plus

import pandas as pd
from sqlalchemy import create_engine, text

# --- DB connection --------------------------------------------------------
DB_USER = os.getenv("OLIST_DB_USER", "root")
DB_PASS = os.getenv("OLIST_DB_PASSWORD") or getpass("MySQL password for 'olist': ")
engine = create_engine(
    f"mysql+pymysql://{DB_USER}:{quote_plus(DB_PASS)}@127.0.0.1:3306/olist"
)

NEGATORS = {"nao", "nem", "nunca", "jamais"}   # accent-stripped

# Reasons split by polarity so we know which ones to negation-check.
PROBLEM_REASONS = {
    "Late or non-delivery": [
        "atras", "demor", "nao chegou", "nao recebi", "nao foi entreg",
        "ainda nao", "aguardando", "no aguardo", "nao entreg", "atrasad",
        "esperando", "ate agora nao", "nunca chegou", "extraviad",
    ],
    "Damaged or defective": [
        "quebrad", "danificad", "rasgad", "amassad", "defeito", "estragad",
        "veio quebr", "trincad", "rachad", "violad", "avariad",
    ],
    "Wrong or incomplete item": [
        "errad", "faltou", "incomplet", "so veio", "veio so", "veio apenas",
        "nao era", "trocad", "outro produto", "metade", "apenas um",
        "nao confere", "cor errada",
    ],
    "Poor quality / not as described": [
        "pessima qualidade", "ma qualidade", "baixa qualidade", "fragil",
        "nao corresponde", "propaganda enganosa", "enganos", "frustr",
        "decepc", "esperava mais", "deixa a desejar", "qualidade ruim",
        "material ruim", "nao vale", "produto fraco",
    ],
    "Poor seller service / communication": [
        "nao responde", "sem resposta", "nao deram retorno", "descaso",
        "pessimo atendimento", "mau atendimento", "nao resolve",
        "ninguem responde", "nao tive retorno", "atendimento ruim",
        "vergonha", "nao recomendo o vendedor",
    ],
    "Wants refund / cancellation": [
        "cancel", "estorno", "reembolso", "devolucao", "devolver", "ressarc",
    ],
}

PRAISE_REASONS = {
    "Fast / early delivery": [
        "chegou antes", "entrega rapida", "super rapid", "antes do prazo",
        "rapidissim", "entregue antes", "rapida entrega", "chegou rapid",
        "agilidade", "chegou bem antes",
    ],
    "Good product / as described": [
        "otimo produto", "produto otimo", "boa qualidade", "otima qualidade",
        "conforme", "como descrito", "igual a foto", "como esperado",
        "produto bom", "excelente produto", "produto de qualidade",
    ],
    "Delighted / would recommend": [
        "recomendo", "amei", "adorei", "maravilh", "perfeit", "excelente",
        "satisfeit", "parabens", "superou", "melhor que esperava",
        "encantad", "muito bom", "otimo",
    ],
}

def normalize(textval):
    repl = str.maketrans("ãáâàéêíóôõúüç", "aaaaeeiooouuc")
    return textval.lower().translate(repl)

def is_negated(text_tokens, trigger_first_word):
    """True if the trigger's first word is preceded by a negator within 3 tokens."""
    try:
        idx = text_tokens.index(trigger_first_word)
    except ValueError:
        return False
    window = text_tokens[max(0, idx - 3): idx]
    return any(neg in window for neg in NEGATORS)

def tag_review(raw):
    """Return (problem_hits, praise_hits, negated_praise_flag)."""
    t = normalize(raw)
    tokens = re.findall(r"[a-z]+", t)
    problem_hits, praise_hits = [], []
    negated_praise = False

    # problem reasons: straightforward substring match
    for reason, triggers in PROBLEM_REASONS.items():
        if any(trig in t for trig in triggers):
            problem_hits.append(reason)

    # praise reasons: match, but drop if negated
    for reason, triggers in PRAISE_REASONS.items():
        matched = False
        for trig in triggers:
            if trig in t:
                first_word = trig.split()[0]
                if is_negated(tokens, first_word):
                    negated_praise = True          # "nao recomendo" etc.
                else:
                    matched = True
        if matched:
            praise_hits.append(reason)

    return problem_hits, praise_hits, negated_praise

# --- 1. Pull labelled reviews --------------------------------------------
print("Pulling labelled reviews...")
df = pd.read_sql(text("""
    SELECT rs.sentiment_label, r.review_comment_message AS msg
    FROM review_sentiment rs
    JOIN order_reviews r ON r.review_id = rs.review_id
    WHERE TRIM(r.review_comment_message) <> ''
"""), engine)
print(f"  {len(df):,} text reviews loaded")

# --- 2. Tag everything ----------------------------------------------------
reason_counts = defaultdict(Counter)
sentiment_totals = Counter()
matched_any = Counter()
negated_praise_count = Counter()

for _, row in df.iterrows():
    s = row["sentiment_label"]
    sentiment_totals[s] += 1
    problems, praises, neg_praise = tag_review(row["msg"])
    if neg_praise:
        negated_praise_count[s] += 1
    all_hits = problems + praises
    if all_hits:
        matched_any[s] += 1
    for reason in all_hits:
        reason_counts[s][reason] += 1

# --- 3. Build summary rows ------------------------------------------------
rows = []
for s in ["negative", "neutral", "positive"]:
    total = sentiment_totals[s]
    for reason in list(PROBLEM_REASONS) + list(PRAISE_REASONS):
        c = reason_counts[s][reason]
        if c == 0:
            continue
        rows.append({
            "sentiment_label": s,
            "reason": reason,
            "review_count": int(c),
            "pct_of_sentiment": round(c / total * 100, 1) if total else 0,
        })
summary = pd.DataFrame(rows)

# --- 4. Report ------------------------------------------------------------
print("\n" + "=" * 64)
print("TOP REASONS PER SENTIMENT  (v2, negation-aware)")
print("=" * 64)
for s in ["negative", "neutral", "positive"]:
    total = sentiment_totals[s]
    print(f"\n{s.upper()}  ({total:,} reviews, {matched_any[s]/total*100:.0f}% matched, "
          f"{negated_praise_count[s]} negated-praise caught)")
    sub = summary[summary.sentiment_label == s].sort_values("review_count", ascending=False)
    for _, r in sub.iterrows():
        print(f"   {r['reason']:<38} {r['review_count']:>5}  ({r['pct_of_sentiment']:>4.1f}%)")

# --- 5. Write to MySQL ----------------------------------------------------
DDL = """
CREATE TABLE IF NOT EXISTS review_reason_summary (
    sentiment_label  VARCHAR(10)  NOT NULL,
    reason           VARCHAR(60)  NOT NULL,
    review_count     INT          NOT NULL,
    pct_of_sentiment DECIMAL(5,1) NOT NULL,
    PRIMARY KEY (sentiment_label, reason)
)
"""
with engine.begin() as conn:
    conn.execute(text(DDL))
    conn.execute(text("DELETE FROM review_reason_summary"))
    conn.execute(text("""
        INSERT INTO review_reason_summary
            (sentiment_label, reason, review_count, pct_of_sentiment)
        VALUES (:sentiment_label, :reason, :review_count, :pct_of_sentiment)
    """), rows)

print(f"\nWrote {len(rows)} reason rows to review_reason_summary. Done.")
