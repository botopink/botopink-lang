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
// on `Array<T>` default-fn bodies that lower to a `var` + `push` shape,
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
{exports, [{separator, 0}, {delimiter, 0}, {split, 1}, {isAbsolute, 1}, {basename, 1}, {dirname, 1}, {extname, 1}, {join, 1}, {normalize, 1}, {relative, 2}, {resolve, 1}, {withoutExtension, 1}, {isInside, 2}]}.
{attributes, []}.
{labels, 233}.

{function, 'Array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "std@path.erl", 1}]}.
    {func_info, {atom, std@path}, {atom, 'Array_range'}, 2}.
  {label, 3}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 42}, [{y, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 43}}.
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 43}.
    {deallocate, 4}.
    return.

{function, 'Array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "std@path.erl", 2}]}.
    {func_info, {atom, std@path}, {atom, 'Array_repeat'}, 2}.
  {label, 5}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 44}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 45}}.
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 45}.
    {deallocate, 4}.
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
    {call, 2, {f, 47}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
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
    {test, is_eq, {f, 67}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 68}}.
  {label, 67}.
    {move, {atom, true}, {x, 0}}.
  {label, 68}.
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
    {test, is_eq_exact, {f, 69}, [{y, 2}, {integer, 0}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 69}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 71}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 71}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 72}}.
  {label, 71}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:40:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 72}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 74}}.
    {test, is_ne_exact, {f, 70}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 77}}.
  {label, 70}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 77}.
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
    {test, is_ge, {f, 78}, [{integer, 1}, {y, 2}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 13}}.
    {test, is_eq, {f, 79}, [{x, 0}, {atom, true}]}.
    {call, 0, {f, 7}}.
    {jump, {f, 80}}.
  {label, 79}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 80}.
    {deallocate, 10}.
    return.
  {label, 78}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 81}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 81}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 82}}.
  {label, 81}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:50:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 82}.
    {test, is_ne_exact, {f, 83}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 0}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {integer, 0}], {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 84}}.
  {label, 83}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 84}.
    {move, {x, 0}, {y, 3}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call, 2, {f, 86}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 13}}.
    {test, is_eq, {f, 91}, [{x, 0}, {atom, true}]}.
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
    {call, 2, {f, 86}}.
    {jump, {f, 92}}.
  {label, 91}.
    {move, {y, 4}, {x, 0}}.
  {label, 92}.
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
    {call, 2, {f, 47}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_ge, {f, 93}, [{integer, 1}, {y, 3}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 93}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 74}}.
    {test, is_ne_exact, {f, 94}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 95}}.
  {label, 94}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 95}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 97}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 97}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 98}}.
  {label, 97}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:68:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 98}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 74}}.
    {test, is_ne_exact, {f, 96}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 99}}.
  {label, 96}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 99}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 100}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 101}}.
  {label, 100}.
    {move, {atom, false}, {x, 0}}.
  {label, 101}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 102}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 104}, [{y, 3}, {integer, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 105}}.
  {label, 104}.
    {move, {atom, false}, {x, 0}}.
  {label, 105}.
    {jump, {f, 103}}.
  {label, 102}.
    {move, {atom, false}, {x, 0}}.
  {label, 103}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq, {f, 106}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 107}}.
  {label, 106}.
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
    {call, 2, {f, 86}}.
  {label, 107}.
    {deallocate, 10}.
    return.
% Join a list of path segments with the separator. Leading separator on
% the first segment is preserved; intra-segment slashes are normalised
% (`"foo/" + "/bar"` joins to `"foo/bar"`, never `"foo//bar"`). Uses
% `map` + `filter` + `join` rather than `fold` / `flatMap`: those land
% on `Array<T>` default-fn bodies that lower to a `var` + `push` shape,
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
    {test, is_eq_exact, {f, 108}, [{x, 0}, {integer, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 109}}.
  {label, 108}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 74}}.
    {test, is_ne_exact, {f, 110}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 111}}.
  {label, 110}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 111}.
    {call, 1, {f, 13}}.
  {label, 109}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 113}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 115}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {move, {x, 0}, {y, 4}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call, 2, {f, 86}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 118}, [{x, 0}, {atom, true}]}.
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
    {call, 2, {f, 86}}.
    {jump, {f, 119}}.
  {label, 118}.
    {move, {y, 5}, {x, 0}}.
  {label, 119}.
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
    {test, is_eq_exact, {f, 120}, [{y, 0}, {x, 0}]}.
    {move, {literal, <<".">>}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 120}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 122}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {move, {x, 0}, {y, 2}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 86}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 125}, [{x, 0}, {atom, true}]}.
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
    {call, 2, {f, 86}}.
    {jump, {f, 126}}.
  {label, 125}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 127}, [{y, 3}, {x, 0}]}.
    {move, {literal, <<".">>}, {x, 0}}.
    {jump, {f, 128}}.
  {label, 127}.
    {move, {y, 3}, {x, 0}}.
  {label, 128}.
  {label, 126}.
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
    {test, is_ge, {f, 129}, [{y, 2}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 129}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ge, {f, 130}, [{y, 2}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 130}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 74}}.
    {test, is_ne_exact, {f, 131}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 132}}.
  {label, 131}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 132}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 74}}.
    {test, is_ne_exact, {f, 133}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 134}}.
  {label, 133}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 134}.
    {move, {x, 0}, {y, 6}}.
    {test, is_eq_exact, {f, 135}, [{y, 4}, {y, 6}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 137}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 137}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 138}}.
  {label, 137}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/path.bp:114:52">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 138}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 25}}.
    {jump, {f, 136}}.
  {label, 135}.
    {move, {y, 2}, {x, 0}}.
  {label, 136}.
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
    {test, is_ge, {f, 139}, [{integer, 0}, {y, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 140}}.
  {label, 139}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 141}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 141}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 142}}.
  {label, 141}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:120:42">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 142}.
    {call, 1, {f, 27}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"..">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 140}.
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
    {test, is_ge, {f, 143}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 143}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 144}}.
  {label, 143}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:135:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 144}.
    {call, 1, {f, 27}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 145}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{y, 4}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {y, 4}], {x, 2}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 146}}.
  {label, 145}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 146}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 7}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {call, 2, {f, 86}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 147}, [{y, 8}, {x, 0}]}.
    {move, {literal, <<".">>}, {x, 0}}.
    {jump, {f, 148}}.
  {label, 147}.
    {move, {y, 8}, {x, 0}}.
  {label, 148}.
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
    {test, is_eq_exact, {f, 149}, [{x, 0}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 149}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 74}}.
    {test, is_ne_exact, {f, 150}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 151}}.
  {label, 150}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 151}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 152}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 1}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {integer, 1}], {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 153}}.
  {label, 152}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 153}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"..">>}, {x, 0}}.
    {test, is_eq_exact, {f, 154}, [{y, 3}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 156}, [{x, 0}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 157}}.
  {label, 156}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 158}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 158}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 159}}.
  {label, 158}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:159:63">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 159}.
    {test, is_ne_exact, {f, 160}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 0}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {integer, 0}], {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 161}}.
  {label, 160}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 161}.
  {label, 157}.
    {jump, {f, 155}}.
  {label, 154}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
  {label, 155}.
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
    {test, is_ne_exact, {f, 162}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 164}, [{x, 0}, 3, {atom, std@path@@PathAccum}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 164}.
    {jump, {f, 163}}.
  {label, 162}.
    {move, {atom, true}, {x, 0}}.
  {label, 163}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 13}}.
    {test, is_eq, {f, 165}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 166}}.
  {label, 165}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 167}, [{x, 0}, 3, {atom, std@path@@PathAccum}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 167}.
  {label, 166}.
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
    {test, is_ge, {f, 168}, [{y, 1}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 168}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 74}}.
    {test, is_ne_exact, {f, 169}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 170}}.
  {label, 169}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 170}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 33}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 171}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 171}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 172}}.
  {label, 171}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/path.bp:175:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 172}.
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
    {test, is_tagged_tuple, {f, 173}, [{x, 0}, 3, {atom, std@path@@PathAccum}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 173}.
    {move, {x, 0}, {y, 2}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 86}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 175}, [{x, 0}, 3, {atom, std@path@@PathAccum}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 175}.
    {test, is_eq, {f, 174}, [{x, 0}, {atom, true}]}.
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
    {call, 2, {f, 86}}.
    {jump, {f, 176}}.
  {label, 174}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 177}, [{y, 3}, {x, 0}]}.
    {move, {literal, <<".">>}, {x, 0}}.
    {jump, {f, 178}}.
  {label, 177}.
    {move, {y, 3}, {x, 0}}.
  {label, 178}.
  {label, 176}.
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
    {test, is_eq_exact, {f, 179}, [{y, 1}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 180}}.
  {label, 179}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 183}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 183}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 184}}.
  {label, 183}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:205:51">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 184}.
    {move, {integer, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 182}}.
  {label, 180}.
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
    {test, is_eq_exact, {f, 185}, [{y, 6}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 186}}.
  {label, 185}.
    {move, {atom, false}, {x, 0}}.
  {label, 186}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 187}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"../">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 189}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 190}}.
  {label, 189}.
    {move, {atom, true}, {x, 0}}.
  {label, 190}.
    {jump, {f, 188}}.
  {label, 187}.
    {move, {atom, true}, {x, 0}}.
  {label, 188}.
    {move, {x, 0}, {y, 7}}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 191}, [{y, 7}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 192}}.
  {label, 191}.
    {move, {atom, false}, {x, 0}}.
  {label, 192}.
    {deallocate, 10}.
    return.
