----- SOURCE CODE -- std/path.bp
```botopink
//// std/path — pure-botopink path manipulation (posix forward-slash).
////
//// Reference:
////   Node.js  — https://nodejs.org/api/path.html
////   Erlang   — https://www.erlang.org/doc/apps/stdlib/filename.html
////
//// Lib-self-contained: every operation composes `String` methods (`split`,
//// `slice`, `length`, `startsWith`), so the module works on every backend
//// including wat. Forward-slash separator only — Windows backslash paths
//// are not normalised here (the spec keeps `path` posix-shaped; a
//// `path_win32` sibling can land later if a target needs it).

pub val separator: string = "/";

pub val delimiter: string = ":";

// Split a path into its non-empty components. Leading-`/` paths drop the
// empty head; trailing-`/` paths drop the empty tail. A path made of pure
// separators yields the empty array. Uses `filter` rather than
// `forEach` + `push`: a `var` + `push` pattern lowers to a dead-store
// (`out ++ [p]` discarded) on Erlang because the immutable runtime never
// rebinds `Out`; `filter` round-trips through `lists:filter/2` and
// `Array.prototype.filter` directly.
pub fn split(path: string) -> string[] {
    val raw = path.split(separator);
    return raw.filter({ p -> p != "" });
}

// True when `path` starts with `/` — the posix absolute-path marker.
pub fn isAbsolute(path: string) -> bool {
    return path.startsWith(separator);
}

// The last non-empty component of `path` (the file name, in the common
// case). Returns "" for the empty path and for pure-separator paths.
pub fn basename(path: string) -> string {
    val parts = split(path);
    val n = parts.length;
    if (n == 0) return "";
    return parts.at(n - 1) ?? "";
}

// Everything except the basename — the parent directory portion. For an
// absolute path this preserves the leading `/`. For a path with no
// separator (`"foo"`), returns `""`.
pub fn dirname(path: string) -> string {
    val parts = split(path);
    val n = parts.length;
    if (n <= 1) return if (isAbsolute(path)) separator else "";
    val head = parts.slice(0, n - 1);
    val joined = head.join(separator);
    // String `+` lowers to numeric `+` on Erlang (badarith on binaries);
    // use a 2-element array `.join("")` to concat instead — that goes
    // through `lists:join("", …)` + `iolist_to_binary` on Erlang and
    // `Array.prototype.join("")` on Node, both string-safe.
    return if (isAbsolute(path)) [separator, joined].join("") else joined;
}

// The trailing extension on the basename — the substring from the LAST
// `.` to the end, including the dot. Returns `""` when the basename has
// no extension (or is a dotfile with no further `.`s, e.g. `.bashrc`).
pub fn extname(path: string) -> string {
    val base = basename(path);
    val pieces = base.split(".");
    val n = pieces.length;
    if (n <= 1) return "";
    val head = pieces.at(0) ?? "";
    val tail = pieces.at(n - 1) ?? "";
    // Dotfiles like ".bashrc" split into ["", "bashrc"] — no extension.
    val isDotfile = head == "" && n == 2;
    return if (isDotfile) "" else [".", tail].join("");
}

// Join a list of path segments with the separator. Leading separator on
// the first segment is preserved; intra-segment slashes are normalised
// (`"foo/" + "/bar"` joins to `"foo/bar"`, never `"foo//bar"`). Uses
// `map` + `filter` + `join` rather than `fold` / `flatMap`: those land
// on `array<T>` default-fn bodies that lower to a `var` + `push` shape,
// which lowers to a dead store on Erlang's immutable runtime (the same
// trap `split` sidesteps).
pub fn join(parts: string[]) -> string {
    val isAbs = if (parts.length == 0) false else isAbsolute(parts.at(0) ?? "");
    val collapsed = parts.map({ p -> split(p).join(separator) });
    val joined = collapsed.filter({ p -> p != "" }).join(separator);
    return if (isAbs) [separator, joined].join("") else joined;
}

// Collapse `//` and drop `.` segments via a `filter` over the split
// pieces. Full `..` pop semantics are deferred: they need a stack-shaped
// accumulator and `var` reassignment, which lowers to a dead store on
// Erlang's immutable runtime (the same trap `split`/`join` sidestep with
// `filter`/`flatMap`).
pub fn normalize(path: string) -> string {
    if (path == "") return ".";
    val isAbs = isAbsolute(path);
    val pieces = split(path).filter({ p -> p != "." });
    val joined = pieces.join(separator);
    return if (isAbs)
        [separator, joined].join("")
    else if (joined == "")
        "."
    else
        joined;
}

// Internal: count how many leading components two split paths share. Tail-
// recursive on `i` so the accumulator never needs a `var` rebind (which
// lowers to a dead store on Erlang's immutable runtime).
fn commonPrefixCount(a: string[], b: string[], i: i32) -> i32 {
    if (i >= a.length) return i;
    if (i >= b.length) return i;
    val ai = a.at(i) ?? "";
    val bi = b.at(i) ?? "";
    return if (ai == bi) commonPrefixCount(a, b, i + 1) else i;
}

// Internal: build an array of `n` ".." strings via head/tail recursion.
// Avoids a `var` + `push` accumulator (the Erlang dead-store trap).
fn makeUps(n: i32) -> string[] {
    return if (n <= 0) [] else makeUps(n - 1).prepend("..");
}

// The relative path from `src` to `dst` — the path you would prefix to
// `src` to reach `dst`. Both inputs are treated structurally (no `cwd()`
// fallback — that belongs in `process` once it lands). Returns "." when
// the paths point at the same location.
//
// `src` is named `src` rather than `from` because `from` is a reserved
// keyword (the `import { … } from "<lib>"` syntax) — it does not parse
// as a parameter name.
pub fn relative(src: string, dst: string) -> string {
    val srcParts = split(src);
    val dstParts = split(dst);
    val common = commonPrefixCount(srcParts, dstParts, 0);
    val ups = makeUps(srcParts.length - common);
    val downs = dstParts.slice(common, dstParts.length);
    val combined = ups.append(downs);
    val joined = combined.join(separator);
    return if (joined == "") "." else joined;
}

// Internal accumulator for `resolve`: a list of normalised path parts
// plus whether the resolved-so-far path is absolute. The record carries
// the state through the tail-recursive `resolveAll` so no `var` is
// needed.
type PathAccum(
    isAbs: bool,
    parts: string[],
)

// Internal: apply each component of one segment (post-split) to the
// accumulator, popping for `..` and appending the rest. Head/tail
// recursive — no `var` rebinds.
fn applyPieces(acc: string[], pieces: string[]) -> string[] {
    if (pieces.length == 0) return acc;
    val p = pieces.at(0) ?? "";
    val rest = pieces.slice(1, pieces.length);
    val nextAcc = if (p == "..") {
        if (acc.length == 0) acc else acc.slice(0, acc.length - 1);
    } else acc.append([p]);
    return applyPieces(nextAcc, rest);
}

fn resolveStep(state: PathAccum, seg: string) -> PathAccum {
    val pieces = split(seg);
    val nextIsAbs = isAbsolute(seg) || state.isAbs;
    val baseParts = if (isAbsolute(seg)) [] else state.parts;
    return PathAccum(isAbs: nextIsAbs, parts: applyPieces(baseParts, pieces));
}

fn resolveAll(segments: string[], i: i32, state: PathAccum) -> PathAccum {
    if (i >= segments.length) return state;
    val seg = segments.at(i) ?? "";
    val next = resolveStep(state, seg);
    return resolveAll(segments, i + 1, next);
}

// Resolve a list of path segments into a single normalised path.
// Absolute segments restart the accumulator (matches Node's
// `path.resolve`); `..` pops one component; `.` drops out (already
// filtered by `split`). The empty input resolves to ".".
pub fn resolve(segments: string[]) -> string {
    val finalState = resolveAll(
        segments,
        0,
        PathAccum(isAbs: false, parts: []),
    );
    val joined = finalState.parts.join(separator);
    return if (finalState.isAbs)
        [separator, joined].join("")
    else if (joined == "")
        "."
    else
        joined;
}

// ── 1.0.10-beta front 01 additions ───────────────────────────────────────────

// `p` without its trailing extension: `page.bp` → `page`, `archive.tar.gz`
// → `archive.tar`, `noext` → `noext`. The extension is what `extname`
// answers, so a dotfile keeps its name.
pub fn withoutExtension(p: string) -> string {
    val ext = extname(p);
    val n = p.length;
    val stem = if (ext == "") p else p.slice(0, n - ext.length);
    return stem;
}

// True when `child` resolves inside `parent` — the traversal guard front 22
// applies before it turns a request path into a file path. Both sides go
// through `resolve`, which pops `..` (`normalize` does not), and a relative
// `child` is resolved against `parent`, so `isInside("/app", "blog/x")` is
// true and `isInside("/app", "blog/../../etc")` is false. A parent is inside
// itself. The check reads the first component of the relative path: `..`
// exactly, or `../…` — a component that merely starts with two dots
// (`..foo`) is a name, not an escape.
pub fn isInside(parent: string, child: string) -> bool {
    val up = resolve([parent]);
    val down = resolve([parent, child]);
    val rel = relative(up, down);
    val escapes = rel == ".." || rel.startsWith("../");
    return escapes == false;
}

// ── tests ────────────────────────────────────────────────────────────────────

test "path.separator is forward slash" {
    assert separator == "/";
}

test "path.isAbsolute distinguishes leading slash" {
    assert isAbsolute("/usr/bin");
    assert isAbsolute("foo/bar").negate();
}

test "path.split drops empties" {
    val s = split("/usr//bin/");
    assert s.length == 2;
    assert s.at(0) ?? "" == "usr";
    assert s.at(1) ?? "" == "bin";
}

test "path.basename returns the last component" {
    assert basename("/usr/bin/zig") == "zig";
    assert basename("foo") == "foo";
    assert basename("") == "";
}

test "path.dirname returns the parent" {
    assert dirname("/usr/bin/zig") == "/usr/bin";
    assert dirname("foo/bar") == "foo";
    assert dirname("foo") == "";
    assert dirname("/foo") == "/";
}

test "path.extname returns the trailing suffix" {
    assert extname("file.txt") == ".txt";
    assert extname("archive.tar.gz") == ".gz";
    assert extname("README") == "";
    assert extname(".bashrc") == "";
}

test "path.join concatenates with separator" {
    assert join(["foo", "bar", "baz"]) == "foo/bar/baz";
    assert join(["/foo", "bar"]) == "/foo/bar";
    assert join(["foo/", "/bar"]) == "foo/bar";
}

test "path.normalize collapses doubles" {
    assert normalize("/foo//bar") == "/foo/bar";
    assert normalize("foo/./bar") == "foo/bar";
}

test "path.normalize on empty is dot" {
    assert normalize("") == ".";
}

test "path.relative same dir" {
    assert relative("/a/b/c", "/a/b/c") == ".";
}

test "path.relative up one" {
    assert relative("/a/b/c", "/a/b") == "..";
}

test "path.resolve absolute" {
    assert resolve(["/a", "b", "c"]) == "/a/b/c";
}

test "path.resolve with double-dot" {
    assert resolve(["/a", "b", "..", "c"]) == "/a/c";
}

test "path.withoutExtension strips the trailing extension only" {
    assert withoutExtension("page.bp") == "page";
    assert withoutExtension("archive.tar.gz") == "archive.tar";
    assert withoutExtension("noext") == "noext";
    assert withoutExtension(".bashrc") == ".bashrc";
    assert withoutExtension("app/blog/page.bp") == "app/blog/page";
}

test "path.isInside accepts a descendant and the parent itself" {
    assert isInside("/app", "/app/blog/page.bp");
    assert isInside("/app", "blog/page.bp");
    assert isInside("/app", "/app");
}

test "path.isInside rejects a path that escapes the parent" {
    assert isInside("/app", "/app/../etc/passwd").negate();
    assert isInside("/app", "/app/blog/../../etc").negate();
    assert isInside("/app", "/application/x").negate();
    assert isInside("/app", "/etc").negate();
}

test "path.isInside treats a name starting with two dots as a name" {
    assert isInside("/app", "/app/..hidden/x");
}

```

----- BEAM ASSEMBLY -- std/path.S
```erlang
{module, std@path}.
{exports, [{separator, 0}, {delimiter, 0}, {split, 1}, {isAbsolute, 1}, {basename, 1}, {dirname, 1}, {extname, 1}, {join, 1}, {normalize, 1}, {relative, 2}, {resolve, 1}, {withoutExtension, 1}, {isInside, 2}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__string_slice', 3}, {'__bp_priv__applyPieces', 2}, {'__bp_priv__commonPrefixCount', 3}, {'__bp_priv__makeUps', 1}, {'__bp_priv__resolveAll', 3}, {'__bp_priv__resolveStep', 2}]}.
{attributes, []}.
{labels, 284}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "std@path.erl", 1}]}.
    {func_info, {atom, std@path}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 42}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 43}}.
  {label, 42}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 45}}.
  {label, 44}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 47}}.
  {label, 45}.
  {label, 43}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "std@path.erl", 2}]}.
    {func_info, {atom, std@path}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 48}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 49}}.
  {label, 48}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 47}}.
    {jump, {f, 51}}.
  {label, 50}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 47}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 47}}.
  {label, 51}.
  {label, 49}.
    {deallocate, 6}.
    return.
%%% std/path — pure-botopink path manipulation (posix forward-slash).
%%% 
%%% Reference:
%%%   Node.js  — https://nodejs.org/api/path.html
%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/filename.html
%%% 
%%% Lib-self-contained: every operation composes `String` methods (`split`,
%%% `slice`, `length`, `startsWith`), so the module works on every backend
%%% including wat. Forward-slash separator only — Windows backslash paths
%%% are not normalised here (the spec keeps `path` posix-shaped; a
%%% `path_win32` sibling can land later if a target needs it).

{function, separator, 0, 7}.
  {label, 6}.
    {line, [{location, "std@path.erl", 3}]}.
    {func_info, {atom, std@path}, {atom, separator}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, delimiter, 0, 9}.
  {label, 8}.
    {line, [{location, "std@path.erl", 4}]}.
    {func_info, {atom, std@path}, {atom, delimiter}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<":">>}, {x, 0}}.
    {deallocate, 0}.
    return.
% Split a path into its non-empty components. Leading-`/` paths drop the
% empty head; trailing-`/` paths drop the empty tail. A path made of pure
% separators yields the empty array. Uses `filter` rather than
% `forEach` + `push`: a `var` + `push` pattern lowers to a dead-store
% (`out ++ [p]` discarded) on Erlang because the immutable runtime never
% rebinds `Out`; `filter` round-trips through `lists:filter/2` and
% `Array.prototype.filter` directly.

{function, split, 1, 11}.
  {label, 10}.
    {line, [{location, "std@path.erl", 5}]}.
    {func_info, {atom, std@path}, {atom, split}, 1}.
  {label, 11}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 53}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 70}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 4}.
% True when `path` starts with `/` — the posix absolute-path marker.

{function, isAbsolute, 1, 13}.
  {label, 12}.
    {line, [{location, "std@path.erl", 6}]}.
    {func_info, {atom, std@path}, {atom, isAbsolute}, 1}.
  {label, 13}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 73}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 74}}.
  {label, 73}.
    {move, {atom, true}, {x, 0}}.
  {label, 74}.
    {deallocate, 3}.
    return.
% The last non-empty component of `path` (the file name, in the common
% case). Returns "" for the empty path and for pure-separator paths.

{function, basename, 1, 15}.
  {label, 14}.
    {line, [{location, "std@path.erl", 7}]}.
    {func_info, {atom, std@path}, {atom, basename}, 1}.
  {label, 15}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_eq_exact, {f, 75}, [{y, 2}, {integer, 0}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 75}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 77}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 77}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:40:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 78}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 76}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 76}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 83}.
    {deallocate, 4}.
    return.
% Everything except the basename — the parent directory portion. For an
% absolute path this preserves the leading `/`. For a path with no
% separator (`"foo"`), returns `""`.

{function, dirname, 1, 17}.
  {label, 16}.
    {line, [{location, "std@path.erl", 8}]}.
    {func_info, {atom, std@path}, {atom, dirname}, 1}.
  {label, 17}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_ge, {f, 84}, [{integer, 1}, {y, 2}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 13}}.
    {test, is_eq, {f, 85}, [{x, 0}, {atom, true}]}.
    {call, 0, {f, 7}}.
    {jump, {f, 86}}.
  {label, 85}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 86}.
    {deallocate, 10}.
    return.
  {label, 84}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 87}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 87}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 88}}.
  {label, 87}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:50:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 88}.
    {test, is_ne_exact, {f, 89}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 0}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {integer, 0}], {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 90}}.
  {label, 89}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 90}.
    {move, {x, 0}, {y, 3}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call, 2, {f, 92}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 13}}.
    {test, is_eq, {f, 125}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {call, 0, {f, 7}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 92}}.
    {jump, {f, 126}}.
  {label, 125}.
    {move, {y, 4}, {x, 0}}.
  {label, 126}.
    {deallocate, 10}.
    return.
% The trailing extension on the basename — the substring from the LAST
% `.` to the end, including the dot. Returns `""` when the basename has
% no extension (or is a dotfile with no further `.`s, e.g. `.bashrc`).

{function, extname, 1, 19}.
  {label, 18}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, extname}, 1}.
  {label, 19}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 15}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<".">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 53}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_ge, {f, 127}, [{integer, 1}, {y, 3}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 127}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 128}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 129}}.
  {label, 128}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 129}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 131}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 131}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 132}}.
  {label, 131}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:68:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 132}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 130}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 133}}.
  {label, 130}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 133}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 134}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 135}}.
  {label, 134}.
    {move, {atom, false}, {x, 0}}.
  {label, 135}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 136}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 138}, [{y, 3}, {integer, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 139}}.
  {label, 138}.
    {move, {atom, false}, {x, 0}}.
  {label, 139}.
    {jump, {f, 137}}.
  {label, 136}.
    {move, {atom, false}, {x, 0}}.
  {label, 137}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq, {f, 140}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 141}}.
  {label, 140}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, <<".">>}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 92}}.
  {label, 141}.
    {deallocate, 10}.
    return.
% Join a list of path segments with the separator. Leading separator on
% the first segment is preserved; intra-segment slashes are normalised
% (`"foo/" + "/bar"` joins to `"foo/bar"`, never `"foo//bar"`). Uses
% `map` + `filter` + `join` rather than `fold` / `flatMap`: those land
% on `array<T>` default-fn bodies that lower to a `var` + `push` shape,
% which lowers to a dead store on Erlang's immutable runtime (the same
% trap `split` sidesteps).

{function, join, 1, 21}.
  {label, 20}.
    {line, [{location, "std@path.erl", 10}]}.
    {func_info, {atom, std@path}, {atom, join}, 1}.
  {label, 21}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 142}, [{x, 0}, {integer, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 143}}.
  {label, 142}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 144}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 145}}.
  {label, 144}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 145}.
    {call, 1, {f, 13}}.
  {label, 143}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 147}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 149}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {move, {x, 0}, {y, 4}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call, 2, {f, 92}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 152}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {call, 0, {f, 7}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 92}}.
    {jump, {f, 153}}.
  {label, 152}.
    {move, {y, 5}, {x, 0}}.
  {label, 153}.
    {deallocate, 10}.
    return.
% Collapse `//` and drop `.` segments via a `filter` over the split
% pieces. Full `..` pop semantics are deferred: they need a stack-shaped
% accumulator and `var` reassignment, which lowers to a dead store on
% Erlang's immutable runtime (the same trap `split`/`join` sidestep with
% `filter`/`flatMap`).

{function, normalize, 1, 23}.
  {label, 22}.
    {line, [{location, "std@path.erl", 11}]}.
    {func_info, {atom, std@path}, {atom, normalize}, 1}.
  {label, 23}.
    {allocate, 11, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 154}, [{y, 0}, {x, 0}]}.
    {move, {literal, <<".">>}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 154}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 156}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {move, {x, 0}, {y, 2}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 92}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 159}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {call, 0, {f, 7}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 92}}.
    {jump, {f, 160}}.
  {label, 159}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 161}, [{y, 3}, {x, 0}]}.
    {move, {literal, <<".">>}, {x, 0}}.
    {jump, {f, 162}}.
  {label, 161}.
    {move, {y, 3}, {x, 0}}.
  {label, 162}.
  {label, 160}.
    {deallocate, 11}.
    return.
% Internal: count how many leading components two split paths share. Tail-
% recursive on `i` so the accumulator never needs a `var` rebind (which
% lowers to a dead store on Erlang's immutable runtime).

{function, commonPrefixCount, 3, 25}.
  {label, 24}.
    {line, [{location, "std@path.erl", 12}]}.
    {func_info, {atom, std@path}, {atom, commonPrefixCount}, 3}.
  {label, 25}.
    {allocate, 7, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ge, {f, 163}, [{y, 2}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 163}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ge, {f, 164}, [{y, 2}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 164}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 165}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 166}}.
  {label, 165}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 166}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 167}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 168}}.
  {label, 167}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 168}.
    {move, {x, 0}, {y, 6}}.
    {test, is_eq_exact, {f, 169}, [{y, 4}, {y, 6}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 171}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 171}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 172}}.
  {label, 171}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/path.bp:114:52">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 172}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 25}}.
    {jump, {f, 170}}.
  {label, 169}.
    {move, {y, 2}, {x, 0}}.
  {label, 170}.
    {deallocate, 7}.
    return.
% Internal: build an array of `n` ".." strings via head/tail recursion.
% Avoids a `var` + `push` accumulator (the Erlang dead-store trap).

{function, makeUps, 1, 27}.
  {label, 26}.
    {line, [{location, "std@path.erl", 13}]}.
    {func_info, {atom, std@path}, {atom, makeUps}, 1}.
  {label, 27}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_ge, {f, 173}, [{integer, 0}, {y, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 174}}.
  {label, 173}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 175}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 175}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 176}}.
  {label, 175}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:120:42">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 176}.
    {call, 1, {f, 27}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"..">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 174}.
    {deallocate, 3}.
    return.
% The relative path from `src` to `dst` — the path you would prefix to
% `src` to reach `dst`. Both inputs are treated structurally (no `cwd()`
% fallback — that belongs in `process` once it lands). Returns "." when
% the paths point at the same location.
% 
% `src` is named `src` rather than `from` because `from` is a reserved
% keyword (the `import { … } from "<lib>"` syntax) — it does not parse
% as a parameter name.

{function, relative, 2, 29}.
  {label, 28}.
    {line, [{location, "std@path.erl", 14}]}.
    {func_info, {atom, std@path}, {atom, relative}, 2}.
  {label, 29}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 2}}.
    {move, {y, 3}, {x, 1}}.
    {call, 3, {f, 25}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 4}], {x, 0}}.
    {test, is_ge, {f, 177}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 177}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 178}}.
  {label, 177}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:135:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 178}.
    {call, 1, {f, 27}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 179}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{y, 4}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {y, 4}], {x, 2}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 180}}.
  {label, 179}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 180}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 7}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {call, 2, {f, 92}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 181}, [{y, 8}, {x, 0}]}.
    {move, {literal, <<".">>}, {x, 0}}.
    {jump, {f, 182}}.
  {label, 181}.
    {move, {y, 8}, {x, 0}}.
  {label, 182}.
    {deallocate, 11}.
    return.
% Internal accumulator for `resolve`: a list of normalised path parts
% plus whether the resolved-so-far path is absolute. The record carries
% the state through the tail-recursive `resolveAll` so no `var` is
% needed.
% Internal: apply each component of one segment (post-split) to the
% accumulator, popping for `..` and appending the rest. Head/tail
% recursive — no `var` rebinds.

{function, applyPieces, 2, 31}.
  {label, 30}.
    {line, [{location, "std@path.erl", 15}]}.
    {func_info, {atom, std@path}, {atom, applyPieces}, 2}.
  {label, 31}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 183}, [{x, 0}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 183}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 184}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 185}}.
  {label, 184}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 185}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 186}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 1}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {integer, 1}], {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 187}}.
  {label, 186}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 187}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"..">>}, {x, 0}}.
    {test, is_eq_exact, {f, 188}, [{y, 3}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 190}, [{x, 0}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 191}}.
  {label, 190}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 192}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 192}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 193}}.
  {label, 192}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:159:63">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 193}.
    {test, is_ne_exact, {f, 194}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 0}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {integer, 0}], {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 195}}.
  {label, 194}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 195}.
  {label, 191}.
    {jump, {f, 189}}.
  {label, 188}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
  {label, 189}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_last, 2, {f, 31}, 7}.

{function, resolveStep, 2, 33}.
  {label, 32}.
    {line, [{location, "std@path.erl", 16}]}.
    {func_info, {atom, std@path}, {atom, resolveStep}, 2}.
  {label, 33}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 196}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 198}, [{x, 0}, 3, {atom, std@path@@PathAccum}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 198}.
    {jump, {f, 197}}.
  {label, 196}.
    {move, {atom, true}, {x, 0}}.
  {label, 197}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 13}}.
    {test, is_eq, {f, 199}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 200}}.
  {label, 199}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 201}, [{x, 0}, 3, {atom, std@path@@PathAccum}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 201}.
  {label, 200}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 31}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@path@@PathAccum}, {y, 3}, {x, 0}]}}.
    {deallocate, 7}.
    return.

{function, resolveAll, 3, 35}.
  {label, 34}.
    {line, [{location, "std@path.erl", 17}]}.
    {func_info, {atom, std@path}, {atom, resolveAll}, 3}.
  {label, 35}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ge, {f, 202}, [{y, 1}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 202}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 203}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 204}}.
  {label, 203}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 204}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 33}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 205}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 205}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 206}}.
  {label, 205}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/path.bp:175:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 206}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 35}, 6}.
% Resolve a list of path segments into a single normalised path.
% Absolute segments restart the accumulator (matches Node's
% `path.resolve`); `..` pops one component; `.` drops out (already
% filtered by `split`). The empty input resolves to ".".

{function, resolve, 1, 37}.
  {label, 36}.
    {line, [{location, "std@path.erl", 18}]}.
    {func_info, {atom, std@path}, {atom, resolve}, 1}.
  {label, 37}.
    {allocate, 11, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@path@@PathAccum}, {x, 1}, {x, 0}]}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 35}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 207}, [{x, 0}, 3, {atom, std@path@@PathAccum}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 207}.
    {move, {x, 0}, {y, 2}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 92}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 209}, [{x, 0}, 3, {atom, std@path@@PathAccum}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 209}.
    {test, is_eq, {f, 208}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {call, 0, {f, 7}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 92}}.
    {jump, {f, 210}}.
  {label, 208}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 211}, [{y, 3}, {x, 0}]}.
    {move, {literal, <<".">>}, {x, 0}}.
    {jump, {f, 212}}.
  {label, 211}.
    {move, {y, 3}, {x, 0}}.
  {label, 212}.
  {label, 210}.
    {deallocate, 11}.
    return.
% ── 1.0.10-beta front 01 additions ───────────────────────────────────────────
% `p` without its trailing extension: `page.bp` → `page`, `archive.tar.gz`
% → `archive.tar`, `noext` → `noext`. The extension is what `extname`
% answers, so a dotfile keeps its name.

{function, withoutExtension, 1, 39}.
  {label, 38}.
    {line, [{location, "std@path.erl", 19}]}.
    {func_info, {atom, std@path}, {atom, withoutExtension}, 1}.
  {label, 39}.
    {allocate, 9, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 213}, [{y, 1}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 214}}.
  {label, 213}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 217}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 217}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 218}}.
  {label, 217}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:205:51">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 218}.
    {move, {integer, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 216}}.
  {label, 214}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 9}.
    return.
% True when `child` resolves inside `parent` — the traversal guard front 22
% applies before it turns a request path into a file path. Both sides go
% through `resolve`, which pops `..` (`normalize` does not), and a relative
% `child` is resolved against `parent`, so `isInside("/app", "blog/x")` is
% true and `isInside("/app", "blog/../../etc")` is false. A parent is inside
% itself. The check reads the first component of the relative path: `..`
% exactly, or `../…` — a component that merely starts with two dots
% (`..foo`) is a name, not an escape.

{function, isInside, 2, 41}.
  {label, 40}.
    {line, [{location, "std@path.erl", 20}]}.
    {func_info, {atom, std@path}, {atom, isInside}, 2}.
  {label, 41}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 37}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 37}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 29}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"..">>}, {x, 0}}.
    {test, is_eq_exact, {f, 219}, [{y, 6}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 220}}.
  {label, 219}.
    {move, {atom, false}, {x, 0}}.
  {label, 220}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 221}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"../">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 223}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 224}}.
  {label, 223}.
    {move, {atom, true}, {x, 0}}.
  {label, 224}.
    {jump, {f, 222}}.
  {label, 221}.
    {move, {atom, true}, {x, 0}}.
  {label, 222}.
    {move, {x, 0}, {y, 7}}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 225}, [{y, 7}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 226}}.
  {label, 225}.
    {move, {atom, false}, {x, 0}}.
  {label, 226}.
    {deallocate, 10}.
    return.
