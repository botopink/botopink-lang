#!/usr/bin/env python3
"""consolidate-cells.py — 144 B-157's mapping and its oracle (decision 765).

B-157 moves the cells of `conformance/modules/<cell>/` into modules, one per decision
(`modules/decisions-taken/<slug>-<N>/cases/<cell>/`) or one per name prefix
(`modules/<prefix>/cases/<cell>/`). This file holds the two pieces that move nothing:

    consolidate-cells.py plan [--allow-unslugged]
        homes every cell and writes `conformance/modules/INDEX.md` (old path · new path · home
        row · also-proved rows · reason) and `conformance/modules/INDEX.ambiguous` (every cell
        with more than one candidate row, every row with more than 20 cases). Both are generated,
        never committed. It refuses, listing them, while a code-bearing row of the ledger has no
        `Cell` slug; `--allow-unslugged` homes those rows' cells outside and lists them.

    consolidate-cells.py verify --base <ref>
        compares the tree with a base commit, measure by measure (cell count, `.snap` files per
        output and target, record counts per kind, manifests with "targets", the multiset of
        (path inside the cell, sha256) over src/, deps/, snapshot/, botopink.json and docs.md,
        the count of `<!-- example:` references): equal / different each, exit 1 on any
        difference. On the unchanged tree it is the identity.

    consolidate-cells.py apply [--group <prefix>|--all] [--range LO-HI] [--drop-star] [--dry-run]
        moves the cells of the plan (`--allow-unslugged` mapping) with `git mv`, writes each
        module's `docs.md`, rewrites every reference by exact token (`modules/<cell>` ->
        `modules/<module>/cases/<cell>`; never the ledger), and adds the manifest globs
        `*/cases/*` and `decisions-taken/*/cases/*`. `--group decisions-taken` takes the decision
        modules (`--range` bounds their home rows); `--all` moves every group, largest first, and
        drops `"*"` at the end (`--drop-star` alone drops it). `groups` lists the groups, largest
        first. Idempotent: a moved cell is already home.

A cell is homed in this precedence order:

    a  a row whose text names the cell (`modules/<cell>` or `<cell>` in backticks);
    b  the decisions the `////` header cites. Numbers are global; a bare N <= 143 or a step
       spelling (`541-b`) counts only when row N is a code-bearing row of the ledger;
    c  else outside, under the first `_` segment of the cell's name.

Several candidate rows: the highest-numbered code-bearing row in force is the home, the others
are "proved also by". A one-liner (`Replaced by N` / `Reversed by N` / `Overtaken by N`) is
followed to the row in force. Row classes are decision-cells.py's.

    t  `conformance/modules/consolidate-homes.txt` overrides all of it for the cells it lists, one
       `<cell> <row> [also <row>,<row>]` per line (`#` starts a comment): the row the cell proves,
       read from its behaviour (decision 765 (2)'s one pass over the ambiguity list), and the rows
       it proves also — none when `also` is left out. `outside` as the row homes the cell under its
       name prefix. A row that is not a slugged code-bearing row, or a cell that does not exist, is
       refused, every one listed. `plan` and `apply` read it alike.
"""
import argparse
import collections
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

CASE_LIMIT = 20
KINDS = ["out", "refused", "at", "label", "from", "abort", "stderr", "no-final-newline"]

ONE_LINER = re.compile(r"(?:Replaced|Reversed|Overtaken) by [\d,\s]*(?:(?:and|with)[\d,\s]*)*\.?")
OPENS_SUPERSEDED = re.compile(r"(?:(?:Replaced|Reversed|Overtaken) by \d|Withdrawn\b)")
FOLLOW = re.compile(r"(?:Replaced|Reversed|Overtaken) by ([\d,\s]*(?:(?:and|with)[\d,\s]*)*)")


# ── the ledger ──────────────────────────────────────────────────────────────────

def strip_parens(text):
    prev = None
    while prev != text:
        prev = text
        text = re.sub(r"\([^()]*\)", "", text)
    return text


