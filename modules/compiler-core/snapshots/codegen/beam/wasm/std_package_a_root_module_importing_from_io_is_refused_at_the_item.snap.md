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

----- WASM TEXT -- std/path.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\01\00\00\00/")
  (data (i32.const 264) "\01\00\00\00:")
  (data (i32.const 272) "\00\00\00\00")
  (data (i32.const 276) "\01\00\00\00.")
  (data (i32.const 284) "\02\00\00\00..")
  (data (i32.const 292) "\1b\00\00\00R\tPathAccum\02\05isAbsb\05parts[s")
  (data (i32.const 324) "\03\00\00\00../")
  (global $__heap_ptr (mut i32) (i32.const 332))
  ;; std/path — pure-botopink path manipulation (posix forward-slash).
  ;; 
  ;; Reference:
  ;;   Node.js  — https://nodejs.org/api/path.html
  ;;   Erlang   — https://www.erlang.org/doc/apps/stdlib/filename.html
  ;; 
  ;; Lib-self-contained: every operation composes `String` methods (`split`,
  ;; `slice`, `length`, `startsWith`), so the module works on every backend
  ;; including wat. Forward-slash separator only — Windows backslash paths
  ;; are not normalised here (the spec keeps `path` posix-shaped; a
  ;; `path_win32` sibling can land later if a target needs it).
  (global $separator (mut i32) (i32.const 256))
  (global $delimiter (mut i32) (i32.const 264))
  ;; Split a path into its non-empty components. Leading-`/` paths drop the
  ;; empty head; trailing-`/` paths drop the empty tail. A path made of pure
  ;; separators yields the empty array. Uses `filter` rather than
  ;; `forEach` + `push`: a `var` + `push` pattern lowers to a dead-store
  ;; (`out ++ [p]` discarded) on Erlang because the immutable runtime never
  ;; rebinds `Out`; `filter` round-trips through `lists:filter/2` and
  ;; `Array.prototype.filter` directly.
  (func $split (export "split") (param $path i32) (result i32)
    (local $raw i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $p i32)
    local.get $path
    global.get $separator
    call $__str_split
    local.set $raw
    local.get $raw
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $p
    i32.const 272
    call $__str_eq
    i32.eqz
    (if
      (then
    local.get $__out0
    local.get $__acc0
    i32.const 4
    i32.mul
    i32.add
    local.get $__iter0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    i32.store offset=4
    local.get $__acc0
    i32.const 1
    i32.add
    local.set $__acc0
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    local.get $__acc0
    i32.store ;; kept count
    local.get $__out0
    return
  )
  ;; True when `path` starts with `/` — the posix absolute-path marker.
  (func $isAbsolute (export "isAbsolute") (param $path i32) (result i32)
    local.get $path
    global.get $separator
    call $__str_starts_with
    return
  )
  ;; The last non-empty component of `path` (the file name, in the common
  ;; case). Returns "" for the empty path and for pure-separator paths.
  (func $basename (export "basename") (param $path i32) (result i32)
    (local $parts i32)
    (local $n i32)
    (local $__bp_nullish i32)
    (local $__opt0 i32)
    local.get $path
    call $split
    local.set $parts
    local.get $parts
    i32.load ;; .length
    local.set $n
    local.get $n
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    i32.const 272
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $parts
    local.get $n
    i32.const 1
    call $__i32_sub_chk
    call $__arr_at
    local.tee $__opt0
    (if (result i32)
      (then
    local.get $__opt0
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 272
      )
    )
    return
  )
  ;; Everything except the basename — the parent directory portion. For an
  ;; absolute path this preserves the leading `/`. For a path with no
  ;; separator (`"foo"`), returns `""`.
  (func $dirname (export "dirname") (param $path i32) (result i32)
    (local $__mem0 i32)
    (local $parts i32)
    (local $n i32)
    (local $head i32)
    (local $joined i32)
    local.get $path
    call $split
    local.set $parts
    local.get $parts
    i32.load ;; .length
    local.set $n
    local.get $n
    i32.const 1
    i32.le_s
    (if (result i32)
      (then
    local.get $path
    call $isAbsolute
    (if (result i32)
      (then
    global.get $separator
      )
      (else
    i32.const 272
      )
    )
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $parts
    i32.const 0
    local.get $n
    i32.const 1
    call $__i32_sub_chk
    call $__arr_slice
    local.set $head
    local.get $head
    global.get $separator
    call $__arr_join_str
    local.set $joined
    local.get $path
    call $isAbsolute
    (if (result i32)
      (then
    i32.const 12
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 2
    i32.store
    local.get $__mem0
    global.get $separator
    i32.store offset=4
    local.get $__mem0
    local.get $joined
    i32.store offset=8
    local.get $__mem0
    i32.const 272
    call $__arr_join_str
      )
      (else
    local.get $joined
      )
    )
    return
  )
  ;; The trailing extension on the basename — the substring from the LAST
  ;; `.` to the end, including the dot. Returns `""` when the basename has
  ;; no extension (or is a dotfile with no further `.`s, e.g. `.bashrc`).
  (func $extname (export "extname") (param $path i32) (result i32)
    (local $__mem0 i32)
    (local $base i32)
    (local $pieces i32)
    (local $n i32)
    (local $head i32)
    (local $__bp_nullish i32)
    (local $tail i32)
    (local $isDotfile i32)
    (local $__opt0 i32)
    (local $__opt1 i32)
    local.get $path
    call $basename
    local.set $base
    local.get $base
    i32.const 276
    call $__str_split
    local.set $pieces
    local.get $pieces
    i32.load ;; .length
    local.set $n
    local.get $n
    i32.const 1
    i32.le_s
    (if (result i32)
      (then
    i32.const 272
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $pieces
    i32.const 0
    call $__arr_at
    local.tee $__opt0
    (if (result i32)
      (then
    local.get $__opt0
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 272
      )
    )
    local.set $head
    local.get $pieces
    local.get $n
    i32.const 1
    call $__i32_sub_chk
    call $__arr_at
    local.tee $__opt1
    (if (result i32)
      (then
    local.get $__opt1
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 272
      )
    )
    local.set $tail
    local.get $head
    i32.const 272
    call $__str_eq
    local.get $n
    i32.const 2
    i32.eq
    i32.and
    local.set $isDotfile
    local.get $isDotfile
    (if (result i32)
      (then
    i32.const 272
      )
      (else
    i32.const 12
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 2
    i32.store
    local.get $__mem0
    i32.const 276
    i32.store offset=4
    local.get $__mem0
    local.get $tail
    i32.store offset=8
    local.get $__mem0
    i32.const 272
    call $__arr_join_str
      )
    )
    return
  )
  ;; Join a list of path segments with the separator. Leading separator on
  ;; the first segment is preserved; intra-segment slashes are normalised
  ;; (`"foo/" + "/bar"` joins to `"foo/bar"`, never `"foo//bar"`). Uses
  ;; `map` + `filter` + `join` rather than `fold` / `flatMap`: those land
  ;; on `Array<T>` default-fn bodies that lower to a `var` + `push` shape,
  ;; which lowers to a dead store on Erlang's immutable runtime (the same
  ;; trap `split` sidesteps).
  (func $join (export "join") (param $parts i32) (result i32)
    (local $__mem0 i32)
    (local $isAbs i32)
    (local $__bp_nullish i32)
    (local $collapsed i32)
    (local $joined i32)
    (local $__opt0 i32)
    (local $__iter1 i32)
    (local $__idx1 i32)
    (local $__len1 i32)
    (local $__acc1 i32)
    (local $__out1 i32)
    (local $p i32)
    (local $__iter2 i32)
    (local $__idx2 i32)
    (local $__len2 i32)
    (local $__acc2 i32)
    (local $__out2 i32)
    local.get $parts
    i32.load ;; .length
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    i32.const 0
      )
      (else
    local.get $parts
    i32.const 0
    call $__arr_at
    local.tee $__opt0
    (if (result i32)
      (then
    local.get $__opt0
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 272
      )
    )
    call $isAbsolute
      )
    )
    local.set $isAbs
    local.get $parts
    local.set $__iter1
    local.get $__iter1
    i32.load ;; element count
    local.set $__len1
    i32.const 0
    local.set $__idx1
    local.get $__len1
    call $__arr_new
    local.set $__out1
    i32.const 0
    local.set $__acc1
    (block $__break
      (loop $__continue
        local.get $__idx1
        local.get $__len1
        i32.ge_s
        br_if $__break
        local.get $__iter1
        local.get $__idx1
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $__out1
    local.get $__idx1
    i32.const 4
    i32.mul
    i32.add
    local.get $p
    call $split
    global.get $separator
    call $__arr_join_str
    i32.store offset=4
        local.get $__idx1
        i32.const 1
        i32.add
        local.set $__idx1
        br $__continue
      )
    )
    local.get $__out1
    local.set $collapsed
    local.get $collapsed
    local.set $__iter2
    local.get $__iter2
    i32.load ;; element count
    local.set $__len2
    i32.const 0
    local.set $__idx2
    local.get $__len2
    call $__arr_new
    local.set $__out2
    i32.const 0
    local.set $__acc2
    (block $__break
      (loop $__continue
        local.get $__idx2
        local.get $__len2
        i32.ge_s
        br_if $__break
        local.get $__iter2
        local.get $__idx2
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $p
    i32.const 272
    call $__str_eq
    i32.eqz
    (if
      (then
    local.get $__out2
    local.get $__acc2
    i32.const 4
    i32.mul
    i32.add
    local.get $__iter2
    local.get $__idx2
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    i32.store offset=4
    local.get $__acc2
    i32.const 1
    i32.add
    local.set $__acc2
      )
    )
        local.get $__idx2
        i32.const 1
        i32.add
        local.set $__idx2
        br $__continue
      )
    )
    local.get $__out2
    local.get $__acc2
    i32.store ;; kept count
    local.get $__out2
    global.get $separator
    call $__arr_join_str
    local.set $joined
    local.get $isAbs
    (if (result i32)
      (then
    i32.const 12
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 2
    i32.store
    local.get $__mem0
    global.get $separator
    i32.store offset=4
    local.get $__mem0
    local.get $joined
    i32.store offset=8
    local.get $__mem0
    i32.const 272
    call $__arr_join_str
      )
      (else
    local.get $joined
      )
    )
    return
  )
  ;; Collapse `//` and drop `.` segments via a `filter` over the split
  ;; pieces. Full `..` pop semantics are deferred: they need a stack-shaped
  ;; accumulator and `var` reassignment, which lowers to a dead store on
  ;; Erlang's immutable runtime (the same trap `split`/`join` sidestep with
  ;; `filter`/`flatMap`).
  (func $normalize (export "normalize") (param $path i32) (result i32)
    (local $__mem0 i32)
    (local $isAbs i32)
    (local $pieces i32)
    (local $joined i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $p i32)
    local.get $path
    i32.const 272
    call $__str_eq
    (if (result i32)
      (then
    i32.const 276
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $path
    call $isAbsolute
    local.set $isAbs
    local.get $path
    call $split
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $p
    local.get $p
    i32.const 276
    call $__str_eq
    i32.eqz
    (if
      (then
    local.get $__out0
    local.get $__acc0
    i32.const 4
    i32.mul
    i32.add
    local.get $__iter0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    i32.store offset=4
    local.get $__acc0
    i32.const 1
    i32.add
    local.set $__acc0
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    local.get $__acc0
    i32.store ;; kept count
    local.get $__out0
    local.set $pieces
    local.get $pieces
    global.get $separator
    call $__arr_join_str
    local.set $joined
    local.get $isAbs
    (if (result i32)
      (then
    i32.const 12
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 2
    i32.store
    local.get $__mem0
    global.get $separator
    i32.store offset=4
    local.get $__mem0
    local.get $joined
    i32.store offset=8
    local.get $__mem0
    i32.const 272
    call $__arr_join_str
      )
      (else
    local.get $joined
    i32.const 272
    call $__str_eq
    (if (result i32)
      (then
    i32.const 276
      )
      (else
    local.get $joined
      )
    )
      )
    )
    return
  )
  ;; Internal: count how many leading components two split paths share. Tail-
  ;; recursive on `i` so the accumulator never needs a `var` rebind (which
  ;; lowers to a dead store on Erlang's immutable runtime).
  (func $commonPrefixCount (param $a i32) (param $b i32) (param $i i32) (result i32)
    (local $ai i32)
    (local $__bp_nullish i32)
    (local $bi i32)
    (local $__opt0 i32)
    (local $__opt1 i32)
    local.get $i
    local.get $a
    i32.load ;; .length
    i32.ge_s
    (if (result i32)
      (then
    local.get $i
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $i
    local.get $b
    i32.load ;; .length
    i32.ge_s
    (if (result i32)
      (then
    local.get $i
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $a
    local.get $i
    call $__arr_at
    local.tee $__opt0
    (if (result i32)
      (then
    local.get $__opt0
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 272
      )
    )
    local.set $ai
    local.get $b
    local.get $i
    call $__arr_at
    local.tee $__opt1
    (if (result i32)
      (then
    local.get $__opt1
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 272
      )
    )
    local.set $bi
    local.get $ai
    local.get $bi
    call $__str_eq
    (if (result i32)
      (then
    local.get $a
    local.get $b
    local.get $i
    i32.const 1
    call $__i32_add_chk
    call $commonPrefixCount
      )
      (else
    local.get $i
      )
    )
    return
  )
  ;; Internal: build an array of `n` ".." strings via head/tail recursion.
  ;; Avoids a `var` + `push` accumulator (the Erlang dead-store trap).
  (func $makeUps (param $n i32) (result i32)
    (local $__mem0 i32)
    local.get $n
    i32.const 0
    i32.le_s
    (if (result i32)
      (then
    i32.const 4
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
      )
      (else
    local.get $n
    i32.const 1
    call $__i32_sub_chk
    call $makeUps
    i32.const 284
    call $__arr_prepend
      )
    )
    return
  )
  ;; The relative path from `src` to `dst` — the path you would prefix to
  ;; `src` to reach `dst`. Both inputs are treated structurally (no `cwd()`
  ;; fallback — that belongs in `process` once it lands). Returns "." when
  ;; the paths point at the same location.
  ;; 
  ;; `src` is named `src` rather than `from` because `from` is a reserved
  ;; keyword (the `import { … } from "<lib>"` syntax) — it does not parse
  ;; as a parameter name.
  (func $relative (export "relative") (param $src i32) (param $dst i32) (result i32)
    (local $srcParts i32)
    (local $dstParts i32)
    (local $common i32)
    (local $ups i32)
    (local $downs i32)
    (local $combined i32)
    (local $joined i32)
    local.get $src
    call $split
    local.set $srcParts
    local.get $dst
    call $split
    local.set $dstParts
    local.get $srcParts
    local.get $dstParts
    i32.const 0
    call $commonPrefixCount
    local.set $common
    local.get $srcParts
    i32.load ;; .length
    local.get $common
    call $__i32_sub_chk
    call $makeUps
    local.set $ups
    local.get $dstParts
    local.get $common
    local.get $dstParts
    i32.load ;; .length
    call $__arr_slice
    local.set $downs
    local.get $ups
    local.get $downs
    call $__arr_concat
    local.set $combined
    local.get $combined
    global.get $separator
    call $__arr_join_str
    local.set $joined
    local.get $joined
    i32.const 272
    call $__str_eq
    (if (result i32)
      (then
    i32.const 276
      )
      (else
    local.get $joined
      )
    )
    return
  )
  ;; Internal accumulator for `resolve`: a list of normalised path parts
  ;; plus whether the resolved-so-far path is absolute. The record carries
  ;; the state through the tail-recursive `resolveAll` so no `var` is
  ;; needed.
  ;; Internal: apply each component of one segment (post-split) to the
  ;; accumulator, popping for `..` and appending the rest. Head/tail
  ;; recursive — no `var` rebinds.
  (func $applyPieces (param $acc i32) (param $pieces i32) (result i32)
    (local $__mem0 i32)
    (local $p i32)
    (local $__bp_nullish i32)
    (local $rest i32)
    (local $nextAcc i32)
    (local $__opt0 i32)
    (loop $__tail (result i32)
    local.get $pieces
    i32.load ;; .length
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    local.get $acc
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $pieces
    i32.const 0
    call $__arr_at
    local.tee $__opt0
    (if (result i32)
      (then
    local.get $__opt0
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 272
      )
    )
    local.set $p
    local.get $pieces
    i32.const 1
    local.get $pieces
    i32.load ;; .length
    call $__arr_slice
    local.set $rest
    local.get $p
    i32.const 284
    call $__str_eq
    (if (result i32)
      (then
    local.get $acc
    i32.load ;; .length
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    local.get $acc
      )
      (else
    local.get $acc
    i32.const 0
    local.get $acc
    i32.load ;; .length
    i32.const 1
    call $__i32_sub_chk
    call $__arr_slice
      )
    )
      )
      (else
    local.get $acc
    i32.const 8
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 1
    i32.store
    local.get $__mem0
    local.get $p
    i32.store offset=4
    local.get $__mem0
    call $__arr_concat
      )
    )
    local.set $nextAcc
    local.get $nextAcc
    local.get $rest
    local.set $pieces
    local.set $acc
    br $__tail ;; tail call
    )
  )
  (func $resolveStep (param $state i32) (param $seg i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $pieces i32)
    (local $nextIsAbs i32)
    (local $baseParts i32)
    local.get $seg
    call $split
    local.set $pieces
    local.get $seg
    call $isAbsolute
    local.get $state
    i32.load ;; .isAbs
    i32.or
    local.set $nextIsAbs
    local.get $seg
    call $isAbsolute
    (if (result i32)
      (then
    i32.const 4
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
      )
      (else
    local.get $state
    i32.load offset=4 ;; .parts
      )
    )
    local.set $baseParts
    i32.const 12
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 296
    i32.store
    local.get $__mem1
    local.get $nextIsAbs
    i32.store offset=4
    local.get $__mem1
    local.get $baseParts
    local.get $pieces
    call $applyPieces
    i32.store offset=8
    local.get $__mem1
    i32.const 4
    i32.add
    return
  )
  (func $resolveAll (param $segments i32) (param $i i32) (param $state i32) (result i32)
    (local $seg i32)
    (local $__bp_nullish i32)
    (local $next i32)
    (local $__opt0 i32)
    (loop $__tail (result i32)
    local.get $i
    local.get $segments
    i32.load ;; .length
    i32.ge_s
    (if (result i32)
      (then
    local.get $state
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $segments
    local.get $i
    call $__arr_at
    local.tee $__opt0
    (if (result i32)
      (then
    local.get $__opt0
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 272
      )
    )
    local.set $seg
    local.get $state
    local.get $seg
    call $resolveStep
    local.set $next
    local.get $segments
    local.get $i
    i32.const 1
    call $__i32_add_chk
    local.get $next
    local.set $state
    local.set $i
    local.set $segments
    br $__tail ;; tail call
    )
  )
  ;; Resolve a list of path segments into a single normalised path.
  ;; Absolute segments restart the accumulator (matches Node's
  ;; `path.resolve`); `..` pops one component; `.` drops out (already
  ;; filtered by `split`). The empty input resolves to ".".
  (func $resolve (export "resolve") (param $segments i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $finalState i32)
    (local $joined i32)
    local.get $segments
    i32.const 0
    i32.const 12
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 296
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 0
    i32.store
    local.get $__mem1
    i32.store offset=8
    local.get $__mem0
    i32.const 4
    i32.add
    call $resolveAll
    local.set $finalState
    local.get $finalState
    i32.load offset=4 ;; .parts
    global.get $separator
    call $__arr_join_str
    local.set $joined
    local.get $finalState
    i32.load ;; .isAbs
    (if (result i32)
      (then
    i32.const 12
    call $__alloc
    local.set $__mem2
    local.get $__mem2
    i32.const 2
    i32.store
    local.get $__mem2
    global.get $separator
    i32.store offset=4
    local.get $__mem2
    local.get $joined
    i32.store offset=8
    local.get $__mem2
    i32.const 272
    call $__arr_join_str
      )
      (else
    local.get $joined
    i32.const 272
    call $__str_eq
    (if (result i32)
      (then
    i32.const 276
      )
      (else
    local.get $joined
      )
    )
      )
    )
    return
  )
  ;; ── 1.0.10-beta front 01 additions ───────────────────────────────────────────
  ;; `p` without its trailing extension: `page.bp` → `page`, `archive.tar.gz`
  ;; → `archive.tar`, `noext` → `noext`. The extension is what `extname`
  ;; answers, so a dotfile keeps its name.
  (func $withoutExtension (export "withoutExtension") (param $p i32) (result i32)
    (local $ext i32)
    (local $n i32)
    (local $stem i32)
    local.get $p
    call $extname
    local.set $ext
    local.get $p
    call $__str_cp_len
    local.set $n
    local.get $ext
    i32.const 272
    call $__str_eq
    (if (result i32)
      (then
    local.get $p
      )
      (else
    local.get $p
    i32.const 0
    local.get $n
    local.get $ext
    call $__str_cp_len
    call $__i32_sub_chk
    call $__str_cp_slice
      )
    )
    local.set $stem
    local.get $stem
    return
  )
  ;; True when `child` resolves inside `parent` — the traversal guard front 22
  ;; applies before it turns a request path into a file path. Both sides go
  ;; through `resolve`, which pops `..` (`normalize` does not), and a relative
  ;; `child` is resolved against `parent`, so `isInside("/app", "blog/x")` is
  ;; true and `isInside("/app", "blog/../../etc")` is false. A parent is inside
  ;; itself. The check reads the first component of the relative path: `..`
  ;; exactly, or `../…` — a component that merely starts with two dots
  ;; (`..foo`) is a name, not an escape.
  (func $isInside (export "isInside") (param $parent i32) (param $child i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $up i32)
    (local $down i32)
    (local $rel i32)
    (local $escapes i32)
    i32.const 8
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 1
    i32.store
    local.get $__mem0
    local.get $parent
    i32.store offset=4
    local.get $__mem0
    call $resolve
    local.set $up
    i32.const 12
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 2
    i32.store
    local.get $__mem1
    local.get $parent
    i32.store offset=4
    local.get $__mem1
    local.get $child
    i32.store offset=8
    local.get $__mem1
    call $resolve
    local.set $down
    local.get $up
    local.get $down
    call $relative
    local.set $rel
    local.get $rel
    i32.const 284
    call $__str_eq
    local.get $rel
    i32.const 324
    call $__str_starts_with
    i32.or
    local.set $escapes
    local.get $escapes
    i32.const 0
    i32.eq
    return
  )
  ;; ── tests ────────────────────────────────────────────────────────────────────
  (func $__arr_at (param $xs i32) (param $i i32) (result i32)
    local.get $i
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $i
        local.get $xs
        i32.load
        i32.add
        local.set $i
      )
    )
    local.get $i
    i32.const 0
    i32.lt_s
    local.get $i
    local.get $xs
    i32.load
    i32.ge_s
    i32.or
    (if (result i32)
      (then i32.const 0)
      (else
        local.get $xs
        local.get $i
        i32.const 1
        i32.add
        i32.const 4
        i32.mul
        i32.add
        i32.load
      )
    )
  )
  (func $__str_eq (param $a i32) (param $b i32) (result i32)
    (local $i i32) (local $alen i32)
    local.get $a
    i32.load
    local.set $alen
    local.get $alen
    local.get $b
    i32.load
    i32.ne
    (if
      (then i32.const 0 return)
    )
    (block $done
      (loop $cmp
        local.get $i
        local.get $alen
        i32.ge_u
        br_if $done
        local.get $a
        local.get $i
        i32.add
        i32.load8_u offset=4
        local.get $b
        local.get $i
        i32.add
        i32.load8_u offset=4
        i32.ne
        (if
          (then i32.const 0 return)
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cmp
      )
    )
    i32.const 1
  )
  (func $__str_slice (param $src i32) (param $start i32) (param $end i32) (result i32)
    (local $newlen i32) (local $dst i32)
    local.get $end
    local.get $start
    i32.sub
    local.set $newlen
    ;; allocate 4 (length prefix) + newlen
    i32.const 4
    local.get $newlen
    i32.add
    call $__alloc
    local.set $dst
    ;; store length prefix
    local.get $dst
    local.get $newlen
    i32.store
    ;; copy bytes: dst+4 <- src+4+start
    local.get $dst
    i32.const 4
    i32.add
    local.get $src
    i32.const 4
    i32.add
    local.get $start
    i32.add
    local.get $newlen
    memory.copy
    local.get $dst
  )
  (func $__alloc (param $n i32) (result i32)
    (local $p i32) (local $e i32)
    global.get $__heap_ptr
    local.set $p
    local.get $p
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    local.set $e
    local.get $e
    local.get $p
    i32.lt_u
    (if
      (then
        unreachable
      )
    )
    local.get $e
    memory.size
    i32.const 16
    i32.shl
    i32.gt_u
    (if
      (then
        local.get $e
        i32.const 65535
        i32.add
        i32.const 16
        i32.shr_u
        memory.size
        i32.sub
        memory.grow
        i32.const -1
        i32.eq
        (if
          (then
            unreachable
          )
        )
      )
    )
    local.get $e
    global.set $__heap_ptr
    local.get $p
  )
  (func $__mem_eq (param $a i32) (param $b i32) (param $n i32) (result i32)
    (local $i i32)
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $a
        local.get $i
        i32.add
        i32.load8_u
        local.get $b
        local.get $i
        i32.add
        i32.load8_u
        i32.ne
        (if
          (then
            i32.const 0
            return
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    i32.const 1
  )
  (func $__str_starts_with (param $s i32) (param $p i32) (result i32)
    local.get $p
    i32.load
    local.get $s
    i32.load
    i32.gt_u
    (if
      (then
        i32.const 0
        return
      )
    )
    local.get $s
    i32.const 4
    i32.add
    local.get $p
    i32.const 4
    i32.add
    local.get $p
    i32.load
    call $__mem_eq
  )
  (func $__str_split (param $s i32) (param $sep i32) (result i32)
    (local $n i32) (local $m i32) (local $i i32) (local $cnt i32) (local $arr i32) (local $start i32) (local $k i32)
    local.get $s
    i32.load
    local.set $n
    local.get $sep
    i32.load
    local.set $m
    local.get $m
    i32.eqz
    (if
      (then
        (block $brk
          (loop $cont
            local.get $i
            local.get $n
            i32.ge_u
            br_if $brk
            local.get $s
            local.get $i
            i32.add
            i32.load8_u offset=4
            i32.const 192
            i32.and
            i32.const 128
            i32.ne
            (if
              (then
                local.get $cnt
                i32.const 1
                i32.add
                local.set $cnt
              )
            )
            local.get $i
            i32.const 1
            i32.add
            local.set $i
            br $cont
          )
        )
        local.get $cnt
        call $__arr_new
        local.set $arr
        i32.const 1
        local.set $i
        (block $brk
          (loop $cont
            local.get $i
            local.get $n
            i32.ge_u
            br_if $brk
            local.get $s
            local.get $i
            i32.add
            i32.load8_u offset=4
            i32.const 192
            i32.and
            i32.const 128
            i32.ne
            (if
              (then
                local.get $arr
                i32.const 4
                i32.add
                local.get $k
                i32.const 4
                i32.mul
                i32.add
                local.get $s
                local.get $start
                local.get $i
                call $__str_slice
                i32.store
                local.get $k
                i32.const 1
                i32.add
                local.set $k
                local.get $i
                local.set $start
              )
            )
            local.get $i
            i32.const 1
            i32.add
            local.set $i
            br $cont
          )
        )
        local.get $n
        (if
          (then
            local.get $arr
            i32.const 4
            i32.add
            local.get $k
            i32.const 4
            i32.mul
            i32.add
            local.get $s
            local.get $start
            local.get $n
            call $__str_slice
            i32.store
          )
        )
        local.get $arr
        return
      )
    )
    i32.const 1
    local.set $cnt
    (block $brk
      (loop $cont
        local.get $i
        local.get $m
        i32.add
        local.get $n
        i32.gt_u
        br_if $brk
        local.get $s
        i32.const 4
        i32.add
        local.get $i
        i32.add
        local.get $sep
        i32.const 4
        i32.add
        local.get $m
        call $__mem_eq
        (if
          (then
            local.get $cnt
            i32.const 1
            i32.add
            local.set $cnt
            local.get $i
            local.get $m
            i32.add
            local.set $i
          )
          (else
            local.get $i
            i32.const 1
            i32.add
            local.set $i
          )
        )
        br $cont
      )
    )
    local.get $cnt
    call $__arr_new
    local.set $arr
    i32.const 0
    local.set $i
    (block $brk
      (loop $cont
        local.get $i
        local.get $m
        i32.add
        local.get $n
        i32.gt_u
        br_if $brk
        local.get $s
        i32.const 4
        i32.add
        local.get $i
        i32.add
        local.get $sep
        i32.const 4
        i32.add
        local.get $m
        call $__mem_eq
        (if
          (then
            local.get $arr
            i32.const 4
            i32.add
            local.get $k
            i32.const 4
            i32.mul
            i32.add
            local.get $s
            local.get $start
            local.get $i
            call $__str_slice
            i32.store
            local.get $k
            i32.const 1
            i32.add
            local.set $k
            local.get $i
            local.get $m
            i32.add
            local.tee $i
            local.set $start
          )
          (else
            local.get $i
            i32.const 1
            i32.add
            local.set $i
          )
        )
        br $cont
      )
    )
    local.get $arr
    i32.const 4
    i32.add
    local.get $k
    i32.const 4
    i32.mul
    i32.add
    local.get $s
    local.get $start
    local.get $n
    call $__str_slice
    i32.store
    local.get $arr
  )
  (func $__arr_new (param $n i32) (result i32)
    (local $p i32)
    local.get $n
    i32.const 1
    i32.add
    i32.const 4
    i32.mul
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
    local.get $p
  )
  (func $__arr_slice (param $xs i32) (param $a i32) (param $b i32) (result i32)
    (local $n i32) (local $cnt i32) (local $p i32)
    local.get $xs
    i32.load
    local.set $n
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $n
        local.get $a
        i32.add
        local.set $a
        local.get $a
        i32.const 0
        i32.lt_s
        (if
          (then
            i32.const 0
            local.set $a
          )
        )
      )
      (else
        local.get $a
        local.get $n
        i32.gt_s
        (if
          (then
            local.get $n
            local.set $a
          )
        )
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $n
        local.get $b
        i32.add
        local.set $b
        local.get $b
        i32.const 0
        i32.lt_s
        (if
          (then
            i32.const 0
            local.set $b
          )
        )
      )
      (else
        local.get $b
        local.get $n
        i32.gt_s
        (if
          (then
            local.get $n
            local.set $b
          )
        )
      )
    )
    local.get $b
    local.get $a
    i32.sub
    local.set $cnt
    local.get $cnt
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 0
        local.set $cnt
      )
    )
    local.get $cnt
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $xs
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.mul
    i32.add
    local.get $cnt
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
  )
  (func $__arr_prepend (param $xs i32) (param $x i32) (result i32)
    (local $n i32) (local $p i32)
    local.get $xs
    i32.load
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    call $__arr_new
    local.set $p
    local.get $p
    local.get $x
    i32.store offset=4
    local.get $p
    i32.const 8
    i32.add
    local.get $xs
    i32.const 4
    i32.add
    local.get $n
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
  )
  (func $__arr_concat (param $a i32) (param $b i32) (result i32)
    (local $na i32) (local $nb i32) (local $p i32)
    local.get $a
    i32.load
    local.set $na
    local.get $b
    i32.load
    local.set $nb
    local.get $na
    local.get $nb
    i32.add
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.add
    local.get $na
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
    i32.const 4
    i32.add
    local.get $na
    i32.const 4
    i32.mul
    i32.add
    local.get $b
    i32.const 4
    i32.add
    local.get $nb
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
  )
  (func $__arr_join_str (param $xs i32) (param $sep i32) (result i32)
    (local $n i32) (local $i i32) (local $total i32) (local $p i32) (local $pos i32) (local $e i32)
    local.get $xs
    i32.load
    local.set $n
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $total
        local.get $xs
        i32.const 4
        i32.add
        local.get $i
        i32.const 4
        i32.mul
        i32.add
        i32.load
        i32.load
        i32.add
        local.set $total
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $n
    (if
      (then
        local.get $total
        local.get $sep
        i32.load
        local.get $n
        i32.const 1
        i32.sub
        i32.mul
        i32.add
        local.set $total
      )
    )
    local.get $total
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $total
    i32.store
    local.get $p
    i32.const 4
    i32.add
    local.set $pos
    i32.const 0
    local.set $i
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $i
        (if
          (then
            local.get $pos
            local.get $sep
            i32.const 4
            i32.add
            local.get $sep
            i32.load
            memory.copy
            local.get $pos
            local.get $sep
            i32.load
            i32.add
            local.set $pos
          )
        )
        local.get $xs
        i32.const 4
        i32.add
        local.get $i
        i32.const 4
        i32.mul
        i32.add
        i32.load
        local.set $e
        local.get $pos
        local.get $e
        i32.const 4
        i32.add
        local.get $e
        i32.load
        memory.copy
        local.get $pos
        local.get $e
        i32.load
        i32.add
        local.set $pos
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
  )
  (func $__str_cp_len (param $s i32) (result i32)
    (local $n i32) (local $i i32) (local $k i32)
    local.get $s
    i32.load
    local.set $n
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $s
        local.get $i
        i32.add
        i32.load8_u offset=4
        i32.const 192
        i32.and
        i32.const 128
        i32.ne
        (if
          (then
            local.get $k
            i32.const 1
            i32.add
            local.set $k
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $k
  )
  (func $__str_cp_off (param $s i32) (param $i i32) (result i32)
    (local $n i32) (local $p i32) (local $k i32)
    local.get $s
    i32.load
    local.set $n
    (block $brk
      (loop $cont
        local.get $p
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $s
        local.get $p
        i32.add
        i32.load8_u offset=4
        i32.const 192
        i32.and
        i32.const 128
        i32.ne
        (if
          (then
            local.get $k
            local.get $i
            i32.eq
            (if
              (then
                local.get $p
                return
              )
            )
            local.get $k
            i32.const 1
            i32.add
            local.set $k
          )
        )
        local.get $p
        i32.const 1
        i32.add
        local.set $p
        br $cont
      )
    )
    local.get $n
  )
  (func $__str_cp_slice (param $s i32) (param $a i32) (param $b i32) (result i32)
    (local $n i32)
    local.get $s
    call $__str_cp_len
    local.set $n
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $a
        local.get $n
        i32.add
        local.set $a
      )
    )
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 0
        local.set $a
      )
    )
    local.get $a
    local.get $n
    i32.gt_s
    (if
      (then
        local.get $n
        local.set $a
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $b
        local.get $n
        i32.add
        local.set $b
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 0
        local.set $b
      )
    )
    local.get $b
    local.get $n
    i32.gt_s
    (if
      (then
        local.get $n
        local.set $b
      )
    )
    local.get $b
    local.get $a
    i32.lt_s
    (if
      (then
        local.get $a
        local.set $b
      )
    )
    local.get $s
    local.get $s
    local.get $a
    call $__str_cp_off
    local.get $s
    local.get $b
    call $__str_cp_off
    call $__str_slice
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.add
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.sub
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.mul
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.add
    local.set $r
    local.get $a
    local.get $r
    i64.xor
    local.get $b
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.sub
    local.set $r
    local.get $a
    local.get $b
    i64.xor
    local.get $a
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (result i64)
    (local $r i64)
    local.get $a
    i64.const -1
    i64.eq
    local.get $b
    i64.const -9223372036854775808
    i64.eq
    i32.and
    (if
      (then
        unreachable
      )
    )
    local.get $a
    local.get $b
    i64.mul
    local.set $r
    local.get $a
    i64.eqz
    i32.eqz
    (if
      (then
        local.get $r
        local.get $a
        i64.div_s
        local.get $b
        i64.ne
        (if
          (then
            unreachable
          )
        )
      )
    )
    local.get $r
  )
)
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