% ── tests ────────────────────────────────────────────────────────────────────

{function, 'String_slice', 3, 182}.
  {label, 181}.
    {line, [{location, "std@path.erl", 21}]}.
    {func_info, {atom, std@path}, {atom, 'String_slice'}, 3}.
  {label, 182}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 193}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 195}, 3}.
  {label, 193}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 217}, 3}.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 51}.
  {label, 50}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 51}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 55}, [{x, 0}]}.
    {jump, {f, 56}}.
  {label, 55}.
    {test, is_tuple, {f, 57}, [{x, 0}]}.
    {test, test_arity, {f, 57}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 56}}.
  {label, 57}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 56}.
    {move, {x, 0}, {y, 4}}.
  {label, 58}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 59}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 61}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 61}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 62}}.
  {label, 61}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 62}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 58}}.
  {label, 59}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 60}, [{x, 0}]}.
    {jump, {f, 54}}.
  {label, 60}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 54}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 53}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_0', 2, 47}.
  {label, 46}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_0'}, 2}.
  {label, 47}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 51}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-split/1-fun-0-', 1, 64}.
  {label, 63}.
    {line, [{location, "std@path.erl", 6}]}.
    {func_info, {atom, std@path}, {atom, '-split/1-fun-0-'}, 1}.
  {label, 64}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 65}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 66}}.
  {label, 65}.
    {move, {atom, false}, {x, 0}}.
  {label, 66}.
    {deallocate, 1}.
    return.

{function, '-bp_at-', 2, 74}.
  {label, 73}.
    {line, [{location, "std@path.erl", 8}]}.
    {func_info, {atom, std@path}, {atom, '-bp_at-'}, 2}.
  {label, 74}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 76}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 75}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 76}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 75}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 75}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 88}.
  {label, 87}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '-bp_stringify-'}, 1}.
  {label, 88}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 89}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 89}.
    {test, is_integer, {f, 90}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 90}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 0}.

{function, '-bp_join-', 2, 86}.
  {label, 85}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '-bp_join-'}, 2}.
  {label, 86}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 88}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '-join/1-fun-1-', 1, 113}.
  {label, 112}.
    {line, [{location, "std@path.erl", 11}]}.
    {func_info, {atom, std@path}, {atom, '-join/1-fun-1-'}, 1}.
  {label, 113}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {y, 1}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 86}}.
    {deallocate, 3}.
    return.

{function, '-join/1-fun-2-', 1, 115}.
  {label, 114}.
    {line, [{location, "std@path.erl", 11}]}.
    {func_info, {atom, std@path}, {atom, '-join/1-fun-2-'}, 1}.
  {label, 115}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 116}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 117}}.
  {label, 116}.
    {move, {atom, false}, {x, 0}}.
  {label, 117}.
    {deallocate, 1}.
    return.

{function, '-normalize/1-fun-3-', 1, 122}.
  {label, 121}.
    {line, [{location, "std@path.erl", 12}]}.
    {func_info, {atom, std@path}, {atom, '-normalize/1-fun-3-'}, 1}.
  {label, 122}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<".">>}, {x, 0}}.
    {test, is_ne_exact, {f, 123}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 124}}.
  {label, 123}.
    {move, {atom, false}, {x, 0}}.
  {label, 124}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_1-t/3-fun-0-', 3, 199}.
  {label, 198}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_1-t/3-fun-0-'}, 3}.
  {label, 199}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 203}}.
  {label, 203}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 205}}.
  {label, 205}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 207}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 206}}.
  {label, 207}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 208}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 206}}.
  {label, 208}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 206}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 210}}.
  {label, 210}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 212}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 211}}.
  {label, 212}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 213}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 211}}.
  {label, 213}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 211}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 215}}.
  {label, 215}.
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

{function, '__bp_tpl_1', 3, 195}.
  {label, 194}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_1'}, 3}.
  {label, 195}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 199}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_2-t/2-fun-0-', 2, 221}.
  {label, 220}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_2-t/2-fun-0-'}, 2}.
  {label, 221}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 225}}.
  {label, 225}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 227}}.
  {label, 227}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 229}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 228}}.
  {label, 229}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 230}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 228}}.
  {label, 230}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 228}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 232}}.
  {label, 232}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_2', 2, 217}.
  {label, 216}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_2'}, 2}.
  {label, 217}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 221}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
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

