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


class ApplyTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "decisions-taken.md").write_text(LEDGER)
        self.m = self.root / "conformance" / "modules"
        self.m.mkdir(parents=True)
        (self.m / "botopink.json").write_text('{\n  "name": "conformance",\n  "version": "0.0.1",\n  "workspaces": ["*"]\n}\n')
        cell(self.m, "named_cell", "//// Decision 40")
        cell(self.m, "other_cell", "//// Decision 40")
        cell(self.m, "both", "//// Decisions 40 and 10")
        cell(self.m, "stray", "//// no decision")
        cell(self.m, "stray_two")
        (self.m / "stray_two" / "docs.md").write_text("see `modules/named_cell` and ../query/conformance/modules/stray\n")
        (self.root / "conformance" / "docs.md").write_text("<!-- example: modules/named_cell -->\n<!-- example: modules/stray -->\n")
        (self.root / "t.zig").write_text('const p = "conformance/modules/other_cell/src/main.bp"; // modules/named_cell_x\n')
        run = lambda *c: subprocess.run(["git", "-C", str(self.root), *c], check=True, capture_output=True)
        run("init", "-q")
        run("add", "-A")
        run("-c", "user.name=t", "-c", "user.email=t@t", "commit", "-qm", "x")
        self.run = run

    def tearDown(self):
        self.tmp.cleanup()

    def apply(self, **kw):
        a = dict(root=str(self.root), group=None, all=False, range=None, drop_star=False, dry_run=False)
        a.update(kw)
        return cc.cmd_apply(type("A", (), a))

    def test_apply_all(self):
        self.assertEqual(self.apply(all=True), 0)
        self.assertTrue((self.m / "decisions-taken/slug_forty-40/cases/other_cell/botopink.json").is_file())
        self.assertTrue((self.m / "stray/cases/stray/botopink.json").is_file())
        self.assertFalse((self.m / "stray_two").exists() or (self.m / "named_cell").exists())
        docs = (self.m / "decisions-taken/slug_forty-40/docs.md").read_text().split("\n")
        self.assertEqual(docs[0], "# Decision 40 \u2014 cited")
        self.assertIn("[cases/other_cell/src/main.bp](cases/other_cell/src/main.bp)", docs)
        self.assertIn("Proved also by [both](../slug_forty-40/cases/both/src/main.bp)",
                      (self.m / "decisions-taken/slug_ten-10/docs.md").read_text())
        self.assertEqual((self.m / "stray/docs.md").read_text().split("\n")[0], "# stray")
        # references: exact token, path only, other repositories' cells and glob stems untouched
        self.assertEqual((self.root / "conformance/docs.md").read_text(),
                         "<!-- example: modules/decisions-taken/slug_ten-10/cases/named_cell -->\n<!-- example: modules/stray/cases/stray -->\n")
        self.assertIn("conformance/modules/decisions-taken/slug_forty-40/cases/other_cell/src/main.bp", (self.root / "t.zig").read_text())
        self.assertIn("modules/named_cell_x", (self.root / "t.zig").read_text())
        moved_docs = (self.m / "stray/cases/stray_two/docs.md").read_text()
        self.assertIn("`modules/decisions-taken/slug_ten-10/cases/named_cell`", moved_docs)
        self.assertIn("../query/conformance/modules/stray", moved_docs)
        self.assertEqual((self.m / "botopink.json").read_text(),
                         '{\n  "name": "conformance",\n  "version": "0.0.1",\n  "workspaces": ["decisions-taken/*/cases/*", "*/cases/*"]\n}\n'.replace('"decisions-taken/*/cases/*", "*/cases/*"', '"*/cases/*", "decisions-taken/*/cases/*"'))
        # the moves are staged and verify is the identity against the base
        self.assertEqual(cc.cmd_verify(type("A", (), {"root": str(self.root), "base": "HEAD"})), 0)
        self.assertEqual(self.apply(all=True), 0)  # idempotent

    def test_group_and_dry_run(self):
        self.assertEqual(self.apply(group="stray", dry_run=True), 0)
        self.assertTrue((self.m / "stray" / "botopink.json").exists())
        self.assertEqual(self.apply(group="stray"), 0)
        self.assertTrue((self.m / "stray/cases/stray_two").is_dir())
        self.assertTrue((self.m / "named_cell").is_dir())
        self.assertIn('"*"', (self.m / "botopink.json").read_text())


if __name__ == "__main__":
    unittest.main()
