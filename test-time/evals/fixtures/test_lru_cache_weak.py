"""Existing tests for lru_cache.LRUCache.

These are the kind of thin, happy-path-only tests this skill is meant to
strengthen: fixed inputs, exact-output assertions, no randomization, no
oracle, no eviction-under-pressure stress, no malformed-input handling.
"""

from lru_cache import LRUCache


def test_put_and_get():
    cache = LRUCache(2)
    cache.put("a", 1)
    assert cache.get("a") == 1


def test_missing_key_returns_none():
    cache = LRUCache(2)
    assert cache.get("nope") is None


def test_eviction():
    cache = LRUCache(2)
    cache.put("a", 1)
    cache.put("b", 2)
    cache.put("c", 3)
    assert cache.get("a") is None
    assert cache.get("b") == 2
    assert cache.get("c") == 3