----- SOURCE CODE -- std/io/fs.bp
```botopink
//// std/io/fs — synchronous filesystem primitives, cross-backend.
////
//// Reference:
////   Node.js  — https://nodejs.org/api/fs.html
////              (`readFileSync`, `writeFileSync`, `existsSync`,
////               `readdirSync`, `mkdirSync`, `rmSync`, `statSync`,
////               `copyFileSync`)
////   Erlang   — https://www.erlang.org/doc/man/file.html
////              (`file:read_file/1`, `file:write_file/2`,
////               `filelib:is_regular/1`, `file:list_dir/1`,
////               `file:make_dir/1`, `file:delete/1`,
////               `file:read_file_info/1`, `file:copy/2`)
////
//// All operations are synchronous (`*Sync` on Node, blocking BIFs on
//// Erlang). Each fallible operation returns `@Result<R, string>` via
//// the §A3 `declare fn` template-owned wrapper — the host
//// template wraps the call in try/catch and lifts the error to the
//// `{error, <message>}` channel.

import {path.relative};

pub type FileStat(
    size: i64,
    mtime: i64,
    isDir: bool,
)

// Read the entire file as a UTF-8 string. Reds with the host's I/O
// error message on missing file / permission denied / etc.
// Node: `require('fs').readFileSync($0, 'utf8')`.
// Erlang: `file:read_file/1` returns `{ok, Bin}` or `{error, Reason}`.
#[@External.Node("""(() => { try { return { ok: require('fs').readFileSync($0, 'utf8') } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> case file:read_file(__P) of {ok, __B} -> {ok, __B}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0)""")]
pub declare fn readText(path: string) -> @Result<string, string>;

// Write `contents` to `path`, creating or truncating. Reds with the
// host's I/O error message.
// Node: `require('fs').writeFileSync($0, $1)`.
// Erlang: `file:write_file/2`.
#[@External.Node("""(() => { try { require('fs').writeFileSync($0, $1); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0, $1)""")]
pub declare fn writeText(
    path: string,
    contents: string,
) -> @Result<i32, string>;

// Whether a path exists, of any kind: a regular file, a directory, a
// character or block device (`/dev/null`), a FIFO or a socket. A symbolic
// link is followed — one whose target is missing is `false`, the answer
// every read through it would give.
// Node: `require('fs').existsSync($0)` (a `stat`).
// Erlang: `file:read_file_info/1` (a `stat`; `filelib:is_file/1`, which it
// replaces, answers only regular files and directories, so `/dev/null`
// was `false` on erlang and `true` on commonJS).
#[@External.Node("""require('fs').existsSync($0)""")]
#[@External.Erlang("""(case file:read_file_info($0) of {ok, _} -> true; _ -> false end)""")]
pub declare fn exists(path: string) -> bool;

// List the names of the directory entries at `path` (relative).
// Node: `require('fs').readdirSync($0)`.
// Erlang: `file:list_dir/1` returns `{ok, [string()]}`.
#[@External.Node("""(() => { try { return { ok: require('fs').readdirSync($0) } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> case file:list_dir(__P) of {ok, __L} -> {ok, [list_to_binary(__N) || __N <- __L]}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0)""")]
pub declare fn list(path: string) -> @Result<string[], string>;

// Create directory at `path`. Use `mkdirRecursive` to create
// intermediate parents (the spec's `recursive: bool = true` overload
// gates on default-fn-param-default support landing).
// Node: `require('fs').mkdirSync($0)`.
// Erlang: `file:make_dir/1`.
#[@External.Node("""(() => { try { require('fs').mkdirSync($0); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> case file:make_dir(__P) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0)""")]
pub declare fn mkdir(path: string) -> @Result<i32, string>;

// Delete the FILE at `path`. A directory — empty or not — is an `Error` on
// both hosts (`ERR_FS_EISDIR` / `eperm`); `removeTree` removes one.
// Node: `require('fs').rmSync($0)`.
// Erlang: `file:delete/1`.
#[@External.Node("""(() => { try { require('fs').rmSync($0); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> case file:delete(__P) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0)""")]
pub declare fn rm(path: string) -> @Result<i32, string>;

// Copy file from `src` to `dest`. Reds when `src` is missing or
// `dest` already exists (Node's default `copyFileSync` semantics).
// Node: `require('fs').copyFileSync($0, $1)`.
// Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).
#[@External.Node("""(() => { try { require('fs').copyFileSync($0, $1); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__S, __D) -> case file:copy(__S, __D) of {ok, _} -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0, $1)""")]
pub declare fn copy(src: string, dest: string) -> @Result<i32, string>;

// File metadata. Returns a `FileStat { size, mtime, isDir }` on
// success. `mtime` is epoch milliseconds (matching `time.nowMillis()`);
// `size` is in bytes.
// Node: `statSync($0, { bigint: true })`, so `size` and the nanosecond
// `mtimeNs` arrive exact at any size; `mtime` is `mtimeNs` floored to whole
// milliseconds, and both answer decision 319's canonical form (a `number`
// within ±(2^53 − 1), a `BigInt` beyond) — never a `number` rounded past 2^53.
// Erlang: `file:read_file_info/1` returns a `#file_info` record; the
// template projects the `size`, `mtime`, and `type` fields. Its `mtime` is
// whole seconds × 1000 — a resolution the Node form does not share
// (question `97-s13-d`).
#[@External.Node("""(() => { try { const __s = require('fs').statSync($0, { bigint: true }); const __c = (__v) => (__v >= -9007199254740991n && __v <= 9007199254740991n) ? Number(__v) : __v; const __ns = __s.mtimeNs; return { ok: { size: __c(__s.size), mtime: __c((__ns - (((__ns % 1000000n) + 1000000n) % 1000000n)) / 1000000n), isDir: __s.isDirectory() } } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> case file:read_file_info(__P, [{time, posix}]) of {ok, {file_info, __Sz, __Ty, _, _, __Mt, _, _, _, _, _, _, _, _}} -> {ok, #{size => __Sz, mtime => __Mt * 1000, isDir => (__Ty =:= directory)}}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0)""")]
pub declare fn stat(path: string) -> @Result<FileStat, string>;

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
#[@External.Node("""(() => { try { const __fs = require('fs'); const __p = require('path'); const __all = __fs.readdirSync($0, { recursive: true }).map(__f => String(__f).split(__p.sep).join('/')).sort(); const __out = []; for (const __f of __all) { const __s = __fs.statSync(__p.join($0, __f), { throwIfNoEntry: false }); if (__s === undefined) return { error: 'fs.walk: dangling link "' + __f + '"' }; if (__s.isFile()) __out.push(__f) } return { ok: __out } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__R) -> __Root = unicode:characters_to_list(__R), case filelib:is_dir(__Root) of false -> {error, <<"enotdir">>}; true -> __Walk = fun __W(__Dir, __Rel, __Acc) -> case file:list_dir(__Dir) of {error, __E} -> throw({bp_fs_walk, __E}); {ok, __Names} -> lists:foldl(fun(__Name, __A) -> __Full = filename:join(__Dir, __Name), __Sub = case __Rel of [] -> __Name; _ -> __Rel ++ "/" ++ __Name end, case file:read_file_info(__Full) of {ok, __I} when element(3, __I) =:= directory -> __W(__Full, __Sub, __A); {ok, __I} when element(3, __I) =:= regular -> [{file, unicode:characters_to_binary(__Sub)} | __A]; {ok, _} -> __A; {error, enoent} -> [{dangling, unicode:characters_to_binary(__Sub)} | __A]; {error, __X} -> throw({bp_fs_walk, __X}) end end, __Acc, __Names) end end, try __Found = __Walk(__Root, [], []), case lists:sort([__D || {dangling, __D} <- __Found]) of [__First | _] -> {error, <<"fs.walk: dangling link ", 34, __First/binary, 34>>}; [] -> {ok, lists:sort([__F || {file, __F} <- __Found])} end catch throw:{bp_fs_walk, __Y} -> {error, iolist_to_binary(io_lib:format("~p", [__Y]))} end end end)($0)""")]
pub declare fn walk(root: string) -> @Result<string[], string>;

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
#[@External.Node("""(() => { try { const __fs = require('fs'); const __p = require('path'); const __root = $1; const __pat = String($0); const __segs = __pat.split('/').filter(__s => __s !== '' && __s !== '.'); const __dirsOnly = __pat.endsWith('/'); const __lst = (__f) => { try { return __fs.lstatSync(__f, { throwIfNoEntry: false }) } catch (__e) { return undefined } }; const __realDir = (__f) => { const __s = __lst(__f); return __s !== undefined && __s.isDirectory() }; const __linkedDir = (__f) => { try { const __s = __fs.statSync(__f, { throwIfNoEntry: false }); return __s !== undefined && __s.isDirectory() } catch (__e) { return false } }; const __magic = (__s) => __s.includes('*') || __s.includes('?') || __s.includes('[') || __s.includes('{'); const __names = (__dir, __seg) => { let __all; try { __all = (__seg === '*' ? __fs.readdirSync(__dir) : __fs.globSync(__seg, { cwd: __dir })).map(String) } catch (__e) { __all = [] } return __all.filter(__n => !__n.startsWith('.') || __seg.startsWith('.')) }; const __join = (__rel, __n) => __rel === '' ? __n : __rel + '/' + __n; const __out = new Set(); const __walk = (__i, __dir, __rel) => { if (__i === __segs.length) { if (__rel !== '') __out.add(__rel); return } const __seg = __segs[__i]; const __last = __i === __segs.length - 1; if (__seg === '**') { if (!__last) __walk(__i + 1, __dir, __rel); for (const __n of __names(__dir, '*')) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); if (__realDir(__f)) __walk(__i, __f, __sub) } return } if (!__magic(__seg)) { const __f = __p.join(__dir, __seg); const __sub = __join(__rel, __seg); if (__last) { if (__lst(__f) !== undefined) __out.add(__sub) } else if (__linkedDir(__f)) __walk(__i + 1, __f, __sub); return } for (const __n of __names(__dir, __seg)) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); else if (__realDir(__f)) __walk(__i + 1, __f, __sub) } }; __walk(0, __root, ''); return { ok: Array.from(__out).filter(__r => !__dirsOnly || __realDir(__p.join(__root, __r))).sort() } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P, __R) -> __Root = unicode:characters_to_list(__R), __Pat = unicode:characters_to_list(__P), __Segs = [__S || __S <- string:split(__Pat, "/", all), __S =/= [], __S =/= "."], __DirsOnly = lists:suffix("/", __Pat), __RealDir = fun(__F) -> case file:read_link_info(__F) of {ok, __I} -> element(3, __I) =:= directory; _ -> false end end, __Magic = fun(__S) -> lists:any(fun(__C) -> lists:member(__C, "*?[{") end, __S) end, __Names = fun(__Dir, __Seg) -> __All = case __Seg of "*" -> case file:list_dir(__Dir) of {ok, __L} -> __L; _ -> [] end; _ -> try filelib:wildcard(__Seg, __Dir) catch _:_ -> [] end end, [__N || __N <- __All, (hd(__N) =/= 46) orelse (hd(__Seg) =:= 46)] end, __Join = fun([], __N) -> __N; (__Rel, __N) -> __Rel ++ "/" ++ __N end, __Walk = fun __W([], _, [], __Acc) -> __Acc; __W([], _, __Rel, __Acc) -> [__Rel | __Acc]; __W(["**"], __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), __Sub = __Join(__Rel, __N), case __RealDir(__F) of true -> __W(["**"], __F, __Sub, [__Sub | __A]); false -> [__Sub | __A] end end, __Acc, __Names(__Dir, "*")); __W(["**" | __Rest] = __Pattern, __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), case __RealDir(__F) of true -> __W(__Pattern, __F, __Join(__Rel, __N), __A); false -> __A end end, __W(__Rest, __Dir, __Rel, __Acc), __Names(__Dir, "*")); __W([__Seg | __Rest], __Dir, __Rel, __Acc) -> case __Magic(__Seg) of false -> __F = filename:join(__Dir, __Seg), __Sub = __Join(__Rel, __Seg), case __Rest of [] -> case file:read_link_info(__F) of {ok, _} -> [__Sub | __Acc]; _ -> __Acc end; _ -> case filelib:is_dir(__F) of true -> __W(__Rest, __F, __Sub, __Acc); false -> __Acc end end; true -> lists:foldl(fun(__N, __A) -> __G = filename:join(__Dir, __N), __Under = __Join(__Rel, __N), case __Rest of [] -> [__Under | __A]; _ -> case __RealDir(__G) of true -> __W(__Rest, __G, __Under, __A); false -> __A end end end, __Acc, __Names(__Dir, __Seg)) end end, {ok, [unicode:characters_to_binary(__X) || __X <- lists:usort(__Walk(__Segs, __Root, [], [])), (not __DirsOnly) orelse __RealDir(filename:join(__Root, __X))]} end)($0, $1)""")]
pub declare fn glob(pattern: string, root: string) -> @Result<string[], string>;