% ── tests ────────────────────────────────────────────────────────────────────

{function, 'string_slice', 3, 216}.
  {label, 215}.
    {line, [{location, "std@path.erl", 21}]}.
    {func_info, {atom, std@path}, {atom, 'string_slice'}, 3}.
  {label, 216}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 227}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 229}, 3}.
  {label, 227}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 251}, 3}.

{function, '__bp_priv__array_range', 2, 269}.
  {label, 268}.
    {line, [{location, "std@path.erl", 23}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 269}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 271}.
  {label, 270}.
    {line, [{location, "std@path.erl", 24}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 271}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__string_slice', 3, 273}.
  {label, 272}.
    {line, [{location, "std@path.erl", 25}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 273}.
    {call_only, 3, {f, 216}}.

{function, '__bp_priv__applyPieces', 2, 275}.
  {label, 274}.
    {line, [{location, "std@path.erl", 26}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__applyPieces'}, 2}.
  {label, 275}.
    {call_only, 2, {f, 31}}.

{function, '__bp_priv__commonPrefixCount', 3, 277}.
  {label, 276}.
    {line, [{location, "std@path.erl", 27}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__commonPrefixCount'}, 3}.
  {label, 277}.
    {call_only, 3, {f, 25}}.

{function, '__bp_priv__makeUps', 1, 279}.
  {label, 278}.
    {line, [{location, "std@path.erl", 28}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__makeUps'}, 1}.
  {label, 279}.
    {call_only, 1, {f, 27}}.

{function, '__bp_priv__resolveAll', 3, 281}.
  {label, 280}.
    {line, [{location, "std@path.erl", 29}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__resolveAll'}, 3}.
  {label, 281}.
    {call_only, 3, {f, 35}}.

{function, '__bp_priv__resolveStep', 2, 283}.
  {label, 282}.
    {line, [{location, "std@path.erl", 30}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__resolveStep'}, 2}.
  {label, 283}.
    {call_only, 2, {f, 33}}.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 57}.
  {label, 56}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 57}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 59}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 61}, [{x, 0}]}.
    {jump, {f, 62}}.
  {label, 61}.
    {test, is_tuple, {f, 63}, [{x, 0}]}.
    {test, test_arity, {f, 63}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 62}}.
  {label, 63}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 62}.
    {move, {x, 0}, {y, 4}}.
  {label, 64}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 65}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 67}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 67}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 68}}.
  {label, 67}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 68}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 64}}.
  {label, 65}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 66}, [{x, 0}]}.
    {jump, {f, 60}}.
  {label, 66}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 60}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 59}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_0', 2, 53}.
  {label, 52}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_0'}, 2}.
  {label, 53}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 57}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-split/1-fun-0-', 1, 70}.
  {label, 69}.
    {line, [{location, "std@path.erl", 6}]}.
    {func_info, {atom, std@path}, {atom, '-split/1-fun-0-'}, 1}.
  {label, 70}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 71}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 72}}.
  {label, 71}.
    {move, {atom, false}, {x, 0}}.
  {label, 72}.
    {deallocate, 1}.
    return.

{function, '-bp_at-', 2, 80}.
  {label, 79}.
    {line, [{location, "std@path.erl", 8}]}.
    {func_info, {atom, std@path}, {atom, '-bp_at-'}, 2}.
  {label, 80}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 82}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 81}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 82}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 81}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 81}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 94}.
  {label, 93}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '__bp_print'}, 1}.
  {label, 94}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 98}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 98}.
  {label, 97}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '-bp_show_top-'}, 1}.
  {label, 98}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 96}}.

{function, '-bp_show_elem-', 1, 100}.
  {label, 99}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '-bp_show_elem-'}, 1}.
  {label, 100}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 96}}.

{function, '__bp_show', 2, 96}.
  {label, 95}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '__bp_show'}, 2}.
  {label, 96}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 108}, [{x, 0}]}.
    {test, is_eq, {f, 107}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 107}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 108}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 109}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 100}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 109}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 111}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 110}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 110}, [{x, 0}]}.
    {test, is_ne_exact, {f, 110}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 110}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 110}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 115}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 116}}.
  {label, 115}.
    {test, is_eq_exact, {f, 112}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 116}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 96}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 110}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 100}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 111}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 113}, [{x, 0}]}.
    {test, is_ne_exact, {f, 113}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 113}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 114}, [{x, 0}, {atom, undefined}]}.
  {label, 112}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 102}, 2}.
  {label, 113}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 114}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 102}.
  {label, 101}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '__bp_tagged'}, 2}.
  {label, 102}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 117}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 117}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 117}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 118}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 104}, 3}.
  {label, 118}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 104}.
  {label, 103}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '__bp_render'}, 1}.
  {label, 104}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 119}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 119}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 120}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 120}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 106}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 106}.
  {label, 105}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '-bp_render_pair-'}, 1}.
  {label, 106}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 96}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 122}.
  {label, 121}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '-bp_stringify-'}, 1}.
  {label, 122}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 123}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 123}.
    {test, is_integer, {f, 124}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 124}.
    {call, 1, {f, 98}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-bp_join-', 2, 92}.
  {label, 91}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '-bp_join-'}, 2}.
  {label, 92}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 122}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '-join/1-fun-1-', 1, 147}.
  {label, 146}.
    {line, [{location, "std@path.erl", 11}]}.
    {func_info, {atom, std@path}, {atom, '-join/1-fun-1-'}, 1}.
  {label, 147}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {y, 1}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 92}}.
    {deallocate, 3}.
    return.

{function, '-join/1-fun-2-', 1, 149}.
  {label, 148}.
    {line, [{location, "std@path.erl", 11}]}.
    {func_info, {atom, std@path}, {atom, '-join/1-fun-2-'}, 1}.
  {label, 149}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 150}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 151}}.
  {label, 150}.
    {move, {atom, false}, {x, 0}}.
  {label, 151}.
    {deallocate, 1}.
    return.

{function, '-normalize/1-fun-3-', 1, 156}.
  {label, 155}.
    {line, [{location, "std@path.erl", 12}]}.
    {func_info, {atom, std@path}, {atom, '-normalize/1-fun-3-'}, 1}.
  {label, 156}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<".">>}, {x, 0}}.
    {test, is_ne_exact, {f, 157}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 158}}.
  {label, 157}.
    {move, {atom, false}, {x, 0}}.
  {label, 158}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_1-t/3-fun-0-', 3, 233}.
  {label, 232}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_1-t/3-fun-0-'}, 3}.
  {label, 233}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 237}}.
  {label, 237}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 239}}.
  {label, 239}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 241}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 240}}.
  {label, 241}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 242}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 240}}.
  {label, 242}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 240}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 244}}.
  {label, 244}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 246}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 245}}.
  {label, 246}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 247}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 245}}.
  {label, 247}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 245}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 249}}.
  {label, 249}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 9}.

{function, '__bp_tpl_1', 3, 229}.
  {label, 228}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_1'}, 3}.
  {label, 229}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 233}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_2-t/2-fun-0-', 2, 255}.
  {label, 254}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_2-t/2-fun-0-'}, 2}.
  {label, 255}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 259}}.
  {label, 259}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 261}}.
  {label, 261}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 263}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 262}}.
  {label, 263}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 264}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 262}}.
  {label, 264}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 262}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 266}}.
  {label, 266}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_2', 2, 251}.
  {label, 250}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_2'}, 2}.
  {label, 251}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 255}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_prim_append', 2, 47}.
  {label, 46}.
    {line, [{location, "std@path.erl", 22}]}.
    {func_info, {atom, std@path}, {atom, '__bp_prim_append'}, 2}.
  {label, 47}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 267}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 267}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@path@@PathAccum.S
```erlang
{module, std@path@@PathAccum}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@path@@PathAccum.erl", 15}]}.
    {func_info, {atom, std@path@@PathAccum}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, isAbs}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, parts}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 7}.
  {label, 6}.
    {line, [{location, "std@path@@PathAccum.erl", 15}]}.
    {func_info, {atom, std@path@@PathAccum}, {atom, '__bp_format'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"parts">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"isAbs">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"PathAccum">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- std/failure.bp
```botopink
//// std/failure — the two records a failure that is not a typed error carries
//// (decisions 431, 492).
////
//// `HostError` is what a host binding that writes `result: true` answers on
//// the `Error` side: the host's message and `kind`, always `"host"`.
//// `Failure` is what `attempt` answers on the `Error` side: `kind` is `panic`
//// (`panic`, `@todo`, `x!`, an overflow, a division by zero), `host` (a raise
//// from a binding without `result: true`) or `crash` (a VM or emitted-code
//// fault, a wasm trap).
////
//// `attempt(f)` runs `f` and answers `Ok` of its value, or `Error(Failure)`
//// for a raise it caught — the one way to contain a crash (decision 431 (3)).
//// `attemptTask(f)` is its `Async` form (decision 494): the task `f` answers,
//// awaited, or the `Failure` it crashed with — a `Async<Result<…>>` read
//// back by `await` like any failing task (decision 432). The kinds
//// (decision 492): a `panic` / `@todo` (and so `x!`), a failed `assert`
//// and an integer overflow or division by zero are `panic`, their message
//// the text the program wrote. A raise of a binding declared outside std without
//// `result: true` is `host` (decision 546), its message the host's text — on
//// commonJS an `Error`'s `message`, else `String(e)`, the call run through
//// `__bp_host_mark`, which marks it `__bp_host`; any raise nothing marked is
//// `crash`, its message the same text. On erlang and beam a
//// host raise is the raise of a binding declared outside std without `result:
//// true` — a library's or the program's, whose calls are wrapped to mark it
//// (decision 546) — its message the reason by `~tp` (decision 489's reading);
//// a raise nothing marked, a failing match or a std binding's, is `crash`,
//// its message the reason by `~tp` too.
////
//// Both are bodyless: each backend wraps the call (a JavaScript `try` /
//// rejection handler, an erlang `try … catch`; beam compiles the erlang
//// form). On wasm (decision 518) each is a private body over `caught`, the
//// `wasi: .Attempt` adapter: the thunk runs inside a `try_table` that
//// catches the program's aborts (wasm exception handling), so the binding
//// declares `needs: [.Exceptions]` and a program reaching it runs with the
//// host's exceptions on (`-W exceptions=y` on wasmtime). On wasm an abort
//// is `panic`; a trap (an overflow or a division by zero there, a host
//// fault) is no exception and is not caught. `attemptTask` contains what
//// the thunk raises before the task's first `await`.

import {compiler};

pub type HostErrorName {
    Error,
    Throw,
    Exit,
}

pub type HostError(message: string, kind: string, name: HostErrorName, detail: ?string)

pub type Failure(message: string, kind: string)

// Decision 606 (2) — the abort `attempt` catches as a `panic` `Failure`: the program stops
// with `panic: <message>` (decision 535) unless an `attempt` above it answers the `Failure`.
// Imported where it is used, `import {failure.panic} from "std";` (`import {failure.panic};`
// inside std); `panic("not implemented")` is what `todo` was.
#[compiler.external(
    .Erlang("erlang:error({panic, $0})"),
    .JavaScript("(() => { throw Object.defineProperty(new Error($0), '__bp_panic', { value: true }) })()"),
)]
pub declare fn panic(message: string = "panic") -> noreturn;

// The Node forms read an abort by the `__bp_panic` mark the backend puts on
// every one it raises — `panic`, `@todo`, an integer overflow or division
// by zero, a failed `assert` (whose mark carries its message) — or a test
// body's `assert` (`__bp_assert_loc`); the Erlang forms by the reasons the
// backends raise for them (`{panic, M}`, `{todo, M}`, `{integer_overflow,
// M}`, `{bp_assert, M, Where}`). `attemptTask` answers a failing task
// (decision 432): marked `__bp_fails`, resolved with the value, rejected with
// the `Failure` (`__bp_failure`); a failing task `f` answers is read as
// `await` reads it.
#[compiler.external(
    .JavaScript("""((__f, __k) => { try { return { ok: __f() }; } catch (__e) { return { error: __k(__e) }; } })($0, ((__e) => (__e != null && __e.__bp_panic != null) ? new Failure(typeof __e.__bp_panic === "string" ? __e.__bp_panic : __e.message, "panic") : (__e != null && typeof __e.__bp_assert_loc === "string") ? new Failure(__e.message, "panic") : new Failure((__e instanceof Error) ? __e.message : String(__e), (__e != null && __e.__bp_host === true) ? "host" : "crash")))"""),
    .Erlang("""(fun(__F) -> try {ok, __F()} catch error:{__T, __M} when (__T =:= panic orelse __T =:= todo orelse __T =:= integer_overflow) andalso (is_binary(__M) orelse is_list(__M)) -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, _, _, __M} -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, __M, _} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"panic">>}}; error:{bp_host, __M} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"host">>}}; _:__R -> {error, {'std@failure@@Failure', unicode:characters_to_binary(io_lib:format("~tp", [__R])), <<"crash">>}} end end)($0)"""),
    .Wasm(body: attemptOnWasm),
)]
pub declare fn attempt<T>(f: fn() -> T) -> Result<T, Failure>;

#[compiler.external(
    .JavaScript("""((__f, __k) => { const __t = (async () => { const __x = __f(); return (__x != null && __x.__bp_fails === true) ? await __x.then((__v) => ({ ok: __v }), (__e) => { if (__x.__bp_failure === true) { return { error: __e }; } throw __e; }) : await __x; })().then((__v) => __v, (__e) => { __t.__bp_failure = true; throw __k(__e); }); __t.__bp_fails = true; __t.catch(() => {}); return __t; })($0, ((__e) => (__e != null && __e.__bp_panic != null) ? new Failure(typeof __e.__bp_panic === "string" ? __e.__bp_panic : __e.message, "panic") : (__e != null && typeof __e.__bp_assert_loc === "string") ? new Failure(__e.message, "panic") : new Failure((__e instanceof Error) ? __e.message : String(__e), (__e != null && __e.__bp_host === true) ? "host" : "crash")))"""),
    .Erlang("""(fun(__F) -> try {ok, __F()} catch error:{__T, __M} when (__T =:= panic orelse __T =:= todo orelse __T =:= integer_overflow) andalso (is_binary(__M) orelse is_list(__M)) -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, _, _, __M} -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, __M, _} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"panic">>}}; error:{bp_host, __M} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"host">>}}; _:__R -> {error, {'std@failure@@Failure', unicode:characters_to_binary(io_lib:format("~tp", [__R])), <<"crash">>}} end end)($0)"""),
    .Wasm(body: attemptTaskOnWasm),
)]
pub declare fn attemptTask<T>(f: fn() -> Async<T>) -> Async<Result<T, Failure>>;

// wasm's form (decision 518): the thunk's value, or the message of the abort
// it raised — `Error` of the abort's text, which `attempt` makes a `panic`.
// The bodies over it are compiled on every target, so it has a form on each;
// only wasm calls it (`attempt`'s own forms answer elsewhere).
#[compiler.external(
    .JavaScript("""((__f) => { try { return { ok: __f() }; } catch (__e) { return { error: (__e instanceof Error) ? __e.message : String(__e) }; } })($0)"""),
    .Erlang("""(fun(__F) -> try {ok, __F()} catch _:__R -> {error, unicode:characters_to_binary(io_lib:format("~tp", [__R]))} end end)($0)"""),
    .Wasm(wasi: .Attempt, needs: [.Exceptions]),
)]
declare fn caught<T>(f: fn() -> T) -> Result<T, string>;

fn attemptOnWasm<T>(f: fn() -> T) -> Result<T, Failure> {
    case caught(f) {
        Ok(v) -> return v;
        Error(m) -> throw Failure(message: m, kind: "panic");
    }
}

// The task the thunk started — or the `Failure` it raised before its first
// `await` — and then its value.
async fn attemptTaskOnWasm<T>(f: fn() -> Async<T>) -> Async<Result<T, Failure>> {
    case caught(f) {
        Ok(t) -> return await t;
        Error(m) -> throw Failure(message: m, kind: "panic");
    }
}

```

----- BEAM ASSEMBLY -- std/failure.S
```erlang
{module, std@failure}.
{exports, [{panic, 1}, {attempt, 1}, {attemptTask, 1}, {'__bp_priv__attemptOnWasm', 1}, {'__bp_priv__attemptTaskOnWasm', 1}]}.
{attributes, []}.
{labels, 59}.
%%% std/failure — the two records a failure that is not a typed error carries
%%% (decisions 431, 492).
%%% 
%%% `HostError` is what a host binding that writes `result: true` answers on
%%% the `Error` side: the host's message and `kind`, always `"host"`.
%%% `Failure` is what `attempt` answers on the `Error` side: `kind` is `panic`
%%% (`panic`, `@todo`, `x!`, an overflow, a division by zero), `host` (a raise
%%% from a binding without `result: true`) or `crash` (a VM or emitted-code
%%% fault, a wasm trap).
%%% 
%%% `attempt(f)` runs `f` and answers `Ok` of its value, or `Error(Failure)`
%%% for a raise it caught — the one way to contain a crash (decision 431 (3)).
%%% `attemptTask(f)` is its `Async` form (decision 494): the task `f` answers,
%%% awaited, or the `Failure` it crashed with — a `Async<Result<…>>` read
%%% back by `await` like any failing task (decision 432). The kinds
%%% (decision 492): a `panic` / `@todo` (and so `x!`), a failed `assert`
%%% and an integer overflow or division by zero are `panic`, their message
%%% the text the program wrote. A raise of a binding declared outside std without
%%% `result: true` is `host` (decision 546), its message the host's text — on
%%% commonJS an `Error`'s `message`, else `String(e)`, the call run through
%%% `__bp_host_mark`, which marks it `__bp_host`; any raise nothing marked is
%%% `crash`, its message the same text. On erlang and beam a
%%% host raise is the raise of a binding declared outside std without `result:
%%% true` — a library's or the program's, whose calls are wrapped to mark it
%%% (decision 546) — its message the reason by `~tp` (decision 489's reading);
%%% a raise nothing marked, a failing match or a std binding's, is `crash`,
%%% its message the reason by `~tp` too.
%%% 
%%% Both are bodyless: each backend wraps the call (a JavaScript `try` /
%%% rejection handler, an erlang `try … catch`; beam compiles the erlang
%%% form). On wasm (decision 518) each is a private body over `caught`, the
%%% `wasi: .Attempt` adapter: the thunk runs inside a `try_table` that
%%% catches the program's aborts (wasm exception handling), so the binding
%%% declares `needs: [.Exceptions]` and a program reaching it runs with the
%%% host's exceptions on (`-W exceptions=y` on wasmtime). On wasm an abort
%%% is `panic`; a trap (an overflow or a division by zero there, a host
%%% fault) is no exception and is not caught. `attemptTask` contains what
%%% the thunk raises before the task's first `await`.
% Decision 606 (2) — the abort `attempt` catches as a `panic` `Failure`: the program stops
% with `panic: <message>` (decision 535) unless an `attempt` above it answers the `Failure`.
% Imported where it is used, `import {failure.panic} from "std";` (`import {failure.panic};`
% inside std); `panic("not implemented")` is what `todo` was.

{function, panic, 1, 9}.
  {label, 8}.
    {line, [{location, "std@failure.erl", 1}]}.
    {func_info, {atom, std@failure}, {atom, panic}, 1}.
  {label, 9}.
    {call_only, 1, {f, 7}}.
% The Node forms read an abort by the `__bp_panic` mark the backend puts on
% every one it raises — `panic`, `@todo`, an integer overflow or division
% by zero, a failed `assert` (whose mark carries its message) — or a test
% body's `assert` (`__bp_assert_loc`); the Erlang forms by the reasons the
% backends raise for them (`{panic, M}`, `{todo, M}`, `{integer_overflow,
% M}`, `{bp_assert, M, Where}`). `attemptTask` answers a failing task
% (decision 432): marked `__bp_fails`, resolved with the value, rejected with
% the `Failure` (`__bp_failure`); a failing task `f` answers is read as
% `await` reads it.

{function, attempt, 1, 35}.
  {label, 34}.
    {line, [{location, "std@failure.erl", 2}]}.
    {func_info, {atom, std@failure}, {atom, attempt}, 1}.
  {label, 35}.
    {call_only, 1, {f, 11}}.

{function, attemptTask, 1, 37}.
  {label, 36}.
    {line, [{location, "std@failure.erl", 3}]}.
    {func_info, {atom, std@failure}, {atom, attemptTask}, 1}.
  {label, 37}.
    {call_only, 1, {f, 11}}.
% wasm's form (decision 518): the thunk's value, or the message of the abort
% it raised — `Error` of the abort's text, which `attempt` makes a `panic`.
% The bodies over it are compiled on every target, so it has a form on each;
% only wasm calls it (`attempt`'s own forms answer elsewhere).

{function, attemptOnWasm, 1, 3}.
  {label, 2}.
    {line, [{location, "std@failure.erl", 4}]}.
    {func_info, {atom, std@failure}, {atom, attemptOnWasm}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 39}}.
    {test, is_tagged_tuple, {f, 50}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 49}}.
  {label, 50}.
    {test, is_tagged_tuple, {f, 51}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {literal, <<"panic">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 2}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 49}}.
  {label, 51}.
    {case_end, {x, 0}}.
  {label, 49}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
% The task the thunk started — or the `Failure` it raised before its first
% `await` — and then its value.

%% @Async — eager lowering
{function, attemptTaskOnWasm, 1, 5}.
  {label, 4}.
    {line, [{location, "std@failure.erl", 5}]}.
    {func_info, {atom, std@failure}, {atom, attemptTaskOnWasm}, 1}.
  {label, 5}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 39}}.
    {test, is_tagged_tuple, {f, 53}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 52}}.
  {label, 53}.
    {test, is_tagged_tuple, {f, 54}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {literal, <<"panic">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 2}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 52}}.
  {label, 54}.
    {case_end, {x, 0}}.
  {label, 52}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_priv__attemptOnWasm', 1, 56}.
  {label, 55}.
    {line, [{location, "std@failure.erl", 6}]}.
    {func_info, {atom, std@failure}, {atom, '__bp_priv__attemptOnWasm'}, 1}.
  {label, 56}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__attemptTaskOnWasm', 1, 58}.
  {label, 57}.
    {line, [{location, "std@failure.erl", 7}]}.
    {func_info, {atom, std@failure}, {atom, '__bp_priv__attemptTaskOnWasm'}, 1}.
  {label, 58}.
    {call_only, 1, {f, 5}}.

{function, '__bp_tpl_0', 1, 7}.
  {label, 6}.
    {func_info, {atom, std@failure}, {atom, '__bp_tpl_0'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_1-t/1-fun-0-', 1, 15}.
  {label, 14}.
    {func_info, {atom, std@failure}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 1}.
  {label, 15}.
    {allocate, 11, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 2}}.
    {'try', {y, 10}, {f, 18}}.
    {move, {y, 2}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {try_end, {y, 10}}.
    {jump, {f, 19}}.
  {label, 18}.
    {try_case, {y, 10}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 1}, {y, 5}}.
    {move, {x, 2}, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 21}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 21}, [{x, 0}]}.
    {test, test_arity, {f, 21}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, panic}, {x, 1}}.
    {test, is_eq_exact, {f, 23}, [{x, 0}, {x, 1}]}.
    {jump, {f, 24}}.
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, todo}, {x, 1}}.
    {test, is_eq_exact, {f, 25}, [{x, 0}, {x, 1}]}.
    {jump, {f, 26}}.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, integer_overflow}, {x, 1}}.
    {test, is_eq_exact, {f, 21}, [{x, 0}, {x, 1}]}.
  {label, 26}.
  {label, 24}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 27}, [{x, 0}]}.
    {jump, {f, 28}}.
  {label, 27}.
    {move, {y, 1}, {x, 0}}.
    {test, is_list, {f, 21}, [{x, 0}]}.
  {label, 28}.
    {jump, {f, 22}}.
  {label, 22}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 9}, {literal, <<"panic">>}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 20}}.
  {label, 21}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 29}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 29}, [{x, 0}]}.
    {test, test_arity, {f, 29}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 3, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 29}, [{x, 0}, {atom, bp_assert}]}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 9}, {literal, <<"panic">>}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 20}}.
  {label, 29}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 30}, [{x, 0}]}.
    {test, test_arity, {f, 30}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, bp_assert}]}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 30}, [{x, 0}]}.
    {jump, {f, 31}}.
  {label, 31}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 1}, {literal, <<"panic">>}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 20}}.
  {label, 30}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 32}, [{x, 0}]}.
    {test, test_arity, {f, 32}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, bp_host}]}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 32}, [{x, 0}]}.
    {jump, {f, 33}}.
  {label, 33}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 1}, {literal, <<"host">>}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 20}}.
  {label, 32}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 7}, {literal, <<"crash">>}]}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 7}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 3}}.
    {jump, {f, 20}}.
  {label, 20}.
  {label, 19}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 11}.
    return.

{function, '__bp_tpl_1', 1, 11}.
  {label, 10}.
    {func_info, {atom, std@failure}, {atom, '__bp_tpl_1'}, 1}.
  {label, 11}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_2-t/1-fun-0-', 1, 43}.
  {label, 42}.
    {func_info, {atom, std@failure}, {atom, '__bp_tpl_2-t/1-fun-0-'}, 1}.
  {label, 43}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 7}, {f, 46}}.
    {move, {y, 1}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 2}}.
    {try_end, {y, 7}}.
    {jump, {f, 47}}.
  {label, 46}.
    {try_case, {y, 7}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 6}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 2}}.
    {jump, {f, 48}}.
  {label, 48}.
  {label, 47}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_tpl_2', 1, 39}.
  {label, 38}.
    {func_info, {atom, std@failure}, {atom, '__bp_tpl_2'}, 1}.
  {label, 39}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 43}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@failure@@HostErrorName.S
```erlang
{module, std@failure@@HostErrorName}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 7}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "std@failure@@HostErrorName.erl", 1}]}.
    {func_info, {atom, std@failure@@HostErrorName}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, std@failure@@HostErrorName__v__error}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HostErrorName.Error">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 5}, [{x, 0}, {atom, std@failure@@HostErrorName__v__throw}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HostErrorName.Throw">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 5}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 6}, [{x, 0}, {atom, std@failure@@HostErrorName__v__exit}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HostErrorName.Exit">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 6}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HostErrorName">>}, nil]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@failure@@HostError.S
```erlang
{module, std@failure@@HostError}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 10}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@failure@@HostError.erl", 1}]}.
    {func_info, {atom, std@failure@@HostError}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, message}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, kind}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, name}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {test, is_eq_exact, {f, 7}, [{x, 1}, {atom, detail}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 7}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 9}.
  {label, 8}.
    {line, [{location, "std@failure@@HostError.erl", 1}]}.
    {func_info, {atom, std@failure@@HostError}, {atom, '__bp_format'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"detail">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"name">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"kind">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"message">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"HostError">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@failure@@Failure.S
```erlang
{module, std@failure@@Failure}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@failure@@Failure.erl", 1}]}.
    {func_info, {atom, std@failure@@Failure}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, message}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, kind}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 7}.
  {label, 6}.
    {line, [{location, "std@failure@@Failure.erl", 1}]}.
    {func_info, {atom, std@failure@@Failure}, {atom, '__bp_format'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"kind">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"message">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Failure">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- std/io/fs.bp
```botopink
//// std/io/fs — the file system, cross-backend (decision 540).
////
//// Reference:
////   Rust     — https://doc.rust-lang.org/std/fs/ (`read`, `read_to_string`,
////              `File`, `io::ErrorKind`)
////   Java     — https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/nio/file/Files.html
////   Erlang   — https://www.erlang.org/doc/man/file.html
////   Node.js  — https://nodejs.org/api/fs.html
////
//// Every function that can fail answers `Result<…, FsError>`: the same OS error is
//// the same `FsError` variant on every target (`ENOENT`, `enoent` → `NotFound`),
//// and `Other.message` is the host's own text. The whole-file shortcuts
//// (`readBytes`, `readText`, `writeBytes`, `writeText`, `appendText`), `stat`, and
//// the directory functions (`exists`, `list`, `mkdir`, `mkdirRecursive`, `rm`,
//// `removeTree`, `copy`, `walk`, `glob`) are followed by the handle: `open`
//// and `create` answer a `File`, a `Closeable` closed by the writer with `defer`.
////
//// The host cells (`raw…`) write `result: true` (decisions 431, 490) and answer
//// `Result<R, HostError>` — Node's `ENOENT: …`, erlang's `enoent` as its `message` —
//// and `lift` reads that message as the `FsError` of the path the caller wrote
//// (decision 486); no cell catches by hand. All operations are synchronous
//// (`*Sync` on Node, blocking BIFs on Erlang); there is no wasm binding here
//// (front 164: `wasi:filesystem` behind `needs: [.Filesystem]`).

import {path.relative, failure, failure.HostError, compiler};

// The error of every `io.fs` function (decision 540). `path` is the path the
// caller wrote (for `copy`, the source; for `walk`, the root).
pub type FsError {
    NotFound(path: string),
    PermissionDenied(path: string),
    IsDirectory(path: string),
    NotDirectory(path: string),
    AlreadyExists(path: string),
    // `readText` / `text` / `lines` on bytes that are not UTF-8: `offset` is
    // the byte, in what was read, where the first invalid sequence starts.
    InvalidUtf8(path: string, offset: i64),
    // Any other host error; `message` is the host's text.
    Other(path: string, message: string),

    // The error's text (decision 563): `<what>: <path>`, the same on every target.
    pub fn message(self: Self) -> string {
        return case self {
            NotFound(path: path) -> "not found: " + path;
            PermissionDenied(path: path) -> "permission denied: " + path;
            IsDirectory(path: path) -> "is a directory: " + path;
            NotDirectory(path: path) -> "not a directory: " + path;
            AlreadyExists(path: path) -> "already exists: " + path;
            InvalidUtf8(path: path, offset: offset) -> "not UTF-8: "
                + path
                + " at byte "
                + offset.toString();
            Other(path: path, message: message) -> path + ": " + message;
        };
    }
}

pub type FileStat(
    size: i64,
    mtime: i64,
    isDir: bool,
)

// Read the whole file as bytes.
// Node: `readFileSync($0)` copied into a plain `Uint8Array`.
// Erlang: `file:read_file/1`.
#[compiler.external(
    .JavaScript("""(() => { return new Uint8Array(require('fs').readFileSync($0)) })()""", result: true),
    .Erlang("""(fun(__P) -> case file:read_file(__P) of {ok, __B} -> {ok, __B}; {error, __R} -> {error, __R} end end)($0)""", result: true),
)]
declare fn rawReadBytes(path: string) -> Result<bytes, HostError>;