class Row:
    def __init__(self, num, rid, rule, binds, slug):
        self.num, self.id, self.rule, self.binds, self.slug = num, rid, rule, binds, slug
        self.text = f"{rid} | {rule} | {binds} | {slug or ''}"
        flat = re.sub(r"\s+", " ", strip_parens(rule.replace("**", ""))).strip()
        if re.search(r"\bprocess\b", rid, re.I):
            self.kind = "process"
        elif ONE_LINER.fullmatch(flat) or OPENS_SUPERSEDED.match(flat):
            self.kind = "oneliner"
        else:
            self.kind = "code"
        m = FOLLOW.match(flat)
        self.follows = [int(n) for n in re.findall(r"\d+", m.group(1))] if m and self.kind == "oneliner" else []

    @property
    def dirname(self):
        return f"{self.slug}-{self.num}"


def load_ledger(path):
    rows = {}
    has_cell = False
    for ln in Path(path).read_text().splitlines():
        if ln.startswith("| #"):
            has_cell = [c.strip() for c in ln.strip().strip("|").split("|")][-1] == "Cell"
            continue
        if not re.match(r"\| \d+ \| ", ln):
            continue
        body = ln.rstrip()
        body = body[:-1].rstrip() if body.endswith("|") else body
        num, rid, rest = [c.strip() for c in body[1:].split("|", 2)]
        tail = [c.strip() for c in (rest + " ").rsplit(" | ", 2 if has_cell else 1)]
        slug = (tail[2].strip("`") or None) if has_cell else None
        rows[int(num)] = Row(int(num), rid, tail[0], tail[1], slug)
    return rows


def in_force(rows, n, seen=None):
    """The code-bearing rows a row stands for: itself, or what a one-liner is followed to."""
    seen = seen or set()
    r = rows.get(n)
    if r is None or n in seen:
        return []
    seen.add(n)
    if r.kind == "code":
        return [n]
    if r.kind == "oneliner":
        out = []
        for m in r.follows:
            out += in_force(rows, m, seen)
        return out
    return []


# ── the cells ───────────────────────────────────────────────────────────────────

def cells_of(modules):
    """Every cell (a directory with a botopink.json that is not under another cell), as
    a path relative to `modules`."""
    found = []

    def walk(d):
        for e in sorted(d.iterdir()):
            if not e.is_dir() or e.name == "draft":
                continue  # a decision's draft/ is no cell (front 166): the row has none yet
            if (e / "botopink.json").exists():
                found.append(e)
            else:
                walk(e)
    walk(modules)
    return found


def header_text(cell):
    """The `////` header block of the cell's sources (every `.bp` under src/)."""
    out = []
    for f in sorted((cell / "src").rglob("*.bp")) if (cell / "src").is_dir() else []:
        for ln in f.read_text(errors="replace").splitlines():
            if ln.startswith("////"):
                out.append(ln[4:].strip())
            elif ln.strip():
                break
    return " ".join(out)


def cited_numbers(header):
    """Decision numbers a header cites: lists after `decision(s)`, and step spellings `541-b`."""
    text = re.sub(r"\d+\.\d+\.\d+-beta", " ", header)
    text = re.sub(r"\bfront\s+\d+", " ", text, flags=re.I)
    nums = []
    for m in re.finditer(r"\b[Dd]ecisions?\s+((?:\d+(?:-[a-z])?(?:\s*\([^)]*\))*(?:\s*(?:,|and|&|–|—)\s*)?)+)", text):
        nums += [int(n) for n in re.findall(r"\d+", re.sub(r"\([^)]*\)", "", m.group(1)))]
    steps = [(int(a), f"{a}-{b}") for a, b in re.findall(r"\b(\d+)-([a-z])\b", text)]
    return nums, steps


def home_cell(name, header, rows, row_tokens):
    """-> (reason, [candidate rows in force, descending]). reason is `a`, `b` or `c`."""
    named = set()
    for tok, nums in row_tokens.items():
        if tok == name:
            named |= nums
    if named:
        reason, direct = "a", sorted(named)
    else:
        nums, steps = cited_numbers(header)
        direct = []
        for n in nums:
            if n in rows:
                direct.append(n)
        for n, tok in steps:
            if n in rows and n not in direct:
                direct.append(n)
        reason = "b"
    cand = set()
    for n in direct:
        cand |= set(in_force(rows, n))
    if not cand:
        return "c", []
    return reason, sorted(cand, reverse=True)


