#!/usr/bin/env bash
# snap_audit.sh — meta-audit of every *.snap.md in the workspace.
#
# Authored by tasks/v0.beta.20/specs/snap-audit.md. Pure shell + awk;
# read-only. Writes its reports under build/snap-audit/<mode>.tsv
# (relative to repository/botopink-lang/).
#
# Usage:
#   scripts/snap_audit.sh --mode={runlog,legacy,values,coverage}
#   scripts/snap_audit.sh --mode=orphans --trace=<file>
#   scripts/snap_audit.sh --mode=review  --trace=<file> [--reports=<dir>]
#   scripts/snap_audit.sh --mode=runtime-parity
#
# `--trace=<file>` is the file a full `BOTOPINK_SNAP_TRACE=<file> zig build test`
# run appended to (one `<snapshot path> TAB <test file:line|-> TAB <test fn|->`
# line per checked snapshot; see modules/compiler-core/src/utils/snap.zig).
# Start from an empty file, and trace an unfiltered run: a filtered run makes
# every snapshot it skipped look like an orphan.
#
# Modes:
#   runlog    Classify every codegen snap as (a) silent / (b) observable /
#             (c) deferred-observable; capture whether the section
#             exists + whether its content is empty.
#             Columns: backend\tlabel\trunlog_state\tpath
#               runlog_state ∈ {nonempty,empty,missing}
#               label        ∈ {a,b,c}
#               backend      ∈ {node,erlang,beam,wasm,errors}
#   legacy    Grep every snap's SOURCE CODE block for legacy surface
#             listed in §F2 of the spec. Columns: surface\tpath\tline
#   values    Dump (suite, backend, source-hash, runlog-text) for the
#             non-empty (b) codegen snaps so F3 can cross-check values.
#             Columns: backend\tsource_sha1\tpath\trunlog_text(escaped)
#   coverage  Pivot of `runlog` by backend × label × runlog_state.
#             Prints the table to stdout AND saves a copy to coverage.tsv.
#   orphans   Every *.snap.md on disk (compiler-core + language-server) that
#             no test checked in the traced run, and every traced path that
#             is not on disk. Columns: kind\tpath
#               kind ∈ {orphan,unrecorded}
#   review    The review worksheet: one row per unique snapshot (the four
#             comptime runtime copies collapse into one row).
#             Columns: suite\tslug\ttest\tpaths\tverdict
#               suite   codegen/<runtime>/<target> · codegen/<runtime>/errors/<target> · comptime ·
#                       comptime/errors · comptime/<dir> · parser · lsp
#               test    test file:line (comma-joined when several tests write
#                       the same path); ORPHAN when no traced test checked it
#               verdict seeded from the 1.0.1-beta review reports (`--reports`,
#                       default ../../specs/1.0.1-beta/06-snapshot-review from
#                       the bot-lang root): every table row whose `verdict`
#                       column names the slug, as `<verdict> [report:line]`,
#                       joined by ` ; `; `-` when no report row names it
#   runtime-parity
#             Front 18 step 4 (decision 85): every codegen snapshot exists
#             under both comptime runtimes — codegen/beam/<t>/<slug> and
#             codegen/wat/<t>/<slug>, the same for errors/ and for
#             comptime/runtime/{beam,wat}/<slug> — and every pair is equal once
#             the listing sections are set aside (`COMPTIME ERLANG` on beam,
#             `COMPTIME WAT` on wat: the only text that may differ). A
#             difference — a COMPTIME REPLY, a RUN LOG, generated code — is a
#             defect in one runtime and is printed as a unified diff; a
#             missing pair member too. No allow-list. Columns of
#             runtime-parity.tsv: verdict\tpath   (verdict ∈ {equal,differs,missing})
#             Also writes review-unmatched.tsv: every report row with a verdict
#             that names no snapshot on disk (report_row\tverdict\tslug_cell).
#
# Exit codes:
#   0  reports written
#   1  argument error / unknown mode
#   2  IO error (snapshots dir missing, write failure, trace missing)
#   3  orphans: an orphan or unrecorded path exists; review: a row has no
#      test file:line; runtime-parity: a pair differs or misses a member

set -euo pipefail