// Write `contents` to `path`, creating or truncating.
// Node: `writeFileSync($0, $1)`. Erlang: `file:write_file/2`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').writeFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
)]
declare fn rawWriteBytes(path: string, contents: bytes) -> Result<i32, HostError>;

// Append `contents` to `path`, creating it when it is not there.
// Node: `appendFileSync($0, $1)`. Erlang: `file:write_file/3` with `append`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').appendFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__P, __C) -> case file:write_file(__P, __C, [append]) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
)]
declare fn rawAppendText(path: string, contents: string) -> Result<i32, HostError>;

// The offset of the first byte that starts a sequence that is not UTF-8 (a byte no sequence
// starts with, a sequence cut short, an overlong form, a surrogate, a code point past U+10FFFF),
// or -1 when every byte is part of a valid sequence — the same offset on every target.
// Node: a scan of the bytes. Erlang: `unicode:characters_to_binary/3`, whose `Good` prefix is the offset.
#[compiler.external(
    .JavaScript("""((__b) => { const __n = __b.length; let __i = 0; while (__i < __n) { const __c = __b[__i]; if (__c < 128) { __i++; continue } let __k; if (__c >= 194 && __c <= 223) __k = 1; else if (__c >= 224 && __c <= 239) __k = 2; else if (__c >= 240 && __c <= 244) __k = 3; else return __i; if (__i + __k >= __n) return __i; let __lo = 128, __hi = 191; if (__c === 224) __lo = 160; else if (__c === 237) __hi = 159; else if (__c === 240) __lo = 144; else if (__c === 244) __hi = 143; const __d = __b[__i + 1]; if (__d < __lo || __d > __hi) return __i; for (let __j = 2; __j <= __k; __j++) { const __e = __b[__i + __j]; if (__e < 128 || __e > 191) return __i } __i += __k + 1 } return -1 })($0)"""),
    .Erlang("""(fun(__B) -> case unicode:characters_to_binary(__B, utf8, utf8) of __S when is_binary(__S) -> -1; {error, __G, _} -> byte_size(__G); {incomplete, __G, _} -> byte_size(__G) end end)($0)"""),
)]
declare fn utf8Offset(bytes: bytes) -> i64;

// `line` without its line terminator: one trailing `\n`, and the `\r` before it.
// Node: `subarray`. Erlang: `binary:part/3`.
#[compiler.external(
    .JavaScript("""((__b) => { let __n = __b.length; if (__n > 0 && __b[__n - 1] === 10) { __n--; if (__n > 0 && __b[__n - 1] === 13) __n-- } return __b.subarray(0, __n) })($0)"""),
    .Erlang("""(fun(__B) -> __N = byte_size(__B), if __N >= 2 -> case binary:part(__B, __N - 2, 2) of <<13, 10>> -> binary:part(__B, 0, __N - 2); <<_, 10>> -> binary:part(__B, 0, __N - 1); _ -> __B end; __N =:= 1 -> case __B of <<10>> -> <<>>; _ -> __B end; true -> __B end end)($0)"""),
)]
declare fn stripEol(line: bytes) -> bytes;

// The handle of the file at `path`, open for reading. A directory is `isdir` on both hosts
// (Node opens one; the template refuses it). The handle is host-owned and opaque: a `{ fd,
// mem, pos, buf }` object on Node, an io device on Erlang (a stream reads it in its own process).
#[compiler.external(
    .JavaScript("""(() => { const __fs = require('fs'); const __p = $0; const __fd = __fs.openSync(__p, 'r'); if (__fs.fstatSync(__fd).isDirectory()) { __fs.closeSync(__fd); throw new Error('EISDIR: illegal operation on a directory, open ' + JSON.stringify(__p)) } return { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } })()""", result: true),
    .Erlang("""(fun(__P) -> case file:open(__P, [read, binary, read_ahead]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __R} end end)($0)""", result: true),
)]
declare fn rawOpen(path: string) -> Result<unknown, HostError>;

// The handle of the file at `path`, open for writing: created, or truncated.
#[compiler.external(
    .JavaScript("""(() => { const __fd = require('fs').openSync($0, 'w'); return { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } })()""", result: true),
    .Erlang("""(fun(__P) -> case file:open(__P, [write, binary, raw]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __R} end end)($0)""", result: true),
)]
declare fn rawCreate(path: string) -> Result<unknown, HostError>;

// A handle over bytes held in memory — what an `Asset` opens as. The position is a field
// on Node and a `counters` cell on Erlang.
#[compiler.external(
    .JavaScript("""({ fd: -1, mem: $0, pos: 0, buf: new Uint8Array(0) })"""),
    .Erlang("""{mem, $0, counters:new(1, [])}"""),
)]
declare fn memHandle(bytes: bytes) -> unknown;

// The size of the file behind `handle`, in bytes. On Erlang it reads `path`.
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; return __h.mem ? __h.mem.length : require('fs').fstatSync(__h.fd).size })()""", result: true),
    .Erlang("""(fun(__H, __P) -> case __H of {mem, __B, _} -> {ok, byte_size(__B)}; _ -> case file:read_file_info(__P) of {ok, __I} -> {ok, element(2, __I)}; {error, __R} -> {error, __R} end end end)($0, $1)""", result: true),
)]
declare fn rawSize(handle: unknown, path: string) -> Result<i64, HostError>;

// Up to `n` bytes (n > 0) from the handle's position; empty at the end.
#[compiler.external(
    .JavaScript("""(() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = $0; const __n = $1; if (__h.buf.length > 0) { const __k = Math.min(__n, __h.buf.length); const __o = new Uint8Array(__h.buf.subarray(0, __k)); __h.buf = __h.buf.subarray(__k); return __o } return new Uint8Array(__more(__h, __n)) })()""", result: true),
    .Erlang("""(fun(__H, __N) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Len = min(__N, byte_size(__B) - __Pos), counters:add(__C, 1, __Len), {ok, binary:part(__B, __Pos, __Len)}; _ -> case file:read(__H, __N) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __R} end end end)($0, $1)""", result: true),
)]
declare fn rawRead(handle: unknown, n: i32) -> Result<bytes, HostError>;

// Every byte from the handle's position to the end.
#[compiler.external(
    .JavaScript("""(() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = $0; const __parts = []; if (__h.buf.length > 0) { __parts.push(__h.buf); __h.buf = new Uint8Array(0) } for (;;) { const __r = __more(__h, 65536); if (__r.length === 0) break; __parts.push(new Uint8Array(__r)) } let __t = 0; for (const __x of __parts) __t += __x.length; const __o = new Uint8Array(__t); let __p = 0; for (const __x of __parts) { __o.set(__x, __p); __p += __x.length } return __o })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), counters:add(__C, 1, byte_size(__B) - __Pos), {ok, binary:part(__B, __Pos, byte_size(__B) - __Pos)}; _ -> (fun __L(__Acc) -> case file:read(__H, 65536) of {ok, __D} -> __L([__Acc, __D]); eof -> {ok, iolist_to_binary(__Acc)}; {error, __R} -> {error, __R} end end)([]) end end)($0)""", result: true),
)]
declare fn rawReadAll(handle: unknown) -> Result<bytes, HostError>;

// The next line, terminator included; empty at the end.
#[compiler.external(
    .JavaScript("""(() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = $0; for (;;) { const __i = __h.buf.indexOf(10); if (__i >= 0) { const __l = new Uint8Array(__h.buf.subarray(0, __i + 1)); __h.buf = __h.buf.subarray(__i + 1); return __l } const __r = __more(__h, 65536); if (__r.length === 0) { const __l = __h.buf; __h.buf = new Uint8Array(0); return __l } const __nb = new Uint8Array(__h.buf.length + __r.length); __nb.set(__h.buf, 0); __nb.set(__r, __h.buf.length); __h.buf = __nb } })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Rest = binary:part(__B, __Pos, byte_size(__B) - __Pos), case binary:match(__Rest, <<10>>) of nomatch -> counters:add(__C, 1, byte_size(__Rest)), {ok, __Rest}; {__At, _} -> counters:add(__C, 1, __At + 1), {ok, binary:part(__Rest, 0, __At + 1)} end; _ -> case file:read_line(__H) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __R} end end end)($0)""", result: true),
)]
declare fn rawReadLine(handle: unknown) -> Result<bytes, HostError>;

// The SHA-256 of the whole file behind the handle, lowercase hex — from its first byte,
// whatever the position, which it leaves where it was. On Erlang `file:pread` leaves the
// position undefined (OTP moves it), so the position is read first and restored.
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; const __hs = require('crypto').createHash('sha256'); if (__h.mem) { __hs.update(__h.mem) } else { const __b = new Uint8Array(65536); let __pos = 0; for (;;) { const __k = require('fs').readSync(__h.fd, __b, 0, 65536, __pos); if (__k === 0) break; __hs.update(__b.subarray(0, __k)); __pos += __k } } return __hs.digest('hex') })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, __B, _} -> {ok, string:lowercase(binary:encode_hex(crypto:hash(sha256, __B)))}; _ -> {ok, __Cur} = file:position(__H, cur), __L = fun __Lp(__Pos, __Ctx) -> case file:pread(__H, __Pos, 65536) of {ok, __D} -> __Lp(__Pos + byte_size(__D), crypto:hash_update(__Ctx, __D)); eof -> crypto:hash_final(__Ctx); {error, __R} -> erlang:error(__R) end end, __Digest = __L(0, crypto:hash_init(sha256)), {ok, _} = file:position(__H, __Cur), {ok, string:lowercase(binary:encode_hex(__Digest))} end end)($0)""", result: true),
)]
declare fn rawHash(handle: unknown) -> Result<string, HostError>;

// Write `bytes` at the handle's position; answers how many.
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; const __b = $1; let __o = 0; while (__o < __b.length) __o += require('fs').writeSync(__h.fd, __b, __o, __b.length - __o); return __b.length })()""", result: true),
    .Erlang("""(fun(__H, __B) -> case file:write(__H, __B) of ok -> {ok, byte_size(__B)}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
)]
declare fn rawWrite(handle: unknown, bytes: bytes) -> Result<i32, HostError>;

// Close the handle. A failure to close is not reported (a `Closeable`'s `close` answers nothing).
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; if (!__h.mem) require('fs').closeSync(__h.fd); return 0 })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, _, _} -> {ok, 0}; _ -> case file:close(__H) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end end)($0)""", result: true),
)]
declare fn rawClose(handle: unknown) -> Result<i32, HostError>;

// Write `contents` to `path`, creating or truncating. Reds with the
// host's I/O error message.
// Node: `require('fs').writeFileSync($0, $1)`.
// Erlang: `file:write_file/2`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').writeFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
)]
declare fn rawWriteText(
    path: string,
    contents: string,
) -> Result<i32, HostError>;

// Whether a path exists, of any kind: a regular file, a directory, a
// character or block device (`/dev/null`), a FIFO or a socket. A symbolic
// link is followed — one whose target is missing is `false`, the answer
// every read through it would give.
// Node: `require('fs').existsSync($0)` (a `stat`).
// Erlang: `file:read_file_info/1` (a `stat`; `filelib:is_file/1`, which it
// replaces, answers only regular files and directories, so `/dev/null`
// was `false` on erlang and `true` on commonJS).
#[compiler.external(
    .JavaScript("""require('fs').existsSync($0)"""),
    .Erlang("""(case file:read_file_info($0) of {ok, _} -> true; _ -> false end)"""),
)]
pub declare fn exists(path: string) -> bool;

// List the names of the directory entries at `path` (relative).
// Node: `require('fs').readdirSync($0)`.
// Erlang: `file:list_dir/1` returns `{ok, [string()]}`.
#[compiler.external(
    .JavaScript("""(() => { return require('fs').readdirSync($0) })()""", result: true),
    .Erlang("""(fun(__P) -> case file:list_dir(__P) of {ok, __L} -> {ok, [list_to_binary(__N) || __N <- __L]}; {error, __R} -> {error, __R} end end)($0)""", result: true),
)]
declare fn rawList(path: string) -> Result<string[], HostError>;

// Create directory at `path`. Use `mkdirRecursive` to create
// intermediate parents.
// Node: `require('fs').mkdirSync($0)`.
// Erlang: `file:make_dir/1`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').mkdirSync($0); return 0 })()""", result: true),
    .Erlang("""(fun(__P) -> case file:make_dir(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0)""", result: true),
)]
declare fn rawMkdir(path: string) -> Result<i32, HostError>;

// Create the directory at `path` and every missing directory above it. A
// directory that is already there is `Ok` too; a path that exists as anything
// else (a file) is an `Error`. What the snapshot library (`snap`) makes the
// directory of a `.snap` with (decision 391).
// Node: `require('fs').mkdirSync($0, { recursive: true })`.
// Erlang: `filelib:ensure_path/1`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').mkdirSync($0, { recursive: true }); return 0 })()""", result: true),
    .Erlang("""(fun(__P) -> case filelib:ensure_path(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0)""", result: true),
)]
declare fn rawMkdirRecursive(path: string) -> Result<i32, HostError>;

// Delete the FILE at `path`. A directory — empty or not — is `IsDirectory` on
// both hosts (Node's `ERR_FS_EISDIR`; Erlang's `eperm` is read as `eisdir` after
// a `read_link_info`, so the variant is the same); `removeTree` removes one.
// Node: `require('fs').rmSync($0)`.
// Erlang: `file:delete/1`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').rmSync($0); return 0 })()""", result: true),
    .Erlang("""(fun(__P) -> case file:read_link_info(__P) of {ok, __I} when element(3, __I) =:= directory -> {error, eisdir}; _ -> case file:delete(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end end)($0)""", result: true),
)]
declare fn rawRm(path: string) -> Result<i32, HostError>;

// Copy file from `src` to `dest`. Reds when `src` is missing or
// `dest` already exists (Node's default `copyFileSync` semantics).
// Node: `require('fs').copyFileSync($0, $1)`.
// Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).
#[compiler.external(
    .JavaScript("""(() => { require('fs').copyFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__S, __D) -> case file:copy(__S, __D) of {ok, _} -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
)]
declare fn rawCopy(src: string, dest: string) -> Result<i32, HostError>;

// File metadata. Returns a `FileStat { size, mtime, isDir }` on
// success. `mtime` is epoch milliseconds (matching `time.nowMillis()`);
// `size` is in bytes.
// Node: `statSync($0, { bigint: true })`, so `size` and the nanosecond
// `mtimeNs` arrive exact at any size; `mtime` is `mtimeNs` floored to whole
// seconds, × 1000, and both answer decision 319's canonical form (a `number`
// within ±(2^53 − 1), a `BigInt` beyond) — never a `number` rounded past 2^53.
// Erlang: `file:read_file_info/1` returns a `#file_info` record; the
// template projects the `size`, `mtime`, and `type` fields. Its `mtime` is
// whole seconds × 1000. One value on every target: whole seconds (decision 499).
#[compiler.external(
    .JavaScript("""(() => { const __s = require('fs').statSync($0, { bigint: true }); const __c = (__v) => (__v >= -9007199254740991n && __v <= 9007199254740991n) ? Number(__v) : __v; const __ns = __s.mtimeNs; return { size: __c(__s.size), mtime: __c(((__ns - (((__ns % 1000000000n) + 1000000000n) % 1000000000n)) / 1000000000n) * 1000n), isDir: __s.isDirectory() } })()""", result: true),
    .Erlang("""(fun(__P) -> case file:read_file_info(__P, [{time, posix}]) of {ok, {file_info, __Sz, __Ty, _, _, __Mt, _, _, _, _, _, _, _, _}} -> {ok, #{size => __Sz, mtime => __Mt * 1000, isDir => (__Ty =:= directory)}}; {error, __R} -> {error, __R} end end)($0)""", result: true),
)]
declare fn rawStat(path: string) -> Result<FileStat, HostError>;

// ── 1.0.10-beta front 01 additions ──────────────────────────────────────────

// Every REGULAR FILE under `root`, recursively, as paths relative to `root`
// with `/` separators, sorted — the same set on both targets (the two hosts
// walk in different orders, so the list is sorted rather than left as found),
// and the same paths however the root is spelled: `dir`, `dir/`, `dir/.`,
// `./dir`, `dir/sub/..`, absolute or relative to the working directory.
// Directories are not listed; a link is followed (a link to a file is listed
// under its own name, a link to a directory is walked). An `Error`: a missing
// or non-directory `root`, a directory under it that cannot be read, and a
// DANGLING link (decision 178) — `fs.walk: dangling link "<relative path>"`,
// the same text on both targets, naming the first one in sorted order.
// Node: `readdirSync(root, { recursive: true })` answers files AND directories
// relative to `root`; the template sorts them, keeps the entries `statSync`
// says are files, and answers the dangling-link `Error` for the first entry
// `statSync` cannot find (`throwIfNoEntry: false`).
// Erlang: the template walks `file:list_dir/1` itself and BUILDS each relative
// path from the names it descended through. It never cuts a prefix off a full
// path: `filelib:fold_files/5` answers full paths `filename:join/2` has
// normalised (`dir/.` + `app` is `dir/app`), so a prefix measured on the root
// as written cut two characters too many when the root ended in `/.`.
#[compiler.external(
    .JavaScript("""(() => { const __fs = require('fs'); const __p = require('path'); const __all = __fs.readdirSync($0, { recursive: true }).map(__f => String(__f).split(__p.sep).join('/')).sort(); const __out = []; const __dng = []; for (const __f of __all) { const __s = __fs.statSync(__p.join($0, __f), { throwIfNoEntry: false }); if (__s === undefined) { __dng.push(__f); continue } if (__s.isFile()) __out.push(__f) } return { files: __out, dangling: __dng } })()""", result: true),
    .Erlang("""(fun(__R) -> __Root = unicode:characters_to_list(__R), case filelib:is_dir(__Root) of false -> {error, case file:read_file_info(__Root) of {ok, _} -> enotdir; {error, __X0} -> __X0 end}; true -> __Walk = fun __W(__Dir, __Rel, __Acc) -> case file:list_dir(__Dir) of {error, __E} -> erlang:error(__E); {ok, __Names} -> lists:foldl(fun(__Name, __A) -> __Full = filename:join(__Dir, __Name), __Sub = case __Rel of [] -> __Name; _ -> __Rel ++ "/" ++ __Name end, case file:read_file_info(__Full) of {ok, __I} when element(3, __I) =:= directory -> __W(__Full, __Sub, __A); {ok, __I} when element(3, __I) =:= regular -> [{file, unicode:characters_to_binary(__Sub)} | __A]; {ok, _} -> __A; {error, enoent} -> [{dangling, unicode:characters_to_binary(__Sub)} | __A]; {error, __X} -> erlang:error(__X) end end, __Acc, __Names) end end, __Found = __Walk(__Root, [], []), {ok, #{files => lists:sort([__F || {file, __F} <- __Found]), dangling => lists:sort([__D || {dangling, __D} <- __Found])}} end end)($0)""", result: true),
)]
declare fn rawWalk(root: string) -> Result<Walked, HostError>;

// The entries under `root` matching the glob `pattern`, as paths relative to
// `root` with `/` separators, sorted, each once. The pattern is read segment
// by segment, by ONE rule on both targets (decision 177 — the narrower of what
// the two hosts did):
//   - `**` is zero or more directories; a segment with `*`, `?`, `[…]` or
//     `{a,b}` matches the names of one directory; any other segment is a name.
//   - `*` and `**` (and `?`, `[…]`, `{…}`) do NOT match a name that starts
//     with `.` — a segment matches one only when the segment itself starts
//     with the dot (`.*`, `.config/*.json`).
//   - the walk does NOT descend through a link to a directory: `**` and a
//     wildcard segment continue into real directories only. The link is still
//     a NAME — `*` lists it — and a segment that names it (`linked/*.bp`) goes
//     through it, because the pattern wrote it.
//   - the last segment matches an entry of any kind (file, directory, link,
//     dangling or not); a final `**` is every entry at every depth; a trailing
//     `/` keeps real directories only.
// An alternative of `{a,b}` cannot hold a `/` (the pattern is split first). A
// root that does not exist answers `Ok([])`; so does a directory that cannot
// be read. Both cells are the same walk; only the match of ONE segment against
// ONE directory is the host's — `fs.globSync(segment, { cwd })` (Node 22+),
// `filelib:wildcard/2` — with the dot rule applied over its answer, since
// `filelib:wildcard` matches dot names and `globSync` matches `{.a,b}`.
#[compiler.external(
    .JavaScript("""(() => { const __fs = require('fs'); const __p = require('path'); const __root = $1; const __pat = String($0); const __segs = __pat.split('/').filter(__s => __s !== '' && __s !== '.'); const __dirsOnly = __pat.endsWith('/'); const __lst = (__f) => { try { return __fs.lstatSync(__f, { throwIfNoEntry: false }) } catch (__e) { return undefined } }; const __realDir = (__f) => { const __s = __lst(__f); return __s !== undefined && __s.isDirectory() }; const __linkedDir = (__f) => { try { const __s = __fs.statSync(__f, { throwIfNoEntry: false }); return __s !== undefined && __s.isDirectory() } catch (__e) { return false } }; const __magic = (__s) => __s.includes('*') || __s.includes('?') || __s.includes('[') || __s.includes('{'); const __names = (__dir, __seg) => { let __all; try { __all = (__seg === '*' ? __fs.readdirSync(__dir) : __fs.globSync(__seg, { cwd: __dir })).map(String) } catch (__e) { __all = [] } return __all.filter(__n => !__n.startsWith('.') || __seg.startsWith('.')) }; const __join = (__rel, __n) => __rel === '' ? __n : __rel + '/' + __n; const __out = new Set(); const __walk = (__i, __dir, __rel) => { if (__i === __segs.length) { if (__rel !== '') __out.add(__rel); return } const __seg = __segs[__i]; const __last = __i === __segs.length - 1; if (__seg === '**') { if (!__last) __walk(__i + 1, __dir, __rel); for (const __n of __names(__dir, '*')) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); if (__realDir(__f)) __walk(__i, __f, __sub) } return } if (!__magic(__seg)) { const __f = __p.join(__dir, __seg); const __sub = __join(__rel, __seg); if (__last) { if (__lst(__f) !== undefined) __out.add(__sub) } else if (__linkedDir(__f)) __walk(__i + 1, __f, __sub); return } for (const __n of __names(__dir, __seg)) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); else if (__realDir(__f)) __walk(__i + 1, __f, __sub) } }; __walk(0, __root, ''); return Array.from(__out).filter(__r => !__dirsOnly || __realDir(__p.join(__root, __r))).sort() })()"""),
    .Erlang("""(fun(__P, __R) -> __Root = unicode:characters_to_list(__R), __Pat = unicode:characters_to_list(__P), __Segs = [__S || __S <- string:split(__Pat, "/", all), __S =/= [], __S =/= "."], __DirsOnly = lists:suffix("/", __Pat), __RealDir = fun(__F) -> case file:read_link_info(__F) of {ok, __I} -> element(3, __I) =:= directory; _ -> false end end, __Magic = fun(__S) -> lists:any(fun(__C) -> lists:member(__C, "*?[{") end, __S) end, __Names = fun(__Dir, __Seg) -> __All = case __Seg of "*" -> case file:list_dir(__Dir) of {ok, __L} -> __L; _ -> [] end; _ -> try filelib:wildcard(__Seg, __Dir) catch _:_ -> [] end end, [__N || __N <- __All, (hd(__N) =/= 46) orelse (hd(__Seg) =:= 46)] end, __Join = fun([], __N) -> __N; (__Rel, __N) -> __Rel ++ "/" ++ __N end, __Walk = fun __W([], _, [], __Acc) -> __Acc; __W([], _, __Rel, __Acc) -> [__Rel | __Acc]; __W(["**"], __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), __Sub = __Join(__Rel, __N), case __RealDir(__F) of true -> __W(["**"], __F, __Sub, [__Sub | __A]); false -> [__Sub | __A] end end, __Acc, __Names(__Dir, "*")); __W(["**" | __Rest] = __Pattern, __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), case __RealDir(__F) of true -> __W(__Pattern, __F, __Join(__Rel, __N), __A); false -> __A end end, __W(__Rest, __Dir, __Rel, __Acc), __Names(__Dir, "*")); __W([__Seg | __Rest], __Dir, __Rel, __Acc) -> case __Magic(__Seg) of false -> __F = filename:join(__Dir, __Seg), __Sub = __Join(__Rel, __Seg), case __Rest of [] -> case file:read_link_info(__F) of {ok, _} -> [__Sub | __Acc]; _ -> __Acc end; _ -> case filelib:is_dir(__F) of true -> __W(__Rest, __F, __Sub, __Acc); false -> __Acc end end; true -> lists:foldl(fun(__N, __A) -> __G = filename:join(__Dir, __N), __Under = __Join(__Rel, __N), case __Rest of [] -> [__Under | __A]; _ -> case __RealDir(__G) of true -> __W(__Rest, __G, __Under, __A); false -> __A end end end, __Acc, __Names(__Dir, __Seg)) end end, [unicode:characters_to_binary(__X) || __X <- lists:usort(__Walk(__Segs, __Root, [], [])), (not __DirsOnly) orelse __RealDir(filename:join(__Root, __X))] end)($0, $1)"""),
)]
declare fn rawGlob(pattern: string, root: string) -> string[];

// Remove `path` and everything under it: a file, a link (the link, never its
// target) or a directory tree. A path that is not there is `Ok` too — the
// caller wanted it gone. What a test fixture is cleared with, and what the
// snapshot engine's tests clear their scratch directories with (1.0.11-beta
// front 97).
// Node: `rmSync(path, { recursive: true, force: true })`.
// Erlang: `file:del_dir_r/1`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').rmSync($0, { recursive: true, force: true }); return 0 })()""", result: true),
    .Erlang("""(fun(__P) -> case file:del_dir_r(__P) of ok -> {ok, 0}; {error, enoent} -> {ok, 0}; {error, __R} -> {error, __R} end end)($0)""", result: true),
)]
declare fn rawRemoveTree(path: string) -> Result<i32, HostError>;

// Internal, test scaffolding: a fresh, unique, empty directory under the
// host's tmpdir. Private — every `walk`/`glob` test makes its fixture tree in
// one of these and removes it with `removeTree`, so a run leaves nothing under
// the host's tmpdir.
#[compiler.external(
    .JavaScript("""require('fs').mkdtempSync(require('path').join(require('os').tmpdir(), 'bp-std-fs-'))"""),
    .Erlang("""(fun() -> __T = case os:getenv("TMPDIR") of false -> "/tmp"; __V -> __V end, __D = filename:join(__T, "bp-std-fs-" ++ integer_to_list(erlang:unique_integer([positive]))), ok = file:make_dir(__D), unicode:characters_to_binary(__D) end)()"""),
)]
declare fn scratchDir() -> string;

