#!/usr/bin/env python3
"""Unit tests of prelude_names.py's prose pass and the `#[@External.<T>(…)]` rule:
`python3 scripts/codemod/test_prelude_names.py`."""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from prelude_names import rewrite, rewrite_prose  # noqa: E402


class Prose(unittest.TestCase):
    def test_comment_and_reference_lines(self):
        src = "//// a @Task<@Result<i32, string>> and #[@External.Node(\"x\")]\n// @Iterator<i32>, @print(1)\n"
        new, _ = rewrite_prose(src)
        self.assertEqual(new, "//// a Async<Result<i32, string>> and #[compiler.external(.JavaScript(\"x\"))]\n// Iter<i32>, terminal.print(1)\n")

    def test_test_name(self):
        new, _ = rewrite_prose('test "returns @Result" {\n}\n')
        self.assertEqual(new, 'test "returns Result" {\n}\n')

    def test_strings_are_kept(self):
        src = 'val s = "// @Result";\n'
        self.assertEqual(rewrite_prose(src)[0], src)

    def test_idempotent(self):
        new, _ = rewrite_prose("// @Stream<i32>\n")
        self.assertEqual(rewrite_prose(new)[0], new)


class External(unittest.TestCase):
    def test_code_form(self):
        src = '#[@External.Beam("m:f")]\ndeclare fn f() -> i32;\n'
        new = rewrite(src, None)[0]
        self.assertIn('#[compiler.external(.Erlang("m:f"))]', new)
        self.assertIn("import {compiler}", new)


if __name__ == "__main__":
    unittest.main()