usage() {
    cat >&2 <<'USAGE'
usage: scripts/snap_audit.sh --mode={runlog,legacy,values,coverage,runtime-parity}
       scripts/snap_audit.sh --mode=orphans --trace=<file>
       scripts/snap_audit.sh --mode=review  --trace=<file> [--reports=<dir>]

Reports land under repository/botopink-lang/build/snap-audit/<mode>.tsv.
USAGE
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

mode=""
trace=""
reports=""
for arg in "$@"; do
    case "$arg" in
        --mode=runlog)   mode=runlog ;;
        --mode=legacy)   mode=legacy ;;
        --mode=values)   mode=values ;;
        --mode=coverage) mode=coverage ;;
        --mode=orphans)  mode=orphans ;;
        --mode=review)   mode=review ;;
        --mode=runtime-parity) mode=runtime-parity ;;
        --trace=*)       trace="${arg#--trace=}" ;;
        --reports=*)     reports="${arg#--reports=}" ;;
        -h|--help)       usage; exit 0 ;;
        *)               usage; exit 1 ;;
    esac
done
if [ -z "$mode" ]; then
    usage
    exit 1
fi
case "$mode" in
    orphans|review)
        if [ -z "$trace" ]; then
            echo "snap_audit: --mode=$mode needs --trace=<file> (from BOTOPINK_SNAP_TRACE=<file> zig build test)" >&2
            exit 1
        fi
        if [ ! -s "$trace" ]; then
            echo "snap_audit: trace file '$trace' is missing or empty" >&2
            exit 2
        fi
        ;;
    *)
        if [ -n "$trace" ] || [ -n "$reports" ]; then
            usage
            exit 1
        fi
        ;;
esac

# Resolve the bot-lang root regardless of where the script is invoked from.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
botlang_root="$(cd "$script_dir/.." && pwd)"
codegen_dir="$botlang_root/modules/compiler-core/snapshots/codegen"
parser_dir="$botlang_root/modules/compiler-core/snapshots/parser"
comptime_dir="$botlang_root/modules/compiler-core/snapshots/comptime"
lsp_dir="$botlang_root/modules/language-server/snapshots/lsp"

if [ ! -d "$codegen_dir" ]; then
    echo "snap_audit: codegen snapshots dir not found at $codegen_dir" >&2
    exit 2
fi

out_dir="$botlang_root/build/snap-audit"
mkdir -p "$out_dir"