// Internal, test scaffolding: the working directory (what a relative root is
// read against) and a symbolic link `link` → `target`.
#[compiler.external(
    .JavaScript("process.cwd()"),
    .Erlang("""(fun() -> {ok, __D} = file:get_cwd(), unicode:characters_to_binary(__D) end)()"""),
)]
declare fn workingDir() -> string;

#[compiler.external(
    .JavaScript("""require('fs').symlinkSync($0, $1)"""),
    .Erlang("""(fun(__T, __L) -> ok = file:make_symlink(__T, __L), ok end)($0, $1)"""),
)]
declare fn linkTo(target: string, link: string) -> void;

// ── the typed error ──────────────────────────────────────────────────────────

// The `FsError` of `path` a host's failure is (decision 486), read from its code: Node's `ENOENT: …`, erlang's `enoent`.
fn fsError(path: string, e: HostError) -> FsError {
    val u = e.message.toUpper();
    if (u.startsWith("ENOENT")) return FsError.NotFound(path: path);
    if (u.startsWith("EACCES") || u.startsWith("EPERM"))
        return FsError.PermissionDenied(path: path);
    if (u.startsWith("EISDIR") || u.startsWith("PATH IS A DIRECTORY"))
        return FsError.IsDirectory(path: path);
    if (u.startsWith("ENOTDIR")) return FsError.NotDirectory(path: path);
    if (u.startsWith("EEXIST")) return FsError.AlreadyExists(path: path);
    return FsError.Other(path: path, message: e.message);
}

// A host cell's answer, its failure read as an `FsError` of `path`.
fn lift<T>(path: string, r: Result<T, HostError>) -> Result<T, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

// The text of `b`, or `InvalidUtf8` at the first invalid byte.
fn decode(path: string, b: bytes) -> Result<string, FsError> {
    val offset = utf8Offset(b);
    if (offset >= 0l) throw FsError.InvalidUtf8(path: path, offset: offset);
    return b.toUtf8().unwrapOr("");
}

// What `rawWalk` finds under a root: the regular files, and the links whose
// target is missing, both as paths relative to the root, sorted.
type Walked(
    files: string[],
    dangling: string[],
)

// Whether the handle is one over bytes held in memory (an `Asset`'s), which cannot be written.
#[compiler.external(
    .JavaScript("""(($0).mem != null)"""),
    .Erlang("""(case $0 of {mem, _, _} -> true; _ -> false end)"""),
)]
declare fn rawReadOnly(handle: unknown) -> bool;

// ── whole-file shortcuts ─────────────────────────────────────────────────────

// The file's bytes.
pub fn readBytes(path: string) -> Result<bytes, FsError> {
    val b = try lift(path, rawReadBytes(path));
    return b;
}

// The file as UTF-8 text. Bytes that are not UTF-8 are `InvalidUtf8` on every
// target — never node's silent U+FFFD nor erlang's unchecked binary.
pub fn readText(path: string) -> Result<string, FsError> {
    val b = try readBytes(path);
    val s = try decode(path, b);
    return s;
}

// Write `contents` to `path`, creating or truncating.
pub fn writeBytes(path: string, contents: bytes) -> Result<i32, FsError> {
    val n = try lift(path, rawWriteBytes(path, contents));
    return n;
}

pub fn writeText(path: string, contents: string) -> Result<i32, FsError> {
    val n = try lift(path, rawWriteText(path, contents));
    return n;
}

// Append `contents`, creating the file when it is not there.
pub fn appendText(path: string, contents: string) -> Result<i32, FsError> {
    val n = try lift(path, rawAppendText(path, contents));
    return n;
}

// ── metadata and directories ─────────────────────────────────────────────────

pub fn stat(path: string) -> Result<FileStat, FsError> {
    val s = try lift(path, rawStat(path));
    return s;
}

pub fn list(path: string) -> Result<string[], FsError> {
    val names = try lift(path, rawList(path));
    return names;
}

pub fn mkdir(path: string) -> Result<i32, FsError> {
    val n = try lift(path, rawMkdir(path));
    return n;
}

pub fn mkdirRecursive(path: string) -> Result<i32, FsError> {
    val n = try lift(path, rawMkdirRecursive(path));
    return n;
}

pub fn rm(path: string) -> Result<i32, FsError> {
    val n = try lift(path, rawRm(path));
    return n;
}

pub fn removeTree(path: string) -> Result<i32, FsError> {
    val n = try lift(path, rawRemoveTree(path));
    return n;
}

pub fn copy(src: string, dest: string) -> Result<i32, FsError> {
    val n = try lift(src, rawCopy(src, dest));
    return n;
}

pub fn walk(root: string) -> Result<string[], FsError> {
    val found = try lift(root, rawWalk(root));
    if (found.dangling.length > 0) {
        val first = found.dangling.at(0) ?? "";
        throw FsError.Other(path: root, message: ["fs.walk: dangling link \"", first, "\""].join(""));
    }
    return found.files;
}

pub fn glob(pattern: string, root: string) -> Result<string[], FsError> {
    return rawGlob(pattern, root);
}

// The host's handle over embedded bytes: read like a file, never closed on disk.
#[compiler.external(
    .JavaScript("""({ fd: -1, mem: $0, pos: 0, buf: new Uint8Array(0) })"""),
    .Erlang("""{mem, $0, counters:new(1, [])}"""),
)]
declare fn memoryHandle(bytes: bytes) -> unknown;

// ── the handle ───────────────────────────────────────────────────────────────

// An open file (decision 540 (3)). `location` is the path it was opened with and
// `handle` the host's — opaque, never read by a program. Closed by the writer:
// `val f = try fs.open(p); defer f.close();`.
pub type File(location: string, handle: unknown) implement Closeable {
    // The path the file was opened with.
    pub fn path(self: Self) -> string {
        return self.location;
    }

    // The file's size in bytes.
    pub fn size(self: Self) -> Result<i64, FsError> {
        val n = try lift(self.location, rawSize(self.handle, self.location));
        return n;
    }

    // Up to `n` bytes from the position; empty at the end of the file.
    pub fn read(self: Self, n: i32) -> Result<bytes, FsError> {
        if (n <= 0) return bytes.fromUtf8("");
        val b = try lift(self.location, rawRead(self.handle, n));
        return b;
    }

    // Every byte from the position to the end.
    pub fn bytes(self: Self) -> Result<bytes, FsError> {
        val b = try lift(self.location, rawReadAll(self.handle));
        return b;
    }

    // The rest of the file as UTF-8 text (`InvalidUtf8` otherwise).
    pub fn text(self: Self) -> Result<string, FsError> {
        val b = try self.bytes();
        val s = try decode(self.location, b);
        return s;
    }

    // The rest of the file in pieces of at most `size` bytes. An error ends the stream.
    pub async iter fn chunks(self: Self, size: i32 = 65536) -> AsyncIter<Result<bytes, FsError>> {
        while (true) {
            val b = try self.read(size);
            if (b.length == 0) break;
            yield b;
        }
    }

    // The rest of the file line by line, `\n` and `\r\n` stripped. A line that is not
    // UTF-8 ends the stream with `InvalidUtf8`, its offset counted from the first
    // line this call read.
    pub async iter fn lines(self: Self) -> AsyncIter<Result<string, FsError>> {
        var consumed = 0l;
        while (true) {
            val raw = try lift(self.location, rawReadLine(self.handle));
            if (raw.length == 0) break;
            val line = stripEol(raw);
            val offset = utf8Offset(line);
            if (offset >= 0l)
                throw FsError.InvalidUtf8(path: self.location, offset: consumed
                    + offset);
            val width: i32 = raw.length;
            consumed = consumed + width.toI64();
            yield line.toUtf8().unwrapOr("");
        }
    }

    // The SHA-256 of the whole file, lowercase hex.
    pub fn hash(self: Self) -> Result<string, FsError> {
        val h = try lift(self.location, rawHash(self.handle));
        return h;
    }

    // Write `b` at the position; answers the number of bytes written.
    pub fn write(self: Self, b: bytes) -> Result<i32, FsError> {
        if (rawReadOnly(self.handle))
            throw FsError.Other(path: self.location, message: "the file is open for reading");
        val n = try lift(self.location, rawWrite(self.handle, b));
        return n;
    }

    // Close the file. Closing twice is harmless; a failure to close is not reported.
    pub fn close(self: Self) -> void {
        val closed = rawClose(self.handle);
    }
}

// Open the file at `path` for reading. A directory is `IsDirectory` on every target.
pub fn open(path: string) -> Result<File, FsError> {
    val h = try lift(path, rawOpen(path));
    return File(location: path, handle: h);
}

// Open the file at `path` for writing: created, or truncated.
pub fn create(path: string) -> Result<File, FsError> {
    val h = try lift(path, rawCreate(path));
    return File(location: path, handle: h);
}

// An `Asset` (`@embed`, decisions 519, 538) as a `File`: the embedded bytes, read
// like a file on disk — no `Result`, the build proved the file exists — and
// closing it is a no-op.
pub fn openAsset(asset: Asset) -> File {
    return File(location: asset.path, handle: memoryHandle(asset.bytes));
}

// ── tests ────────────────────────────────────────────────────────────────────
// (Inline tests are smoke-grade — they require the host filesystem to be
// writable at the host's `tmpdir()`. The lib-test harness runs each
// inline test as a separate process; the temp filenames are seeded with
// `time.nowMillis()` for cross-run uniqueness.)

test "fs.exists is false for a fixed-name path that doesn't exist" {
    val e = exists("/__bp_std_fs_definitely_not_a_real_path_xyz__");
    assert e.negate();
}

test "fs.exists is true for a path of any kind" {
    assert exists("/");
    assert exists("/dev/null");
    val dir = scratchDir();
    writeText([dir, "/file.txt"].join(""), "x");
    assert exists([dir, "/file.txt"].join(""));
    assert exists(dir);
    removeTree(dir);
    assert exists(dir).negate();
}

test "fs.removeTree removes a tree, a file and a link, and a missing path is Ok" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    linkTo("blog", [dir, "/app/linked"].join(""));
    assert removeTree([dir, "/app/linked"].join("")).isOk();
    assert exists([dir, "/app/linked"].join("")).negate();
    assert exists([dir, "/app/blog/page.bp"].join(""));
    assert removeTree([dir, "/app/page.bp"].join("")).isOk();
    assert exists([dir, "/app/page.bp"].join("")).negate();
    assert removeTree([dir, "/app"].join("")).isOk();
    assert exists([dir, "/app"].join("")).negate();
    assert removeTree([dir, "/app"].join("")).isOk();
    assert removeTree(dir).isOk();
    assert exists(dir).negate();
}

test "fs.mkdirRecursive makes a directory with its parents and is Ok on one that is there" {
    val dir = scratchDir();
    val deep = [dir, "/a/b/c"].join("");
    assert mkdirRecursive(deep).isOk();
    assert stat(deep).unwrapOr(
        FileStat(size: 0l, mtime: 0l, isDir: false),
    ).isDir;
    assert mkdirRecursive(deep).isOk();
    writeText([dir, "/file.txt"].join(""), "x");
    assert mkdirRecursive([dir, "/file.txt"].join("")).isError();
    assert mkdirRecursive([dir, "/file.txt/sub"].join("")).isError();
    removeTree(dir);
}

test "fs.list of the host '/' resolves Ok" {
    val r = list("/");
    assert r.isOk();
}

// Internal, test scaffolding: `stat(p)`, or a stat no file has.
fn statOr(p: string) -> FileStat {
    return case stat(p) {
        Ok(s) -> s;
        Error(_) -> FileStat(size: -1l, mtime: -1l, isDir: false);
    };
}

test "fs.stat answers a file's size, a directory's kind and the mtime in epoch milliseconds" {
    val dir = scratchDir();
    writeText([dir, "/five.txt"].join(""), "12345");
    val file = statOr([dir, "/five.txt"].join(""));
    assert file.size == 5l;
    assert file.isDir == false;
    // After 2020-01-01T00:00:00Z and before 2100-01-01T00:00:00Z.
    assert file.mtime > 1577836800000l;
    assert file.mtime < 4102444800000l;
    // Whole seconds on every target (decision 499).
    assert file.mtime % 1000l == 0l;
    assert statOr(dir).isDir;
    assert stat([dir, "/missing.txt"].join("")).isError();
    removeTree(dir);
}

// Internal, test scaffolding: `<dir>/app/page.bp`, `<dir>/app/blog/page.bp`,
// `<dir>/app/blog/notes.md` — the fixture tree every walk/glob test reads.
fn makeFixtureTree(dir: string) -> void {
    mkdir([dir, "/app"].join(""));
    mkdir([dir, "/app/blog"].join(""));
    writeText([dir, "/app/page.bp"].join(""), "root page");
    writeText([dir, "/app/blog/page.bp"].join(""), "blog page");
    writeText([dir, "/app/blog/notes.md"].join(""), "notes");
}

// Internal, test scaffolding: what `walk` answers for the fixture tree when
// its root is spelled `<scratch dir><suffix>` — every spelling of one root has
// to answer the same three relative paths.
fn walkFixture(suffix: string) -> string {
    val dir = scratchDir();
    makeFixtureTree(dir);
    val walked = walk([dir, suffix].join("")).unwrapOr(["<error>"]);
    removeTree(dir);
    return walked.join(",");
}

// Internal, test scaffolding: the same, with the root spelled relative to the
// working directory — `<prefix><path from the cwd to the fixture>`.
fn walkFixtureFromCwd(prefix: string) -> string {
    val dir = scratchDir();
    makeFixtureTree(dir);
    val root = [prefix, relative(workingDir(), dir), "/app"].join("");
    val walked = walk(root).unwrapOr(["<error>"]);
    removeTree(dir);
    return walked.join(",");
}

test "fs.walk lists every regular file relative to the root, sorted" {
    assert walkFixture("/app") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a root with a trailing slash answers the same paths" {
    assert walkFixture("/app/") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a root ending in a dot segment answers the same paths" {
    assert walkFixture("/app/.") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a root with a dot segment inside answers the same paths" {
    assert walkFixture("/./app") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a root with a doubled separator answers the same paths" {
    assert walkFixture("//app//") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a root ending in a parent segment answers the same paths" {
    assert walkFixture("/app/blog/..") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a relative root answers the same paths" {
    assert walkFixtureFromCwd("") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a relative root spelled with a leading dot answers the same paths" {
    assert walkFixtureFromCwd("./") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk follows a link to a file and a link to a directory" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    linkTo("blog", [dir, "/app/linked"].join(""));
    linkTo("page.bp", [dir, "/app/alias.bp"].join(""));
    val walked = walk([dir, "/app"].join("")).unwrapOr(["<error>"]);
    removeTree(dir);
    assert walked.join(",")
        == "alias.bp,blog/notes.md,blog/page.bp,linked/notes.md,linked/page.bp,page.bp";
}

// Internal, test scaffolding: the `Error` of `walk(root)`, `""` when it walked.
fn walkRefusal(root: string) -> string {
    return case walk(root) {
        Ok(_) -> "";
        Error(e) -> describe(e);
    };
}

// Internal, test scaffolding: an `FsError` as one line — the variant, the path
// and the message where it holds one (a dangling link is `Other`, decision 178).
fn describe(e: FsError) -> string {
    return case e {
        FsError.NotFound(p) -> "NotFound " + p;
        FsError.PermissionDenied(p) -> "PermissionDenied " + p;
        FsError.IsDirectory(p) -> "IsDirectory " + p;
        FsError.NotDirectory(p) -> "NotDirectory " + p;
        FsError.AlreadyExists(p) -> "AlreadyExists " + p;
        FsError.InvalidUtf8(p, offset) -> "InvalidUtf8 "
            + p
            + " "
            + offset.toString();
        FsError.Other(p, message) -> message;
    };
}

test "fs.walk of a tree with a dangling link is an Error naming the link" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    linkTo("missing.bp", [dir, "/app/gone.bp"].join(""));
    val refusal = walkRefusal([dir, "/app"].join(""));
    val dotted = walkRefusal([dir, "/app/."].join(""));
    removeTree(dir);
    assert refusal == "fs.walk: dangling link \"gone.bp\"";
    assert dotted == "fs.walk: dangling link \"gone.bp\"";
}

test "fs.walk names the first dangling link in sorted order, by its relative path" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    linkTo("missing.bp", [dir, "/app/zz-gone.bp"].join(""));
    linkTo("missing.md", [dir, "/app/blog/gone.md"].join(""));
    val refusal = walkRefusal([dir, "/app"].join(""));
    removeTree(dir);
    assert refusal == "fs.walk: dangling link \"blog/gone.md\"";
}

test "fs.walk of a regular file is an Error" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    val r = walk([dir, "/app/page.bp"].join(""));
    removeTree(dir);
    assert r.isError();
}

test "fs.walk of a missing root is an Error" {
    val r = walk("/__bp_std_fs_definitely_not_a_real_path_xyz__");
    assert r.isError();
}

test "fs.glob finds a nested file through a double-star pattern" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    val found = glob("**/page.bp", [dir, "/app"].join("")).unwrapOr([]);
    removeTree(dir);
    assert found.join(",") == "blog/page.bp,page.bp";
}

test "fs.glob answers the empty list when nothing matches" {
    val dir = scratchDir();
    val found = glob("*.nothing", dir).unwrapOr(["x"]);
    removeTree(dir);
    assert found.length == 0;
}

// Internal, test scaffolding: the fixture tree plus the names decision 177 is
// about — a dot file and a dot directory, a link to a directory, a link to a
// file and a dangling link, all under `<dir>/app`.
fn makeGlobTree(dir: string) -> void {
    makeFixtureTree(dir);
    mkdir([dir, "/app/.cache"].join(""));
    writeText([dir, "/app/.cache/page.bp"].join(""), "cached");
    writeText([dir, "/app/.hidden.bp"].join(""), "hidden");
    writeText([dir, "/app/blog/.draft.md"].join(""), "draft");
    linkTo("blog", [dir, "/app/linked"].join(""));
    linkTo("page.bp", [dir, "/app/alias.bp"].join(""));
    linkTo("missing.bp", [dir, "/app/gone.bp"].join(""));
}

// Internal, test scaffolding: what `glob(pattern, <dir>/app)` answers over
// `makeGlobTree`, joined by `,`.
fn globbed(pattern: string) -> string {
    val dir = scratchDir();
    makeGlobTree(dir);
    val found = glob(pattern, [dir, "/app"].join("")).unwrapOr(["<error>"]);
    removeTree(dir);
    return found.join(",");
}

test "fs.glob star matches every name but one that starts with a dot" {
    assert globbed("*") == "alias.bp,blog,gone.bp,linked,page.bp";
    assert globbed("*.bp") == "alias.bp,gone.bp,page.bp";
    assert globbed("blog/*") == "blog/notes.md,blog/page.bp";
}

test "fs.glob matches a dot name only when the segment writes the dot" {
    assert globbed(".*") == ".cache,.hidden.bp";
    assert globbed(".hidden.bp") == ".hidden.bp";
    assert globbed(".cache/*.bp") == ".cache/page.bp";
    assert globbed("blog/.*") == "blog/.draft.md";
    assert globbed("?hidden.bp") == "";
    assert globbed("[.]hidden.bp") == "";
    assert globbed("{.hidden,page}.bp") == "page.bp";
}

test "fs.glob double star does not enter a directory that starts with a dot" {
    assert globbed("**/page.bp") == "blog/page.bp,page.bp";
    assert globbed("**/*.md") == "blog/notes.md";
    assert globbed("**/.*") == ".cache,.hidden.bp,blog/.draft.md";
    assert globbed(".cache/**/*.bp") == ".cache/page.bp";
}

test "fs.glob does not descend through a link to a directory" {
    assert globbed("**/notes.md") == "blog/notes.md";
    assert globbed("*/notes.md") == "blog/notes.md";
    assert globbed("l*/notes.md") == "";
    assert globbed("**/*/notes.md") == "blog/notes.md";
}

test "fs.glob goes through a link the pattern names, and lists a link as a name" {
    assert globbed("linked/*.md") == "linked/notes.md";
    assert globbed("linked/**/*.bp") == "linked/page.bp";
    assert globbed("**/linked/*.md") == "linked/notes.md";
    assert globbed("linked") == "linked";
    assert globbed("l*") == "linked";
    assert globbed("gone.bp") == "gone.bp";
}

test "fs.glob final double star is every entry at every depth" {
    assert globbed("**")
        == "alias.bp,blog,blog/notes.md,blog/page.bp,gone.bp,linked,page.bp";
    assert globbed("blog/**") == "blog/notes.md,blog/page.bp";
}

test "fs.glob reads the classes, the alternatives and a trailing slash" {
    assert globbed("blo?/[np]*.md") == "blog/notes.md";
    assert globbed("{blog,nowhere}/page.bp") == "blog/page.bp";
    assert globbed("**/{notes,page}.*") == "blog/notes.md,blog/page.bp,page.bp";
    assert globbed("*/") == "blog";
    assert globbed("./blog//page.bp") == "blog/page.bp";
}

test "fs.glob of a root that does not exist answers the empty list" {
    val found = glob("**/*", "/__bp_std_fs_definitely_not_a_real_path_xyz__");
    assert found.unwrapOr(["x"]).length == 0;
}

// ── FsError, readText and the handle ─────────────────────────────────────────

// Internal, test scaffolding: the variant of an `Error`, `"ok"` for an `Ok`.
fn variantOf<T>(r: Result<T, FsError>) -> string {
    return case r {
        Ok(_) -> "ok";
        Error(e) -> describe(e);
    };
}

test "fs answers the same FsError variant for the same OS error" {
    val dir = scratchDir();
    writeText([dir, "/file.txt"].join(""), "x");
    val missing = [dir, "/missing"].join("");
    val file = [dir, "/file.txt"].join("");
    assert variantOf(readText(missing)) == "NotFound " + missing;
    assert variantOf(readText(dir)) == "IsDirectory " + dir;
    assert variantOf(list(file)) == "NotDirectory " + file;
    assert variantOf(mkdir(dir)) == "AlreadyExists " + dir;
    assert variantOf(mkdir([dir, "/a/b"].join("")))
        == "NotFound " + [dir, "/a/b"].join("");
    assert variantOf(rm(dir)) == "IsDirectory " + dir;
    assert variantOf(open(missing)) == "NotFound " + missing;
    assert variantOf(open(dir)) == "IsDirectory " + dir;
    assert variantOf(create(dir)) == "IsDirectory " + dir;
    removeTree(dir);
}

test "fs.readText of bytes that are not UTF-8 is InvalidUtf8 at the first invalid byte" {
    val dir = scratchDir();
    val path = [dir, "/bad.bin"].join("");
    // "ok", then the first byte of a two-byte sequence, then "z".
    writeBytes(path, bytes
        .fromUtf8("ok")
        .concat(bytes.fromUtf8("é").slice(0, 1))
        .concat(bytes.fromUtf8("z")));
    assert variantOf(readText(path)) == "InvalidUtf8 " + path + " 2";
    assert readBytes(path).isOk();
    // A sequence cut short at the end of the file.
    writeBytes(path, bytes.fromUtf8("é").slice(0, 1));
    assert variantOf(readText(path)) == "InvalidUtf8 " + path + " 0";
    // A well-formed multi-byte file reads back whole.
    writeText(path, "héllo ✓");
    assert readText(path).unwrapOr("") == "héllo ✓";
    removeTree(dir);
}

test "fs.appendText adds to the end and creates the file" {
    val dir = scratchDir();
    val path = [dir, "/log.txt"].join("");
    appendText(path, "a");
    appendText(path, "b");
    assert readText(path).unwrapOr("") == "ab";
    removeTree(dir);
}

// Internal, test scaffolding: the file a failed `open` falls back to.
fn noFile() -> File {
    return File(location: "", handle: memHandle(bytes.fromUtf8("")));
}

test "fs.File writes, then reads bytes, text, a size and a hash" {
    val dir = scratchDir();
    val path = [dir, "/data.txt"].join("");
    val w = create(path).unwrapOr(noFile());
    assert w.write(bytes.fromUtf8("hello ")).unwrapOr(-1) == 6;
    assert w.write(bytes.fromUtf8("world")).unwrapOr(-1) == 5;
    w.close();
    val r = open(path).unwrapOr(w);
    assert r.path() == path;
    assert r.size().unwrapOr(-1l) == 11l;
    assert r.read(5).unwrapOr(bytes.fromUtf8("")).toUtf8().unwrapOr("")
        == "hello";
    assert r.text().unwrapOr("") == " world";
    assert r.read(5).unwrapOr(bytes.fromUtf8("x")).length == 0;
    assert r.hash().unwrapOr("")
        == "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";
    r.close();
    removeTree(dir);
}

test "fs.File's hash leaves the position where it was" {
    val dir = scratchDir();
    val path = [dir, "/pos.txt"].join("");
    val w = create(path).unwrapOr(noFile());
    assert w.write(bytes.fromUtf8("hello world")).unwrapOr(-1) == 11;
    w.close();
    val r = open(path).unwrapOr(w);
    assert r.read(5).unwrapOr(bytes.fromUtf8("")).length == 5;
    assert r.hash().unwrapOr("")
        == "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";
    assert r.text().unwrapOr("") == " world";
    r.close();
    removeTree(dir);
}

// Internal, test scaffolding: take every permission from `path`; whether that
// denies this user anything (root is denied nothing), and give them back.
#[compiler.external(
    .JavaScript("""(() => { require('fs').chmodSync($0, 0); return typeof process.getuid === 'function' ? process.getuid() !== 0 : false })()"""),
    .Erlang("""(fun(__P) -> ok = file:change_mode(__P, 0), string:trim(os:cmd("id -u")) =/= "0" end)($0)"""),
)]
declare fn denyAll(path: string) -> bool;

#[compiler.external(
    .JavaScript("""require('fs').chmodSync($0, 0o700)"""),
    .Erlang("""(fun(__P) -> ok = file:change_mode(__P, 8#700), ok end)($0)"""),
)]
declare fn allowAll(path: string) -> void;

test "fs answers PermissionDenied for an OS permission error" {
    val dir = scratchDir();
    val locked = [dir, "/locked"].join("");
    mkdir(locked);
    writeText([locked, "/f.txt"].join(""), "x");
    val denied = denyAll(locked);
    val listed = variantOf(list(locked));
    val read = variantOf(readText([locked, "/f.txt"].join("")));
    allowAll(locked);
    removeTree(dir);
    // Run as root nothing is denied, and there is nothing to read.
    if (denied) {
        assert listed == "PermissionDenied " + locked;
        assert read == "PermissionDenied " + [locked, "/f.txt"].join("");
    }
}

