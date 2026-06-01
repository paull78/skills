"""Existing tests for csv_record.parse_record — the kind of thin suite this
skill is meant to strengthen: only well-formed, simple inputs; no quoted-quote
("") case; no fuzzing; no oracle; exact-output assertions on a few examples."""

from csv_record import parse_record


def test_simple():
    assert parse_record("a,b,c") == ["a", "b", "c"]


def test_quoted_comma():
    assert parse_record('a,"b,c",d') == ["a", "b,c", "d"]


def test_single_field():
    assert parse_record("hello") == ["hello"]
