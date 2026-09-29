import unittest

from wordfreq import top_words


class TopWordsTest(unittest.TestCase):
    def test_counts_case_insensitively(self):
        self.assertEqual(top_words("The the THE cat"), [("the", 3), ("cat", 1)])

    def test_breaks_ties_alphabetically(self):
        self.assertEqual(top_words("b a"), [("a", 1), ("b", 1)])

    def test_limits_to_n(self):
        self.assertEqual(len(top_words("a b c d", n=2)), 2)


if __name__ == "__main__":
    unittest.main()
