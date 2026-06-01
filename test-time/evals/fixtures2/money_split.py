def split(amount_cents, n):
    """Split a sum of money as evenly as possible among n recipients.

    Returns a list of n integer cent amounts. Contract:
      - sum(result) == amount_cents      (no cent is ever created or lost)
      - any two amounts differ by at most 1 cent
      - the larger amounts come first (result is non-increasing)
    Preconditions: amount_cents >= 0, n >= 1.

    Examples:
      split(100, 4) -> [25, 25, 25, 25]
      split(100, 3) -> [34, 33, 33]
    """
    if n < 1:
        raise ValueError("n must be >= 1")
    if amount_cents < 0:
        raise ValueError("amount_cents must be >= 0")
    base = amount_cents // n
    remainder = amount_cents % n
    result = []
    for i in range(n):
        if i < remainder - 1:
            result.append(base + 1)
        else:
            result.append(base)
    return result