def name_tokens(rows, names):
    """token -> row numbers whose text names it (`modules/<cell>` or backticked `<cell>`)."""
    out = collections.defaultdict(set)
    for r in rows.values():
        for m in re.finditer(r"modules/([a-z0-9_]+)|`([a-z0-9_]+)`", r.text):
            t = m.group(1) or m.group(2)
            if t in names:
                out[t].add(r.num)
    return out


def prefix_of(name):
    return name.split("_", 1)[0]


HOMES = "consolidate-homes.txt"


class HomesError(Exception):
    pass


def load_homes(path, rows, names=None):
    """The homes table: cell -> (row or None for outside, [also rows]). Refuses, listing every bad line."""
    path = Path(path)
    if not path.is_file():
        return {}
    homes, bad = {}, []
    for i, ln in enumerate(path.read_text().splitlines(), 1):
        ln = ln.split("#", 1)[0].strip()
        if not ln:
            continue
        m = re.fullmatch(r"([a-z0-9_]+)\s+(outside|\d+)(?:\s+also\s+(\d+(?:\s*,\s*\d+)*))?", ln)
        if not m:
            bad.append(f"{path.name}:{i}: not `<cell> <row> [also <row>,<row>]`: {ln}")
            continue
        cell, row = m.group(1), m.group(2)
        also = [int(n) for n in re.findall(r"\d+", m.group(3) or "")]
        home = None if row == "outside" else int(row)
        if home is None and also:
            bad.append(f"{path.name}:{i}: an outside cell proves no row: {ln}")
        for n in ([home] if home is not None else []) + also:
            r = rows.get(n)
            if r is None or r.kind != "code" or not r.slug:
                bad.append(f"{path.name}:{i}: row {n} is no slugged code-bearing row")
        if names is not None and cell not in names:
            bad.append(f"{path.name}:{i}: no cell `{cell}`")
        if cell in homes:
            bad.append(f"{path.name}:{i}: `{cell}` listed twice")
        homes[cell] = (home, sorted(set(also) - {home}, reverse=True))
    if bad:
        raise HomesError("\n".join(bad))
    return homes


def plan(rows, modules, homes=None):
    cells = cells_of(modules)
    names = {c.name for c in cells}
    if homes is None:
        homes = load_homes(Path(modules) / HOMES, rows, names)
    tokens = name_tokens(rows, names)
    result = []
    for c in cells:
        rel = c.relative_to(modules).as_posix()
        reason, cand = home_cell(c.name, header_text(c), rows, tokens)
        new, home, also, note = None, None, [], ""
        if c.name in homes:
            home, also = homes[c.name]
            if home is not None:
                new = f"modules/decisions-taken/{rows[home].dirname}/cases/{c.name}"
            result.append({"cell": c.name, "old": f"modules/{rel}",
                           "new": new or f"modules/{prefix_of(c.name)}/cases/{c.name}", "home": home,
                           "also": also, "reason": "t", "candidates": cand, "note": ""})
            continue
        if cand:
            home, also = cand[0], cand[1:]
            if rows[home].slug:
                new = f"modules/decisions-taken/{rows[home].dirname}/cases/{c.name}"
            else:
                note = f"row {home} has no slug"
                reason, home, also = "c", None, []
        if new is None:
            new = f"modules/{prefix_of(c.name)}/cases/{c.name}"
        result.append({"cell": c.name, "old": f"modules/{rel}", "new": new, "home": home,
                       "also": also, "reason": reason, "candidates": cand, "note": note})
    return result