// Remove `path` and everything under it: a file, a link (the link, never its
// target) or a directory tree. A path that is not there is `Ok` too — the
// caller wanted it gone. What a test fixture is cleared with, and what the
// snapshot engine's tests clear their scratch directories with (1.0.11-beta
// front 97).
// Node: `rmSync(path, { recursive: true, force: true })`.
// Erlang: `file:del_dir_r/1`.
#[@External.Node("""(() => { try { require('fs').rmSync($0, { recursive: true, force: true }); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> case file:del_dir_r(__P) of ok -> {ok, 0}; {error, enoent} -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0)""")]
pub declare fn removeTree(path: string) -> @Result<i32, string>;

// Internal, test scaffolding: a fresh, unique, empty directory under the
// host's tmpdir. Private — every `walk`/`glob` test makes its fixture tree in
// one of these and removes it with `removeTree`, so a run leaves nothing under
// the host's tmpdir.
#[@External.Node("""require('fs').mkdtempSync(require('path').join(require('os').tmpdir(), 'bp-std-fs-'))""")]
#[@External.Erlang("""(fun() -> __T = case os:getenv("TMPDIR") of false -> "/tmp"; __V -> __V end, __D = filename:join(__T, "bp-std-fs-" ++ integer_to_list(erlang:unique_integer([positive]))), ok = file:make_dir(__D), unicode:characters_to_binary(__D) end)()""")]
declare fn scratchDir() -> string;

// Internal, test scaffolding: the working directory (what a relative root is
// read against) and a symbolic link `link` → `target`.
#[@External.Node("process.cwd()")]
#[@External.Erlang("""(fun() -> {ok, __D} = file:get_cwd(), unicode:characters_to_binary(__D) end)()""")]
declare fn workingDir() -> string;

#[@External.Node("""require('fs').symlinkSync($0, $1)""")]
#[@External.Erlang("""(fun(__T, __L) -> ok = file:make_symlink(__T, __L), ok end)($0, $1)""")]
declare fn linkTo(target: string, link: string) -> void;

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
        Error(reason) -> reason;
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

```

----- BEAM ASSEMBLY -- std/io/fs.S
```erlang
{module, std@io@fs}.
{exports, [{readText, 1}, {writeText, 2}, {exists, 1}, {list, 1}, {mkdir, 1}, {rm, 1}, {copy, 2}, {stat, 1}, {walk, 1}, {glob, 2}, {removeTree, 1}]}.
{attributes, []}.
{labels, 406}.
%%% std/io/fs — synchronous filesystem primitives, cross-backend.
%%% 
%%% Reference:
%%%   Node.js  — https://nodejs.org/api/fs.html
%%%              (`readFileSync`, `writeFileSync`, `existsSync`,
%%%               `readdirSync`, `mkdirSync`, `rmSync`, `statSync`,
%%%               `copyFileSync`)
%%%   Erlang   — https://www.erlang.org/doc/man/file.html
%%%              (`file:read_file/1`, `file:write_file/2`,
%%%               `filelib:is_regular/1`, `file:list_dir/1`,
%%%               `file:make_dir/1`, `file:delete/1`,
%%%               `file:read_file_info/1`, `file:copy/2`)
%%% 
%%% All operations are synchronous (`*Sync` on Node, blocking BIFs on
%%% Erlang). Each fallible operation returns `@Result<R, string>` via
%%% the §A3 `declare fn` template-owned wrapper — the host
%%% template wraps the call in try/catch and lifts the error to the
%%% `{error, <message>}` channel.
% Read the entire file as a UTF-8 string. Reds with the host's I/O
% error message on missing file / permission denied / etc.
% Node: `require('fs').readFileSync($0, 'utf8')`.
% Erlang: `file:read_file/1` returns `{ok, Bin}` or `{error, Reason}`.

{function, readText, 1, 28}.
  {label, 27}.
    {line, [{location, "std@io@fs.erl", 1}]}.
    {func_info, {atom, std@io@fs}, {atom, readText}, 1}.
  {label, 28}.
    {call_only, 1, {f, 17}}.
% Write `contents` to `path`, creating or truncating. Reds with the
% host's I/O error message.
% Node: `require('fs').writeFileSync($0, $1)`.
% Erlang: `file:write_file/2`.

{function, writeText, 2, 41}.
  {label, 40}.
    {line, [{location, "std@io@fs.erl", 2}]}.
    {func_info, {atom, std@io@fs}, {atom, writeText}, 2}.
  {label, 41}.
    {call_only, 2, {f, 30}}.
% Whether a path exists, of any kind: a regular file, a directory, a
% character or block device (`/dev/null`), a FIFO or a socket. A symbolic
% link is followed — one whose target is missing is `false`, the answer
% every read through it would give.
% Node: `require('fs').existsSync($0)` (a `stat`).
% Erlang: `file:read_file_info/1` (a `stat`; `filelib:is_file/1`, which it
% replaces, answers only regular files and directories, so `/dev/null`
% was `false` on erlang and `true` on commonJS).

{function, exists, 1, 49}.
  {label, 48}.
    {line, [{location, "std@io@fs.erl", 3}]}.
    {func_info, {atom, std@io@fs}, {atom, exists}, 1}.
  {label, 49}.
    {call_only, 1, {f, 43}}.
% List the names of the directory entries at `path` (relative).
% Node: `require('fs').readdirSync($0)`.
% Erlang: `file:list_dir/1` returns `{ok, [string()]}`.

{function, list, 1, 66}.
  {label, 65}.
    {line, [{location, "std@io@fs.erl", 4}]}.
    {func_info, {atom, std@io@fs}, {atom, list}, 1}.
  {label, 66}.
    {call_only, 1, {f, 51}}.
% Create directory at `path`. Use `mkdirRecursive` to create
% intermediate parents (the spec's `recursive: bool = true` overload
% gates on default-fn-param-default support landing).
% Node: `require('fs').mkdirSync($0)`.
% Erlang: `file:make_dir/1`.

{function, mkdir, 1, 79}.
  {label, 78}.
    {line, [{location, "std@io@fs.erl", 5}]}.
    {func_info, {atom, std@io@fs}, {atom, mkdir}, 1}.
  {label, 79}.
    {call_only, 1, {f, 68}}.
% Delete the FILE at `path`. A directory — empty or not — is an `Error` on
% both hosts (`ERR_FS_EISDIR` / `eperm`); `removeTree` removes one.
% Node: `require('fs').rmSync($0)`.
% Erlang: `file:delete/1`.

{function, rm, 1, 92}.
  {label, 91}.
    {line, [{location, "std@io@fs.erl", 6}]}.
    {func_info, {atom, std@io@fs}, {atom, rm}, 1}.
  {label, 92}.
    {call_only, 1, {f, 81}}.
% Copy file from `src` to `dest`. Reds when `src` is missing or
% `dest` already exists (Node's default `copyFileSync` semantics).
% Node: `require('fs').copyFileSync($0, $1)`.
% Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).

{function, copy, 2, 105}.
  {label, 104}.
    {line, [{location, "std@io@fs.erl", 7}]}.
    {func_info, {atom, std@io@fs}, {atom, copy}, 2}.
  {label, 105}.
    {call_only, 2, {f, 94}}.
% File metadata. Returns a `FileStat { size, mtime, isDir }` on
% success. `mtime` is epoch milliseconds (matching `time.nowMillis()`);
% `size` is in bytes.
% Node: `statSync($0, { bigint: true })`, so `size` and the nanosecond
% `mtimeNs` arrive exact at any size; `mtime` is `mtimeNs` floored to whole
% milliseconds, and both answer decision 319's canonical form (a `number`
% within ±(2^53 − 1), a `BigInt` beyond) — never a `number` rounded past 2^53.
% Erlang: `file:read_file_info/1` returns a `#file_info` record; the
% template projects the `size`, `mtime`, and `type` fields. Its `mtime` is
% whole seconds × 1000 — a resolution the Node form does not share
% (question `97-s13-d`).

