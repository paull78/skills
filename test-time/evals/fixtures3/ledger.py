class InsufficientFunds(Exception):
    pass


class Ledger:
    """A simple in-memory ledger of named accounts holding integer balances.

    Supports opening accounts, depositing and withdrawing funds, transferring
    between accounts, and querying balances. Intended as the backing store for
    a small payments service.
    """

    def __init__(self):
        self._accounts = {}

    def open(self, name, opening_balance=0):
        """Create a new account with the given starting balance."""
        if opening_balance < 0:
            raise ValueError("opening balance cannot be negative")
        self._accounts[name] = opening_balance

    def deposit(self, name, amount):
        """Add funds to an account."""
        if amount < 0:
            raise ValueError("amount cannot be negative")
        self._accounts[name] += amount

    def withdraw(self, name, amount):
        """Remove funds from an account, if it has enough."""
        if amount < 0:
            raise ValueError("amount cannot be negative")
        if self._accounts[name] < amount:
            raise InsufficientFunds(name)
        self._accounts[name] -= amount

    def transfer(self, src, dst, amount):
        """Move funds from one account to another."""
        if amount < 0:
            raise ValueError("amount cannot be negative")
        src_balance = self._accounts[src]
        dst_balance = self._accounts[dst]
        if src_balance < amount:
            raise InsufficientFunds(src)
        self._accounts[src] = src_balance - amount
        self._accounts[dst] = dst_balance + amount

    def balance(self, name):
        """Return the current balance of an account."""
        return self._accounts[name]

    def total(self):
        """Return the sum of all account balances."""
        return sum(self._accounts.values())