```

----- BEAM ASSEMBLY -- std/io/fs.S
```erlang
{module, std@io@fs}.
{exports, [{exists, 1}, {readBytes, 1}, {readText, 1}, {writeBytes, 2}, {writeText, 2}, {appendText, 2}, {stat, 1}, {list, 1}, {mkdir, 1}, {mkdirRecursive, 1}, {rm, 1}, {removeTree, 1}, {copy, 2}, {walk, 1}, {glob, 2}, {open, 1}, {create, 1}, {openAsset, 1}, {lift, 2}, {decode, 2}, {'__bp_priv__describe', 1}, {'__bp_priv__fsError', 2}, {'__bp_priv__globbed', 1}, {'__bp_priv__makeFixtureTree', 1}, {'__bp_priv__makeGlobTree', 1}, {'__bp_priv__noFile', 0}, {'__bp_priv__statOr', 1}, {'__bp_priv__variantOf', 1}, {'__bp_priv__walkFixture', 1}, {'__bp_priv__walkFixtureFromCwd', 1}, {'__bp_priv__walkRefusal', 1}]}.
{attributes, []}.
{labels, 798}.
%%% std/io/fs — the file system, cross-backend (decision 540).
%%% 
%%% Reference:
%%%   Rust     — https://doc.rust-lang.org/std/fs/ (`read`, `read_to_string`,
%%%              `File`, `io::ErrorKind`)
%%%   Java     — https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/nio/file/Files.html
%%%   Erlang   — https://www.erlang.org/doc/man/file.html
%%%   Node.js  — https://nodejs.org/api/fs.html
%%% 
%%% Every function that can fail answers `Result<…, FsError>`: the same OS error is
%%% the same `FsError` variant on every target (`ENOENT`, `enoent` → `NotFound`),
%%% and `Other.message` is the host's own text. The whole-file shortcuts
%%% (`readBytes`, `readText`, `writeBytes`, `writeText`, `appendText`), `stat`, and
%%% the directory functions (`exists`, `list`, `mkdir`, `mkdirRecursive`, `rm`,
%%% `removeTree`, `copy`, `walk`, `glob`) are followed by the handle: `open`
%%% and `create` answer a `File`, a `Closeable` closed by the writer with `defer`.
%%% 
%%% The host cells (`raw…`) write `result: true` (decisions 431, 490) and answer
%%% `Result<R, HostError>` — Node's `ENOENT: …`, erlang's `enoent` as its `message` —
%%% and `lift` reads that message as the `FsError` of the path the caller wrote
%%% (decision 486); no cell catches by hand. All operations are synchronous
%%% (`*Sync` on Node, blocking BIFs on Erlang); there is no wasm binding here
%%% (front 164: `wasi:filesystem` behind `needs: [.Filesystem]`).
% The error of every `io.fs` function (decision 540). `path` is the path the
% caller wrote (for `copy`, the source; for `walk`, the root).
% Read the whole file as bytes.
% Node: `readFileSync($0)` copied into a plain `Uint8Array`.
% Erlang: `file:read_file/1`.
% Write `contents` to `path`, creating or truncating.
% Node: `writeFileSync($0, $1)`. Erlang: `file:write_file/2`.
% Append `contents` to `path`, creating it when it is not there.
% Node: `appendFileSync($0, $1)`. Erlang: `file:write_file/3` with `append`.
% The offset of the first byte that starts a sequence that is not UTF-8 (a byte no sequence
% starts with, a sequence cut short, an overlong form, a surrogate, a code point past U+10FFFF),
% or -1 when every byte is part of a valid sequence — the same offset on every target.
% Node: a scan of the bytes. Erlang: `unicode:characters_to_binary/3`, whose `Good` prefix is the offset.
% `line` without its line terminator: one trailing `\n`, and the `\r` before it.
% Node: `subarray`. Erlang: `binary:part/3`.
% The handle of the file at `path`, open for reading. A directory is `isdir` on both hosts
% (Node opens one; the template refuses it). The handle is host-owned and opaque: a `{ fd,
% mem, pos, buf }` object on Node, an io device on Erlang (a stream reads it in its own process).
% The handle of the file at `path`, open for writing: created, or truncated.
% A handle over bytes held in memory — what an `Asset` opens as. The position is a field
% on Node and a `counters` cell on Erlang.
% The size of the file behind `handle`, in bytes. On Erlang it reads `path`.
% Up to `n` bytes (n > 0) from the handle's position; empty at the end.
% Every byte from the handle's position to the end.
% The next line, terminator included; empty at the end.
% The SHA-256 of the whole file behind the handle, lowercase hex — from its first byte,
% whatever the position, which it leaves where it was. On Erlang `file:pread` leaves the
% position undefined (OTP moves it), so the position is read first and restored.
% Write `bytes` at the handle's position; answers how many.
% Close the handle. A failure to close is not reported (a `Closeable`'s `close` answers nothing).
% Write `contents` to `path`, creating or truncating. Reds with the
% host's I/O error message.
% Node: `require('fs').writeFileSync($0, $1)`.
% Erlang: `file:write_file/2`.
% Whether a path exists, of any kind: a regular file, a directory, a
% character or block device (`/dev/null`), a FIFO or a socket. A symbolic
% link is followed — one whose target is missing is `false`, the answer
% every read through it would give.
% Node: `require('fs').existsSync($0)` (a `stat`).
% Erlang: `file:read_file_info/1` (a `stat`; `filelib:is_file/1`, which it
% replaces, answers only regular files and directories, so `/dev/null`
% was `false` on erlang and `true` on commonJS).

{function, exists, 1, 69}.
  {label, 68}.
    {line, [{location, "std@io@fs.erl", 2}]}.
    {func_info, {atom, std@io@fs}, {atom, exists}, 1}.
  {label, 69}.
    {call_only, 1, {f, 63}}.
% List the names of the directory entries at `path` (relative).
% Node: `require('fs').readdirSync($0)`.
% Erlang: `file:list_dir/1` returns `{ok, [string()]}`.
% Create directory at `path`. Use `mkdirRecursive` to create
% intermediate parents.
% Node: `require('fs').mkdirSync($0)`.
% Erlang: `file:make_dir/1`.
% Create the directory at `path` and every missing directory above it. A
% directory that is already there is `Ok` too; a path that exists as anything
% else (a file) is an `Error`. What the snapshot library (`snap`) makes the
% directory of a `.snap` with (decision 391).
% Node: `require('fs').mkdirSync($0, { recursive: true })`.
% Erlang: `filelib:ensure_path/1`.
% Delete the FILE at `path`. A directory — empty or not — is `IsDirectory` on
% both hosts (Node's `ERR_FS_EISDIR`; Erlang's `eperm` is read as `eisdir` after
% a `read_link_info`, so the variant is the same); `removeTree` removes one.
% Node: `require('fs').rmSync($0)`.
% Erlang: `file:delete/1`.
% Copy file from `src` to `dest`. Reds when `src` is missing or
% `dest` already exists (Node's default `copyFileSync` semantics).
% Node: `require('fs').copyFileSync($0, $1)`.
% Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).
% File metadata. Returns a `FileStat { size, mtime, isDir }` on
% success. `mtime` is epoch milliseconds (matching `time.nowMillis()`);
% `size` is in bytes.
% Node: `statSync($0, { bigint: true })`, so `size` and the nanosecond
% `mtimeNs` arrive exact at any size; `mtime` is `mtimeNs` floored to whole
% seconds, × 1000, and both answer decision 319's canonical form (a `number`
% within ±(2^53 − 1), a `BigInt` beyond) — never a `number` rounded past 2^53.
% Erlang: `file:read_file_info/1` returns a `#file_info` record; the
% template projects the `size`, `mtime`, and `type` fields. Its `mtime` is
% whole seconds × 1000. One value on every target: whole seconds (decision 499).
% ── 1.0.10-beta front 01 additions ──────────────────────────────────────────
% Every REGULAR FILE under `root`, recursively, as paths relative to `root`
% with `/` separators, sorted — the same set on both targets (the two hosts
% walk in different orders, so the list is sorted rather than left as found),
% and the same paths however the root is spelled: `dir`, `dir/`, `dir/.`,
% `./dir`, `dir/sub/..`, absolute or relative to the working directory.
% Directories are not listed; a link is followed (a link to a file is listed
% under its own name, a link to a directory is walked). An `Error`: a missing
% or non-directory `root`, a directory under it that cannot be read, and a
% DANGLING link (decision 178) — `fs.walk: dangling link "<relative path>"`,
% the same text on both targets, naming the first one in sorted order.
% Node: `readdirSync(root, { recursive: true })` answers files AND directories
% relative to `root`; the template sorts them, keeps the entries `statSync`
% says are files, and answers the dangling-link `Error` for the first entry
% `statSync` cannot find (`throwIfNoEntry: false`).
% Erlang: the template walks `file:list_dir/1` itself and BUILDS each relative
% path from the names it descended through. It never cuts a prefix off a full
% path: `filelib:fold_files/5` answers full paths `filename:join/2` has
% normalised (`dir/.` + `app` is `dir/app`), so a prefix measured on the root
% as written cut two characters too many when the root ended in `/.`.
% The entries under `root` matching the glob `pattern`, as paths relative to
% `root` with `/` separators, sorted, each once. The pattern is read segment
% by segment, by ONE rule on both targets (decision 177 — the narrower of what
% the two hosts did):
%   - `**` is zero or more directories; a segment with `*`, `?`, `[…]` or
%     `{a,b}` matches the names of one directory; any other segment is a name.
%   - `*` and `**` (and `?`, `[…]`, `{…}`) do NOT match a name that starts
%     with `.` — a segment matches one only when the segment itself starts
%     with the dot (`.*`, `.config/*.json`).
%   - the walk does NOT descend through a link to a directory: `**` and a
%     wildcard segment continue into real directories only. The link is still
%     a NAME — `*` lists it — and a segment that names it (`linked/*.bp`) goes
%     through it, because the pattern wrote it.
%   - the last segment matches an entry of any kind (file, directory, link,
%     dangling or not); a final `**` is every entry at every depth; a trailing
%     `/` keeps real directories only.
% An alternative of `{a,b}` cannot hold a `/` (the pattern is split first). A
% root that does not exist answers `Ok([])`; so does a directory that cannot
% be read. Both cells are the same walk; only the match of ONE segment against
% ONE directory is the host's — `fs.globSync(segment, { cwd })` (Node 22+),
% `filelib:wildcard/2` — with the dot rule applied over its answer, since
% `filelib:wildcard` matches dot names and `globSync` matches `{.a,b}`.
% Remove `path` and everything under it: a file, a link (the link, never its
% target) or a directory tree. A path that is not there is `Ok` too — the
% caller wanted it gone. What a test fixture is cleared with, and what the
% snapshot engine's tests clear their scratch directories with (1.0.11-beta
% front 97).
% Node: `rmSync(path, { recursive: true, force: true })`.
% Erlang: `file:del_dir_r/1`.
% Internal, test scaffolding: a fresh, unique, empty directory under the
% host's tmpdir. Private — every `walk`/`glob` test makes its fixture tree in
% one of these and removes it with `removeTree`, so a run leaves nothing under
% the host's tmpdir.
% Internal, test scaffolding: the working directory (what a relative root is
% read against) and a symbolic link `link` → `target`.
% ── the typed error ──────────────────────────────────────────────────────────
% The `FsError` of `path` a host's failure is (decision 486), read from its code: Node's `ENOENT: …`, erlang's `enoent`.

{function, fsError, 2, 3}.
  {label, 2}.
    {line, [{location, "std@io@fs.erl", 3}]}.
    {func_info, {atom, std@io@fs}, {atom, fsError}, 2}.
  {label, 3}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 70}, [{x, 0}, 5, {atom, std@failure@@HostError}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 70}.
    {call_ext, 1, {extfunc, string, uppercase, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"ENOENT">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 72}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 73}}.
  {label, 72}.
    {move, {atom, true}, {x, 0}}.
  {label, 73}.
    {test, is_eq, {f, 71}, [{x, 0}, {atom, true}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__notfound}, {y, 0}]}}.
    {deallocate, 7}.
    return.
  {label, 71}.
    {move, {literal, <<"EACCES">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 75}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 76}}.
  {label, 75}.
    {move, {atom, true}, {x, 0}}.
  {label, 76}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 77}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"EPERM">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 79}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 80}}.
  {label, 79}.
    {move, {atom, true}, {x, 0}}.
  {label, 80}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {atom, true}, {x, 0}}.
  {label, 78}.
    {test, is_eq, {f, 74}, [{x, 0}, {atom, true}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__permissiondenied}, {y, 0}]}}.
    {deallocate, 7}.
    return.
  {label, 74}.
    {move, {literal, <<"EISDIR">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 82}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 82}.
    {move, {atom, true}, {x, 0}}.
  {label, 83}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 84}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"PATH IS A DIRECTORY">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 86}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 87}}.
  {label, 86}.
    {move, {atom, true}, {x, 0}}.
  {label, 87}.
    {jump, {f, 85}}.
  {label, 84}.
    {move, {atom, true}, {x, 0}}.
  {label, 85}.
    {test, is_eq, {f, 81}, [{x, 0}, {atom, true}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__isdirectory}, {y, 0}]}}.
    {deallocate, 7}.
    return.
  {label, 81}.
    {move, {literal, <<"ENOTDIR">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 89}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 90}}.
  {label, 89}.
    {move, {atom, true}, {x, 0}}.
  {label, 90}.
    {test, is_eq, {f, 88}, [{x, 0}, {atom, true}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__notdirectory}, {y, 0}]}}.
    {deallocate, 7}.
    return.
  {label, 88}.
    {move, {literal, <<"EEXIST">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 92}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 93}}.
  {label, 92}.
    {move, {atom, true}, {x, 0}}.
  {label, 93}.
    {test, is_eq, {f, 91}, [{x, 0}, {atom, true}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__alreadyexists}, {y, 0}]}}.
    {deallocate, 7}.
    return.
  {label, 91}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 94}, [{x, 0}, 5, {atom, std@failure@@HostError}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 94}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__other}, {y, 0}, {x, 0}]}}.
    {deallocate, 7}.
    return.
% A host cell's answer, its failure read as an `FsError` of `path`.

{function, lift, 2, 5}.
  {label, 4}.
    {line, [{location, "std@io@fs.erl", 4}]}.
    {func_info, {atom, std@io@fs}, {atom, lift}, 2}.
  {label, 5}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 96}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 95}}.
  {label, 96}.
    {test, is_tagged_tuple, {f, 97}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 95}}.
  {label, 97}.
    {case_end, {x, 0}}.
  {label, 95}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.
% The text of `b`, or `InvalidUtf8` at the first invalid byte.

{function, decode, 2, 7}.
  {label, 6}.
    {line, [{location, "std@io@fs.erl", 5}]}.
    {func_info, {atom, std@io@fs}, {atom, decode}, 2}.
  {label, 7}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 99}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_ge, {f, 111}, [{y, 2}, {integer, 0}]}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__invalidutf8}, {y, 0}, {y, 2}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
  {label, 111}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 115}}.
    {test, is_tagged_tuple, {f, 112}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 113}}.
  {label, 112}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 113}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
% What `rawWalk` finds under a root: the regular files, and the links whose
% target is missing, both as paths relative to the root, sorted.
% Whether the handle is one over bytes held in memory (an `Asset`'s), which cannot be written.
% ── whole-file shortcuts ─────────────────────────────────────────────────────
% The file's bytes.

{function, readBytes, 1, 9}.
  {label, 8}.
    {line, [{location, "std@io@fs.erl", 6}]}.
    {func_info, {atom, std@io@fs}, {atom, readBytes}, 1}.
  {label, 9}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 126}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 148}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 149}}.
  {label, 148}.
    {deallocate, 4}.
    return.
  {label, 149}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
% The file as UTF-8 text. Bytes that are not UTF-8 are `InvalidUtf8` on every
% target — never node's silent U+FFFD nor erlang's unchecked binary.

{function, readText, 1, 11}.
  {label, 10}.
    {line, [{location, "std@io@fs.erl", 7}]}.
    {func_info, {atom, std@io@fs}, {atom, readText}, 1}.
  {label, 11}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test, is_tagged_tuple, {f, 150}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 151}}.
  {label, 150}.
    {deallocate, 3}.
    return.
  {label, 151}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 7}}.
    {test, is_tagged_tuple, {f, 152}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 153}}.
  {label, 152}.
    {deallocate, 3}.
    return.
  {label, 153}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
% Write `contents` to `path`, creating or truncating.

{function, writeBytes, 2, 13}.
  {label, 12}.
    {line, [{location, "std@io@fs.erl", 8}]}.
    {func_info, {atom, std@io@fs}, {atom, writeBytes}, 2}.
  {label, 13}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 155}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 177}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 178}}.
  {label, 177}.
    {deallocate, 5}.
    return.
  {label, 178}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.

{function, writeText, 2, 15}.
  {label, 14}.
    {line, [{location, "std@io@fs.erl", 9}]}.
    {func_info, {atom, std@io@fs}, {atom, writeText}, 2}.
  {label, 15}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 155}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 179}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 180}}.
  {label, 179}.
    {deallocate, 5}.
    return.
  {label, 180}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.
% Append `contents`, creating the file when it is not there.

{function, appendText, 2, 17}.
  {label, 16}.
    {line, [{location, "std@io@fs.erl", 10}]}.
    {func_info, {atom, std@io@fs}, {atom, appendText}, 2}.
  {label, 17}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 182}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 204}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 205}}.
  {label, 204}.
    {deallocate, 5}.
    return.
  {label, 205}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.
% ── metadata and directories ─────────────────────────────────────────────────

{function, stat, 1, 19}.
  {label, 18}.
    {line, [{location, "std@io@fs.erl", 11}]}.
    {func_info, {atom, std@io@fs}, {atom, stat}, 1}.
  {label, 19}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 207}}.
    {move, {atom, std@io@fs@@FileStat}, {x, 1}}.
    {move, {literal, [size, mtime, isDir]}, {x, 2}}.
    {call, 3, {f, 230}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 240}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 241}}.
  {label, 240}.
    {deallocate, 4}.
    return.
  {label, 241}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, list, 1, 21}.
  {label, 20}.
    {line, [{location, "std@io@fs.erl", 12}]}.
    {func_info, {atom, std@io@fs}, {atom, list}, 1}.
  {label, 21}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 243}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 269}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 270}}.
  {label, 269}.
    {deallocate, 4}.
    return.
  {label, 270}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, mkdir, 1, 23}.
  {label, 22}.
    {line, [{location, "std@io@fs.erl", 13}]}.
    {func_info, {atom, std@io@fs}, {atom, mkdir}, 1}.
  {label, 23}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 272}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 294}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 295}}.
  {label, 294}.
    {deallocate, 4}.
    return.
  {label, 295}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, mkdirRecursive, 1, 25}.
  {label, 24}.
    {line, [{location, "std@io@fs.erl", 14}]}.
    {func_info, {atom, std@io@fs}, {atom, mkdirRecursive}, 1}.
  {label, 25}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 297}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 319}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 320}}.
  {label, 319}.
    {deallocate, 4}.
    return.
  {label, 320}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, rm, 1, 27}.
  {label, 26}.
    {line, [{location, "std@io@fs.erl", 15}]}.
    {func_info, {atom, std@io@fs}, {atom, rm}, 1}.
  {label, 27}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 322}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 348}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 349}}.
  {label, 348}.
    {deallocate, 4}.
    return.
  {label, 349}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, removeTree, 1, 29}.
  {label, 28}.
    {line, [{location, "std@io@fs.erl", 16}]}.
    {func_info, {atom, std@io@fs}, {atom, removeTree}, 1}.
  {label, 29}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 351}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 374}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 375}}.
  {label, 374}.
    {deallocate, 4}.
    return.
  {label, 375}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, copy, 2, 31}.
  {label, 30}.
    {line, [{location, "std@io@fs.erl", 17}]}.
    {func_info, {atom, std@io@fs}, {atom, copy}, 2}.
  {label, 31}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 377}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 399}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 400}}.
  {label, 399}.
    {deallocate, 5}.
    return.
  {label, 400}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.

{function, walk, 1, 33}.
  {label, 32}.
    {line, [{location, "std@io@fs.erl", 18}]}.
    {func_info, {atom, std@io@fs}, {atom, walk}, 1}.
  {label, 33}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 402}}.
    {move, {atom, std@io@fs@@Walked}, {x, 1}}.
    {move, {literal, [files, dangling]}, {x, 2}}.
    {call, 3, {f, 230}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 467}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 468}}.
  {label, 467}.
    {deallocate, 10}.
    return.
  {label, 468}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 470}, [{x, 0}, 3, {atom, std@io@fs@@Walked}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 470}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 469}, [{integer, 0}, {x, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 472}, [{x, 0}, 3, {atom, std@io@fs@@Walked}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 472}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 474}}.
    {test, is_ne_exact, {f, 471}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 477}}.
  {label, 471}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 477}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"fs.walk: dangling link \"">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__other}, {y, 0}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 10}.
    return.
  {label, 469}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 512}, [{x, 0}, 3, {atom, std@io@fs@@Walked}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 512}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 10}.
    return.

{function, glob, 2, 35}.
  {label, 34}.
    {line, [{location, "std@io@fs.erl", 19}]}.
    {func_info, {atom, std@io@fs}, {atom, glob}, 2}.
  {label, 35}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 514}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% The host's handle over embedded bytes: read like a file, never closed on disk.
% ── the handle ───────────────────────────────────────────────────────────────
% An open file (decision 540 (3)). `location` is the path it was opened with and
% `handle` the host's — opaque, never read by a program. Closed by the writer:
% `val f = try fs.open(p); defer f.close();`.
% Open the file at `path` for reading. A directory is `IsDirectory` on every target.

{function, open, 1, 37}.
  {label, 36}.
    {line, [{location, "std@io@fs.erl", 30}]}.
    {func_info, {atom, std@io@fs}, {atom, open}, 1}.
  {label, 37}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 657}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 679}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 680}}.
  {label, 679}.
    {deallocate, 4}.
    return.
  {label, 680}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@File}, {y, 0}, {y, 1}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
% Open the file at `path` for writing: created, or truncated.

{function, create, 1, 39}.
  {label, 38}.
    {line, [{location, "std@io@fs.erl", 31}]}.
    {func_info, {atom, std@io@fs}, {atom, create}, 1}.
  {label, 39}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 682}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 704}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 705}}.
  {label, 704}.
    {deallocate, 4}.
    return.
  {label, 705}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@File}, {y, 0}, {y, 1}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
% An `Asset` (`@embed`, decisions 519, 538) as a `File`: the embedded bytes, read
% like a file on disk — no `Result`, the build proved the file exists — and
% closing it is a no-op.

{function, openAsset, 1, 41}.
  {label, 40}.
    {line, [{location, "std@io@fs.erl", 32}]}.
    {func_info, {atom, std@io@fs}, {atom, openAsset}, 1}.
  {label, 41}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, path}, {x, 1}}.
    {call, 2, {f, 707}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, bytes}, {x, 1}}.
    {call, 2, {f, 707}}.
    {call, 1, {f, 713}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@File}, {y, 1}, {x, 0}]}}.
    {deallocate, 3}.
    return.
% ── tests ────────────────────────────────────────────────────────────────────
% (Inline tests are smoke-grade — they require the host filesystem to be
% writable at the host's `tmpdir()`. The lib-test harness runs each
% inline test as a separate process; the temp filenames are seeded with
% `time.nowMillis()` for cross-run uniqueness.)
% Internal, test scaffolding: `stat(p)`, or a stat no file has.

{function, statOr, 1, 43}.
  {label, 42}.
    {line, [{location, "std@io@fs.erl", 33}]}.
    {func_info, {atom, std@io@fs}, {atom, statOr}, 1}.
  {label, 43}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 19}}.
    {test, is_tagged_tuple, {f, 715}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 714}}.
  {label, 715}.
    {test, is_tagged_tuple, {f, 716}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, false}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FileStat}, {integer, -1}, {integer, -1}, {x, 0}]}}.
    {jump, {f, 714}}.
  {label, 716}.
    {case_end, {x, 0}}.
  {label, 714}.
    {deallocate, 2}.
    return.
% Internal, test scaffolding: `<dir>/app/page.bp`, `<dir>/app/blog/page.bp`,
% `<dir>/app/blog/notes.md` — the fixture tree every walk/glob test reads.

{function, makeFixtureTree, 1, 45}.
  {label, 44}.
    {line, [{location, "std@io@fs.erl", 34}]}.
    {func_info, {atom, std@io@fs}, {atom, makeFixtureTree}, 1}.
  {label, 45}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"/app">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {call, 1, {f, 23}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"/app/blog">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {call, 1, {f, 23}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"/app/page.bp">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"root page">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 15}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"/app/blog/page.bp">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"blog page">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 15}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"/app/blog/notes.md">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"notes">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 15}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 6}.
    return.
% Internal, test scaffolding: what `walk` answers for the fixture tree when
% its root is spelled `<scratch dir><suffix>` — every spelling of one root has
% to answer the same three relative paths.

{function, walkFixture, 1, 47}.
  {label, 46}.
    {line, [{location, "std@io@fs.erl", 35}]}.
    {func_info, {atom, std@io@fs}, {atom, walkFixture}, 1}.
  {label, 47}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 718}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {call, 1, {f, 33}}.
    {test, is_tagged_tuple, {f, 734}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 735}}.
  {label, 734}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"<error>">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 735}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_last, 2, {f, 479}, 5}.
% Internal, test scaffolding: the same, with the root spelled relative to the
% working directory — `<prefix><path from the cwd to the fixture>`.

{function, walkFixtureFromCwd, 1, 49}.
  {label, 48}.
    {line, [{location, "std@io@fs.erl", 36}]}.
    {func_info, {atom, std@io@fs}, {atom, walkFixtureFromCwd}, 1}.
  {label, 49}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 718}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"/app">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {call, 0, {f, 737}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, std@path, relative, 2}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 33}}.
    {test, is_tagged_tuple, {f, 746}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 747}}.
  {label, 746}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"<error>">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 747}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_last, 2, {f, 479}, 8}.
% Internal, test scaffolding: the `Error` of `walk(root)`, `""` when it walked.

{function, walkRefusal, 1, 51}.
  {label, 50}.
    {line, [{location, "std@io@fs.erl", 37}]}.
    {func_info, {atom, std@io@fs}, {atom, walkRefusal}, 1}.
  {label, 51}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 33}}.
    {test, is_tagged_tuple, {f, 749}, [{x, 0}, 2, {atom, ok}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 748}}.
  {label, 749}.
    {test, is_tagged_tuple, {f, 750}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 53}}.
    {jump, {f, 748}}.
  {label, 750}.
    {case_end, {x, 0}}.
  {label, 748}.
    {deallocate, 2}.
    return.
% Internal, test scaffolding: an `FsError` as one line — the variant, the path
% and the message where it holds one (a dangling link is `Other`, decision 178).

{function, describe, 1, 53}.
  {label, 52}.
    {line, [{location, "std@io@fs.erl", 38}]}.
    {func_info, {atom, std@io@fs}, {atom, describe}, 1}.
  {label, 53}.
    {allocate, 16, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 752}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__notfound}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"NotFound ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 509}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 751}}.
  {label, 752}.
    {test, is_tagged_tuple, {f, 753}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__permissiondenied}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"PermissionDenied ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 509}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 751}}.
  {label, 753}.
    {test, is_tagged_tuple, {f, 754}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__isdirectory}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"IsDirectory ">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 509}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 751}}.
  {label, 754}.
    {test, is_tagged_tuple, {f, 755}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__notdirectory}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"NotDirectory ">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 509}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 751}}.
  {label, 755}.
    {test, is_tagged_tuple, {f, 756}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__alreadyexists}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 9}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, <<"AlreadyExists ">>}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 509}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 751}}.
  {label, 756}.
    {test, is_tagged_tuple, {f, 757}, [{x, 0}, 3, {atom, std@io@fs@@FsError__v__invalidutf8}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 11}}.
    {get_tuple_element, {x, 0}, 2, {x, 1}}.
    {move, {x, 1}, {y, 12}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {literal, <<"InvalidUtf8 ">>}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 509}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 751}}.
  {label, 757}.
    {test, is_tagged_tuple, {f, 758}, [{x, 0}, 3, {atom, std@io@fs@@FsError__v__other}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 14}}.
    {get_tuple_element, {x, 0}, 2, {x, 1}}.
    {move, {x, 1}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {jump, {f, 751}}.
  {label, 758}.
    {case_end, {x, 0}}.
  {label, 751}.
    {deallocate, 16}.
    return.
% Internal, test scaffolding: the fixture tree plus the names decision 177 is
% about — a dot file and a dot directory, a link to a directory, a link to a
% file and a dangling link, all under `<dir>/app`.

{function, makeGlobTree, 1, 55}.
  {label, 54}.
    {line, [{location, "std@io@fs.erl", 39}]}.
    {func_info, {atom, std@io@fs}, {atom, makeGlobTree}, 1}.
  {label, 55}.
    {allocate, 14, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"/app/.cache">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {call, 1, {f, 23}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"/app/.cache/page.bp">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cached">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 15}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"/app/.hidden.bp">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"hidden">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 15}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"/app/blog/.draft.md">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"draft">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 15}}.
    {move, {literal, <<"blog">>}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"/app/linked">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call, 2, {f, 760}}.
    {move, {literal, <<"page.bp">>}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"/app/alias.bp">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {call, 2, {f, 760}}.
    {move, {literal, <<"missing.bp">>}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, <<"/app/gone.bp">>}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call, 2, {f, 760}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 14}.
    return.
% Internal, test scaffolding: what `glob(pattern, <dir>/app)` answers over
% `makeGlobTree`, joined by `,`.

{function, globbed, 1, 57}.
  {label, 56}.
    {line, [{location, "std@io@fs.erl", 40}]}.
    {func_info, {atom, std@io@fs}, {atom, globbed}, 1}.
  {label, 57}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 718}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 55}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"/app">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 479}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 35}}.
    {test, is_tagged_tuple, {f, 769}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 770}}.
  {label, 769}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"<error>">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 770}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_last, 2, {f, 479}, 7}.
% ── FsError, readText and the handle ─────────────────────────────────────────
% Internal, test scaffolding: the variant of an `Error`, `"ok"` for an `Ok`.

{function, variantOf, 1, 59}.
  {label, 58}.
    {line, [{location, "std@io@fs.erl", 41}]}.
    {func_info, {atom, std@io@fs}, {atom, variantOf}, 1}.
  {label, 59}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 772}, [{x, 0}, 2, {atom, ok}]}.
    {move, {literal, <<"ok">>}, {x, 0}}.
    {jump, {f, 771}}.
  {label, 772}.
    {test, is_tagged_tuple, {f, 773}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 53}}.
    {jump, {f, 771}}.
  {label, 773}.
    {case_end, {x, 0}}.
  {label, 771}.
    {deallocate, 2}.
    return.
% Internal, test scaffolding: the file a failed `open` falls back to.