def render(result, rows):
    by_row = collections.defaultdict(list)
    proves = collections.defaultdict(set)
    for r in result:
        if r["home"]:
            by_row[r["home"]].append(r["cell"])
            proves[r["home"]].add(r["cell"])
        for a in r["also"]:
            proves[a].add(r["cell"])
    reasons = collections.Counter(r["reason"] for r in result)
    code = [n for n, r in rows.items() if r.kind == "code"]
    with_cases = [n for n in code if proves.get(n)]
    drafts = [n for n in code if not proves.get(n)]
    amb = [r for r in result if len(r["candidates"]) > 1 and r["reason"] != "t"]
    big = {n: len(c) for n, c in by_row.items() if len(c) > CASE_LIMIT}

    md = ["# Cell mapping (generated by scripts/consolidate-cells.py plan; not committed)", "",
          f"cells {len(result)} · a {reasons['a']} · b {reasons['b']} · c {reasons['c']} · t {reasons['t']} · "
          f"code-bearing rows {len(code)} · with a case {len(with_cases)} · needing a draft {len(drafts)}", "",
          "| old path | new path | home row | also proved by | reason |", "|---|---|---|---|---|"]
    for r in sorted(result, key=lambda r: r["old"]):
        why = r["reason"] + (f" ({r['note']})" if r["note"] else "")
        md.append(f"| {r['old']} | {r['new']} | {r['home'] or ''} | {', '.join(map(str, r['also']))} | {why} |")
    amb_lines = [f"# Ambiguity (generated): {len(amb)} cells with more than one candidate row not in {HOMES}, "
                 f"{len(big)} rows with more than {CASE_LIMIT} cases", "", "## Cells", ""]
    for r in sorted(amb, key=lambda r: r["old"]):
        amb_lines.append(f"{r['cell']}: home {r['home']} (reason {r['reason']}) of candidates "
                         f"{', '.join(map(str, r['candidates']))}")
    amb_lines += ["", f"## Rows with more than {CASE_LIMIT} cases", ""]
    for n, k in sorted(big.items(), key=lambda kv: -kv[1]):
        amb_lines.append(f"{n}: {k} cases")
    stats = {"cells": len(result), "a": reasons["a"], "b": reasons["b"], "c": reasons["c"], "t": reasons["t"],
             "code_rows": len(code), "rows_with_cases": len(with_cases), "rows_needing_draft": len(drafts),
             "ambiguous_cells": len(amb), "big_rows": len(big)}
    return "\n".join(md) + "\n", "\n".join(amb_lines) + "\n", stats


def cmd_plan(args):
    root = Path(args.root)
    rows = load_ledger(root / "decisions-taken.md")
    unslugged = sorted(n for n, r in rows.items() if r.kind == "code" and not r.slug)
    if unslugged and not args.allow_unslugged:
        print(f"refused: {len(unslugged)} code-bearing rows of the ledger have no Cell slug "
              f"(rows 1-143 first, front 166 s3); --allow-unslugged homes their cells outside:", file=sys.stderr)
        print(" ".join(map(str, unslugged)), file=sys.stderr)
        return 1
    modules = root / "conformance" / "modules"
    try:
        result = plan(rows, modules)
    except HomesError as e:
        print(f"refused: {HOMES}:\n{e}", file=sys.stderr)
        return 1
    md, amb, stats = render(result, rows)
    (modules / "INDEX.md").write_text(md)
    (modules / "INDEX.ambiguous").write_text(amb)
    if unslugged:
        print(f"unslugged code-bearing rows ({len(unslugged)}): {' '.join(map(str, unslugged))}")
        outside = [r["cell"] for r in result if r["note"]]
        print(f"cells homed outside for it: {len(outside)}")
    print(json.dumps(stats))
    return 0


# ── verify ──────────────────────────────────────────────────────────────────────

def measure(root):
    modules = Path(root) / "conformance" / "modules"
    cells = cells_of(modules)
    snaps, kinds, files = collections.Counter(), collections.Counter(), collections.Counter()
    targets = 0
    for c in cells:
        for f in sorted((c / "snapshot").rglob("*.snap")) if (c / "snapshot").is_dir() else []:
            rel = f.relative_to(c / "snapshot").parts
            snaps["output" if rel[0] == "output" else f"target:{rel[1]}"] += 1
            for ln in f.read_text(errors="replace").splitlines():
                w = ln.split(" ", 1)[0]
                if w in KINDS:
                    kinds[w] += 1
        try:
            if "targets" in json.loads((c / "botopink.json").read_text()):
                targets += 1
        except ValueError:
            pass
        inside = [c / "botopink.json", c / "docs.md"]
        for d in ("src", "deps", "snapshot"):
            if (c / d).is_dir():
                inside += [p for p in (c / d).rglob("*") if p.is_file()]
        for p in inside:
            if p.is_file():
                data = p.read_bytes()
                if p.name == "docs.md" and p.parent == c:  # a moved cell's references name its new home
                    data = MOVED.sub(b"modules/", data)
                files[(p.relative_to(c).as_posix(), hashlib.sha256(data).hexdigest())] += 1
    examples = 0
    for md in (Path(root) / "conformance").rglob("*.md"):
        if md.name != "INDEX.md":
            examples += md.read_text(errors="replace").count("<!-- example:")
    return {"cells": len(cells), "snap files": dict(snaps), "records": dict(kinds),
            "manifests with targets": targets, "file multiset": files, "example references": examples}