{function, stat, 1, 118}.
  {label, 117}.
    {line, [{location, "std@io@fs.erl", 8}]}.
    {func_info, {atom, std@io@fs}, {atom, stat}, 1}.
  {label, 118}.
    {allocate, 0, 1}.
    {call, 1, {f, 107}}.
    {move, {atom, std@io@fs@@FileStat}, {x, 1}}.
    {move, {literal, [size, mtime, isDir]}, {x, 2}}.
    {call_last, 3, {f, 341}, 0}.
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

{function, walk, 1, 180}.
  {label, 179}.
    {line, [{location, "std@io@fs.erl", 9}]}.
    {func_info, {atom, std@io@fs}, {atom, walk}, 1}.
  {label, 180}.
    {call_only, 1, {f, 120}}.
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

{function, glob, 2, 325}.
  {label, 324}.
    {line, [{location, "std@io@fs.erl", 10}]}.
    {func_info, {atom, std@io@fs}, {atom, glob}, 2}.
  {label, 325}.
    {call_only, 2, {f, 182}}.
% Remove `path` and everything under it: a file, a link (the link, never its
% target) or a directory tree. A path that is not there is `Ok` too — the
% caller wanted it gone. What a test fixture is cleared with, and what the
% snapshot engine's tests clear their scratch directories with (1.0.11-beta
% front 97).
% Node: `rmSync(path, { recursive: true, force: true })`.
% Erlang: `file:del_dir_r/1`.

{function, removeTree, 1, 339}.
  {label, 338}.
    {line, [{location, "std@io@fs.erl", 11}]}.
    {func_info, {atom, std@io@fs}, {atom, removeTree}, 1}.
  {label, 339}.
    {call_only, 1, {f, 327}}.
% Internal, test scaffolding: a fresh, unique, empty directory under the
% host's tmpdir. Private — every `walk`/`glob` test makes its fixture tree in
% one of these and removes it with `removeTree`, so a run leaves nothing under
% the host's tmpdir.
% Internal, test scaffolding: the working directory (what a relative root is
% read against) and a symbolic link `link` → `target`.
% ── tests ────────────────────────────────────────────────────────────────────
% (Inline tests are smoke-grade — they require the host filesystem to be
% writable at the host's `tmpdir()`. The lib-test harness runs each
% inline test as a separate process; the temp filenames are seeded with
% `time.nowMillis()` for cross-run uniqueness.)
% Internal, test scaffolding: `stat(p)`, or a stat no file has.

{function, statOr, 1, 3}.
  {label, 2}.
    {line, [{location, "std@io@fs.erl", 12}]}.
    {func_info, {atom, std@io@fs}, {atom, statOr}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 107}}.
    {move, {atom, std@io@fs@@FileStat}, {x, 1}}.
    {move, {literal, [size, mtime, isDir]}, {x, 2}}.
    {call, 3, {f, 341}}.
    {test, is_tagged_tuple, {f, 352}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 351}}.
  {label, 352}.
    {test, is_tagged_tuple, {f, 353}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, false}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FileStat}, {integer, -1}, {integer, -1}, {x, 0}]}}.
    {jump, {f, 351}}.
  {label, 353}.
    {case_end, {x, 0}}.
  {label, 351}.
    {deallocate, 2}.
    return.
% Internal, test scaffolding: `<dir>/app/page.bp`, `<dir>/app/blog/page.bp`,
% `<dir>/app/blog/notes.md` — the fixture tree every walk/glob test reads.

{function, makeFixtureTree, 1, 5}.
  {label, 4}.
    {line, [{location, "std@io@fs.erl", 13}]}.
    {func_info, {atom, std@io@fs}, {atom, makeFixtureTree}, 1}.
  {label, 5}.
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
    {call, 2, {f, 355}}.
    {call, 1, {f, 68}}.
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
    {call, 2, {f, 355}}.
    {call, 1, {f, 68}}.
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
    {call, 2, {f, 355}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"root page">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 30}}.
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
    {call, 2, {f, 355}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"blog page">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 30}}.
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
    {call, 2, {f, 355}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"notes">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 30}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 6}.
    return.
% Internal, test scaffolding: what `walk` answers for the fixture tree when
% its root is spelled `<scratch dir><suffix>` — every spelling of one root has
% to answer the same three relative paths.

{function, walkFixture, 1, 7}.
  {label, 6}.
    {line, [{location, "std@io@fs.erl", 14}]}.
    {func_info, {atom, std@io@fs}, {atom, walkFixture}, 1}.
  {label, 7}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 361}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 5}}.
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
    {call, 2, {f, 355}}.
    {call, 1, {f, 120}}.
    {test, is_tagged_tuple, {f, 377}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 378}}.
  {label, 377}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"<error>">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 378}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 327}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_last, 2, {f, 355}, 5}.
% Internal, test scaffolding: the same, with the root spelled relative to the
% working directory — `<prefix><path from the cwd to the fixture>`.

{function, walkFixtureFromCwd, 1, 9}.
  {label, 8}.
    {line, [{location, "std@io@fs.erl", 15}]}.
    {func_info, {atom, std@io@fs}, {atom, walkFixtureFromCwd}, 1}.
  {label, 9}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 361}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"/app">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {call, 0, {f, 380}}.
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
    {call, 2, {f, 355}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 120}}.
    {test, is_tagged_tuple, {f, 389}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 390}}.
  {label, 389}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"<error>">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 390}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 327}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_last, 2, {f, 355}, 8}.
% Internal, test scaffolding: the `Error` of `walk(root)`, `""` when it walked.

{function, walkRefusal, 1, 11}.
  {label, 10}.
    {line, [{location, "std@io@fs.erl", 16}]}.
    {func_info, {atom, std@io@fs}, {atom, walkRefusal}, 1}.
  {label, 11}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 120}}.
    {test, is_tagged_tuple, {f, 392}, [{x, 0}, 2, {atom, ok}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 391}}.
  {label, 392}.
    {test, is_tagged_tuple, {f, 393}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 391}}.
  {label, 393}.
    {case_end, {x, 0}}.
  {label, 391}.
    {deallocate, 2}.
    return.
% Internal, test scaffolding: the fixture tree plus the names decision 177 is
% about — a dot file and a dot directory, a link to a directory, a link to a
% file and a dangling link, all under `<dir>/app`.

{function, makeGlobTree, 1, 13}.
  {label, 12}.
    {line, [{location, "std@io@fs.erl", 17}]}.
    {func_info, {atom, std@io@fs}, {atom, makeGlobTree}, 1}.
  {label, 13}.
    {allocate, 14, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
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
    {call, 2, {f, 355}}.
    {call, 1, {f, 68}}.
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
    {call, 2, {f, 355}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cached">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 30}}.
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
    {call, 2, {f, 355}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"hidden">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 30}}.
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
    {call, 2, {f, 355}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"draft">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 30}}.
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
    {call, 2, {f, 355}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call, 2, {f, 395}}.
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
    {call, 2, {f, 355}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {call, 2, {f, 395}}.
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
    {call, 2, {f, 355}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call, 2, {f, 395}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 14}.
    return.
% Internal, test scaffolding: what `glob(pattern, <dir>/app)` answers over
% `makeGlobTree`, joined by `,`.

{function, globbed, 1, 15}.
  {label, 14}.
    {line, [{location, "std@io@fs.erl", 18}]}.
    {func_info, {atom, std@io@fs}, {atom, globbed}, 1}.
  {label, 15}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 361}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 13}}.
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
    {call, 2, {f, 355}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 182}}.
    {test, is_tagged_tuple, {f, 404}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 405}}.
  {label, 404}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"<error>">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 405}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 327}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_last, 2, {f, 355}, 7}.

