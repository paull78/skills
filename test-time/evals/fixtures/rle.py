"""Run-length encoding codec operating on bytes.

Format: a sequence of (count, value) pairs, each a single byte.
encode() turns raw bytes into this form; decode() reverses it.
Public API: encode(data: bytes) -> bytes, decode(data: bytes) -> bytes.
"""


def encode(data: bytes) -> bytes:
    out = bytearray()
    i = 0
    n = len(data)
    while i < n:
        value = data[i]
        run = 1
        while i + run < n and data[i + run] == value and run < 255:
            run += 1
        out.append(run)
        out.append(value)
        i += run
    return bytes(out)


def decode(data: bytes) -> bytes:
    if len(data) % 2 != 0:
        raise ValueError("truncated RLE stream")
    out = bytearray()
    for j in range(0, len(data), 2):
        count = data[j]
        value = data[j + 1]
        out.extend([value] * count)
    return bytes(out)