def cmd_verify(args):
    root = Path(args.root)
    with tempfile.TemporaryDirectory() as tmp:
        tar = subprocess.run(["git", "-C", str(root), "archive", args.base, "conformance"],
                             capture_output=True)
        if tar.returncode != 0:
            print(f"cannot read {args.base}: {tar.stderr.decode().strip()}", file=sys.stderr)
            return 2
        subprocess.run(["tar", "-x", "-C", tmp], input=tar.stdout, check=True)
        old, new = measure(tmp), measure(root)
    bad = 0
    for k in old:
        a, b = old[k], new[k]
        if a == b:
            size = sum(a.values()) if isinstance(a, collections.Counter) else a
            print(f"equal      {k}: {size if not isinstance(a, dict) else dict(sorted(a.items()))}"
                  if not isinstance(a, collections.Counter) else f"equal      {k}: {size} files")
        else:
            bad += 1
            print(f"different  {k}")
            if isinstance(a, collections.Counter):
                for x in list((a - b).items())[:5]:
                    print(f"  only in base: {x}")
                for x in list((b - a).items())[:5]:
                    print(f"  only in tree: {x}")
            else:
                print(f"  base {a}\n  tree {b}")
    return 1 if bad else 0


# ── apply ───────────────────────────────────────────────────────────────────────

DASH = "—"
GEN_LINE = re.compile(r"^(?:\[cases/[^\]]*\]\(cases/[^()\s]*\)|Proved also by .*)$")
SKIP_PARTS = {"src", "snapshot", "deps"}
OWN_REPO = {"botopink-lang", ".", "..", "$d", "$REPO_ROOT", "${REPO_ROOT}", "$repo", "$root"}


def lead_of(rule):
    """The lead of a row as decision-cells.py titles it."""
    m = re.match(r"\*\*(.+?)\*\*", rule)
    lead = m.group(1) if m else re.split(r"(?<=[.!?])\s", rule, maxsplit=1)[0][:120]
    return re.sub(r"\s+", " ", lead.replace("\\|", "|")).strip()


def group_of(entry):
    return entry["new"].split("/")[1]


def group_order(result):
    n = collections.Counter(group_of(r) for r in result)
    return sorted(n, key=lambda g: (-n[g], g))


def git(root, *a):
    return subprocess.run(["git", "-C", str(root), *a], check=True, capture_output=True, text=True)


def module_of(entry):
    return entry["new"].rsplit("/cases/", 1)[0]