# Backend derived from the target component of the path. The codegen layout
# is codegen/<comptime runtime>/<target>/<slug>.snap.md, plus a
# codegen/<comptime runtime>/errors/<target>/<slug>.snap.md tree (front 18
# step 4, decision 85: runtime ∈ {beam, wat}). The "errors" leg
# never carries a RUN LOG by contract — surface it under its own
# backend label so the coverage pivot stays meaningful.
backendOf() {
    local p="$1"
    case "$p" in
        */codegen/*/errors/*)   echo errors ;;
        */codegen/*/commonJS/*) echo node ;;
        */codegen/*/erlang/*)   echo erlang ;;
        */codegen/*/beam/*)     echo beam ;;
        */codegen/*/wasm/*)     echo wasm ;;
        *)                  echo unknown ;;
    esac
}

# Classify a codegen snap by its SOURCE CODE block + its RUN LOG section.
# Emits one line: `<label>\t<runlog_state>` where
#   label        — a (silent) / b (observable, has fn main()) / c (deferred — has @print but no fn main())
#   runlog_state — nonempty / empty / missing
classifyCodegen() {
    awk '
        BEGIN { in_src=0; in_run=0; saw_run=0; src=""; run=""; has_main=0; has_print=0 }
        /^----- SOURCE CODE/  { in_src=0; section="src"; next }
        /^----- RUN LOG -----/ { in_run=0; section="run"; saw_run=1; next }
        /^----- /              { section="other"; next }
        /^```botopink/         { if (section=="src") in_src=1; next }
        /^```logs/             { if (section=="run") in_run=1; next }
        /^```/                 { in_src=0; in_run=0; next }
        in_src                 { src = src $0 "\n" }
        in_run                 { run = run $0 "\n" }
        END {
            if (src ~ /\<fn[[:space:]]+main[[:space:]]*\(/) has_main=1
            if (src ~ /@print|@assert|@panic/)              has_print=1
            label = (has_print && has_main) ? "b" : (has_print ? "c" : "a")
            if (!saw_run)         state = "missing"
            else if (run == "")   state = "empty"
            else                  state = "nonempty"
            print label "\t" state
        }
    ' "$1"
}

# Pull the SOURCE CODE block of a snap (any suite) into stdout, stripped
# of the fence lines.
extractSource() {
    awk '
        BEGIN { in_src=0 }
        /^----- SOURCE CODE/    { section="src"; next }
        /^----- /               { section="other"; in_src=0; next }
        /^```botopink/          { if (section=="src") { in_src=1; next } }
        /^```/                  { if (in_src) { in_src=0; next } }
        in_src                  { print }
    ' "$1"
}

# Pull the RUN LOG block content (whatever's inside ```logs ... ```).
extractRunLog() {
    awk '
        BEGIN { in_run=0 }
        /^----- RUN LOG -----/  { section="run"; next }
        /^----- /               { section="other"; in_run=0; next }
        /^```logs/              { if (section=="run") { in_run=1; next } }
        /^```/                  { if (in_run) { in_run=0; next } }
        in_run                  { print }
    ' "$1"
}

# Every *.snap.md on disk, compiler-core and language-server, relative to the
# bot-lang root, sorted (byte order, so `comm` can diff it).
listSnapshots() {
    local roots=("$botlang_root/modules/compiler-core/snapshots")
    [ -d "$lsp_dir" ] && roots+=("$lsp_dir")
    find "${roots[@]}" -name '*.snap.md' -print | while IFS= read -r p; do
        printf '%s\n' "${p#$botlang_root/}"
    done | LC_ALL=C sort
}

# The trace with both columns made root-relative (`modules/<module>/…`), so a
# trace recorded in another checkout of the same tree still lines up.
# Columns: path\ttest   (test is `-` when the snapshot was checked outside a
# helper's `traceEnter` scope)
normalizeTrace() {
    awk -F'\t' 'BEGIN { OFS = "\t" }
        NF >= 2 {
            p = $1
            if (match(p, /\/modules\/[^\/]+\/snapshots\//)) p = substr(p, RSTART + 1)
            t = $2
            if (t != "-" && match(t, /\/modules\/[^\/]+\/src\//)) t = substr(t, RSTART + 1)
            print p, t
        }' "$trace"
}

# A snapshot with its comptime listing sections set aside: the header line
# of `COMPTIME ERLANG` / `COMPTIME WAT` becomes `COMPTIME LISTING` and the
# fenced body after it is dropped — the one part the runtimes may differ in.
withoutListings() {
    awk '
        /^----- COMPTIME (ERLANG|WAT) -- / { sub(/COMPTIME (ERLANG|WAT)/, "COMPTIME LISTING"); print; skip = 1; next }
        skip == 1 && /^```/ { skip = 2; next }
        skip == 2 { if ($0 ~ /^```$/) skip = 0; next }
        { print }
    ' "$1"
}

case "$mode" in
    runtime-parity)
        out="$out_dir/runtime-parity.tsv"
        : > "$out"
        printf 'verdict\tpath\n' >> "$out"
        bad=0
        pairs=0
        comptime_runtime_dir="$comptime_dir/runtime"
        for tree in "$codegen_dir" "$comptime_runtime_dir"; do
            [ -d "$tree/beam" ] || [ -d "$tree/wat" ] || continue
            while IFS= read -r rel; do
                b="$tree/beam/$rel"
                w="$tree/wat/$rel"
                shown="${tree#$botlang_root/}/{beam,wat}/$rel"
                if [ ! -f "$b" ] || [ ! -f "$w" ]; then
                    printf 'missing\t%s\n' "$shown" >> "$out"
                    echo "runtime-parity: MISSING $shown (beam: $([ -f "$b" ] && echo present || echo absent), wat: $([ -f "$w" ] && echo present || echo absent))" >&2
                    bad=$((bad + 1))
                    continue
                fi
                pairs=$((pairs + 1))
                if ! diff -u --label "beam/$rel" --label "wat/$rel" <(withoutListings "$b") <(withoutListings "$w") > "$out_dir/runtime-parity.diff.tmp"; then
                    printf 'differs\t%s\n' "$shown" >> "$out"
                    cat "$out_dir/runtime-parity.diff.tmp" >&2
                    bad=$((bad + 1))
                else
                    printf 'equal\t%s\n' "$shown" >> "$out"
                fi
            done < <( { [ -d "$tree/beam" ] && (cd "$tree/beam" && find . -name '*.snap.md' | sed 's|^\./||');
                        [ -d "$tree/wat" ] && (cd "$tree/wat" && find . -name '*.snap.md' | sed 's|^\./||'); } | LC_ALL=C sort -u )
        done
        rm -f "$out_dir/runtime-parity.diff.tmp"
        printf 'runtime-parity: %d pairs, %d differing or missing — %s\n' "$pairs" "$bad" "$out"
        [ "$bad" -eq 0 ] || exit 3
        ;;
    runlog)
        # ---- F0.1 --mode=runlog
        out="$out_dir/runlog.tsv"
        : > "$out"
        printf 'backend\tlabel\trunlog_state\tpath\n' >> "$out"
        find "$codegen_dir" -name '*.snap.md' -print | sort | while IFS= read -r p; do
            backend="$(backendOf "$p")"
            cls="$(classifyCodegen "$p")"
            rel="${p#$botlang_root/}"
            printf '%s\t%s\t%s\n' "$backend" "$cls" "$rel" >> "$out"
        done
        printf 'wrote %s (%d rows)\n' "$out" "$(($(wc -l < "$out") - 1))"
        ;;

    legacy)
        # ---- F0.1 --mode=legacy
        out="$out_dir/legacy.tsv"
        : > "$out"
        printf 'surface\tpath\tline\n' >> "$out"
        # Each row: surface_key + extended-regex applied to SOURCE blocks
        # only (we extract first to avoid hitting the emitted-code
        # sections where these literals legitimately appear). Uses
        # `grep -nE` instead of awk because awk's `\*` / `\[` get
        # un-escaped when passed via `-v`, producing nonsense regexes.
        scan() {
            local key="$1" pattern="$2" root="$3"
            [ -d "$root" ] || return 0
            find "$root" -name '*.snap.md' -print | sort | while IFS= read -r p; do
                rel="${p#$botlang_root/}"
                # grep -nE emits `<line>:<text>`; we keep only the line
                # number and drop the body. `|| true` so a zero-hit
                # file doesn't trip set -e.
                extractSource "$p" | grep -nE "$pattern" 2>/dev/null | \
                    awk -F: -v key="$key" -v pth="$rel" '{ printf "%s\t%s\t%s\n", key, pth, $1 }' \
                    >> "$out" || true
            done
        }
        # Surface list mirrors §F2 of the spec.
        # The grep ERE escapes are literal here — they survive the shell
        # quoting because every regex is in single quotes.
        for suite in codegen parser comptime lsp; do
            case "$suite" in
                codegen)  root="$codegen_dir" ;;
                parser)   root="$parser_dir" ;;
                comptime) root="$comptime_dir" ;;
                lsp)      root="$lsp_dir" ;;
            esac
            # `*fn ` v19 §S removed. Anchored at BoL or whitespace so we
            # do not match identifiers like `defaultFn` that legitimately
            # contain the substring.
            scan "star-fn"            '(^|[[:space:]])\*fn[[:space:]]'        "$root"
            # Legacy `#\[@External\.target("…")]` form retired by prim-op-annotation.
            scan "external-legacy"    '#\[@external\([a-zA-Z_]+,'             "$root"
            # `@[name]` outside `#[…]` — the deprecated annotation form.
            # Restrict to forms that look like annotations (lowercase
            # letter immediately after `[`, followed by `]` or `(`).
            scan "at-bracket-annot"   '@\[[a-z][a-zA-Z0-9_]*[](]'             "$root"
            # `when($argc == N)` literal retired by prim-op-extension when-argc-removal.
            scan "when-argc"          'when\(\$argc[[:space:]]*=='            "$root"
            # `string.length()` / `value:length()` template footguns from memory.
            scan "string-dot-length"  'string\.length\(\)'                    "$root"
            scan "value-colon-length" 'value:length\(\)'                      "$root"
        done
        printf 'wrote %s (%d rows)\n' "$out" "$(($(wc -l < "$out") - 1))"
        ;;

    values)
        # ---- F0.1 --mode=values
        # Only for (b) codegen snaps with non-empty RUN LOG: emit a row
        # with the source SHA-1 (so duplicate fixtures collapse) and
        # the runlog text base64-encoded (so tabs/newlines survive a
        # TSV column intact).
        out="$out_dir/values.tsv"
        : > "$out"
        printf 'backend\tsource_sha1\tpath\trunlog_b64\n' >> "$out"
        find "$codegen_dir" -name '*.snap.md' -print | sort | while IFS= read -r p; do
            backend="$(backendOf "$p")"
            [ "$backend" = "errors" ] && continue
            cls="$(classifyCodegen "$p")"
            label="${cls%%	*}"
            state="${cls##*	}"
            [ "$label" = "b" ] || continue
            [ "$state" = "nonempty" ] || continue
            rel="${p#$botlang_root/}"
            src_sha="$(extractSource "$p" | sha1sum | awk '{print $1}')"
            runlog_b64="$(extractRunLog "$p" | base64 -w0)"
            printf '%s\t%s\t%s\t%s\n' "$backend" "$src_sha" "$rel" "$runlog_b64" >> "$out"
        done
        printf 'wrote %s (%d rows)\n' "$out" "$(($(wc -l < "$out") - 1))"
        ;;

    coverage)
        # ---- F0.1 --mode=coverage
        # Builds on --mode=runlog. Re-runs the classifier to stay
        # stateless (the user can call --mode=coverage directly without
        # having run --mode=runlog first).
        out="$out_dir/coverage.tsv"
        tmp="$(mktemp)"
        trap 'rm -f "$tmp"' EXIT
        find "$codegen_dir" -name '*.snap.md' -print | sort | while IFS= read -r p; do
            backend="$(backendOf "$p")"
            cls="$(classifyCodegen "$p")"
            printf '%s\t%s\n' "$backend" "$cls" >> "$tmp"
        done
        # Pivot in awk: counts by (backend, label, state).
        awk -F'\t' '
            { count[$1 "\t" $2 "\t" $3]++; totals[$1]++ }
            END {
                printf "backend\tlabel\tstate\tcount\tpct_of_backend\n"
                for (k in count) {
                    split(k, a, "\t")
                    printf "%s\t%s\t%s\t%d\t%.1f%%\n", a[1], a[2], a[3], count[k], (count[k]/totals[a[1]])*100
                }
            }
        ' "$tmp" | sort > "$out"
        # Pretty-print to stdout: backend × label matrix.
        printf '\n# coverage pivot (backend × label):\n'
        awk -F'\t' '
            NR==1 { next }
            { lbl=$2; state=$3; key=$1 "\t" lbl "/" state; counts[key]+=$4; totals[$1]+=$4; labels[lbl "/" state]=1; backends[$1]=1 }
            END {
                printf "%-10s", "backend"
                n=0; for (l in labels) { ord[++n]=l }
                # Stable order
                ord_arr[1]="a/missing"; ord_arr[2]="a/empty"; ord_arr[3]="a/nonempty"
                ord_arr[4]="b/missing"; ord_arr[5]="b/empty"; ord_arr[6]="b/nonempty"
                ord_arr[7]="c/missing"; ord_arr[8]="c/empty"; ord_arr[9]="c/nonempty"
                for (i=1;i<=9;i++) printf "  %-12s", ord_arr[i]
                printf "  %-6s\n", "total"
                for (b in backends) {
                    printf "%-10s", b
                    for (i=1;i<=9;i++) {
                        k=b "\t" ord_arr[i]
                        c=(k in counts)?counts[k]:0
                        printf "  %-12d", c
                    }
                    printf "  %-6d\n", totals[b]
                }
            }
        ' "$out"
        printf '\nwrote %s\n' "$out"
        ;;
    orphans)
        # ---- F9 step 1 --mode=orphans
        out="$out_dir/orphans.tsv"
        tmp_dir="$(mktemp -d)"
        trap 'rm -rf "$tmp_dir"' EXIT
        listSnapshots > "$tmp_dir/disk"
        normalizeTrace | cut -f1 | LC_ALL=C sort -u > "$tmp_dir/traced"
        {
            printf 'kind\tpath\n'
            LC_ALL=C comm -23 "$tmp_dir/disk" "$tmp_dir/traced" | sed 's/^/orphan\t/'
            LC_ALL=C comm -13 "$tmp_dir/disk" "$tmp_dir/traced" | sed 's/^/missing\t/'
        } > "$out"
        n_disk="$(wc -l < "$tmp_dir/disk")"
        n_traced="$(wc -l < "$tmp_dir/traced")"
        n_orphan="$(grep -c '^orphan	' "$out" || true)"
        n_missing="$(grep -c '^missing	' "$out" || true)"
        printf 'on disk %d · traced %d · orphan %d · missing %d\n' \
            "$n_disk" "$n_traced" "$n_orphan" "$n_missing"
        printf 'wrote %s\n' "$out"
        if [ "$n_orphan" -gt 0 ] || [ "$n_missing" -gt 0 ]; then
            exit 3
        fi
        ;;

    review)
        # ---- F9 step 2 --mode=review
        out="$out_dir/review.tsv"
        if [ -z "$reports" ]; then
            default_reports="$botlang_root/../../specs/1.0.1-beta/06-snapshot-review"
            [ -d "$default_reports" ] && reports="$(cd "$default_reports" && pwd)"
        fi
        if [ -n "$reports" ] && [ ! -d "$reports" ]; then
            echo "snap_audit: reports dir '$reports' not found" >&2
            exit 2
        fi
        tmp_dir="$(mktemp -d)"
        trap 'rm -rf "$tmp_dir"' EXIT
        listSnapshots > "$tmp_dir/disk"
        normalizeTrace > "$tmp_dir/trace"

        # String literals in the test sources that look like a snapshot name,
        # with their file:line — the fallback for a snapshot checked outside a
        # `traceEnter` scope (the LSP asserts take a literal slug).
        find "$botlang_root/modules/compiler-core/src/codegen/tests" \
             "$botlang_root/modules/compiler-core/src/comptime/tests" \
             "$botlang_root/modules/compiler-core/src/parser/tests" \
             "$botlang_root/modules/language-server/src/tests" \
             -name '*.zig' -print 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do
            awk -v rel="${f#$botlang_root/}" '
                BEGIN { re = "\"[A-Za-z0-9_./-]+\"" }
                {
                    line = $0
                    while (match(line, re)) {
                        printf "%s\t%s:%d\n", substr(line, RSTART + 1, RLENGTH - 2), rel, FNR
                        line = substr(line, RSTART + RLENGTH)
                    }
                }' "$f"
        done > "$tmp_dir/literals"

        report_files=()
        if [ -n "$reports" ]; then
            while IFS= read -r f; do report_files+=("$f"); done \
                < <(find "$reports" -maxdepth 1 -name '*.md' -print | LC_ALL=C sort)
        fi

        status=0
        unmatched="$out_dir/review-unmatched.tsv"
        printf 'report_row\tverdict\tslug_cell\n' > "$unmatched"
        awk -v unmatched_out="$unmatched" -f - \
            role=disk "$tmp_dir/disk" \
            role=trace "$tmp_dir/trace" \
            role=lit "$tmp_dir/literals" \
            role=report ${report_files[@]+"${report_files[@]}"} \
            > "$tmp_dir/rows" 2> "$tmp_dir/summary" <<'AWK' || status=$?
function trim(x) { gsub(/^[ \t]+|[ \t]+$/, "", x); return x }
function addUnique(list, item,    parts, n, i) {
    if (item == "") return list
    if (list == "") return item
    n = split(list, parts, ",")
    for (i = 1; i <= n; i++) if (parts[i] == item) return list
    return list "," item
}
# Known slugs named by a report's slug cell. A token counts only when it holds
# an `_` or is the whole cell, so prose ("parser error: use after return") never
# matches a one-word slug by accident.
function slugsInCell(c, fam,    whole, n, toks, i, out) {
    whole = c
    gsub(/[`*]/, "", whole)
    sub(/\.snap\.md$/, "", whole)
    whole = trim(whole)
    out = ""
    n = split(c, toks, /[^A-Za-z0-9_]+/)
    for (i = 1; i <= n; i++) {
        if (toks[i] == "") continue
        if (!((fam SUBSEP toks[i]) in known)) continue
        if (index(toks[i], "_") == 0 && toks[i] != whole) continue
        out = addUnique(out, toks[i])
    }
    return out
}
function backendsInCell(c,    l, out) {
    l = tolower(c)
    out = ""
    if (l ~ /node|commonjs|(^|[^a-z])js([^a-z]|$)/) out = addUnique(out, "commonJS")
    if (l ~ /erlang|(^|[^a-z])erl([^a-z]|$)/) out = addUnique(out, "erlang")
    if (l ~ /beam/) out = addUnique(out, "beam")
    if (l ~ /wasm|wat/) out = addUnique(out, "wasm")
    if (out == "" || l ~ /all/) out = "*"
    return out
}
function addVerdict(fam, be, slug, text,    k) {
    k = fam SUBSEP be SUBSEP slug
    if (!(k in verd)) verd[k] = text
    else if (index(verd[k], text) == 0) verd[k] = verd[k] " ; " text
}
BEGIN { FS = "\t"; OFS = "\t" }

role == "disk" {
    path = $0
    n = split(path, seg, "/")
    slug = seg[n]
    sub(/\.snap\.md$/, "", slug)
    be = "*"
    if (seg[2] == "language-server") { suite = "lsp"; fam = "lsp" }
    else if (seg[4] == "codegen") {
        fam = "codegen"
        # codegen/<runtime>/<target>/<slug> · codegen/<runtime>/errors/<target>/<slug>
        if (seg[6] == "errors" && n == 8) { suite = "codegen/" seg[5] "/errors/" seg[7]; be = seg[7] }
        else { suite = "codegen/" seg[5] "/" seg[6]; be = seg[6] }
    }
    else if (seg[4] == "comptime") {
        fam = "comptime"
        if (seg[5] ~ /^(node|erlang|wasm|beam)$/) suite = (n == 7 && seg[6] == "errors") ? "comptime/errors" : "comptime"
        else suite = "comptime/" seg[5]
    }
    else if (seg[4] == "parser") { suite = "parser"; fam = "parser" }
    else { suite = "other"; fam = "other" }
    key = suite SUBSEP slug
    if (!(key in kpaths)) {
        order[++nk] = key
        ksuite[key] = suite; kslug[key] = slug; kfam[key] = fam; kbe[key] = be
        kpaths[key] = path
    } else {
        kpaths[key] = kpaths[key] "," path
    }
    known[fam SUBSEP slug] = 1
    next
}

role == "trace" {
    traced[$1] = 1
    if ($2 != "-") ptests[$1] = addUnique(ptests[$1], $2)
    next
}

role == "lit" {
    if (!($1 in litloc)) litloc[$1] = $2
    next
}

role == "report" {
    if (FNR == 1) {
        rep = FILENAME; sub(/.*\//, "", rep)
        rfam = rep ~ /^codegen-/ ? "codegen" : rep ~ /^comptime-/ ? "comptime" : rep ~ /^parser/ ? "parser" : rep ~ /^lsp/ ? "lsp" : "other"
        in_table = 0; prev_slugs = ""
        nreports++
    }
    line = $0
    if (line !~ /^[ \t]*\|/) { in_table = 0; next }
    gsub(/\\\|/, "\001", line)
    sub(/^[ \t]*\|/, "", line)
    sub(/\|[ \t]*$/, "", line)
    ncell = split(line, cell, "|")
    for (i = 1; i <= ncell; i++) { gsub(/\001/, "|", cell[i]); cell[i] = trim(cell[i]) }
    if (!in_table) {
        in_table = 1; vcol = 0; bcol = 0; idtable = 0; prev_slugs = ""
        for (i = 1; i <= ncell; i++) {
            h = tolower(cell[i])
            if (h == "verdict") vcol = i
            if (h ~ /^(backend|target)/) bcol = i
        }
        # A summary table ("Verdict counts") leads with the verdict column.
        if (vcol == 1) vcol = 0
        if (vcol) idtable = (tolower(cell[1]) == "id")
        next
    }
    if (line ~ /^[ \t:|-]+$/) next
    if (!vcol || ncell < vcol) next

    verdict = cell[vcol]
    gsub(/[`*]/, "", verdict)
    gsub(/[ \t]+/, " ", verdict)
    verdict = trim(verdict) " [" rep ":" FNR "]"
    bes = bcol ? backendsInCell(cell[bcol]) : "*"

    if (tolower(cell[1]) ~ /^same/) slugs = prev_slugs
    else slugs = slugsInCell(cell[1], rfam)

    if (slugs != "") {
        prev_slugs = slugs
        ns = split(slugs, sl, ",")
        nb = split(bes, bl, ",")
        for (i = 1; i <= ns; i++) for (j = 1; j <= nb; j++) addVerdict(rfam, bl[j], sl[i], verdict)
        seeded++
        next
    }
    if (idtable) {
        # Root-cause index rows (S1…) name their fixtures as <backend>/<slug>.
        rest = $0
        hit = 0
        while (match(rest, /(commonJS|erlang|beam|wasm)\/[a-z0-9_]+/)) {
            ref = substr(rest, RSTART, RLENGTH)
            rest = substr(rest, RSTART + RLENGTH)
            split(ref, rp, "/")
            if ((rfam SUBSEP rp[2]) in known) { addVerdict(rfam, rp[1], rp[2], verdict); hit = 1 }
        }
        if (hit) { seeded++; next }
    }
    unmatched++
    snippet = cell[1]
    gsub(/[\t`*]/, "", snippet)
    printf "%s:%d\t%s\t%s\n", rep, FNR, verdict, substr(snippet, 1, 160) >> unmatched_out
    next
}

END {
    rows = 0; untested = 0; orphans = 0; withverdict = 0
    for (x = 1; x <= nk; x++) {
        key = order[x]
        np = split(kpaths[key], paths, ",")
        tests = ""; orphan = 0; unscoped = 0
        for (i = 1; i <= np; i++) {
            p = paths[i]
            if (p in ptests) {
                nt = split(ptests[p], tl, ",")
                for (j = 1; j <= nt; j++) tests = addUnique(tests, tl[j])
            } else if (p in traced) unscoped = 1
            else orphan = 1
        }
        if (tests == "" && unscoped) {
            name = paths[1]
            sub(/^modules\/[^\/]+\/snapshots\//, "", name)
            sub(/\.snap\.md$/, "", name)
            if (name in litloc) tests = litloc[name]
            else if (kslug[key] in litloc) tests = litloc[kslug[key]]
        }
        if (tests == "") {
            tests = orphan ? "ORPHAN" : "?"
            untested++
            if (orphan) orphans++
        }
        fam = kfam[key]; slug = kslug[key]
        v = ""
        if ((fam SUBSEP kbe[key] SUBSEP slug) in verd) v = verd[fam SUBSEP kbe[key] SUBSEP slug]
        if (kbe[key] != "*" && (fam SUBSEP "*" SUBSEP slug) in verd) v = (v == "" ? "" : v " ; ") verd[fam SUBSEP "*" SUBSEP slug]
        if (v == "") v = "-"
        else withverdict++
        print ksuite[key], slug, tests, kpaths[key], v
        rows++
    }
    printf "rows %d · with a verdict %d · without a test file:line %d (orphans %d)\n", rows, withverdict, untested, orphans > "/dev/stderr"
    printf "reports %d · verdict rows mapped %d · verdict rows naming no snapshot %d\n", nreports, seeded, unmatched > "/dev/stderr"
    exit (untested > 0 ? 3 : 0)
}
AWK
        {
            printf 'suite\tslug\ttest\tpaths\tverdict\n'
            LC_ALL=C sort -t "$(printf '\t')" -k1,1 -k2,2 "$tmp_dir/rows"
        } > "$out"
        cat "$tmp_dir/summary"
        [ -n "$reports" ] || echo "note: no reports dir found — verdict column is unseeded (pass --reports=<dir>)"
        printf 'wrote %s\nwrote %s (report rows that name no snapshot on disk: renamed or deleted tests, tests without a snapshot, harness-level rows)\n' "$out" "$unmatched"
        exit "$status"
        ;;
esac