{function, '__bp_tpl_0-t/1-fun-0-', 1, 21}.
  {label, 20}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_0-t/1-fun-0-'}, 1}.
  {label, 21}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_file, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 25}, [{x, 0}]}.
    {test, test_arity, {f, 25}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 25}, [{x, 0}, {atom, ok}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 25}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 26}, [{x, 0}]}.
    {test, test_arity, {f, 26}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 26}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, [126, 112]}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 5}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 26}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_0', 1, 17}.
  {label, 16}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_0'}, 1}.
  {label, 17}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 21}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 34}.
  {label, 33}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 34}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, file, write_file, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
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
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, [126, 112]}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 6}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 39}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_1', 2, 30}.
  {label, 29}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_1'}, 2}.
  {label, 30}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 34}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_2', 1, 43}.
  {label, 42}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_2'}, 1}.
  {label, 43}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_file_info, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 47}, [{x, 0}]}.
    {test, test_arity, {f, 47}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, {atom, ok}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 47}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_3-t/1-fun-0-', 1, 55}.
  {label, 54}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_3-t/1-fun-0-'}, 1}.
  {label, 55}.
    {allocate, 9, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, list_dir, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 59}, [{x, 0}]}.
    {test, test_arity, {f, 59}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 59}, [{x, 0}, {atom, ok}]}.
    {move, {y, 4}, {y, 0}}.
    {move, nil, {y, 5}}.
    {move, {y, 0}, {y, 6}}.
  {label, 61}.
    {move, {y, 6}, {x, 0}}.
    {test, is_nonempty_list, {f, 62}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 7}, {y, 6}}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 2, 0}.
    {put_list, {y, 8}, {y, 5}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 61}}.
  {label, 62}.
    {move, {y, 6}, {x, 0}}.
    {test, is_nil, {f, 63}, [{x, 0}]}.
    {jump, {f, 60}}.
  {label, 63}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 60}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 6}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 59}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 64}, [{x, 0}]}.
    {test, test_arity, {f, 64}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, [126, 112]}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 5}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 64}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_3', 1, 51}.
  {label, 50}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_3'}, 1}.
  {label, 51}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 55}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_4-t/1-fun-0-', 1, 72}.
  {label, 71}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_4-t/1-fun-0-'}, 1}.
  {label, 72}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, make_dir, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 76}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 76}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 77}, [{x, 0}]}.
    {test, test_arity, {f, 77}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 77}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, [126, 112]}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 5}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 77}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_4', 1, 68}.
  {label, 67}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_4'}, 1}.
  {label, 68}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 72}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_5-t/1-fun-0-', 1, 85}.
  {label, 84}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_5-t/1-fun-0-'}, 1}.
  {label, 85}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, delete, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 89}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 89}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 90}, [{x, 0}]}.
    {test, test_arity, {f, 90}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 90}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, [126, 112]}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 5}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 90}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_5', 1, 81}.
  {label, 80}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_5'}, 1}.
  {label, 81}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 85}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_6-t/2-fun-0-', 2, 98}.
  {label, 97}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_6-t/2-fun-0-'}, 2}.
  {label, 98}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, file, copy, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 102}, [{x, 0}]}.
    {test, test_arity, {f, 102}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 102}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 102}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 103}, [{x, 0}]}.
    {test, test_arity, {f, 103}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 103}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, [126, 112]}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 6}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 103}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_6', 2, 94}.
  {label, 93}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_6'}, 2}.
  {label, 94}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 98}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_7-t/1-fun-0-', 1, 111}.
  {label, 110}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_7-t/1-fun-0-'}, 1}.
  {label, 111}.
    {allocate, 13, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, [{time, posix}]}, {x, 1}}.
    {call_ext, 2, {extfunc, file, read_file_info, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 115}, [{x, 0}]}.
    {test, test_arity, {f, 115}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 115}, [{x, 0}, {atom, ok}]}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 115}, [{x, 0}]}.
    {test, test_arity, {f, 115}, [{x, 0}, 14]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {get_tuple_element, {x, 0}, 2, {y, 9}}.
    {get_tuple_element, {x, 0}, 5, {y, 10}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 115}, [{x, 0}, {atom, file_info}]}.
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
  {label, 115}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 116}, [{x, 0}]}.
    {test, test_arity, {f, 116}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 116}, [{x, 0}, {atom, error}]}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, [126, 112]}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 7}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 116}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_7', 1, 107}.
  {label, 106}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_7'}, 1}.
  {label, 107}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 111}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_8---t/1-fun-0--fun-1--fun-2-', 5, 140}.
  {label, 139}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_8---t/1-fun-0--fun-1--fun-2-'}, 5}.
  {label, 140}.
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
    {jump, {f, 144}}.
  {label, 144}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 146}, [{x, 0}, nil]}.
    {move, {y, 6}, {y, 8}}.
    {jump, {f, 145}}.
  {label, 146}.
    {move, {literal, [47]}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 8}}.
    {jump, {f, 145}}.
  {label, 145}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 149}}.
  {label, 149}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_file_info, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 151}, [{x, 0}]}.
    {test, test_arity, {f, 151}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 151}, [{x, 0}, {atom, ok}]}.
    {move, {y, 10}, {y, 5}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {bif, element, {f, 151}, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {move, {atom, directory}, {x, 1}}.
    {test, is_eq_exact, {f, 151}, [{x, 0}, {x, 1}]}.
    {jump, {f, 152}}.
  {label, 152}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {move, {y, 2}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 12}.
    return.
  {label, 151}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 153}, [{x, 0}]}.
    {test, test_arity, {f, 153}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 153}, [{x, 0}, {atom, ok}]}.
    {move, {y, 10}, {y, 5}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {bif, element, {f, 153}, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {move, {atom, regular}, {x, 1}}.
    {test, is_eq_exact, {f, 153}, [{x, 0}, {x, 1}]}.
    {jump, {f, 154}}.
  {label, 154}.
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
  {label, 153}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 155}, [{x, 0}]}.
    {test, test_arity, {f, 155}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 155}, [{x, 0}, {atom, ok}]}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 155}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 156}, [{x, 0}, {literal, {error, enoent}}]}.
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
  {label, 156}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 157}, [{x, 0}]}.
    {test, test_arity, {f, 157}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 157}, [{x, 0}, {atom, error}]}.
    {move, {y, 10}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_fs_walk}, {y, 3}]}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, throw, 1}, 12}.
  {label, 157}.
    {move, {y, 8}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_8--t/1-fun-0--fun-1-', 3, 133}.
  {label, 132}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_8--t/1-fun-0--fun-1-'}, 3}.
  {label, 133}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {x, 2}, {y, 4}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 133}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, file, list_dir, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 137}, [{x, 0}]}.
    {test, test_arity, {f, 137}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 137}, [{x, 0}, {atom, error}]}.
    {move, {y, 7}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_fs_walk}, {y, 1}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, throw, 1}, 9}.
  {label, 137}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 138}, [{x, 0}]}.
    {test, test_arity, {f, 138}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 138}, [{x, 0}, {atom, ok}]}.
    {move, {y, 7}, {y, 1}}.
    {test_heap, {alloc, [{words, 3}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 140}, 1, 0, {x, 0}, {list, [{y, 2}, {y, 3}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_ext_last, 3, {extfunc, lists, foldl, 3}, 9}.
  {label, 138}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_8-t/1-fun-0-', 1, 124}.
  {label, 123}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_8-t/1-fun-0-'}, 1}.
  {label, 124}.
    {allocate, 13, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 128}}.
  {label, 128}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, filelib, is_dir, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 130}, [{x, 0}, {atom, false}]}.
    {move, {literal, {error, <<"enotdir">>}}, {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 130}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 131}, [{x, 0}, {atom, true}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 133}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 159}}.
  {label, 159}.
    {'try', {y, 12}, {f, 160}}.
    {move, {y, 0}, {x, 0}}.
    {move, nil, {x, 1}}.
    {move, nil, {x, 2}}.
    {move, {y, 1}, {x, 3}}.
    {call_fun, 3}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 163}}.
  {label, 163}.
    {move, nil, {y, 5}}.
    {move, {y, 0}, {y, 6}}.
  {label, 165}.
    {move, {y, 6}, {x, 0}}.
    {test, is_nonempty_list, {f, 166}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 7}, {y, 6}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 165}, [{x, 0}]}.
    {test, test_arity, {f, 165}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 165}, [{x, 0}, {atom, dangling}]}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, {y, 5}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 165}}.
  {label, 166}.
    {move, {y, 6}, {x, 0}}.
    {test, is_nil, {f, 167}, [{x, 0}]}.
    {jump, {f, 164}}.
  {label, 167}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 164}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, sort, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nonempty_list, {f, 169}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 7}, {y, 8}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 170}, [{x, 0}]}.
    {test_heap, 8, 0}.
    {put_list, {literal, <<"\"">>}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"\"">>}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"fs.walk: dangling link ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 171}}.
  {label, 170}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 171}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 6}}.
    {jump, {f, 168}}.
  {label, 169}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 172}, [{x, 0}, nil]}.
    {move, nil, {y, 7}}.
    {move, {y, 0}, {y, 8}}.
  {label, 174}.
    {move, {y, 8}, {x, 0}}.
    {test, is_nonempty_list, {f, 175}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 9}, {y, 8}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tuple, {f, 174}, [{x, 0}]}.
    {test, test_arity, {f, 174}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 10}}.
    {get_tuple_element, {x, 0}, 1, {y, 11}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 174}, [{x, 0}, {atom, file}]}.
    {move, {y, 11}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, {y, 7}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {jump, {f, 174}}.
  {label, 175}.
    {move, {y, 8}, {x, 0}}.
    {test, is_nil, {f, 176}, [{x, 0}]}.
    {jump, {f, 173}}.
  {label, 176}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 8}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 173}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, sort, 1}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 7}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 168}}.
  {label, 172}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 168}.
    {move, {y, 6}, {y, 4}}.
    {try_end, {y, 12}}.
    {jump, {f, 161}}.
  {label, 160}.
    {try_case, {y, 12}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 178}, [{x, 0}, {atom, throw}]}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 178}, [{x, 0}]}.
    {test, test_arity, {f, 178}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 178}, [{x, 0}, {atom, bp_fs_walk}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 4}}.
    {jump, {f, 177}}.
  {label, 178}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    raw_raise.
  {label, 177}.
  {label, 161}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 131}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_8', 1, 120}.
  {label, 119}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_8'}, 1}.
  {label, 120}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 124}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_9--t/2-fun-0--fun-1-', 1, 205}.
  {label, 204}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_9--t/2-fun-0--fun-1-'}, 1}.
  {label, 205}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_link_info, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 209}, [{x, 0}]}.
    {test, test_arity, {f, 209}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 209}, [{x, 0}, {atom, ok}]}.
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
  {label, 209}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '__bp_tpl_9---t/2-fun-0--fun-2--fun-3-', 1, 218}.
  {label, 217}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_9---t/2-fun-0--fun-2--fun-3-'}, 1}.
  {label, 218}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, [42, 63, 91, 123]}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, member, 2}, 1}.