{function, noFile, 0, 61}.
  {label, 60}.
    {line, [{location, "std@io@fs.erl", 42}]}.
    {func_info, {atom, std@io@fs}, {atom, noFile}, 0}.
  {label, 61}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {call, 1, {f, 775}}.
    {call, 1, {f, 713}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@File}, {y, 0}, {x, 0}]}}.
    {deallocate, 2}.
    return.
% Internal, test scaffolding: take every permission from `path`; whether that
% denies this user anything (root is denied nothing), and give them back.

{function, '__bp_priv__describe', 1, 777}.
  {label, 776}.
    {line, [{location, "std@io@fs.erl", 43}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__describe'}, 1}.
  {label, 777}.
    {call_only, 1, {f, 53}}.

{function, '__bp_priv__fsError', 2, 779}.
  {label, 778}.
    {line, [{location, "std@io@fs.erl", 44}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__fsError'}, 2}.
  {label, 779}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__globbed', 1, 781}.
  {label, 780}.
    {line, [{location, "std@io@fs.erl", 45}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__globbed'}, 1}.
  {label, 781}.
    {call_only, 1, {f, 57}}.

{function, '__bp_priv__makeFixtureTree', 1, 783}.
  {label, 782}.
    {line, [{location, "std@io@fs.erl", 46}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__makeFixtureTree'}, 1}.
  {label, 783}.
    {call_only, 1, {f, 45}}.

{function, '__bp_priv__makeGlobTree', 1, 785}.
  {label, 784}.
    {line, [{location, "std@io@fs.erl", 47}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__makeGlobTree'}, 1}.
  {label, 785}.
    {call_only, 1, {f, 55}}.

{function, '__bp_priv__noFile', 0, 787}.
  {label, 786}.
    {line, [{location, "std@io@fs.erl", 48}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__noFile'}, 0}.
  {label, 787}.
    {call_only, 0, {f, 61}}.

{function, '__bp_priv__statOr', 1, 789}.
  {label, 788}.
    {line, [{location, "std@io@fs.erl", 49}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__statOr'}, 1}.
  {label, 789}.
    {call_only, 1, {f, 43}}.

{function, '__bp_priv__variantOf', 1, 791}.
  {label, 790}.
    {line, [{location, "std@io@fs.erl", 50}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__variantOf'}, 1}.
  {label, 791}.
    {call_only, 1, {f, 59}}.

{function, '__bp_priv__walkFixture', 1, 793}.
  {label, 792}.
    {line, [{location, "std@io@fs.erl", 51}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__walkFixture'}, 1}.
  {label, 793}.
    {call_only, 1, {f, 47}}.

{function, '__bp_priv__walkFixtureFromCwd', 1, 795}.
  {label, 794}.
    {line, [{location, "std@io@fs.erl", 52}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__walkFixtureFromCwd'}, 1}.
  {label, 795}.
    {call_only, 1, {f, 49}}.

{function, '__bp_priv__walkRefusal', 1, 797}.
  {label, 796}.
    {line, [{location, "std@io@fs.erl", 53}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__walkRefusal'}, 1}.
  {label, 797}.
    {call_only, 1, {f, 51}}.

{function, '__bp_tpl_0', 1, 63}.
  {label, 62}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_0'}, 1}.
  {label, 63}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_file_info, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 67}, [{x, 0}]}.
    {test, test_arity, {f, 67}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 67}, [{x, 0}, {atom, ok}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 67}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1-t/1-fun-0-', 1, 103}.
  {label, 102}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 1}.
  {label, 103}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {move, {atom, utf8}, {x, 2}}.
    {call_ext, 3, {extfunc, unicode, characters_to_binary, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 107}, [{x, 0}]}.
    {jump, {f, 108}}.
  {label, 108}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 107}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 109}, [{x, 0}]}.
    {test, test_arity, {f, 109}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 109}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, byte_size, 1}, 5}.
  {label, 109}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 110}, [{x, 0}]}.
    {test, test_arity, {f, 110}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 110}, [{x, 0}, {atom, incomplete}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, byte_size, 1}, 5}.
  {label, 110}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_1', 1, 99}.
  {label, 98}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_1'}, 1}.
  {label, 99}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 103}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_2-t/1-fun-0-', 1, 119}.
  {label, 118}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_2-t/1-fun-0-'}, 1}.
  {label, 119}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 123}, [{x, 0}]}.
    {jump, {f, 124}}.
  {label, 124}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 123}.
    {move, {literal, {error, <<"Bytes.toUtf8: not valid UTF-8">>}}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_2', 1, 115}.
  {label, 114}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_2'}, 1}.
  {label, 115}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 119}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_3-t/1-fun-0-', 1, 132}.
  {label, 131}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_3-t/1-fun-0-'}, 1}.
  {label, 132}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_file, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 136}, [{x, 0}]}.
    {test, test_arity, {f, 136}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 136}, [{x, 0}, {atom, ok}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 136}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 137}, [{x, 0}]}.
    {test, test_arity, {f, 137}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 137}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 137}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_3', 1, 126}.
  {label, 125}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_3'}, 1}.
  {label, 126}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 129}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 132}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 139}, [{x, 0}]}.
    {test, test_arity, {f, 139}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 139}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 138}}.
  {label, 139}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 140}, [{x, 0}]}.
    {test, test_arity, {f, 140}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 140}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 138}}.
  {label, 140}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 138}}.
  {label, 138}.
    {jump, {f, 130}}.
  {label, 129}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 145}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 144}}.
  {label, 145}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 146}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 144}}.
  {label, 146}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 147}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 144}}.
  {label, 147}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 144}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 142}}.
  {label, 142}.
  {label, 130}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_4-t/2-fun-0-', 2, 161}.
  {label, 160}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_4-t/2-fun-0-'}, 2}.
  {label, 161}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, file, write_file, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 165}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 165}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 166}, [{x, 0}]}.
    {test, test_arity, {f, 166}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 166}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 166}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_4', 2, 155}.
  {label, 154}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_4'}, 2}.
  {label, 155}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {'try', {y, 12}, {f, 158}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 161}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 7}}.
    {try_end, {y, 12}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 168}, [{x, 0}]}.
    {test, test_arity, {f, 168}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 168}, [{x, 0}, {atom, ok}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 167}}.
  {label, 168}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 169}, [{x, 0}]}.
    {test, test_arity, {f, 169}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 169}, [{x, 0}, {atom, error}]}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 10}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 167}}.
  {label, 169}.
    {move, {y, 7}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 5}}.
    {jump, {f, 167}}.
  {label, 167}.
    {jump, {f, 159}}.
  {label, 158}.
    {try_case, {y, 12}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 174}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 10}}.
    {jump, {f, 173}}.
  {label, 174}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 175}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 10}}.
    {jump, {f, 173}}.
  {label, 175}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 176}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 10}}.
    {jump, {f, 173}}.
  {label, 176}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 173}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 171}}.
  {label, 171}.
  {label, 159}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_5-t/2-fun-0-', 2, 188}.
  {label, 187}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_5-t/2-fun-0-'}, 2}.
  {label, 188}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {literal, [append]}, {x, 2}}.
    {call_ext, 3, {extfunc, file, write_file, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 192}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 192}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 193}, [{x, 0}]}.
    {test, test_arity, {f, 193}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 193}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 193}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_5', 2, 182}.
  {label, 181}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_5'}, 2}.
  {label, 182}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {'try', {y, 12}, {f, 185}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 188}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 7}}.
    {try_end, {y, 12}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 195}, [{x, 0}]}.
    {test, test_arity, {f, 195}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 195}, [{x, 0}, {atom, ok}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 194}}.
  {label, 195}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 196}, [{x, 0}]}.
    {test, test_arity, {f, 196}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 196}, [{x, 0}, {atom, error}]}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 10}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 194}}.
  {label, 196}.
    {move, {y, 7}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 5}}.
    {jump, {f, 194}}.
  {label, 194}.
    {jump, {f, 186}}.
  {label, 185}.
    {try_case, {y, 12}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 201}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 10}}.
    {jump, {f, 200}}.
  {label, 201}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 202}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 10}}.
    {jump, {f, 200}}.
  {label, 202}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 203}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 10}}.
    {jump, {f, 200}}.
  {label, 203}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 200}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 198}}.
  {label, 198}.
  {label, 186}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_6-t/1-fun-0-', 1, 213}.
  {label, 212}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_6-t/1-fun-0-'}, 1}.
  {label, 213}.
    {allocate, 13, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, [{time, posix}]}, {x, 1}}.
    {call_ext, 2, {extfunc, file, read_file_info, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 217}, [{x, 0}]}.
    {test, test_arity, {f, 217}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 217}, [{x, 0}, {atom, ok}]}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 217}, [{x, 0}]}.
    {test, test_arity, {f, 217}, [{x, 0}, 14]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {get_tuple_element, {x, 0}, 2, {y, 9}}.
    {get_tuple_element, {x, 0}, 5, {y, 10}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 217}, [{x, 0}, {atom, file_info}]}.
    {move, {y, 8}, {y, 0}}.
    {move, {y, 9}, {y, 1}}.
    {move, {y, 10}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1000}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '*', 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, directory}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 12}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, size}, {y, 0}, {atom, mtime}, {y, 11}, {atom, isDir}, {y, 12}]}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 11}]}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 217}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 218}, [{x, 0}]}.
    {test, test_arity, {f, 218}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 218}, [{x, 0}, {atom, error}]}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 218}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_6', 1, 207}.
  {label, 206}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_6'}, 1}.
  {label, 207}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 210}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 213}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 220}, [{x, 0}]}.
    {test, test_arity, {f, 220}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 220}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 219}}.
  {label, 220}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 221}, [{x, 0}]}.
    {test, test_arity, {f, 221}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 221}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 219}}.
  {label, 221}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 219}}.
  {label, 219}.
    {jump, {f, 211}}.
  {label, 210}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 226}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 225}}.
  {label, 226}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 227}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 225}}.
  {label, 227}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 228}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 225}}.
  {label, 228}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 225}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 223}}.
  {label, 223}.
  {label, 211}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_adopt', 3, 230}.
  {label, 229}.
    {line, [{location, "std@io@fs.erl", 12}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_adopt'}, 3}.
  {label, 230}.
    {test, is_map, {f, 235}, [{x, 0}]}.
    {allocate, 1, 3}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 232}}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_tuple, 1}, 1}.
  {label, 235}.
    {test, is_list, {f, 236}, [{x, 0}]}.
    {call_only, 3, {f, 234}}.
  {label, 236}.
    {test, is_tagged_tuple, {f, 237}, [{x, 0}, 2, {atom, ok}]}.
    {allocate, 0, 3}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {call, 3, {f, 230}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 0}]}}.
    {deallocate, 0}.
    return.
  {label, 237}.
    return.

{function, '-bp_adopt_fields-', 2, 232}.
  {label, 231}.
    {line, [{location, "std@io@fs.erl", 12}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_adopt_fields-'}, 2}.
  {label, 232}.
    {test, is_nonempty_list, {f, 238}, [{x, 0}]}.
    {allocate, 2, 2}.
    {move, {x, 1}, {y, 1}}.
    {get_list, {x, 0}, {x, 0}, {y, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_ext, 3, {extfunc, maps, get, 3}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 232}}.
    {test_heap, 2, 1}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 238}.
    {move, nil, {x, 0}}.
    return.

{function, '-bp_adopt_each-', 3, 234}.
  {label, 233}.
    {line, [{location, "std@io@fs.erl", 12}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_adopt_each-'}, 3}.
  {label, 234}.
    {test, is_nonempty_list, {f, 239}, [{x, 0}]}.
    {allocate, 3, 3}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {get_list, {x, 0}, {x, 0}, {y, 0}}.
    {call, 3, {f, 230}}.
    {move, {y, 0}, {x, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call, 3, {f, 234}}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 239}.
    {move, nil, {x, 0}}.
    return.

{function, '__bp_tpl_7-t/1-fun-0-', 1, 249}.
  {label, 248}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_7-t/1-fun-0-'}, 1}.
  {label, 249}.
    {allocate, 9, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, list_dir, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 253}, [{x, 0}]}.
    {test, test_arity, {f, 253}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 253}, [{x, 0}, {atom, ok}]}.
    {move, {y, 4}, {y, 0}}.
    {move, nil, {y, 5}}.
    {move, {y, 0}, {y, 6}}.
  {label, 255}.
    {move, {y, 6}, {x, 0}}.
    {test, is_nonempty_list, {f, 256}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 7}, {y, 6}}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 2, 0}.
    {put_list, {y, 8}, {y, 5}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 255}}.
  {label, 256}.
    {move, {y, 6}, {x, 0}}.
    {test, is_nil, {f, 257}, [{x, 0}]}.
    {jump, {f, 254}}.
  {label, 257}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 254}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 6}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 253}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 258}, [{x, 0}]}.
    {test, test_arity, {f, 258}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 258}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 258}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_7', 1, 243}.
  {label, 242}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_7'}, 1}.
  {label, 243}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 246}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 249}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 260}, [{x, 0}]}.
    {test, test_arity, {f, 260}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 260}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 259}}.
  {label, 260}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 261}, [{x, 0}]}.
    {test, test_arity, {f, 261}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 261}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 259}}.
  {label, 261}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 259}}.
  {label, 259}.
    {jump, {f, 247}}.
  {label, 246}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 266}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 265}}.
  {label, 266}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 267}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 265}}.
  {label, 267}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 268}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 265}}.
  {label, 268}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 265}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 263}}.
  {label, 263}.
  {label, 247}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_8-t/1-fun-0-', 1, 278}.
  {label, 277}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_8-t/1-fun-0-'}, 1}.
  {label, 278}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, make_dir, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 282}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 282}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 283}, [{x, 0}]}.
    {test, test_arity, {f, 283}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 283}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 283}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_8', 1, 272}.
  {label, 271}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_8'}, 1}.
  {label, 272}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 275}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 278}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 285}, [{x, 0}]}.
    {test, test_arity, {f, 285}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 285}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 284}}.
  {label, 285}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 286}, [{x, 0}]}.
    {test, test_arity, {f, 286}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 286}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 284}}.
  {label, 286}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 284}}.
  {label, 284}.
    {jump, {f, 276}}.
  {label, 275}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 291}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 290}}.
  {label, 291}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 292}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 290}}.
  {label, 292}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 293}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 290}}.
  {label, 293}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 290}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 288}}.
  {label, 288}.
  {label, 276}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_9-t/1-fun-0-', 1, 303}.
  {label, 302}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_9-t/1-fun-0-'}, 1}.
  {label, 303}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, filelib, ensure_path, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 307}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 307}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 308}, [{x, 0}]}.
    {test, test_arity, {f, 308}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 308}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 308}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_9', 1, 297}.
  {label, 296}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_9'}, 1}.
  {label, 297}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 300}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 303}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 310}, [{x, 0}]}.
    {test, test_arity, {f, 310}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 310}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 309}}.
  {label, 310}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 311}, [{x, 0}]}.
    {test, test_arity, {f, 311}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 311}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 309}}.
  {label, 311}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 309}}.
  {label, 309}.
    {jump, {f, 301}}.
  {label, 300}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 316}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 315}}.
  {label, 316}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 317}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 315}}.
  {label, 317}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 318}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 315}}.
  {label, 318}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 315}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 313}}.
  {label, 313}.
  {label, 301}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_10-t/1-fun-0-', 1, 328}.
  {label, 327}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_10-t/1-fun-0-'}, 1}.
  {label, 328}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_link_info, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 332}, [{x, 0}]}.
    {test, test_arity, {f, 332}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 332}, [{x, 0}, {atom, ok}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {bif, element, {f, 332}, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, directory}, {x, 1}}.
    {test, is_eq_exact, {f, 332}, [{x, 0}, {x, 1}]}.
    {jump, {f, 333}}.
  {label, 333}.
    {move, {literal, {error, eisdir}}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 332}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, delete, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 336}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 336}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 337}, [{x, 0}]}.
    {test, test_arity, {f, 337}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 337}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 337}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_10', 1, 322}.
  {label, 321}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_10'}, 1}.
  {label, 322}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 325}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 328}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 339}, [{x, 0}]}.
    {test, test_arity, {f, 339}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 339}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 338}}.
  {label, 339}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 340}, [{x, 0}]}.
    {test, test_arity, {f, 340}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 340}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 338}}.
  {label, 340}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 338}}.
  {label, 338}.
    {jump, {f, 326}}.
  {label, 325}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 345}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 344}}.
  {label, 345}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 346}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 344}}.
  {label, 346}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 347}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 344}}.
  {label, 347}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 344}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 342}}.
  {label, 342}.
  {label, 326}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_11-t/1-fun-0-', 1, 357}.
  {label, 356}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_11-t/1-fun-0-'}, 1}.
  {label, 357}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, del_dir_r, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 361}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 361}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 362}, [{x, 0}, {literal, {error, enoent}}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 362}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 363}, [{x, 0}]}.
    {test, test_arity, {f, 363}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 363}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 363}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_11', 1, 351}.
  {label, 350}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_11'}, 1}.
  {label, 351}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 354}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 357}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 365}, [{x, 0}]}.
    {test, test_arity, {f, 365}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 365}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 364}}.
  {label, 365}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 366}, [{x, 0}]}.
    {test, test_arity, {f, 366}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 366}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 364}}.
  {label, 366}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 364}}.
  {label, 364}.
    {jump, {f, 355}}.
  {label, 354}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 371}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 370}}.
  {label, 371}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 372}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 370}}.
  {label, 372}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 373}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 370}}.
  {label, 373}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 370}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 368}}.
  {label, 368}.
  {label, 355}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_12-t/2-fun-0-', 2, 383}.
  {label, 382}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_12-t/2-fun-0-'}, 2}.
  {label, 383}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, file, copy, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 387}, [{x, 0}]}.
    {test, test_arity, {f, 387}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 387}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 387}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 388}, [{x, 0}]}.
    {test, test_arity, {f, 388}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 388}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 388}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_12', 2, 377}.
  {label, 376}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_12'}, 2}.
  {label, 377}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {'try', {y, 12}, {f, 380}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 383}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 7}}.
    {try_end, {y, 12}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 390}, [{x, 0}]}.
    {test, test_arity, {f, 390}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 390}, [{x, 0}, {atom, ok}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 389}}.
  {label, 390}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 391}, [{x, 0}]}.
    {test, test_arity, {f, 391}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 391}, [{x, 0}, {atom, error}]}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 10}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 389}}.
  {label, 391}.
    {move, {y, 7}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 5}}.
    {jump, {f, 389}}.
  {label, 389}.
    {jump, {f, 381}}.
  {label, 380}.
    {try_case, {y, 12}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 396}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 10}}.
    {jump, {f, 395}}.
  {label, 396}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 397}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 10}}.
    {jump, {f, 395}}.
  {label, 397}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 398}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 10}}.
    {jump, {f, 395}}.
  {label, 398}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 395}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 393}}.
  {label, 393}.
  {label, 381}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_13---t/1-fun-0--fun-1--fun-2-', 5, 427}.
  {label, 426}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_13---t/1-fun-0--fun-1--fun-2-'}, 5}.
  {label, 427}.
    {allocate, 12, 5}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 0}}.
    {move, {x, 3}, {y, 1}}.
    {move, {x, 4}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 3}}.
    {jump, {f, 431}}.
  {label, 431}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 433}, [{x, 0}, nil]}.
    {move, {y, 6}, {y, 8}}.
    {jump, {f, 432}}.
  {label, 433}.
    {move, {literal, [47]}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 8}}.
    {jump, {f, 432}}.
  {label, 432}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 436}}.
  {label, 436}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_file_info, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 438}, [{x, 0}]}.
    {test, test_arity, {f, 438}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 438}, [{x, 0}, {atom, ok}]}.
    {move, {y, 10}, {y, 5}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {bif, element, {f, 438}, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {move, {atom, directory}, {x, 1}}.
    {test, is_eq_exact, {f, 438}, [{x, 0}, {x, 1}]}.
    {jump, {f, 439}}.
  {label, 439}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {move, {y, 2}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 12}.
    return.
  {label, 438}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 440}, [{x, 0}]}.
    {test, test_arity, {f, 440}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 440}, [{x, 0}, {atom, ok}]}.
    {move, {y, 10}, {y, 5}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {bif, element, {f, 440}, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {move, {atom, regular}, {x, 1}}.
    {test, is_eq_exact, {f, 440}, [{x, 0}, {x, 1}]}.
    {jump, {f, 441}}.
  {label, 441}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, file}, {y, 11}]}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 2, 0}.
    {put_list, {y, 11}, {y, 7}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 440}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 442}, [{x, 0}]}.
    {test, test_arity, {f, 442}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 442}, [{x, 0}, {atom, ok}]}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 442}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 443}, [{x, 0}, {literal, {error, enoent}}]}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, dangling}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 2, 0}.
    {put_list, {y, 9}, {y, 7}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 443}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 444}, [{x, 0}]}.
    {test, test_arity, {f, 444}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 444}, [{x, 0}, {atom, error}]}.
    {move, {y, 10}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 12}.
  {label, 444}.
    {move, {y, 8}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_13--t/1-fun-0--fun-1-', 3, 420}.
  {label, 419}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_13--t/1-fun-0--fun-1-'}, 3}.
  {label, 420}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {x, 2}, {y, 4}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 420}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, file, list_dir, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 424}, [{x, 0}]}.
    {test, test_arity, {f, 424}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 424}, [{x, 0}, {atom, error}]}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 9}.
  {label, 424}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 425}, [{x, 0}]}.
    {test, test_arity, {f, 425}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 425}, [{x, 0}, {atom, ok}]}.
    {move, {y, 7}, {y, 1}}.
    {test_heap, {alloc, [{words, 3}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 427}, 1, 0, {x, 0}, {list, [{y, 2}, {y, 3}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_ext_last, 3, {extfunc, lists, foldl, 3}, 9}.
  {label, 425}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_13-t/1-fun-0-', 1, 408}.
  {label, 407}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_13-t/1-fun-0-'}, 1}.
  {label, 408}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 412}}.
  {label, 412}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, filelib, is_dir, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 414}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_file_info, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 416}, [{x, 0}]}.
    {test, test_arity, {f, 416}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 416}, [{x, 0}, {atom, ok}]}.
    {move, {atom, enotdir}, {y, 5}}.
    {jump, {f, 415}}.
  {label, 416}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 417}, [{x, 0}]}.
    {test, test_arity, {f, 417}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 417}, [{x, 0}, {atom, error}]}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 1}, {y, 5}}.
    {jump, {f, 415}}.
  {label, 417}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 415}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 5}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 414}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 418}, [{x, 0}, {atom, true}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 420}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 446}}.
  {label, 446}.
    {move, {y, 0}, {x, 0}}.
    {move, nil, {x, 1}}.
    {move, nil, {x, 2}}.
    {move, {y, 1}, {x, 3}}.
    {call_fun, 3}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 448}}.
  {label, 448}.
    {move, nil, {y, 4}}.
    {move, {y, 0}, {y, 5}}.
  {label, 450}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nonempty_list, {f, 451}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 6}, {y, 5}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 450}, [{x, 0}]}.
    {test, test_arity, {f, 450}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 450}, [{x, 0}, {atom, file}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, {y, 4}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 450}}.
  {label, 451}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nil, {f, 452}, [{x, 0}]}.
    {jump, {f, 449}}.
  {label, 452}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 449}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, sort, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, nil, {y, 5}}.
    {move, {y, 0}, {y, 6}}.
  {label, 454}.
    {move, {y, 6}, {x, 0}}.
    {test, is_nonempty_list, {f, 455}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 7}, {y, 6}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 454}, [{x, 0}]}.
    {test, test_arity, {f, 454}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 454}, [{x, 0}, {atom, dangling}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, {y, 5}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 454}}.
  {label, 455}.
    {move, {y, 6}, {x, 0}}.
    {test, is_nil, {f, 456}, [{x, 0}]}.
    {jump, {f, 453}}.
  {label, 456}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 453}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, sort, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, files}, {y, 4}, {atom, dangling}, {y, 5}]}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 418}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_13', 1, 402}.
  {label, 401}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_13'}, 1}.
  {label, 402}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 405}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 408}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 458}, [{x, 0}]}.
    {test, test_arity, {f, 458}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 458}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 457}}.
  {label, 458}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 459}, [{x, 0}]}.
    {test, test_arity, {f, 459}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 459}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 457}}.
  {label, 459}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 457}}.
  {label, 457}.
    {jump, {f, 406}}.
  {label, 405}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 464}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 463}}.
  {label, 464}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 465}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 463}}.
  {label, 465}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 466}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 463}}.
  {label, 466}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 463}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 461}}.
  {label, 461}.
  {label, 406}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '-bp_at-', 2, 474}.
  {label, 473}.
    {line, [{location, "std@io@fs.erl", 19}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_at-'}, 2}.
  {label, 474}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 476}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 475}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 476}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 475}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 475}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 481}.
  {label, 480}.
    {line, [{location, "std@io@fs.erl", 19}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_print'}, 1}.
  {label, 481}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 485}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 485}.
  {label, 484}.
    {line, [{location, "std@io@fs.erl", 19}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_show_top-'}, 1}.
  {label, 485}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 483}}.

{function, '-bp_show_elem-', 1, 487}.
  {label, 486}.
    {line, [{location, "std@io@fs.erl", 19}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_show_elem-'}, 1}.
  {label, 487}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 483}}.

{function, '__bp_show', 2, 483}.
  {label, 482}.
    {line, [{location, "std@io@fs.erl", 19}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_show'}, 2}.
  {label, 483}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 495}, [{x, 0}]}.
    {test, is_eq, {f, 494}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 494}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 495}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 496}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 487}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 496}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 498}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 497}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 497}, [{x, 0}]}.
    {test, is_ne_exact, {f, 497}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 497}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 497}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 502}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 503}}.
  {label, 502}.
    {test, is_eq_exact, {f, 499}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 503}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 483}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 497}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 487}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 498}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 500}, [{x, 0}]}.
    {test, is_ne_exact, {f, 500}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 500}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 501}, [{x, 0}, {atom, undefined}]}.
  {label, 499}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 489}, 2}.
  {label, 500}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 501}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 489}.
  {label, 488}.
    {line, [{location, "std@io@fs.erl", 19}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tagged'}, 2}.
  {label, 489}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 504}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 504}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 504}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 505}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 491}, 3}.
  {label, 505}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 491}.
  {label, 490}.
    {line, [{location, "std@io@fs.erl", 19}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_render'}, 1}.
  {label, 491}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 506}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 506}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 507}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 507}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 493}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 493}.
  {label, 492}.
    {line, [{location, "std@io@fs.erl", 19}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_render_pair-'}, 1}.
  {label, 493}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 483}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 509}.
  {label, 508}.
    {line, [{location, "std@io@fs.erl", 19}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_stringify-'}, 1}.
  {label, 509}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 510}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 510}.
    {test, is_integer, {f, 511}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 511}.
    {call, 1, {f, 485}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-bp_join-', 2, 479}.
  {label, 478}.
    {line, [{location, "std@io@fs.erl", 19}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_join-'}, 2}.
  {label, 479}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 509}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '__bp_tpl_14--t/2-fun-0--fun-1-', 1, 537}.
  {label, 536}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14--t/2-fun-0--fun-1-'}, 1}.
  {label, 537}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_link_info, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 541}, [{x, 0}]}.
    {test, test_arity, {f, 541}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 541}, [{x, 0}, {atom, ok}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, directory}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 541}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '__bp_tpl_14---t/2-fun-0--fun-2--fun-3-', 1, 550}.
  {label, 549}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14---t/2-fun-0--fun-2--fun-3-'}, 1}.
  {label, 550}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, [42, 63, 91, 123]}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, member, 2}, 1}.

{function, '__bp_tpl_14--t/2-fun-0--fun-2-', 1, 546}.
  {label, 545}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14--t/2-fun-0--fun-2-'}, 1}.
  {label, 546}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 550}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, any, 2}, 2}.

{function, '__bp_tpl_14--t/2-fun-0--fun-4-', 2, 556}.
  {label, 555}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14--t/2-fun-0--fun-4-'}, 2}.
  {label, 556}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 560}, [{x, 0}, {literal, [42]}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, list_dir, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 562}, [{x, 0}]}.
    {test, test_arity, {f, 562}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 562}, [{x, 0}, {atom, ok}]}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 0}, {y, 5}}.
    {jump, {f, 561}}.
  {label, 562}.
    {move, nil, {y, 5}}.
    {jump, {f, 561}}.
  {label, 561}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 559}}.
  {label, 560}.
    {'try', {y, 8}, {f, 565}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, filelib, wildcard, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 4}}.
    {try_end, {y, 8}}.
    {jump, {f, 566}}.
  {label, 565}.
    {try_case, {y, 8}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, nil, {y, 4}}.
    {jump, {f, 567}}.
  {label, 567}.
  {label, 566}.
    {move, {y, 4}, {y, 3}}.
    {jump, {f, 559}}.
  {label, 559}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 570}}.
  {label, 570}.
    {move, nil, {y, 3}}.
    {move, {y, 0}, {y, 4}}.
  {label, 572}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 573}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {bif, hd, {f, 572}, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 46}, {x, 1}}.
    {test, is_ne_exact, {f, 575}, [{x, 0}, {x, 1}]}.
    {jump, {f, 576}}.
  {label, 575}.
    {move, {y, 2}, {x, 0}}.
    {bif, hd, {f, 572}, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 46}, {x, 1}}.
    {test, is_eq_exact, {f, 572}, [{x, 0}, {x, 1}]}.
  {label, 576}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 572}}.
  {label, 573}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 574}, [{x, 0}]}.
    {jump, {f, 571}}.
  {label, 574}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 571}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 9}.
    return.

