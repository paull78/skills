class RingBuffer:
    """A fixed-capacity ring buffer (circular buffer).

    Contract:
      - push(x) appends x. If the buffer is already at capacity, the oldest
        item is overwritten (dropped) to make room.
      - items() returns the current contents as a list, oldest first and
        newest last.
      - len(buf) is the number of items currently stored (0..capacity).

    Example:
      b = RingBuffer(3)
      for x in [1, 2, 3]: b.push(x)
      b.items()          # -> [1, 2, 3]
    """

    def __init__(self, capacity):
        if capacity <= 0:
            raise ValueError("capacity must be positive")
        self.capacity = capacity
        self._buf = [None] * capacity
        self._start = 0
        self._size = 0

    def push(self, x):
        end = (self._start + self._size) % self.capacity
        self._buf[end] = x
        if self._size < self.capacity:
            self._size += 1
        else:
            self._start = (self._start + 1) % self.capacity

    def items(self):
        return [self._buf[i] for i in range(self._size)]

    def __len__(self):
        return self._size