{function, '__bp_tpl_9--t/2-fun-0--fun-2-', 1, 214}.
  {label, 213}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_9--t/2-fun-0--fun-2-'}, 1}.
  {label, 214}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 218}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, any, 2}, 2}.

{function, '__bp_tpl_9--t/2-fun-0--fun-4-', 2, 224}.
  {label, 223}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_9--t/2-fun-0--fun-4-'}, 2}.
  {label, 224}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 228}, [{x, 0}, {literal, [42]}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, list_dir, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 230}, [{x, 0}]}.
    {test, test_arity, {f, 230}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 230}, [{x, 0}, {atom, ok}]}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 0}, {y, 5}}.
    {jump, {f, 229}}.
  {label, 230}.
    {move, nil, {y, 5}}.
    {jump, {f, 229}}.
  {label, 229}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 227}}.
  {label, 228}.
    {'try', {y, 8}, {f, 233}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, filelib, wildcard, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 4}}.
    {try_end, {y, 8}}.
    {jump, {f, 234}}.
  {label, 233}.
    {try_case, {y, 8}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, nil, {y, 4}}.
    {jump, {f, 235}}.
  {label, 235}.
  {label, 234}.
    {move, {y, 4}, {y, 3}}.
    {jump, {f, 227}}.
  {label, 227}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 238}}.
  {label, 238}.
    {move, nil, {y, 3}}.
    {move, {y, 0}, {y, 4}}.
  {label, 240}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 241}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {bif, hd, {f, 240}, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 46}, {x, 1}}.
    {test, is_ne_exact, {f, 243}, [{x, 0}, {x, 1}]}.
    {jump, {f, 244}}.
  {label, 243}.
    {move, {y, 2}, {x, 0}}.
    {bif, hd, {f, 240}, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 46}, {x, 1}}.
    {test, is_eq_exact, {f, 240}, [{x, 0}, {x, 1}]}.
  {label, 244}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 240}}.
  {label, 241}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 242}, [{x, 0}]}.
    {jump, {f, 239}}.
  {label, 242}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 239}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 9}.
    return.

{function, '__bp_tpl_9--t/2-fun-0--fun-5-', 2, 248}.
  {label, 247}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_9--t/2-fun-0--fun-5-'}, 2}.
  {label, 248}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 250}, [{x, 0}, nil]}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 250}.
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

{function, '__bp_tpl_9---t/2-fun-0--fun-6--fun-7-', 7, 261}.
  {label, 260}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_9---t/2-fun-0--fun-6--fun-7-'}, 7}.
  {label, 261}.
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
    {jump, {f, 265}}.
  {label, 265}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 6}}.
    {jump, {f, 267}}.
  {label, 267}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 269}, [{x, 0}, {atom, true}]}.
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
  {label, 269}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 270}, [{x, 0}, {atom, false}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 8}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 270}.
    {move, {y, 9}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_9---t/2-fun-0--fun-6--fun-8-', 8, 273}.
  {label, 272}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_9---t/2-fun-0--fun-6--fun-8-'}, 8}.
  {label, 273}.
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
    {jump, {f, 277}}.
  {label, 277}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 279}, [{x, 0}, {atom, true}]}.
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
  {label, 279}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 280}, [{x, 0}, {atom, false}]}.
    {move, {y, 8}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 280}.
    {move, {y, 9}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_9---t/2-fun-0--fun-6--fun-9-', 8, 299}.
  {label, 298}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_9---t/2-fun-0--fun-6--fun-9-'}, 8}.
  {label, 299}.
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
    {jump, {f, 303}}.
  {label, 303}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 7}}.
    {jump, {f, 305}}.
  {label, 305}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 307}, [{x, 0}, nil]}.
    {test_heap, 2, 0}.
    {put_list, {y, 7}, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 307}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 310}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {move, {y, 9}, {x, 3}}.
    {move, {y, 5}, {x, 4}}.
    {call_fun, 4}.
    {deallocate, 11}.
    return.
  {label, 310}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 311}, [{x, 0}, {atom, false}]}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 311}.
    {move, {y, 10}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_9--t/2-fun-0--fun-6-', 8, 255}.
  {label, 254}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_9--t/2-fun-0--fun-6-'}, 8}.
  {label, 255}.
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
    {make_fun3, {f, 255}, 1, 0, {x, 0}, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 257}, [{x, 0}, nil]}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 257}, [{x, 0}, nil]}.
    {move, {y, 12}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 257}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 258}, [{x, 0}, nil]}.
    {test_heap, 2, 0}.
    {put_list, {y, 11}, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 258}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 259}, [{x, 0}, {literal, [[42, 42]]}]}.
    {test_heap, {alloc, [{words, 5}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 261}, 2, 0, {x, 0}, {list, [{y, 10}, {y, 0}, {y, 11}, {y, 1}, {y, 4}]}}.
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
  {label, 259}.
    {move, {y, 9}, {x, 0}}.
    {test, is_nonempty_list, {f, 271}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 13}, {y, 14}}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 271}, [{x, 0}, {literal, [42, 42]}]}.
    {move, {y, 14}, {y, 5}}.
    {move, {y, 9}, {y, 6}}.
    {test_heap, {alloc, [{words, 6}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 273}, 3, 0, {x, 0}, {list, [{y, 10}, {y, 1}, {y, 4}, {y, 6}, {y, 0}, {y, 11}]}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {move, {y, 11}, {x, 2}}.
    {move, {y, 12}, {x, 3}}.
    {move, {y, 0}, {x, 4}}.
    {move, {y, 1}, {x, 5}}.
    {move, {y, 2}, {x, 6}}.
    {move, {y, 3}, {x, 7}}.
    {call, 8, {f, 255}}.
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
  {label, 271}.
    {move, {y, 9}, {x, 0}}.
    {test, is_nonempty_list, {f, 281}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 13}, {y, 14}}.
    {move, {y, 13}, {y, 6}}.
    {move, {y, 14}, {y, 5}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {test, is_eq_exact, {f, 283}, [{x, 0}, {atom, false}]}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {y, 7}}.
    {jump, {f, 285}}.
  {label, 285}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {y, 8}}.
    {jump, {f, 287}}.
  {label, 287}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 289}, [{x, 0}, nil]}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_link_info, 1}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {test, is_tuple, {f, 291}, [{x, 0}]}.
    {test, test_arity, {f, 291}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 17}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq_exact, {f, 291}, [{x, 0}, {atom, ok}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 8}, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 18}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 291}.
    {move, {y, 12}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 289}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, filelib, is_dir, 1}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {test, is_eq_exact, {f, 295}, [{x, 0}, {atom, true}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {move, {y, 8}, {x, 2}}.
    {move, {y, 12}, {x, 3}}.
    {move, {y, 0}, {x, 4}}.
    {move, {y, 1}, {x, 5}}.
    {move, {y, 2}, {x, 6}}.
    {move, {y, 3}, {x, 7}}.
    {call_last, 8, {f, 255}, 19}.
  {label, 295}.
    {move, {y, 16}, {x, 0}}.
    {test, is_eq_exact, {f, 296}, [{x, 0}, {atom, false}]}.
    {move, {y, 12}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 296}.
    {move, {y, 16}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 283}.
    {move, {y, 15}, {x, 0}}.
    {test, is_eq_exact, {f, 297}, [{x, 0}, {atom, true}]}.
    {test_heap, {alloc, [{words, 6}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 299}, 4, 0, {x, 0}, {list, [{y, 10}, {y, 0}, {y, 11}, {y, 5}, {y, 1}, {y, 4}]}}.
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
  {label, 297}.
    {move, {y, 15}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 281}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {move, {y, 11}, {x, 2}}.
    {move, {y, 12}, {x, 3}}.
    {move, {y, 0}, {x, 4}}.
    {move, {y, 1}, {x, 5}}.
    {move, {y, 2}, {x, 6}}.
    {move, {y, 3}, {x, 7}}.
    {deallocate, 19}.
    {jump, {f, 254}}.

{function, '__bp_tpl_9-t/2-fun-0-', 2, 186}.
  {label, 185}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_9-t/2-fun-0-'}, 2}.
  {label, 186}.
    {allocate, 16, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 0}}.
    {jump, {f, 190}}.
  {label, 190}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 1}}.
    {jump, {f, 192}}.
  {label, 192}.
    {move, nil, {y, 9}}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, [47]}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext, 3, {extfunc, string, split, 3}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 10}}.
  {label, 194}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nonempty_list, {f, 195}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 12}, {y, 10}}.
    {move, {y, 12}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, nil, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 197}, [{x, 0}, {atom, true}]}.
    {jump, {f, 199}}.
  {label, 197}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 198}, [{x, 0}, {atom, false}]}.
    {jump, {f, 194}}.
  {label, 198}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_filter}, {y, 13}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 199}.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, [46]}, {x, 1}}.
    {test, is_ne_exact, {f, 194}, [{x, 0}, {x, 1}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 194}}.
  {label, 195}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nil, {f, 196}, [{x, 0}]}.
    {jump, {f, 193}}.
  {label, 196}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 10}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 193}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 2}}.
    {jump, {f, 201}}.
  {label, 201}.
    {move, {literal, [47]}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, suffix, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 1}}.
    {jump, {f, 203}}.
  {label, 203}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 205}, 5, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 212}}.
  {label, 212}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 214}, 6, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 222}}.
  {label, 222}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 224}, 7, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 246}}.
  {label, 246}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 248}, 8, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 6}}.
    {jump, {f, 253}}.
  {label, 253}.
    {test_heap, {alloc, [{words, 4}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 255}, 1, 0, {x, 0}, {list, [{y, 6}, {y, 3}, {y, 5}, {y, 4}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 313}}.
  {label, 313}.
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
  {label, 315}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nonempty_list, {f, 316}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 12}, {y, 10}}.
    {move, {y, 12}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, 'not', 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 318}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {y, 13}}.
    {jump, {f, 320}}.
  {label, 318}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 319}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {y, 13}}.
    {jump, {f, 320}}.
  {label, 319}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 14}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 320}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 321}, [{x, 0}, {atom, true}]}.
    {jump, {f, 323}}.
  {label, 321}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 322}, [{x, 0}, {atom, false}]}.
    {jump, {f, 315}}.
  {label, 322}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_filter}, {y, 13}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 323}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 13}}.
    {test_heap, 2, 0}.
    {put_list, {y, 13}, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 315}}.
  {label, 316}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nil, {f, 317}, [{x, 0}]}.
    {jump, {f, 314}}.
  {label, 317}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 10}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 314}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 10}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 16}.
    return.