{function, '__bp_tpl_14--t/2-fun-0--fun-5-', 2, 580}.
  {label, 579}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14--t/2-fun-0--fun-5-'}, 2}.
  {label, 580}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 582}, [{x, 0}, nil]}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 582}.
    {move, {literal, [47]}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_14---t/2-fun-0--fun-6--fun-7-', 7, 593}.
  {label, 592}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14---t/2-fun-0--fun-6--fun-7-'}, 7}.
  {label, 593}.
    {allocate, 11, 7}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 8}}.
    {move, {x, 2}, {y, 0}}.
    {move, {x, 3}, {y, 1}}.
    {move, {x, 4}, {y, 2}}.
    {move, {x, 5}, {y, 3}}.
    {move, {x, 6}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 597}}.
  {label, 597}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 6}}.
    {jump, {f, 599}}.
  {label, 599}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 601}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 8}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [[42, 42]]}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {move, {y, 10}, {x, 3}}.
    {move, {y, 4}, {x, 4}}.
    {call_fun, 4}.
    {deallocate, 11}.
    return.
  {label, 601}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 602}, [{x, 0}, {atom, false}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 8}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 602}.
    {move, {y, 9}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_14---t/2-fun-0--fun-6--fun-8-', 8, 605}.
  {label, 604}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14---t/2-fun-0--fun-6--fun-8-'}, 8}.
  {label, 605}.
    {allocate, 11, 8}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 8}}.
    {move, {x, 2}, {y, 0}}.
    {move, {x, 3}, {y, 1}}.
    {move, {x, 4}, {y, 2}}.
    {move, {x, 5}, {y, 3}}.
    {move, {x, 6}, {y, 4}}.
    {move, {x, 7}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 6}}.
    {jump, {f, 609}}.
  {label, 609}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 611}, [{x, 0}, {atom, true}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 10}, {x, 2}}.
    {move, {y, 8}, {x, 3}}.
    {move, {y, 2}, {x, 4}}.
    {call_fun, 4}.
    {deallocate, 11}.
    return.
  {label, 611}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 612}, [{x, 0}, {atom, false}]}.
    {move, {y, 8}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 612}.
    {move, {y, 9}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_14---t/2-fun-0--fun-6--fun-9-', 8, 631}.
  {label, 630}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14---t/2-fun-0--fun-6--fun-9-'}, 8}.
  {label, 631}.
    {allocate, 11, 8}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {x, 1}, {y, 9}}.
    {move, {x, 2}, {y, 0}}.
    {move, {x, 3}, {y, 1}}.
    {move, {x, 4}, {y, 2}}.
    {move, {x, 5}, {y, 3}}.
    {move, {x, 6}, {y, 4}}.
    {move, {x, 7}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 6}}.
    {jump, {f, 635}}.
  {label, 635}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 7}}.
    {jump, {f, 637}}.
  {label, 637}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 639}, [{x, 0}, nil]}.
    {test_heap, 2, 0}.
    {put_list, {y, 7}, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 639}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 642}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {move, {y, 9}, {x, 3}}.
    {move, {y, 5}, {x, 4}}.
    {call_fun, 4}.
    {deallocate, 11}.
    return.
  {label, 642}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 643}, [{x, 0}, {atom, false}]}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 643}.
    {move, {y, 10}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_14--t/2-fun-0--fun-6-', 8, 587}.
  {label, 586}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14--t/2-fun-0--fun-6-'}, 8}.
  {label, 587}.
    {allocate, 19, 8}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {x, 1}, {y, 10}}.
    {move, {x, 2}, {y, 11}}.
    {move, {x, 3}, {y, 12}}.
    {move, {x, 4}, {y, 0}}.
    {move, {x, 5}, {y, 1}}.
    {move, {x, 6}, {y, 2}}.
    {move, {x, 7}, {y, 3}}.
    {test_heap, {alloc, [{words, 4}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 587}, 1, 0, {x, 0}, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 589}, [{x, 0}, nil]}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 589}, [{x, 0}, nil]}.
    {move, {y, 12}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 589}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 590}, [{x, 0}, nil]}.
    {test_heap, 2, 0}.
    {put_list, {y, 11}, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 590}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 591}, [{x, 0}, {literal, [[42, 42]]}]}.
    {test_heap, {alloc, [{words, 5}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 593}, 2, 0, {x, 0}, {list, [{y, 10}, {y, 0}, {y, 11}, {y, 1}, {y, 4}]}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 10}, {x, 0}}.
    {move, {literal, [42]}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 13}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {move, {y, 14}, {x, 2}}.
    {call_ext_last, 3, {extfunc, lists, foldl, 3}, 19}.
  {label, 591}.
    {move, {y, 9}, {x, 0}}.
    {test, is_nonempty_list, {f, 603}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 13}, {y, 14}}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 603}, [{x, 0}, {literal, [42, 42]}]}.
    {move, {y, 14}, {y, 5}}.
    {move, {y, 9}, {y, 6}}.
    {test_heap, {alloc, [{words, 6}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 605}, 3, 0, {x, 0}, {list, [{y, 10}, {y, 1}, {y, 4}, {y, 6}, {y, 0}, {y, 11}]}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {move, {y, 11}, {x, 2}}.
    {move, {y, 12}, {x, 3}}.
    {move, {y, 0}, {x, 4}}.
    {move, {y, 1}, {x, 5}}.
    {move, {y, 2}, {x, 6}}.
    {move, {y, 3}, {x, 7}}.
    {call, 8, {f, 587}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 10}, {x, 0}}.
    {move, {literal, [42]}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 15}, {x, 0}}.
    {move, {y, 16}, {x, 1}}.
    {move, {y, 17}, {x, 2}}.
    {call_ext_last, 3, {extfunc, lists, foldl, 3}, 19}.
  {label, 603}.
    {move, {y, 9}, {x, 0}}.
    {test, is_nonempty_list, {f, 613}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 13}, {y, 14}}.
    {move, {y, 13}, {y, 6}}.
    {move, {y, 14}, {y, 5}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {test, is_eq_exact, {f, 615}, [{x, 0}, {atom, false}]}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {y, 7}}.
    {jump, {f, 617}}.
  {label, 617}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {y, 8}}.
    {jump, {f, 619}}.
  {label, 619}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 621}, [{x, 0}, nil]}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_link_info, 1}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {test, is_tuple, {f, 623}, [{x, 0}]}.
    {test, test_arity, {f, 623}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 17}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq_exact, {f, 623}, [{x, 0}, {atom, ok}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 8}, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 18}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 623}.
    {move, {y, 12}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 621}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, filelib, is_dir, 1}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {test, is_eq_exact, {f, 627}, [{x, 0}, {atom, true}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {move, {y, 8}, {x, 2}}.
    {move, {y, 12}, {x, 3}}.
    {move, {y, 0}, {x, 4}}.
    {move, {y, 1}, {x, 5}}.
    {move, {y, 2}, {x, 6}}.
    {move, {y, 3}, {x, 7}}.
    {call_last, 8, {f, 587}, 19}.
  {label, 627}.
    {move, {y, 16}, {x, 0}}.
    {test, is_eq_exact, {f, 628}, [{x, 0}, {atom, false}]}.
    {move, {y, 12}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 628}.
    {move, {y, 16}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 615}.
    {move, {y, 15}, {x, 0}}.
    {test, is_eq_exact, {f, 629}, [{x, 0}, {atom, true}]}.
    {test_heap, {alloc, [{words, 6}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 631}, 4, 0, {x, 0}, {list, [{y, 10}, {y, 0}, {y, 11}, {y, 5}, {y, 1}, {y, 4}]}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 16}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {move, {y, 17}, {x, 2}}.
    {call_ext_last, 3, {extfunc, lists, foldl, 3}, 19}.
  {label, 629}.
    {move, {y, 15}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 613}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {move, {y, 11}, {x, 2}}.
    {move, {y, 12}, {x, 3}}.
    {move, {y, 0}, {x, 4}}.
    {move, {y, 1}, {x, 5}}.
    {move, {y, 2}, {x, 6}}.
    {move, {y, 3}, {x, 7}}.
    {deallocate, 19}.
    {jump, {f, 586}}.

{function, '__bp_tpl_14-t/2-fun-0-', 2, 518}.
  {label, 517}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14-t/2-fun-0-'}, 2}.
  {label, 518}.
    {allocate, 16, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 0}}.
    {jump, {f, 522}}.
  {label, 522}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 1}}.
    {jump, {f, 524}}.
  {label, 524}.
    {move, nil, {y, 9}}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, [47]}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext, 3, {extfunc, string, split, 3}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 10}}.
  {label, 526}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nonempty_list, {f, 527}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 12}, {y, 10}}.
    {move, {y, 12}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, nil, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 529}, [{x, 0}, {atom, true}]}.
    {jump, {f, 531}}.
  {label, 529}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 530}, [{x, 0}, {atom, false}]}.
    {jump, {f, 526}}.
  {label, 530}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_filter}, {y, 13}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 531}.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, [46]}, {x, 1}}.
    {test, is_ne_exact, {f, 526}, [{x, 0}, {x, 1}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 526}}.
  {label, 527}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nil, {f, 528}, [{x, 0}]}.
    {jump, {f, 525}}.
  {label, 528}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 10}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 525}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 2}}.
    {jump, {f, 533}}.
  {label, 533}.
    {move, {literal, [47]}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, suffix, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 1}}.
    {jump, {f, 535}}.
  {label, 535}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 537}, 5, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 544}}.
  {label, 544}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 546}, 6, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 554}}.
  {label, 554}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 556}, 7, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 578}}.
  {label, 578}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 580}, 8, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 6}}.
    {jump, {f, 585}}.
  {label, 585}.
    {test_heap, {alloc, [{words, 4}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 587}, 1, 0, {x, 0}, {list, [{y, 6}, {y, 3}, {y, 5}, {y, 4}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 645}}.
  {label, 645}.
    {move, nil, {y, 9}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, nil, {x, 2}}.
    {move, nil, {x, 3}}.
    {move, {y, 4}, {x, 4}}.
    {call_fun, 4}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, usort, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 10}}.
  {label, 647}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nonempty_list, {f, 648}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 12}, {y, 10}}.
    {move, {y, 12}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, 'not', 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 650}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {y, 13}}.
    {jump, {f, 652}}.
  {label, 650}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 651}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {y, 13}}.
    {jump, {f, 652}}.
  {label, 651}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 14}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 652}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 653}, [{x, 0}, {atom, true}]}.
    {jump, {f, 655}}.
  {label, 653}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 654}, [{x, 0}, {atom, false}]}.
    {jump, {f, 647}}.
  {label, 654}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_filter}, {y, 13}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 655}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 13}}.
    {test_heap, 2, 0}.
    {put_list, {y, 13}, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 647}}.
  {label, 648}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nil, {f, 649}, [{x, 0}]}.
    {jump, {f, 646}}.
  {label, 649}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 10}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 646}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 16}.
    return.

{function, '__bp_tpl_14', 2, 514}.
  {label, 513}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14'}, 2}.
  {label, 514}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 518}, 9, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_15-t/1-fun-0-', 1, 663}.
  {label, 662}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_15-t/1-fun-0-'}, 1}.
  {label, 663}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, [read, binary, read_ahead]}, {x, 1}}.
    {call_ext, 2, {extfunc, file, open, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 667}, [{x, 0}]}.
    {test, test_arity, {f, 667}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 667}, [{x, 0}, {atom, ok}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 667}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 668}, [{x, 0}]}.
    {test, test_arity, {f, 668}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 668}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 668}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_15', 1, 657}.
  {label, 656}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_15'}, 1}.
  {label, 657}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 660}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 663}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 670}, [{x, 0}]}.
    {test, test_arity, {f, 670}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 670}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 669}}.
  {label, 670}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 671}, [{x, 0}]}.
    {test, test_arity, {f, 671}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 671}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 669}}.
  {label, 671}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 669}}.
  {label, 669}.
    {jump, {f, 661}}.
  {label, 660}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 676}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 675}}.
  {label, 676}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 677}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 675}}.
  {label, 677}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 678}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 675}}.
  {label, 678}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 675}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 673}}.
  {label, 673}.
  {label, 661}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_16-t/1-fun-0-', 1, 688}.
  {label, 687}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_16-t/1-fun-0-'}, 1}.
  {label, 688}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, [write, binary, raw]}, {x, 1}}.
    {call_ext, 2, {extfunc, file, open, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 692}, [{x, 0}]}.
    {test, test_arity, {f, 692}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 692}, [{x, 0}, {atom, ok}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 692}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 693}, [{x, 0}]}.
    {test, test_arity, {f, 693}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 693}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 693}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_16', 1, 682}.
  {label, 681}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_16'}, 1}.
  {label, 682}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 685}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 688}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 695}, [{x, 0}]}.
    {test, test_arity, {f, 695}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 695}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 694}}.
  {label, 695}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 696}, [{x, 0}]}.
    {test, test_arity, {f, 696}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 696}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 694}}.
  {label, 696}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 694}}.
  {label, 694}.
    {jump, {f, 686}}.
  {label, 685}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 701}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 700}}.
  {label, 701}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 702}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 700}}.
  {label, 702}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 703}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 700}}.
  {label, 703}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 700}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 698}}.
  {label, 698}.
  {label, 686}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '-bp_field-', 2, 707}.
  {label, 706}.
    {line, [{location, "std@io@fs.erl", 33}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_field-'}, 2}.
  {label, 707}.
    {test, is_map, {f, 708}, [{x, 0}]}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_ext_only, 3, {extfunc, maps, get, 3}}.
  {label, 708}.
    {test, is_tuple, {f, 709}, [{x, 0}]}.
    {bif, element, {f, 711}, [{integer, 1}, {x, 0}], {x, 2}}.
    {test, is_atom, {f, 711}, [{x, 2}]}.
    {test_heap, 4, 3}.
    {put_list, {x, 1}, nil, {x, 3}}.
    {put_list, {x, 0}, {x, 3}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {atom, '__bp_get'}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {call_ext_only, 3, {extfunc, erlang, apply, 3}}.
  {label, 709}.
    {test, is_eq_exact, {f, 711}, [{x, 1}, {atom, length}]}.
    {test, is_list, {f, 710}, [{x, 0}]}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    return.
  {label, 710}.
    {test, is_binary, {f, 711}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 711}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_tpl_17', 1, 713}.
  {label, 712}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_17'}, 1}.
  {label, 713}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, nil, {x, 1}}.
    {call_ext, 2, {extfunc, counters, new, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, mem}, {y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_18-t/0-fun-0-', 0, 722}.
  {label, 721}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_18-t/0-fun-0-'}, 0}.
  {label, 722}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {literal, [84, 77, 80, 68, 73, 82]}, {x, 0}}.
    {call_ext, 1, {extfunc, os, getenv, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 726}, [{x, 0}, {atom, false}]}.
    {move, {literal, [47, 116, 109, 112]}, {y, 2}}.
    {jump, {f, 725}}.
  {label, 726}.
    {move, {y, 1}, {y, 0}}.
    {move, {y, 0}, {y, 2}}.
    {jump, {f, 725}}.
  {label, 725}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 729}}.
  {label, 729}.
    {move, {literal, [positive]}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, unique_integer, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, [98, 112, 45, 115, 116, 100, 45, 102, 115, 45]}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {y, 0}}.
    {jump, {f, 731}}.
  {label, 731}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, file, make_dir, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 732}, [{x, 0}, {atom, ok}]}.
    {jump, {f, 733}}.
  {label, 732}.
    {move, {y, 1}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 733}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 3}.

{function, '__bp_tpl_18', 0, 718}.
  {label, 717}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_18'}, 0}.
  {label, 718}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 722}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_19-t/0-fun-0-', 0, 741}.
  {label, 740}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_19-t/0-fun-0-'}, 0}.
  {label, 741}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {call_ext, 0, {extfunc, file, get_cwd, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 744}, [{x, 0}]}.
    {test, test_arity, {f, 744}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {get_tuple_element, {x, 0}, 1, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 744}, [{x, 0}, {atom, ok}]}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 745}}.
  {label, 744}.
    {move, {y, 1}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 745}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 4}.

{function, '__bp_tpl_19', 0, 737}.
  {label, 736}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_19'}, 0}.
  {label, 737}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 741}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_20-t/2-fun-0-', 2, 764}.
  {label, 763}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_20-t/2-fun-0-'}, 2}.
  {label, 764}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, file, make_symlink, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 767}, [{x, 0}, {atom, ok}]}.
    {jump, {f, 768}}.
  {label, 767}.
    {move, {y, 2}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 768}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_20', 2, 760}.
  {label, 759}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_20'}, 2}.
  {label, 760}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 764}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_21', 1, 775}.
  {label, 774}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_21'}, 1}.
  {label, 775}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- BEAM ASSEMBLY -- std@io@fs@@FsError.S
```erlang
{module, std@io@fs@@FsError}.
{exports, [{message, 1}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 53}.

{function, message, 1, 3}.
  {label, 2}.
    {line, [{location, "std@io@fs@@FsError.erl", 1}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, message}, 1}.
  {label, 3}.
    {allocate, 17, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 5}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__notfound}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"not found: ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 5}.
    {test, is_tagged_tuple, {f, 38}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__permissiondenied}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"permission denied: ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 38}.
    {test, is_tagged_tuple, {f, 39}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__isdirectory}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"is a directory: ">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 39}.
    {test, is_tagged_tuple, {f, 40}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__notdirectory}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"not a directory: ">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 40}.
    {test, is_tagged_tuple, {f, 41}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__alreadyexists}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 9}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, <<"already exists: ">>}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 41}.
    {test, is_tagged_tuple, {f, 42}, [{x, 0}, 3, {atom, std@io@fs@@FsError__v__invalidutf8}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 11}}.
    {get_tuple_element, {x, 0}, 2, {x, 1}}.
    {move, {x, 1}, {y, 12}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {literal, <<" at byte ">>}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {literal, <<"not UTF-8: ">>}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 42}.
    {test, is_tagged_tuple, {f, 43}, [{x, 0}, 3, {atom, std@io@fs@@FsError__v__other}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 14}}.
    {get_tuple_element, {x, 0}, 2, {x, 1}}.
    {move, {x, 1}, {y, 15}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 15}, {x, 0}}.
    {move, {y, 16}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {literal, <<": ">>}, {x, 0}}.
    {move, {y, 16}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 14}, {x, 0}}.
    {move, {y, 16}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 43}.
    {case_end, {x, 0}}.
  {label, 4}.
    {deallocate, 17}.
    return.

{function, '__bp_format', 1, 45}.
  {label, 44}.
    {line, [{location, "std@io@fs@@FsError.erl", 2}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '__bp_format'}, 1}.
  {label, 45}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 46}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__notfound}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"path">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError.NotFound">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 46}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 47}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__permissiondenied}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"path">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError.PermissionDenied">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 48}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__isdirectory}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"path">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError.IsDirectory">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 49}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__notdirectory}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"path">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError.NotDirectory">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 49}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 50}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__alreadyexists}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"path">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError.AlreadyExists">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 50}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 51}, [{x, 0}, 3, {atom, std@io@fs@@FsError__v__invalidutf8}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"offset">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"path">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError.InvalidUtf8">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 51}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 52}, [{x, 0}, 3, {atom, std@io@fs@@FsError__v__other}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"message">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"path">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError.Other">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 52}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError">>}, nil]}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 7}.
  {label, 6}.
    {line, [{location, "std@io@fs@@FsError.erl", 2}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '__bp_print'}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 11}.
  {label, 10}.
    {line, [{location, "std@io@fs@@FsError.erl", 2}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '-bp_show_top-'}, 1}.
  {label, 11}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 9}}.

{function, '-bp_show_elem-', 1, 13}.
  {label, 12}.
    {line, [{location, "std@io@fs@@FsError.erl", 2}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '-bp_show_elem-'}, 1}.
  {label, 13}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 9}}.

{function, '__bp_show', 2, 9}.
  {label, 8}.
    {line, [{location, "std@io@fs@@FsError.erl", 2}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '__bp_show'}, 2}.
  {label, 9}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 21}, [{x, 0}]}.
    {test, is_eq, {f, 20}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 20}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 21}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 22}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 22}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 24}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 23}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 23}, [{x, 0}]}.
    {test, is_ne_exact, {f, 23}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 23}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 23}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 28}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 29}}.
  {label, 28}.
    {test, is_eq_exact, {f, 25}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 29}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 9}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 24}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 26}, [{x, 0}]}.
    {test, is_ne_exact, {f, 26}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 26}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 27}, [{x, 0}, {atom, undefined}]}.
  {label, 25}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 15}, 2}.
  {label, 26}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 27}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 15}.
  {label, 14}.
    {line, [{location, "std@io@fs@@FsError.erl", 2}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '__bp_tagged'}, 2}.
  {label, 15}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 30}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 30}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 30}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 17}, 3}.
  {label, 31}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 17}.
  {label, 16}.
    {line, [{location, "std@io@fs@@FsError.erl", 2}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '__bp_render'}, 1}.
  {label, 17}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 32}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 33}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 33}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 19}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 19}.
  {label, 18}.
    {line, [{location, "std@io@fs@@FsError.erl", 2}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '-bp_render_pair-'}, 1}.
  {label, 19}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 9}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 35}.
  {label, 34}.
    {line, [{location, "std@io@fs@@FsError.erl", 2}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '-bp_stringify-'}, 1}.
  {label, 35}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 36}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 36}.
    {test, is_integer, {f, 37}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 37}.
    {call, 1, {f, 11}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
```

