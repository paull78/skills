import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "voice_stats",
    Path(__file__).resolve().parent.parent / "human-write-time" / "scripts" / "voice_stats.py",
)
vs = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(vs)

VOICE = """# Voice profile

## 1. Samples

### Sample: an email

<!-- redacted -->

I wrote this myself. It has two sentences.

**Do not normalize any of this.** Commentary about the sample.

### Sample: una nota

Ho scritto questa nota. Ma non la ricordo e quindi la riscrivo.

**Nota:** commento.

## 2. Pacing

- Short paragraphs.
"""


def test_extracts_sample_bodies_without_commentary():
    samples = vs.extract_samples(VOICE)
    assert [s.name for s in samples] == ["an email", "una nota"]
    assert samples[0].text.strip() == "I wrote this myself. It has two sentences."
    assert "Commentary" not in samples[0].text
    assert "redacted" not in samples[0].text
    assert "Short paragraphs" not in samples[1].text


def test_detects_language():
    assert vs.detect_language("I think that the plan is good and we should do it.") == "en"
    assert vs.detect_language("Penso che il piano sia buono e che dobbiamo farlo.") == "it"


def test_sentence_metrics():
    m = vs.measure("One two three. One two three four five six seven eight nine ten.", "en")
    assert m["sentences"] == 2
    assert m["sent_len_mean"] == 6.5
    assert m["short_share"] == 0.5


def test_punctuation_is_per_thousand_words():
    text = "Alpha beta: gamma delta; epsilon (zeta) eta theta iota kappa."
    m = vs.measure(text, "en")
    assert m["colon"] == 100.0
    assert m["semicolon"] == 100.0
    assert m["paren"] == 100.0


def test_dashes_count_em_and_spaced_en():
    m = vs.measure("One — two – three four-five six seven eight nine ten.", "en")
    assert m["dash"] == 200.0


def test_contractions_only_in_english():
    en = vs.measure("I don't know. It's fine, isn't it?", "en")
    assert en["contraction"] > 0
    it = vs.measure("L'amico dell'uomo non c'è.", "it")
    assert it["contraction"] == 0


def test_conjunction_openers():
    m = vs.measure("And so it began. But then it stopped. It ended.", "en")
    assert round(m["conj_open"], 2) == 0.67
    m_it = vs.measure("Ma non era vero. E poi basta. Fine.", "it")
    assert round(m_it["conj_open"], 2) == 0.67


def test_compare_flags_values_outside_the_sample_range():
    samples = [{"colon": 5.0}, {"colon": 10.0}]
    rows = vs.compare(samples, {"colon": 40.0})
    (row,) = rows
    assert row.metric == "colon"
    assert row.flag
    rows = vs.compare(samples, {"colon": 8.0})
    assert not rows[0].flag


def test_cli_prints_a_table(tmp_path, capsys):
    voice = tmp_path / "VOICE.md"
    voice.write_text(VOICE, encoding="utf-8")
    draft = tmp_path / "draft.md"
    draft.write_text("I wrote a draft; it has a semicolon. And another sentence here.", encoding="utf-8")
    assert vs.main(["--voice", str(voice), "--draft", str(draft)]) == 0
    out = capsys.readouterr().out
    assert "| metric |" in out
    assert "semicolon" in out
    assert "an email" in out
    assert "una nota" not in out  # filtered out: different language from the draft
