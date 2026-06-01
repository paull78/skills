"""A fixed-capacity LRU (least-recently-used) cache.

Public API:
    cache = LRUCache(capacity)
    cache.put(key, value)      # insert or update; evicts LRU if over capacity
    cache.get(key)             # returns value or None; counts as a use
    len(cache)                 # current number of entries

Both get and put count as "using" a key, making it most-recently-used.
When capacity is exceeded, the least-recently-used key is evicted.
"""

from collections import OrderedDict


class LRUCache:
    def __init__(self, capacity):
        if capacity <= 0:
            raise ValueError("capacity must be positive")
        self.capacity = capacity
        self._store = OrderedDict()

    def get(self, key):
        if key not in self._store:
            return None
        self._store.move_to_end(key)
        return self._store[key]

    def put(self, key, value):
        if key in self._store:
            self._store.move_to_end(key)
        self._store[key] = value
        if len(self._store) > self.capacity:
            self._store.popitem(last=False)

    def __len__(self):
        return len(self._store)