----- BEAM ASSEMBLY -- std@io@fs@@FileStat.S
```erlang
{module, std@io@fs@@FileStat}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 9}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@io@fs@@FileStat.erl", 2}]}.
    {func_info, {atom, std@io@fs@@FileStat}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, size}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, mtime}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, isDir}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 8}.
  {label, 7}.
    {line, [{location, "std@io@fs@@FileStat.erl", 2}]}.
    {func_info, {atom, std@io@fs@@FileStat}, {atom, '__bp_format'}, 1}.
  {label, 8}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"isDir">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"mtime">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"size">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"FileStat">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@io@fs@@Walked.S
```erlang
{module, std@io@fs@@Walked}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@io@fs@@Walked.erl", 6}]}.
    {func_info, {atom, std@io@fs@@Walked}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, files}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, dangling}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 7}.
  {label, 6}.
    {line, [{location, "std@io@fs@@Walked.erl", 6}]}.
    {func_info, {atom, std@io@fs@@Walked}, {atom, '__bp_format'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"dangling">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"files">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Walked">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@io@fs@@File.S
```erlang
{module, std@io@fs@@File}.
{exports, [{path, 1}, {size, 1}, {read, 2}, {bytes, 1}, {text, 1}, {chunks, 2}, {lines, 1}, {hash, 1}, {write, 2}, {close, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 493}.

{function, path, 1, 3}.
  {label, 2}.
    {line, [{location, "std@io@fs@@File.erl", 20}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, path}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 22}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 22}.
    {deallocate, 1}.
    return.

{function, size, 1, 5}.
  {label, 4}.
    {line, [{location, "std@io@fs@@File.erl", 21}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, size}, 1}.
  {label, 5}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 23}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 23}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 50}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 50}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 51}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 51}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 25}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, std@io@fs, lift, 2}}.
    {test, is_tagged_tuple, {f, 52}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 53}}.
  {label, 52}.
    {deallocate, 4}.
    return.
  {label, 53}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, read, 2, 7}.
  {label, 6}.
    {line, [{location, "std@io@fs@@File.erl", 22}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, read}, 2}.
  {label, 7}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 54}, [{integer, 0}, {y, 1}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {call, 1, {f, 56}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.
  {label, 54}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 57}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 57}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 89}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 89}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 59}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, std@io@fs, lift, 2}}.
    {test, is_tagged_tuple, {f, 90}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 91}}.
  {label, 90}.
    {deallocate, 5}.
    return.
  {label, 91}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.

{function, bytes, 1, 9}.
  {label, 8}.
    {line, [{location, "std@io@fs@@File.erl", 23}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, bytes}, 1}.
  {label, 9}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 92}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 92}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 126}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 126}.
    {call, 1, {f, 94}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, std@io@fs, lift, 2}}.
    {test, is_tagged_tuple, {f, 127}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 128}}.
  {label, 127}.
    {deallocate, 4}.
    return.
  {label, 128}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, text, 1, 11}.
  {label, 10}.
    {line, [{location, "std@io@fs@@File.erl", 24}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, text}, 1}.
  {label, 11}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test, is_tagged_tuple, {f, 129}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 130}}.
  {label, 129}.
    {deallocate, 3}.
    return.
  {label, 130}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 131}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 131}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, std@io@fs, decode, 2}}.
    {test, is_tagged_tuple, {f, 132}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 133}}.
  {label, 132}.
    {deallocate, 3}.
    return.
  {label, 133}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.

{function, chunks, 2, 13}.
  {label, 12}.
    {line, [{location, "std@io@fs@@File.erl", 25}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, chunks}, 2}.
  {label, 13}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 135}, 0, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {call, 1, {f, 199}}.
    {deallocate, 4}.
    return.

{function, lines, 1, 15}.
  {label, 14}.
    {line, [{location, "std@io@fs@@File.erl", 26}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, lines}, 1}.
  {label, 15}.
    {allocate, 11, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 270}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 199}}.
    {deallocate, 11}.
    return.

{function, hash, 1, 17}.
  {label, 16}.
    {line, [{location, "std@io@fs@@File.erl", 27}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, hash}, 1}.
  {label, 17}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 381}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 381}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 421}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 421}.
    {call, 1, {f, 383}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, std@io@fs, lift, 2}}.
    {test, is_tagged_tuple, {f, 422}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 423}}.
  {label, 422}.
    {deallocate, 4}.
    return.
  {label, 423}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, write, 2, 19}.
  {label, 18}.
    {line, [{location, "std@io@fs@@File.erl", 28}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, write}, 2}.
  {label, 19}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 431}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 431}.
    {call, 1, {f, 426}}.
    {test, is_eq, {f, 424}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 432}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 432}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"the file is open for reading">>}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__other}, {x, 1}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 5}.
    return.
  {label, 424}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 433}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 433}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 457}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 457}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 435}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, std@io@fs, lift, 2}}.
    {test, is_tagged_tuple, {f, 458}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 459}}.
  {label, 458}.
    {deallocate, 5}.
    return.
  {label, 459}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.

{function, close, 1, 21}.
  {label, 20}.
    {line, [{location, "std@io@fs@@File.erl", 29}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, close}, 1}.
  {label, 21}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 486}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 486}.
    {call, 1, {f, 461}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 488}.
  {label, 487}.
    {line, [{location, "std@io@fs@@File.erl", 30}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_get'}, 2}.
  {label, 488}.
    {test, is_eq_exact, {f, 489}, [{x, 1}, {atom, location}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 489}.
    {test, is_eq_exact, {f, 490}, [{x, 1}, {atom, handle}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 490}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 492}.
  {label, 491}.
    {line, [{location, "std@io@fs@@File.erl", 30}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_format'}, 1}.
  {label, 492}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"handle">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"location">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"File">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 31}.
  {label, 30}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 31}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 35}, [{x, 0}]}.
    {test, test_arity, {f, 35}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 35}, [{x, 0}, {atom, mem}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 5}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 35}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_file_info, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 38}, [{x, 0}]}.
    {test, test_arity, {f, 38}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {atom, ok}]}.
    {move, {y, 5}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 6}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 38}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 39}, [{x, 0}]}.
    {test, test_arity, {f, 39}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 39}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_0', 2, 25}.
  {label, 24}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_0'}, 2}.
  {label, 25}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {'try', {y, 12}, {f, 28}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 7}}.
    {try_end, {y, 12}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 41}, [{x, 0}]}.
    {test, test_arity, {f, 41}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 41}, [{x, 0}, {atom, ok}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 40}}.
  {label, 41}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 42}, [{x, 0}]}.
    {test, test_arity, {f, 42}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 42}, [{x, 0}, {atom, error}]}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 10}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 40}}.
  {label, 42}.
    {move, {y, 7}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 5}}.
    {jump, {f, 40}}.
  {label, 40}.
    {jump, {f, 29}}.
  {label, 28}.
    {try_case, {y, 12}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 10}}.
    {jump, {f, 46}}.
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 48}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 10}}.
    {jump, {f, 46}}.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 10}}.
    {jump, {f, 46}}.
  {label, 49}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 46}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 44}}.
  {label, 44}.
  {label, 29}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_1', 1, 56}.
  {label, 55}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_1'}, 1}.
  {label, 56}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_2-t/2-fun-0-', 2, 65}.
  {label, 64}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_2-t/2-fun-0-'}, 2}.
  {label, 65}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 1}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 69}, [{x, 0}]}.
    {test, test_arity, {f, 69}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {get_tuple_element, {x, 0}, 2, {y, 8}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, {atom, mem}]}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, counters, get, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 2}}.
    {jump, {f, 71}}.
  {label, 71}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 73}}.
  {label, 73}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_ext, 3, {extfunc, counters, add, 3}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 69}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, file, read, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 76}, [{x, 0}]}.
    {test, test_arity, {f, 76}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 76}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 76}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 77}, [{x, 0}, {atom, eof}]}.
    {move, {literal, {ok, <<"">>}}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 77}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 78}, [{x, 0}]}.
    {test, test_arity, {f, 78}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 78}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 78}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_2', 2, 59}.
  {label, 58}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_2'}, 2}.
  {label, 59}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {'try', {y, 12}, {f, 62}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 65}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 7}}.
    {try_end, {y, 12}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 80}, [{x, 0}]}.
    {test, test_arity, {f, 80}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 80}, [{x, 0}, {atom, ok}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 79}}.
  {label, 80}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 81}, [{x, 0}]}.
    {test, test_arity, {f, 81}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 81}, [{x, 0}, {atom, error}]}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 10}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 79}}.
  {label, 81}.
    {move, {y, 7}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 5}}.
    {jump, {f, 79}}.
  {label, 79}.
    {jump, {f, 63}}.
  {label, 62}.
    {try_case, {y, 12}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 86}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 10}}.
    {jump, {f, 85}}.
  {label, 86}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 87}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 10}}.
    {jump, {f, 85}}.
  {label, 87}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 88}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 10}}.
    {jump, {f, 85}}.
  {label, 88}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 85}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 83}}.
  {label, 83}.
  {label, 63}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_3--t/1-fun-0--fun-1-', 2, 109}.
  {label, 108}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_3--t/1-fun-0--fun-1-'}, 2}.
  {label, 109}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 109}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 65536}, {x, 1}}.
    {call_ext, 2, {extfunc, file, read, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 113}, [{x, 0}]}.
    {test, test_arity, {f, 113}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 113}, [{x, 0}, {atom, ok}]}.
    {move, {y, 5}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {put_list, {y, 2}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 109}, 7}.
  {label, 113}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 114}, [{x, 0}, {atom, eof}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 114}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 115}, [{x, 0}]}.
    {test, test_arity, {f, 115}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 115}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 1}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 115}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_3-t/1-fun-0-', 1, 100}.
  {label, 99}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_3-t/1-fun-0-'}, 1}.
  {label, 100}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 104}, [{x, 0}]}.
    {test, test_arity, {f, 104}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {get_tuple_element, {x, 0}, 2, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 104}, [{x, 0}, {atom, mem}]}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, counters, get, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 106}}.
  {label, 106}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, counters, add, 3}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 7}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 104}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 109}, 0, 0, {x, 0}, {list, [{y, 3}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 8}.
    return.

{function, '__bp_tpl_3', 1, 94}.
  {label, 93}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_3'}, 1}.
  {label, 94}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 97}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 100}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 117}, [{x, 0}]}.
    {test, test_arity, {f, 117}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 117}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 116}}.
  {label, 117}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 118}, [{x, 0}]}.
    {test, test_arity, {f, 118}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 118}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 116}}.
  {label, 118}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 116}}.
  {label, 116}.
    {jump, {f, 98}}.
  {label, 97}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 123}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 122}}.
  {label, 123}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 124}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 122}}.
  {label, 124}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 125}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 122}}.
  {label, 125}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 122}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 120}}.
  {label, 120}.
  {label, 98}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_4--t/1-fun-0--fun-1-', 1, 150}.
  {label, 149}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_4--t/1-fun-0--fun-1-'}, 1}.
  {label, 150}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 152}, [{x, 0}]}.
    {test, test_arity, {f, 152}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 153}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_mon'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 155}}.
  {label, 153}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 154}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 3}}.
    {jump, {f, 155}}.
  {label, 154}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 155}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 152}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    {jump, {f, 149}}.

{function, '__bp_tpl_4-t/1-fun-0-', 0, 146}.
  {label, 145}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_4-t/1-fun-0-'}, 0}.
  {label, 146}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 150}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_4--t/1-fun-2--fun-3-', 1, 167}.
  {label, 166}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_4--t/1-fun-2--fun-3-'}, 1}.
  {label, 167}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 169}, [{x, 0}]}.
    {test, test_arity, {f, 169}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 169}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 166}}.

{function, '__bp_tpl_4-t/1-fun-2-', 1, 159}.
  {label, 158}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_4-t/1-fun-2-'}, 1}.
  {label, 159}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 163}}.
  {label, 163}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 165}}.
  {label, 165}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 167}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 171}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 3}}.
    {jump, {f, 170}}.
  {label, 171}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {jump, {f, 170}}.
  {label, 170}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 174}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 174}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.

{function, '__bp_tpl_4-t/1-fun-4-', 3, 179}.
  {label, 178}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_4-t/1-fun-4-'}, 3}.
  {label, 179}.
    {allocate, 15, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 182}, [{x, 0}]}.
    {test, test_arity, {f, 182}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {y, 2}}.
    {move, {y, 10}, {y, 3}}.
    {jump, {f, 183}}.
  {label, 182}.
    {move, {y, 8}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 183}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 3}, {atom, item}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, send, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 2}}.
    {jump, {f, 185}}.
  {label, 185}.
  {label, 186}.
    {loop_rec, {f, 187}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 190}, [{x, 0}]}.
    {test, test_arity, {f, 190}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 190}, [{x, 0}, {atom, 'DOWN'}]}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 190}, [{x, 0}, {x, 1}]}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 190}, [{x, 0}, {atom, process}]}.
    remove_message.
    {move, {atom, '__bp_gen_closed'}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, throw, 1}, 15}.
  {label, 190}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 191}, [{x, 0}]}.
    {test, test_arity, {f, 191}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {get_tuple_element, {x, 0}, 3, {y, 12}}.
    {get_tuple_element, {x, 0}, 4, {y, 13}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 191}, [{x, 0}, {atom, '__bp_gen'}]}.
    {move, {y, 10}, {y, 6}}.
    {move, {y, 11}, {y, 5}}.
    {move, {y, 12}, {y, 3}}.
    {move, {y, 13}, {y, 4}}.
    remove_message.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 14}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 5}, {y, 3}]}}.
    {move, {x, 0}, {y, 14}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 14}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 193}, [{x, 0}, {atom, next}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 193}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 194}, [{x, 0}, {atom, close}]}.
    {move, {atom, '__bp_gen_closed'}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, throw, 1}, 15}.
  {label, 194}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 191}.
    {move, nil, {y, 8}}.
    {move, nil, {y, 3}}.
    {move, nil, {y, 4}}.
    {move, nil, {y, 5}}.
    {move, nil, {y, 6}}.
    {move, nil, {y, 9}}.
    {move, nil, {y, 10}}.
    {move, nil, {y, 11}}.
    {move, nil, {y, 12}}.
    {move, nil, {y, 13}}.
    {move, nil, {y, 14}}.
    {loop_rec_end, {f, 186}}.
  {label, 187}.
    {wait, {f, 186}}.

{function, '__bp_tpl_4', 1, 142}.
  {label, 141}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_4'}, 1}.
  {label, 142}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 146}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 157}}.
  {label, 157}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 159}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 177}}.
  {label, 177}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 179}, 4, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 196}}.
  {label, 196}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 4}.
    return.

{function, '-glob/2-gen-0-', 2, 135}.
  {label, 134}.
    {line, [{location, "std@io@fs@@File.erl", 26}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, '-glob/2-gen-0-'}, 2}.
  {label, 135}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {line, [{location, "std@io@fs@@File.erl", 26}]}.
  {label, 137}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 138}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 7}}.
    {test, is_tagged_tuple, {f, 139}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 140}}.
  {label, 139}.
    {call, 1, {f, 142}}.
    {jump, {f, 136}}.
  {label, 140}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, byte_size, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 197}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 138}}.
  {label, 197}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {call, 1, {f, 142}}.
    {jump, {f, 137}}.
  {label, 138}.
  {label, 136}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_5--t/1-fun-0--fun-1-', 1, 207}.
  {label, 206}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_5--t/1-fun-0--fun-1-'}, 1}.
  {label, 207}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 209}, [{x, 0}]}.
    {test, test_arity, {f, 209}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 210}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_mon'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 212}}.
  {label, 210}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 211}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 3}}.
    {jump, {f, 212}}.
  {label, 211}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 212}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 209}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    {jump, {f, 206}}.

{function, '__bp_tpl_5-t/1-fun-0-', 0, 203}.
  {label, 202}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_5-t/1-fun-0-'}, 0}.
  {label, 203}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 207}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_5--t/1-fun-2--fun-3-', 1, 224}.
  {label, 223}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_5--t/1-fun-2--fun-3-'}, 1}.
  {label, 224}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 226}, [{x, 0}]}.
    {test, test_arity, {f, 226}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 226}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 223}}.

{function, '__bp_tpl_5-t/1-fun-2-', 1, 216}.
  {label, 215}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_5-t/1-fun-2-'}, 1}.
  {label, 216}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 220}}.
  {label, 220}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 222}}.
  {label, 222}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 224}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 228}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 3}}.
    {jump, {f, 227}}.
  {label, 228}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {jump, {f, 227}}.
  {label, 227}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 231}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 231}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.

{function, '__bp_tpl_5--t/1-fun-4--fun-5-', 4, 242}.
  {label, 241}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_5--t/1-fun-4--fun-5-'}, 4}.
  {label, 242}.
    {allocate, 33, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {atom, process}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, monitor, 2}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {y, 4}}.
    {jump, {f, 246}}.
  {label, 246}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 16}}.
  {label, 247}.
    {loop_rec, {f, 248}, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {test, is_tuple, {f, 251}, [{x, 0}]}.
    {test, test_arity, {f, 251}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 17}}.
    {get_tuple_element, {x, 0}, 1, {y, 18}}.
    {get_tuple_element, {x, 0}, 2, {y, 19}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq_exact, {f, 251}, [{x, 0}, {atom, 'DOWN'}]}.
    {move, {y, 18}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test, is_eq_exact, {f, 251}, [{x, 0}, {x, 1}]}.
    {move, {y, 19}, {x, 0}}.
    {test, is_eq_exact, {f, 251}, [{x, 0}, {atom, process}]}.
    remove_message.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 33}.
    return.
  {label, 251}.
    {move, {y, 16}, {x, 0}}.
    {test, is_tuple, {f, 252}, [{x, 0}]}.
    {test, test_arity, {f, 252}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 17}}.
    {get_tuple_element, {x, 0}, 1, {y, 18}}.
    {get_tuple_element, {x, 0}, 2, {y, 19}}.
    {get_tuple_element, {x, 0}, 3, {y, 20}}.
    {get_tuple_element, {x, 0}, 4, {y, 21}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq_exact, {f, 252}, [{x, 0}, {atom, '__bp_gen'}]}.
    {move, {y, 18}, {y, 6}}.
    {move, {y, 19}, {y, 5}}.
    {move, {y, 20}, {y, 7}}.
    {move, {y, 21}, {y, 8}}.
    remove_message.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 22}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 5}, {y, 7}]}}.
    {move, {x, 0}, {y, 22}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 22}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 254}, [{x, 0}, {atom, close}]}.
    {move, {atom, ok}, {y, 22}}.
    {jump, {f, 253}}.
  {label, 254}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 255}, [{x, 0}, {atom, next}]}.
    {'try', {y, 32}, {f, 256}}.
    {move, {y, 2}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 24}, {y, 23}}.
    {try_end, {y, 32}}.
    {jump, {f, 257}}.
  {label, 256}.
    {try_case, {y, 32}}.
    {move, {x, 0}, {y, 24}}.
    {move, {x, 1}, {y, 25}}.
    {move, {x, 2}, {y, 26}}.
    {move, {y, 24}, {x, 0}}.
    {test, is_eq_exact, {f, 259}, [{x, 0}, {atom, throw}]}.
    {move, {y, 25}, {x, 0}}.
    {test, is_eq_exact, {f, 259}, [{x, 0}, {atom, '__bp_gen_closed'}]}.
    {move, {atom, ok}, {y, 23}}.
    {jump, {f, 258}}.
  {label, 259}.
    {move, {y, 24}, {y, 9}}.
    {move, {y, 25}, {y, 10}}.
    {move, {y, 26}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 11}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 27}}.
    {move, {y, 27}, {x, 0}}.
    {test, is_tuple, {f, 262}, [{x, 0}]}.
    {test, test_arity, {f, 262}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 29}}.
    {get_tuple_element, {x, 0}, 1, {y, 30}}.
    {move, {y, 29}, {y, 12}}.
    {move, {y, 30}, {y, 13}}.
    {move, {y, 3}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 31}}.
    {test_heap, 7, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 13}, {atom, raise}, {y, 9}, {y, 10}, {y, 11}, {y, 31}]}}.
    {move, {x, 0}, {y, 31}}.
    {move, {y, 12}, {x, 0}}.
    {move, {y, 31}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, send, 2}}.
    {move, {x, 0}, {y, 31}}.
    {move, {y, 31}, {y, 28}}.
    {jump, {f, 261}}.
  {label, 262}.
    {move, {y, 27}, {x, 0}}.
    {test, is_eq_exact, {f, 263}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 28}}.
    {jump, {f, 261}}.
  {label, 263}.
    {move, {y, 27}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 261}.
    {move, {atom, normal}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, exit, 1}}.
  {label, 258}.
  {label, 257}.
    {move, {y, 23}, {y, 22}}.
    {jump, {f, 253}}.
  {label, 255}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 253}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 22}, {x, 0}}.
    {test, is_tuple, {f, 265}, [{x, 0}]}.
    {test, test_arity, {f, 265}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 23}}.
    {get_tuple_element, {x, 0}, 1, {y, 24}}.
    {move, {y, 23}, {y, 14}}.
    {move, {y, 24}, {y, 15}}.
    {move, {y, 3}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 25}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 15}, {atom, done}, {y, 25}]}}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 14}, {x, 0}}.
    {move, {y, 25}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, send, 2}, 33}.
  {label, 265}.
    {move, {y, 22}, {x, 0}}.
    {test, is_eq_exact, {f, 266}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 33}.
    return.
  {label, 266}.
    {move, {y, 22}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 252}.
    {move, nil, {y, 16}}.
    {move, nil, {y, 5}}.
    {move, nil, {y, 6}}.
    {move, nil, {y, 7}}.
    {move, nil, {y, 8}}.
    {move, nil, {y, 17}}.
    {move, nil, {y, 18}}.
    {move, nil, {y, 19}}.
    {move, nil, {y, 20}}.
    {move, nil, {y, 21}}.
    {move, nil, {y, 22}}.
    {move, nil, {y, 23}}.
    {move, nil, {y, 24}}.
    {move, nil, {y, 25}}.
    {move, nil, {y, 26}}.
    {move, nil, {y, 27}}.
    {move, nil, {y, 28}}.
    {move, nil, {y, 29}}.
    {move, nil, {y, 30}}.
    {move, nil, {y, 31}}.
    {loop_rec_end, {f, 247}}.
  {label, 248}.
    {wait, {f, 247}}.

{function, '__bp_tpl_5-t/1-fun-4-', 3, 236}.
  {label, 235}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_5-t/1-fun-4-'}, 3}.
  {label, 236}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {jump, {f, 240}}.
  {label, 240}.
    {test_heap, {alloc, [{words, 4}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 242}, 2, 0, {x, 0}, {list, [{y, 2}, {y, 0}, {y, 3}, {y, 1}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, spawn, 1}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_gen'}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_5', 1, 199}.
  {label, 198}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_5'}, 1}.
  {label, 199}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 203}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 214}}.
  {label, 214}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 216}, 4, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 234}}.
  {label, 234}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 236}, 5, 0, {x, 0}, {list, [{y, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 268}}.
  {label, 268}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_6-t/1-fun-0-', 1, 282}.
  {label, 281}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_6-t/1-fun-0-'}, 1}.
  {label, 282}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 286}, [{x, 0}]}.
    {test, test_arity, {f, 286}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {get_tuple_element, {x, 0}, 2, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 286}, [{x, 0}, {atom, mem}]}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, counters, get, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 288}}.
  {label, 288}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 0}}.
    {jump, {f, 290}}.
  {label, 290}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, <<"\n">>}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 292}, [{x, 0}, {atom, nomatch}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {move, {y, 8}, {x, 2}}.
    {call_ext, 3, {extfunc, counters, add, 3}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 292}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 293}, [{x, 0}]}.
    {test, test_arity, {f, 293}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {move, {y, 8}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {move, {y, 9}, {x, 2}}.
    {call_ext, 3, {extfunc, counters, add, 3}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {y, 9}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 293}.
    {move, {y, 7}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 286}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_line, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 296}, [{x, 0}]}.
    {test, test_arity, {f, 296}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 296}, [{x, 0}, {atom, ok}]}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 296}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 297}, [{x, 0}, {atom, eof}]}.
    {move, {literal, {ok, <<"">>}}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 297}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 298}, [{x, 0}]}.
    {test, test_arity, {f, 298}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 298}, [{x, 0}, {atom, error}]}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 298}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_6', 1, 276}.
  {label, 275}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_6'}, 1}.
  {label, 276}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 279}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 282}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 300}, [{x, 0}]}.
    {test, test_arity, {f, 300}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 300}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 299}}.
  {label, 300}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 301}, [{x, 0}]}.
    {test, test_arity, {f, 301}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 301}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 299}}.
  {label, 301}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 299}}.
  {label, 299}.
    {jump, {f, 280}}.
  {label, 279}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 306}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 305}}.
  {label, 306}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 307}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 305}}.
  {label, 307}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 308}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 305}}.
  {label, 308}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 305}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 303}}.
  {label, 303}.
  {label, 280}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_7-t/1-fun-0-', 1, 318}.
  {label, 317}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_7-t/1-fun-0-'}, 1}.
  {label, 318}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 322}}.
  {label, 322}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {test, is_ge, {f, 324}, [{x, 0}, {x, 1}]}.
    {jump, {f, 325}}.
  {label, 325}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {integer, 2}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 327}, [{x, 0}, {literal, <<"\r\n">>}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_ext_last, 3, {extfunc, binary, part, 3}, 7}.
  {label, 327}.
    {move, {y, 2}, {x, 0}}.
    {test, is_binary, {f, 328}, [{x, 0}]}.
    {gc_bif, byte_size, {f, 328}, 1, [{x, 0}], {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 328}, [{x, 0}, {integer, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, binary, decode_unsigned, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bsr', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 255}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'band', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 328}, [{x, 0}, {integer, 10}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_ext_last, 3, {extfunc, binary, part, 3}, 7}.
  {label, 328}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 324}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {test, is_eq_exact, {f, 330}, [{x, 0}, {x, 1}]}.
    {jump, {f, 331}}.
  {label, 331}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 333}, [{x, 0}, {literal, <<"\n">>}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 333}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 330}.
    {jump, {f, 336}}.
  {label, 336}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '__bp_tpl_7', 1, 314}.
  {label, 313}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_7'}, 1}.
  {label, 314}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 318}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_8-t/1-fun-0-', 1, 342}.
  {label, 341}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_8-t/1-fun-0-'}, 1}.
  {label, 342}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {move, {atom, utf8}, {x, 2}}.
    {call_ext, 3, {extfunc, unicode, characters_to_binary, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 346}, [{x, 0}]}.
    {jump, {f, 347}}.
  {label, 347}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 346}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 348}, [{x, 0}]}.
    {test, test_arity, {f, 348}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 348}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, byte_size, 1}, 5}.
  {label, 348}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 349}, [{x, 0}]}.
    {test, test_arity, {f, 349}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 349}, [{x, 0}, {atom, incomplete}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, byte_size, 1}, 5}.
  {label, 349}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_8', 1, 338}.
  {label, 337}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_8'}, 1}.
  {label, 338}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 342}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_9-t/1-fun-0-', 1, 359}.
  {label, 358}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_9-t/1-fun-0-'}, 1}.
  {label, 359}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, -9223372036854775807}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {gc_bif, '-', {f, 361}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test, is_ge, {f, 361}, [{x, 0}, {x, 1}]}.
    {move, {integer, 9223372036854775807}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_ge, {f, 361}, [{x, 0}, {x, 1}]}.
    {jump, {f, 362}}.
  {label, 362}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 361}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 364}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" does not fit i64">>}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toI64: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 365}}.
  {label, 364}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 365}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_9', 1, 355}.
  {label, 354}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_9'}, 1}.
  {label, 355}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 359}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_10-t/1-fun-0-', 1, 375}.
  {label, 374}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_10-t/1-fun-0-'}, 1}.
  {label, 375}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 379}, [{x, 0}]}.
    {jump, {f, 380}}.
  {label, 380}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 379}.
    {move, {literal, {error, <<"Bytes.toUtf8: not valid UTF-8">>}}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_10', 1, 371}.
  {label, 370}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_10'}, 1}.
  {label, 371}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 375}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '-glob/1-gen-1-', 1, 270}.
  {label, 269}.
    {line, [{location, "std@io@fs@@File.erl", 27}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, '-glob/1-gen-1-'}, 1}.
  {label, 270}.
    {allocate, 11, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {line, [{location, "std@io@fs@@File.erl", 27}]}.
  {label, 272}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 273}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 274}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 274}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 309}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 309}.
    {call, 1, {f, 276}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, std@io@fs, lift, 2}}.
    {test, is_tagged_tuple, {f, 310}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 311}}.
  {label, 310}.
    {call, 1, {f, 142}}.
    {jump, {f, 271}}.
  {label, 311}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, byte_size, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 312}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 273}}.
  {label, 312}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 314}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 338}}.
    {move, {x, 0}, {y, 5}}.
    {test, is_ge, {f, 350}, [{y, 5}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 351}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 351}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 1}, {y, 5}], {x, 0}}.
    {test, is_ge, {f, 352}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 352}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 353}}.
  {label, 352}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i64 at src/io/fs.bp:561:21">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 353}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__invalidutf8}, {x, 1}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {call, 1, {f, 142}}.
    {jump, {f, 271}}.
  {label, 350}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, byte_size, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 355}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 366}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 366}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 367}}.
  {label, 366}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i64 at src/io/fs.bp:563:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 367}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 371}}.
    {test, is_tagged_tuple, {f, 368}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 369}}.
  {label, 368}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 369}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {call, 1, {f, 142}}.
    {jump, {f, 272}}.
  {label, 273}.
  {label, 271}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 11}.
    return.

{function, '__bp_tpl_11--t/1-fun-0--fun-1-', 3, 398}.
  {label, 397}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_11--t/1-fun-0--fun-1-'}, 3}.
  {label, 398}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {x, 2}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 398}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {integer, 65536}, {x, 2}}.
    {call_ext, 3, {extfunc, file, pread, 3}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 402}, [{x, 0}]}.
    {test, test_arity, {f, 402}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 402}, [{x, 0}, {atom, ok}]}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, crypto, hash_update, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_last, 3, {f, 398}, 9}.
  {label, 402}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 403}, [{x, 0}, {atom, eof}]}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, crypto, hash_final, 1}, 9}.
  {label, 403}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 404}, [{x, 0}]}.
    {test, test_arity, {f, 404}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 404}, [{x, 0}, {atom, error}]}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 9}.
  {label, 404}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_11-t/1-fun-0-', 1, 389}.
  {label, 388}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_11-t/1-fun-0-'}, 1}.
  {label, 389}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 393}, [{x, 0}]}.
    {test, test_arity, {f, 393}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 393}, [{x, 0}, {atom, mem}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {atom, sha256}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, crypto, hash, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, binary, encode_hex, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, string, lowercase, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 5}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 393}.
    {move, {y, 2}, {x, 0}}.
    {move, {atom, cur}, {x, 1}}.
    {call_ext, 2, {extfunc, file, position, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 395}, [{x, 0}]}.
    {test, test_arity, {f, 395}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 395}, [{x, 0}, {atom, ok}]}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 396}}.
  {label, 395}.
    {move, {y, 3}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 396}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 398}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 406}}.
  {label, 406}.
    {move, {atom, sha256}, {x, 0}}.
    {call_ext, 1, {extfunc, crypto, hash_init, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 408}}.
  {label, 408}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, file, position, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 409}, [{x, 0}]}.
    {test, test_arity, {f, 409}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 409}, [{x, 0}, {atom, ok}]}.
    {jump, {f, 410}}.
  {label, 409}.
    {move, {y, 3}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 410}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, binary, encode_hex, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, string, lowercase, 1}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '__bp_tpl_11', 1, 383}.
  {label, 382}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_11'}, 1}.
  {label, 383}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 386}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 389}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 412}, [{x, 0}]}.
    {test, test_arity, {f, 412}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 412}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 411}}.
  {label, 412}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 413}, [{x, 0}]}.
    {test, test_arity, {f, 413}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 413}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 411}}.
  {label, 413}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 411}}.
  {label, 411}.
    {jump, {f, 387}}.
  {label, 386}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 418}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 417}}.
  {label, 418}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 419}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 417}}.
  {label, 419}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 420}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 417}}.
  {label, 420}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 417}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 415}}.
  {label, 415}.
  {label, 387}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_12', 1, 426}.
  {label, 425}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_12'}, 1}.
  {label, 426}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 430}, [{x, 0}]}.
    {test, test_arity, {f, 430}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 430}, [{x, 0}, {atom, mem}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 430}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_13-t/2-fun-0-', 2, 441}.
  {label, 440}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_13-t/2-fun-0-'}, 2}.
  {label, 441}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, file, write, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 445}, [{x, 0}, {atom, ok}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 445}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 446}, [{x, 0}]}.
    {test, test_arity, {f, 446}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 446}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 446}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_13', 2, 435}.
  {label, 434}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_13'}, 2}.
  {label, 435}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {'try', {y, 12}, {f, 438}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 441}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 7}}.
    {try_end, {y, 12}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 448}, [{x, 0}]}.
    {test, test_arity, {f, 448}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 448}, [{x, 0}, {atom, ok}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 447}}.
  {label, 448}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 449}, [{x, 0}]}.
    {test, test_arity, {f, 449}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 449}, [{x, 0}, {atom, error}]}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 10}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 447}}.
  {label, 449}.
    {move, {y, 7}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 5}}.
    {jump, {f, 447}}.
  {label, 447}.
    {jump, {f, 439}}.
  {label, 438}.
    {try_case, {y, 12}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 454}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 10}}.
    {jump, {f, 453}}.
  {label, 454}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 455}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 10}}.
    {jump, {f, 453}}.
  {label, 455}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 456}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 10}}.
    {jump, {f, 453}}.
  {label, 456}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 453}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 451}}.
  {label, 451}.
  {label, 439}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_14-t/1-fun-0-', 1, 467}.
  {label, 466}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_14-t/1-fun-0-'}, 1}.
  {label, 467}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 471}, [{x, 0}]}.
    {test, test_arity, {f, 471}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 471}, [{x, 0}, {atom, mem}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 471}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, close, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 474}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 474}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 475}, [{x, 0}]}.
    {test, test_arity, {f, 475}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 475}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 475}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_14', 1, 461}.
  {label, 460}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_14'}, 1}.
  {label, 461}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 464}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 467}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 477}, [{x, 0}]}.
    {test, test_arity, {f, 477}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 477}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 476}}.
  {label, 477}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 478}, [{x, 0}]}.
    {test, test_arity, {f, 478}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 478}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 476}}.
  {label, 478}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 476}}.
  {label, 476}.
    {jump, {f, 465}}.
  {label, 464}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 483}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 482}}.
  {label, 483}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 484}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 482}}.
  {label, 484}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 485}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 482}}.
  {label, 485}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 482}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 480}}.
  {label, 480}.
  {label, 465}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- std/probe.bp
```botopink
import {path: {join}, io.fs.readText};

pub fn peek(p: string) -> string {
    return readText(join([p, "a"]));
}
```

----- COMPILE DIAGNOSTIC -- std/probe
```text
error: std-root-imports-io: std module `probe` is at the root of std, which is pure; `io.fs.readText` imports from `io/`
  ┌─ std/probe.bp:1:23
  │
1 │ import {path: {join}, io.fs.readText};
  │                       ^

  hint: Move the module under `io/` (it talks to the world), or take the value it needs as a parameter.
```