def write_docs(conf, rows, result):
    """(Re)writes the docs.md of every module that holds a case on disk (or already has a docs.md)."""
    mods = collections.defaultdict(lambda: {"cases": [], "also": [], "row": None})
    for r in result:
        m = module_of(r)
        mods[m]["cases"].append(r)
        if r["home"]:
            mods[m]["row"] = r["home"]
        for a in r["also"]:
            if rows[a].slug:
                mods[f"modules/decisions-taken/{rows[a].dirname}"]["also"].append(r)
    for m, info in sorted(mods.items()):
        d = conf / m
        on_disk = [c for c in info["cases"] if (conf / c["new"]).is_dir()]
        if not d.is_dir() or not on_disk:
            continue
        f = d / "docs.md"
        if f.exists():
            lines = [ln for ln in f.read_text().split("\n") if not GEN_LINE.match(ln)]
        elif info["row"]:
            lines = [f"# Decision {info['row']} {DASH} {lead_of(rows[info['row']].rule)}"]
        else:
            lines = [f"# {m.split('/')[1]}"]
        while lines and lines[-1] == "":
            lines.pop()
        body = [f"[cases/{c['cell']}/src/main.bp](cases/{c['cell']}/src/main.bp)"
                for c in sorted(on_disk, key=lambda c: c["cell"]) if (conf / c["new"] / "src/main.bp").is_file()]
        also = []
        for c in sorted(info["also"], key=lambda c: c["cell"]):
            tgt = conf / c["new"]
            if tgt.is_dir() and c["new"].startswith("modules/decisions-taken/"):
                leaf = "src/main.bp" if (tgt / "src/main.bp").is_file() else "docs.md"
                also.append(f"Proved also by [{c['cell']}](../{'/'.join(c['new'].split('/')[2:])}/{leaf})")
        out = lines + [""] + body + ([""] + also if also else [])
        f.write_text("\n".join(out) + "\n")


def rewrite_text(text, rx, moved, dirs):
    """`modules/<cell>` -> the cell's new path, by exact token and only where it names this repository's cell."""
    def sub(m):
        pre = re.search(r"[\w./$~{}-]*$", text[:m.start()]).group(0)
        n = m.group(1)
        if pre == "":
            ok = n not in dirs  # a bare `modules/<name>` that is also a source module is not a cell
        elif pre.endswith("conformance/"):
            head = pre[:-len("conformance/")].rstrip("/")
            ok = not head or head.rsplit("/", 1)[-1] in OWN_REPO
        else:
            ok = False
        return moved[n] if ok else m.group(0)
    return rx.sub(sub, text)


def rewrite_refs(root, moved):
    """moved: cell name -> its new `modules/...` path. -> the files changed."""
    dirs = {p.name for p in (root / "modules").iterdir() if p.is_dir()} if (root / "modules").is_dir() else set()
    alt = "|".join(re.escape(n) for n in sorted(moved, key=lambda n: (-len(n), n)))
    rx = re.compile(r"modules/(" + alt + r")(?![\w-])(?!/cases/)")
    listed = git(root, "grep", "-lE", "modules/[A-Za-z0-9_]").stdout.split("\n")
    changed = []
    for rel in filter(None, listed):
        parts = rel.split("/")
        if rel == "decisions-taken.md" or parts[-1] == "INDEX.md" or rel.startswith("scripts/consolidate-cells"):
            continue
        if parts[:2] == ["conformance", "modules"] and (parts[-1] != "docs.md" or SKIP_PARTS & set(parts[3:-1])):
            continue
        f = root / rel
        if not f.is_file():
            continue
        try:
            text = f.read_text()
        except UnicodeDecodeError:
            continue
        out = rewrite_text(text, rx, moved, dirs)
        if out != text:
            f.write_text(out)
            changed.append(rel)
    return changed


def add_globs(conf, drop_star):
    f = conf / "modules" / "botopink.json"
    d = json.loads(f.read_text())
    ws = d.setdefault("workspaces", [])
    before = list(ws)
    for g in ("*/cases/*", "decisions-taken/*/cases/*"):
        if g not in ws:
            ws.append(g)
    if drop_star and "*" in ws:
        ws.remove("*")
    if ws == before:
        return
    rest = {k: v for k, v in d.items() if k != "workspaces"}
    lines = ["{"] + [f"  {json.dumps(k)}: {json.dumps(v)}," for k, v in rest.items()]
    lines.append(f'  "workspaces": [{", ".join(json.dumps(w) for w in ws)}]')
    f.write_text("\n".join(lines + ["}"]) + "\n")


def cmd_groups(args):
    root = Path(args.root)
    rows = load_ledger(root / "decisions-taken.md")
    result = plan(rows, root / "conformance" / "modules")
    n = collections.Counter(group_of(r) for r in result if r["old"] != r["new"])
    for g in group_order(result):
        print(f"{n[g]:5d} {g}")
    return 0


