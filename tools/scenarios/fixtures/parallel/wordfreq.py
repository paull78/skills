"""Print the most frequent words in a text file."""
import re
import sys
from collections import Counter


def top_words(text, n=10):
    words = re.findall(r"[a-z']+", text.lower())
    counts = Counter(words)
    return sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))[:n]


def main(argv):
    with open(argv[1], encoding="utf-8") as f:
        for word, count in top_words(f.read()):
            print(f"{word} {count}")


if __name__ == "__main__":
    main(sys.argv)
