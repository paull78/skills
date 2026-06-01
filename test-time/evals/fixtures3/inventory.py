class OutOfStock(Exception):
    pass


class Inventory:
    """Tracks reservable stock for a single product.

    A fixed number of units exists. Callers reserve units under a reservation
    id, and may later release a reservation to return its units to the
    available pool. Useful as the core of a checkout / hold system where
    items are held while a customer completes payment.
    """

    def __init__(self, total_units):
        if total_units < 0:
            raise ValueError("total_units cannot be negative")
        self._total = total_units
        self._available = total_units
        self._reservations = {}

    def reserve(self, reservation_id, qty):
        """Hold `qty` units under the given reservation id."""
        if qty <= 0:
            raise ValueError("qty must be positive")
        if qty > self._available:
            raise OutOfStock(reservation_id)
        self._reservations[reservation_id] = qty
        self._available -= qty

    def release(self, reservation_id):
        """Return a reservation's units to the available pool."""
        qty = self._reservations.get(reservation_id, 0)
        self._available += qty
        if reservation_id in self._reservations:
            del self._reservations[reservation_id]

    def available(self):
        """Units currently free to reserve."""
        return self._available

    def reserved(self):
        """Total units currently held across all reservations."""
        return sum(self._reservations.values())

    def total(self):
        """Total units the inventory was created with."""
        return self._total
