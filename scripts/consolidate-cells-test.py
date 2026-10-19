#!/usr/bin/env python3
"""Tests of consolidate-cells.py: the homing rules on a fixture, and verify's identity."""
import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("cc", Path(__file__).with_name("consolidate-cells.py"))
cc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cc)

LEDGER = """| # | Id | Rule in force | Binds | Cell |
|---|---|---|---|---|
| 5 | 1.0.5-beta | **old rule** text | x | |
| 10 | a | **named** touches `named_cell` | x | slug_ten |
| 20 | a | **Replaced by 30.** | x | |
| 30 | a | **in force** rule | x | slug_thirty |
| 40 | a | **cited** rule | x | slug_forty |
| 41 | process | **process** rule | x | |
"""


def cell(modules, name, header="", snap="botopink-cell 1\nout hi\n"):
    d = modules / name
    (d / "src").mkdir(parents=True)
    (d / "snapshot" / "output").mkdir(parents=True)
    (d / "botopink.json").write_text('{"name": "%s"}' % name)
    (d / "src" / "main.bp").write_text(header + "\nfn main() {}\n")
    (d / "snapshot" / "output" / "main.snap").write_text(snap)


class Tests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "decisions-taken.md").write_text(LEDGER)
        self.m = self.root / "conformance" / "modules"
        self.m.mkdir(parents=True)
        cell(self.m, "named_cell", "//// Decision 40 — cited too")
        cell(self.m, "via_oneliner", "//// Decisions 20, 40 (1) and 5 — x")
        cell(self.m, "step_form", "//// Decision 40 and 41-a — x")
        cell(self.m, "stray_cell", "//// Decision 999 and 1.0.5-beta front 40")
        cell(self.m, "no_header")
        cell(self.m, "old_number", "//// Decision 5 of 1.0.5-beta")

    def tearDown(self):
        self.tmp.cleanup()

    def plan(self):
        rows = cc.load_ledger(self.root / "decisions-taken.md")
        return rows, {r["cell"]: r for r in cc.plan(rows, self.m)}

    def test_classes(self):
        rows, _ = self.plan()
        self.assertEqual(rows[20].kind, "oneliner")
        self.assertEqual(rows[41].kind, "process")
        self.assertEqual(rows[30].kind, "code")

    def test_named_beats_header(self):
        _, p = self.plan()
        self.assertEqual((p["named_cell"]["reason"], p["named_cell"]["home"]), ("a", 10))
        self.assertEqual(p["named_cell"]["new"], "modules/decisions-taken/slug_ten-10/cases/named_cell")

    def test_oneliner_followed_highest_wins(self):
        _, p = self.plan()
        c = p["via_oneliner"]
        self.assertEqual((c["reason"], c["home"], c["also"]), ("b", 40, [30, 5]))

    def test_outside_by_prefix(self):
        _, p = self.plan()
        self.assertEqual(p["stray_cell"]["new"], "modules/stray/cases/stray_cell")
        self.assertEqual(p["no_header"]["reason"], "c")

    def test_unslugged_row_homes_outside(self):
        _, p = self.plan()
        c = p["old_number"]
        self.assertEqual((c["reason"], c["new"]), ("c", "modules/old/cases/old_number"))
        self.assertIn("no slug", c["note"])

    def test_plan_refuses_unslugged(self):
        a = type("A", (), {"root": str(self.root), "allow_unslugged": False})
        self.assertEqual(cc.cmd_plan(a), 1)
        a.allow_unslugged = True
        self.assertEqual(cc.cmd_plan(a), 0)
        self.assertTrue((self.m / "INDEX.md").exists() and (self.m / "INDEX.ambiguous").exists())

    def test_verify_identity_and_difference(self):
        run = lambda *c: subprocess.run(["git", "-C", str(self.root), *c], check=True, capture_output=True)
        run("init", "-q")
        run("add", "-A")
        run("-c", "user.name=t", "-c", "user.email=t@t", "commit", "-qm", "x")
        a = type("A", (), {"root": str(self.root), "base": "HEAD"})
        self.assertEqual(cc.cmd_verify(a), 0)
        (self.m / "no_header" / "snapshot" / "output" / "main.snap").write_text("botopink-cell 1\nout bye\n")
        self.assertEqual(cc.cmd_verify(a), 1)


if __name__ == "__main__":
    unittest.main()