def apply_group(root, rows, result, group, lo, hi, dry):
    conf = root / "conformance"
    todo = [r for r in result if r["old"] != r["new"]
            and (group is None or group_of(r) == group)
            and (lo is None or (r["home"] is not None and lo <= r["home"] <= hi))]
    if dry:
        return todo, []
    # a cell named like its own module moves out of the way first
    selfmv = [r for r in todo if r["new"].startswith(f"{r['old']}/")]
    for r in selfmv:
        git(conf, "mv", r["old"], r["old"] + ".moving")
    for r in selfmv:
        (conf / r["new"]).parent.mkdir(parents=True, exist_ok=True)
        git(conf, "mv", r["old"] + ".moving", r["new"])
    for r in todo:
        if r not in selfmv:
            (conf / r["new"]).parent.mkdir(parents=True, exist_ok=True)
            git(conf, "mv", r["old"], r["new"])
    changed = rewrite_refs(root, {r["cell"]: r["new"] for r in todo}) if todo else []
    for r in todo:
        r["old"] = r["new"]
    write_docs(conf, rows, result)
    git(root, "add", "-A", "conformance", ":!conformance/modules/INDEX.md", ":!conformance/modules/INDEX.ambiguous", *changed)
    return todo, changed


def cmd_apply(args):
    root = Path(args.root)
    rows = load_ledger(root / "decisions-taken.md")
    conf = root / "conformance"
    result = plan(rows, conf / "modules")
    groups = group_order(result) if args.all else [args.group] if args.group else []
    lo = hi = None
    if args.range:
        lo, hi = (int(x) for x in args.range.split("-"))
    total = 0
    steps = []  # (group, lo, hi); the decision modules go a hundred rows at a time
    for g in groups:
        if g == "decisions-taken" and lo is None and args.commit:
            top = max(r["home"] for r in result if r["home"])
            steps += [(g, k, k + 99) for k in range(0, top + 1, 100)]
        else:
            steps.append((g, lo, hi))
    for g, l, h in steps:
        todo, changed = apply_group(root, rows, result, g, l, h, args.dry_run)
        if not todo:
            continue
        total += len(todo)
        label = g if l is None else f"{g} rows {l}-{h}"
        print(f"{label}: {len(todo)} cells, {len(changed)} files rewritten", flush=True)
        if args.commit:
            msg = (f"conformance: {len(todo)} cells into modules of cases, {label} (B-157 P3, decision 765)\n\n"
                   "Moved by scripts/consolidate-cells.py apply. Committed with --no-verify at the user's "
                   "request (green later); the hook's analysis_equivalence.sh is red on rakun.\n\n"
                   "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>\n")
            git(root, "commit", "--no-verify", "-q", "-m", msg)
    if not args.dry_run and (groups or args.drop_star):
        add_globs(conf, args.all or args.drop_star)
        git(root, "add", "conformance/modules/botopink.json")
        if args.commit and git(root, "diff", "--cached", "--name-only").stdout.strip():
            git(root, "commit", "--no-verify", "-q", "-m",
                "conformance: the module manifest drops \"*\", every cell is in a module of cases (B-157 P3, decision 765)\n\n"
                "Committed with --no-verify at the user's request (green later).\n\n"
                "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>\n")
    print(f"moved {total} cells" if not args.dry_run else f"{total} cells would move")
    return 0


MOVED = re.compile(rb"modules/(?:[\w-]+/){1,2}cases/")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--root", default=str(Path(__file__).resolve().parent.parent))
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("plan")
    p.add_argument("--allow-unslugged", action="store_true")
    sub.add_parser("groups")
    a = sub.add_parser("apply")
    a.add_argument("--group")
    a.add_argument("--all", action="store_true")
    a.add_argument("--range")
    a.add_argument("--drop-star", action="store_true")
    a.add_argument("--dry-run", action="store_true")
    a.add_argument("--commit", action="store_true", help="one commit per group (decision modules: per hundred rows)")
    v = sub.add_parser("verify")
    v.add_argument("--base", required=True)
    args = ap.parse_args(argv)
    try:
        return {"plan": cmd_plan, "verify": cmd_verify, "apply": cmd_apply, "groups": cmd_groups}[args.cmd](args)
    except HomesError as e:
        print(f"refused: {HOMES}:\n{e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