{function, '__bp_tpl_9', 2, 182}.
  {label, 181}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_9'}, 2}.
  {label, 182}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 186}, 9, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_10-t/1-fun-0-', 1, 331}.
  {label, 330}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_10-t/1-fun-0-'}, 1}.
  {label, 331}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, del_dir_r, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 335}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 335}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 336}, [{x, 0}, {literal, {error, enoent}}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 336}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 337}, [{x, 0}]}.
    {test, test_arity, {f, 337}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 337}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, [126, 112]}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 5}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 337}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_10', 1, 327}.
  {label, 326}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_10'}, 1}.
  {label, 327}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 331}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_adopt', 3, 341}.
  {label, 340}.
    {line, [{location, "std@io@fs.erl", 8}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_adopt'}, 3}.
  {label, 341}.
    {test, is_map, {f, 346}, [{x, 0}]}.
    {allocate, 1, 3}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 343}}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_tuple, 1}, 1}.
  {label, 346}.
    {test, is_list, {f, 347}, [{x, 0}]}.
    {call_only, 3, {f, 345}}.
  {label, 347}.
    {test, is_tagged_tuple, {f, 348}, [{x, 0}, 2, {atom, ok}]}.
    {allocate, 0, 3}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {call, 3, {f, 341}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 0}]}}.
    {deallocate, 0}.
    return.
  {label, 348}.
    return.

{function, '-bp_adopt_fields-', 2, 343}.
  {label, 342}.
    {line, [{location, "std@io@fs.erl", 8}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_adopt_fields-'}, 2}.
  {label, 343}.
    {test, is_nonempty_list, {f, 349}, [{x, 0}]}.
    {allocate, 2, 2}.
    {move, {x, 1}, {y, 1}}.
    {get_list, {x, 0}, {x, 0}, {y, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_ext, 3, {extfunc, maps, get, 3}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 343}}.
    {test_heap, 2, 1}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 349}.
    {move, nil, {x, 0}}.
    return.

{function, '-bp_adopt_each-', 3, 345}.
  {label, 344}.
    {line, [{location, "std@io@fs.erl", 8}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_adopt_each-'}, 3}.
  {label, 345}.
    {test, is_nonempty_list, {f, 350}, [{x, 0}]}.
    {allocate, 3, 3}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {get_list, {x, 0}, {x, 0}, {y, 0}}.
    {call, 3, {f, 341}}.
    {move, {y, 0}, {x, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call, 3, {f, 345}}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 350}.
    {move, nil, {x, 0}}.
    return.

{function, '-bp_stringify-', 1, 357}.
  {label, 356}.
    {line, [{location, "std@io@fs.erl", 14}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_stringify-'}, 1}.
  {label, 357}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 358}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 358}.
    {test, is_integer, {f, 359}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 359}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 0}.

{function, '-bp_join-', 2, 355}.
  {label, 354}.
    {line, [{location, "std@io@fs.erl", 14}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_join-'}, 2}.
  {label, 355}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 357}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '__bp_tpl_11-t/0-fun-0-', 0, 365}.
  {label, 364}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_11-t/0-fun-0-'}, 0}.
  {label, 365}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {literal, [84, 77, 80, 68, 73, 82]}, {x, 0}}.
    {call_ext, 1, {extfunc, os, getenv, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 369}, [{x, 0}, {atom, false}]}.
    {move, {literal, [47, 116, 109, 112]}, {y, 2}}.
    {jump, {f, 368}}.
  {label, 369}.
    {move, {y, 1}, {y, 0}}.
    {move, {y, 0}, {y, 2}}.
    {jump, {f, 368}}.
  {label, 368}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 372}}.
  {label, 372}.
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
    {jump, {f, 374}}.
  {label, 374}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, file, make_dir, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 375}, [{x, 0}, {atom, ok}]}.
    {jump, {f, 376}}.
  {label, 375}.
    {move, {y, 1}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 376}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 3}.

{function, '__bp_tpl_11', 0, 361}.
  {label, 360}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_11'}, 0}.
  {label, 361}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 365}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_12-t/0-fun-0-', 0, 384}.
  {label, 383}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_12-t/0-fun-0-'}, 0}.
  {label, 384}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {call_ext, 0, {extfunc, file, get_cwd, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 387}, [{x, 0}]}.
    {test, test_arity, {f, 387}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {get_tuple_element, {x, 0}, 1, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 387}, [{x, 0}, {atom, ok}]}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 388}}.
  {label, 387}.
    {move, {y, 1}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 388}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 4}.

{function, '__bp_tpl_12', 0, 380}.
  {label, 379}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_12'}, 0}.
  {label, 380}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 384}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_13-t/2-fun-0-', 2, 399}.
  {label, 398}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_13-t/2-fun-0-'}, 2}.
  {label, 399}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, file, make_symlink, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 402}, [{x, 0}, {atom, ok}]}.
    {jump, {f, 403}}.
  {label, 402}.
    {move, {y, 2}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 403}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_13', 2, 395}.
  {label, 394}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_13'}, 2}.
  {label, 395}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 399}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
```

----- BEAM ASSEMBLY -- std@io@fs@@FileStat.S
```erlang
{module, std@io@fs@@FileStat}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 9}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@io@fs@@FileStat.erl", 1}]}.
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
    {line, [{location, "std@io@fs@@FileStat.erl", 1}]}.
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

