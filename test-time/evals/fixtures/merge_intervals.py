"""Merge overlapping integer intervals.

Public API: merge(intervals: list[tuple[int, int]]) -> list[tuple[int, int]]
Each interval is an inclusive (start, end) pair with start <= end.
Returns a list of non-overlapping intervals sorted by start, covering
exactly the same set of integer points as the input.
"""


def merge(intervals):
    if not intervals:
        return []
    ordered = sorted(intervals)
    result = [ordered[0]]
    for start, end in ordered[1:]:
        last_start, last_end = result[-1]
        if start <= last_end:
            result[-1] = (last_start, max(last_end, end))
        else:
            result.append((start, end))
    return result
