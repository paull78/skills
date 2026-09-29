#!/usr/bin/env python3
"""Measure an author's writing samples and check a draft against them.

Model impressions of "voice" drift toward a generic register; these numbers don't.
Standard library only.

  python3 voice_stats.py --voice ~/.claude/VOICE.md                 # the samples' profile
  python3 voice_stats.py --voice ~/.claude/VOICE.md --draft out.md  # draft vs samples
  python3 voice_stats.py --sample a.txt --sample b.txt --draft out.md
"""
import argparse
import re
import statistics
import sys
from dataclasses import dataclass
from pathlib import Path

WORD = re.compile(r"[^\W\d_]+(?:['’][^\W\d_]+)*")
SENTENCE_END = re.compile(r"(?<=[.!?…])\s+|\n+")
CONTRACTION = re.compile(r"\b[A-Za-z]+['’](?:s|t|re|ve|ll|d|m)\b", re.IGNORECASE)

STOPWORDS = {
    "en": {"the", "and", "is", "of", "to", "that", "we", "it", "i", "you", "a", "in",
           "should", "do", "was", "are", "this", "with", "for", "not", "but", "have"},
    "it": {"il", "che", "e", "di", "la", "non", "per", "un", "una", "sia", "è", "ho",
           "questa", "questo", "lo", "le", "gli", "del", "della", "ma", "mi", "si", "con"},
}
CONJUNCTIONS = {
    "en": {"and", "but", "so", "or", "yet"},
    "it": {"e", "ma", "quindi", "però", "o", "eppure"},
}
FIRST_PERSON = {
    "en": {"i", "me", "my", "mine", "myself"},
    "it": {"io", "mi", "mio", "mia", "miei", "mie", "me"},
}

# metric -> label shown in the table
METRICS = {
    "sent_len_mean": "sentence length, mean words",
    "sent_len_sd": "sentence length, spread (sd)",
    "short_share": "share of sentences under 8 words",
    "long_share": "share of sentences over 30 words",
    "sent_per_para": "sentences per paragraph",
    "dash": "dashes per 1,000 words",
    "colon": "colons per 1,000 words",
    "semicolon": "semicolons per 1,000 words",
    "paren": "parentheses per 1,000 words",
    "question": "questions per 1,000 words",
    "exclamation": "exclamations per 1,000 words",
    "ellipsis": "ellipses per 1,000 words",
    "contraction": "contractions per 1,000 words",
    "conj_open": "share of sentences opening with a conjunction",
    "first_person": "first-person words per 1,000 words",
}


@dataclass
class Sample:
    name: str
    text: str


@dataclass
class Row:
    metric: str
    lo: float
    hi: float
    value: float
    flag: bool


def extract_samples(voice_md):
    """Sample bodies from a VOICE.md: text after each `### Sample:` heading, minus HTML
    comments, up to the first `**` commentary line or the next heading."""
    samples, name, body, in_comment = [], None, [], False
    for line in voice_md.splitlines():
        if line.startswith("### Sample:"):
            if name is not None:
                samples.append(Sample(name, "\n".join(body).strip()))
            name, body, in_comment = line.split(":", 1)[1].strip(), [], False
            continue
        if name is None:
            continue
        if in_comment:
            in_comment = "-->" not in line
            continue
        if line.lstrip().startswith("<!--"):
            in_comment = "-->" not in line
            continue
        if line.startswith("#") or line.startswith("**"):
            samples.append(Sample(name, "\n".join(body).strip()))
            name = None
            continue
        body.append(line)
    if name is not None:
        samples.append(Sample(name, "\n".join(body).strip()))
    return [s for s in samples if s.text]


def words(text):
    return WORD.findall(text)


def detect_language(text):
    tokens = [w.lower() for w in words(text)]
    scores = {lang: sum(t in stop for t in tokens) for lang, stop in STOPWORDS.items()}
    return max(scores, key=scores.get)


def _sentences(text):
    return [s for s in SENTENCE_END.split(text) if words(s)]


def measure(text, lang):
    ws = words(text)
    n = max(len(ws), 1)
    per_k = lambda count: round(count * 1000 / n, 1)
    sentences = _sentences(text)
    lengths = [len(words(s)) for s in sentences] or [0]
    paragraphs = [p for p in re.split(r"\n\s*\n", text) if words(p)] or [text]
    first_words = [words(s)[0].lower() for s in sentences]
    return {
        "words": len(ws),
        "sentences": len(sentences),
        "sent_len_mean": round(statistics.mean(lengths), 1),
        "sent_len_sd": round(statistics.pstdev(lengths), 1),
        "short_share": round(sum(l < 8 for l in lengths) / len(lengths), 2),
        "long_share": round(sum(l > 30 for l in lengths) / len(lengths), 2),
        "sent_per_para": round(len(sentences) / len(paragraphs), 1),
        "dash": per_k(text.count("—") + len(re.findall(r"\s–\s", text))),
        "colon": per_k(text.count(":")),
        "semicolon": per_k(text.count(";")),
        "paren": per_k(text.count("(")),
        "question": per_k(text.count("?")),
        "exclamation": per_k(text.count("!")),
        "ellipsis": per_k(text.count("...") + text.count("…")),
        "contraction": per_k(len(CONTRACTION.findall(text))) if lang == "en" else 0,
        "conj_open": round(sum(w in CONJUNCTIONS[lang] for w in first_words) / max(len(first_words), 1), 2),
        "first_person": per_k(sum(w.lower() in FIRST_PERSON[lang] for w in ws)),
    }


def compare(sample_metrics, draft_metrics):
    """Flag draft values outside the samples' range, widened by a margin so a handful of
    samples doesn't make every small difference an alarm."""
    rows = []
    for metric, value in draft_metrics.items():
        values = [m[metric] for m in sample_metrics if metric in m]
        if not values:
            continue
        lo, hi = min(values), max(values)
        margin = max((hi - lo) * 0.25, abs(hi) * 0.15, 0.5)
        rows.append(Row(metric, lo, hi, value, not (lo - margin <= value <= hi + margin)))
    return rows


def _load_samples(args):
    samples = []
    if args.voice:
        samples += extract_samples(Path(args.voice).expanduser().read_text(encoding="utf-8"))
    for path in args.sample or []:
        p = Path(path).expanduser()
        samples.append(Sample(p.stem, p.read_text(encoding="utf-8")))
    return samples


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--voice", help="a VOICE.md with '### Sample:' sections")
    parser.add_argument("--sample", action="append", help="a file with one sample (repeatable)")
    parser.add_argument("--draft", help="the draft to check")
    parser.add_argument("--lang", default="auto", choices=["auto", "en", "it"])
    args = parser.parse_args(argv)

    samples = _load_samples(args)
    if not samples:
        print("no samples found", file=sys.stderr)
        return 2
    draft = Path(args.draft).expanduser().read_text(encoding="utf-8") if args.draft else None
    lang = args.lang
    if lang == "auto":
        lang = detect_language(draft if draft else " ".join(s.text for s in samples))
    matching = [s for s in samples if detect_language(s.text) == lang] or samples
    measured = [(s, measure(s.text, lang)) for s in matching]

    print(f"Samples ({lang}): " + ", ".join(f"{s.name} ({m['words']} words)" for s, m in measured))
    print()
    if draft is None:
        names = [s.name for s, _ in measured]
        print("| metric | " + " | ".join(names) + " |")
        print("|---|" + "---|" * len(names))
        for key, label in METRICS.items():
            print(f"| {label} | " + " | ".join(str(m[key]) for _, m in measured) + " |")
        return 0

    rows = compare([m for _, m in measured], {k: v for k, v in measure(draft, lang).items() if k in METRICS})
    print("| metric | samples | draft | |")
    print("|---|---|---|---|")
    for r in rows:
        mark = "OUT OF RANGE" if r.flag else ""
        print(f"| {METRICS[r.metric]} ({r.metric}) | {r.lo} to {r.hi} | {r.value} | {mark} |")
    return 0


if __name__ == "__main__":
    sys.exit(main())
