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

----- WASM TEXT -- std/path.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_any (array (mut anyref)))
    (type $rec_PathAccum (struct (field $f0 (mut i32)) (field $f1 (mut (ref null $arr_any)))))
  )
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (start $__init_strs)
  (global $__heap_ptr (mut i32) (i32.const 1408))
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
  (global $separator (mut (ref null $str)) (ref.null $str))
  (global $delimiter (mut (ref null $str)) (ref.null $str))
  ;; Split a path into its non-empty components. Leading-`/` paths drop the
  ;; empty head; trailing-`/` paths drop the empty tail. A path made of pure
  ;; separators yields the empty array. Uses `filter` rather than
  ;; `forEach` + `push`: a `var` + `push` pattern lowers to a dead-store
  ;; (`out ++ [p]` discarded) on Erlang because the immutable runtime never
  ;; rebinds `Out`; `filter` round-trips through `lists:filter/2` and
  ;; `Array.prototype.filter` directly.
  (func $split (export "split") (param $path (ref null $str)) (result (ref null $arr_any))
    (local $raw (ref null $arr_any))
    (local $__gc0 (ref null $str))
    (local $__gc1 (ref null $str))
    (local $__gc2 i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $str))
    (local $__out0 (ref null $arr_any))
    local.get $path
    global.get $separator
    local.set $__gc0
    local.set $__gc1
    global.get $__heap_ptr
    local.set $__gc2
    local.get $__gc1
    call $__gc_to_lin_str
    local.get $__gc0
    call $__gc_to_lin_str
    call $__std_text_split
    call $__lin_to_gc_strs
    local.get $__gc2
    global.set $__heap_ptr
    local.set $raw
    local.get $raw
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
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
        array.get $arr_any
    ref.cast (ref null $str)
        local.set $p
    local.get $p
    global.get $__s0
    call $__str_eq
    i32.eqz
    (if
      (then
    local.get $__out0
    local.get $__acc0
    local.get $__iter0
    local.get $__idx0
    array.get $arr_any
    array.set $arr_any
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
    i32.const 0
    local.get $__acc0
    call $__arr_slice_any
    return
  )
  ;; True when `path` starts with `/` — the posix absolute-path marker.
  (func $isAbsolute (export "isAbsolute") (param $path (ref null $str)) (result i32)
    (local $__gc3 (ref null $str))
    (local $__gc4 (ref null $str))
    (local $__gc5 i32)
    local.get $path
    global.get $separator
    local.set $__gc3
    local.set $__gc4
    global.get $__heap_ptr
    local.set $__gc5
    local.get $__gc4
    call $__gc_to_lin_str
    local.get $__gc3
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc5
    global.set $__heap_ptr
    return
  )
  ;; The last non-empty component of `path` (the file name, in the common
  ;; case). Returns "" for the empty path and for pure-separator paths.
  (func $basename (export "basename") (param $path (ref null $str)) (result (ref null $str))
    (local $parts (ref null $arr_any))
    (local $n i32)
    (local $__bp_nullish i32)
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__0 (ref null $str))
    local.get $path
    call $split
    local.set $parts
    local.get $parts
    array.len
    local.set $n
    local.get $n
    i32.const 0
    i32.eq
    (if (result (ref null $str))
      (then
    global.get $__s0
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    local.get $parts
    local.get $n
    i32.const 1
    global.get $__s1
    call $__i32_sub_chk
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__0
    local.get $__bp_nullish__0
      )
      (else
    global.get $__s0
      )
    )
    return
  )
  ;; Everything except the basename — the parent directory portion. For an
  ;; absolute path this preserves the leading `/`. For a path with no
  ;; separator (`"foo"`), returns `""`.
  (func $dirname (export "dirname") (param $path (ref null $str)) (result (ref null $str))
    (local $__mem0 i32)
    (local $parts (ref null $arr_any))
    (local $n i32)
    (local $head (ref null $arr_any))
    (local $joined (ref null $str))
    local.get $path
    call $split
    local.set $parts
    local.get $parts
    array.len
    local.set $n
    local.get $n
    i32.const 1
    i32.le_s
    (if (result (ref null $str))
      (then
    local.get $path
    call $isAbsolute
    (if (result (ref null $str))
      (then
    global.get $separator
      )
      (else
    global.get $__s0
      )
    )
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    local.get $parts
    i32.const 0
    local.get $n
    i32.const 1
    global.get $__s2
    call $__i32_sub_chk
    call $__arr_slice_any
    local.set $head
    local.get $head
    global.get $separator
    call $__arr_join_any
    local.set $joined
    local.get $path
    call $isAbsolute
    (if (result (ref null $str))
      (then
    global.get $separator
    local.get $joined
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
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
  (func $extname (export "extname") (param $path (ref null $str)) (result (ref null $str))
    (local $__mem0 i32)
    (local $base (ref null $str))
    (local $pieces (ref null $arr_any))
    (local $n i32)
    (local $head (ref null $str))
    (local $__bp_nullish i32)
    (local $tail (ref null $str))
    (local $isDotfile i32)
    (local $__gc6 (ref null $str))
    (local $__gc7 (ref null $str))
    (local $__gc8 i32)
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__1 (ref null $str))
    (local $__opt1 (ref null $str))
    (local $__bp_nullish__2 (ref null $str))
    local.get $path
    call $basename
    local.set $base
    local.get $base
    global.get $__s3
    local.set $__gc6
    local.set $__gc7
    global.get $__heap_ptr
    local.set $__gc8
    local.get $__gc7
    call $__gc_to_lin_str
    local.get $__gc6
    call $__gc_to_lin_str
    call $__std_text_split
    call $__lin_to_gc_strs
    local.get $__gc8
    global.set $__heap_ptr
    local.set $pieces
    local.get $pieces
    array.len
    local.set $n
    local.get $n
    i32.const 1
    i32.le_s
    (if (result (ref null $str))
      (then
    global.get $__s0
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    local.get $pieces
    i32.const 0
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__1
    local.get $__bp_nullish__1
      )
      (else
    global.get $__s0
      )
    )
    local.set $head
    local.get $pieces
    local.get $n
    i32.const 1
    global.get $__s4
    call $__i32_sub_chk
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt1
    local.set $__bp_nullish__2
    local.get $__bp_nullish__2
      )
      (else
    global.get $__s0
      )
    )
    local.set $tail
    local.get $head
    global.get $__s0
    call $__str_eq
    (if (result i32)
      (then
    local.get $n
    i32.const 2
    i32.eq
      )
      (else
    i32.const 0
      )
    )
    local.set $isDotfile
    local.get $isDotfile
    (if (result (ref null $str))
      (then
    global.get $__s0
      )
      (else
    global.get $__s3
    local.get $tail
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
      )
    )
    return
  )
  ;; Join a list of path segments with the separator. Leading separator on
  ;; the first segment is preserved; intra-segment slashes are normalised
  ;; (`"foo/" + "/bar"` joins to `"foo/bar"`, never `"foo//bar"`). Uses
  ;; `map` + `filter` + `join` rather than `fold` / `flatMap`: those land
  ;; on `array<T>` default-fn bodies that lower to a `var` + `push` shape,
  ;; which lowers to a dead store on Erlang's immutable runtime (the same
  ;; trap `split` sidesteps).
  (func $join (export "join") (param $parts (ref null $arr_any)) (result (ref null $str))
    (local $__mem0 i32)
    (local $isAbs i32)
    (local $__bp_nullish i32)
    (local $collapsed (ref null $arr_any))
    (local $joined (ref null $str))
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__3 (ref null $str))
    (local $__iter1 (ref null $arr_any))
    (local $__idx1 i32)
    (local $__len1 i32)
    (local $__acc1 i32)
    (local $p (ref null $str))
    (local $__out1 (ref null $arr_any))
    (local $__iter2 (ref null $arr_any))
    (local $__idx2 i32)
    (local $__len2 i32)
    (local $__acc2 i32)
    (local $__out2 (ref null $arr_any))
    local.get $parts
    array.len
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    i32.const 0
      )
      (else
    local.get $parts
    i32.const 0
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__3
    local.get $__bp_nullish__3
      )
      (else
    global.get $__s0
      )
    )
    call $isAbsolute
      )
    )
    local.set $isAbs
    local.get $parts
    local.set $__iter1
    local.get $__iter1
    array.len
    local.set $__len1
    i32.const 0
    local.set $__idx1
    local.get $__len1
    array.new_default $arr_any
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
        array.get $arr_any
    ref.cast (ref null $str)
        local.set $p
    local.get $__out1
    local.get $__idx1
    local.get $p
    call $split
    global.get $separator
    call $__arr_join_any
    array.set $arr_any
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
    array.len
    local.set $__len2
    i32.const 0
    local.set $__idx2
    local.get $__len2
    array.new_default $arr_any
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
        array.get $arr_any
    ref.cast (ref null $str)
        local.set $p
    local.get $p
    global.get $__s0
    call $__str_eq
    i32.eqz
    (if
      (then
    local.get $__out2
    local.get $__acc2
    local.get $__iter2
    local.get $__idx2
    array.get $arr_any
    array.set $arr_any
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
    i32.const 0
    local.get $__acc2
    call $__arr_slice_any
    global.get $separator
    call $__arr_join_any
    local.set $joined
    local.get $isAbs
    (if (result (ref null $str))
      (then
    global.get $separator
    local.get $joined
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
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
  (func $normalize (export "normalize") (param $path (ref null $str)) (result (ref null $str))
    (local $__mem0 i32)
    (local $isAbs i32)
    (local $pieces (ref null $arr_any))
    (local $joined (ref null $str))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $str))
    (local $__out0 (ref null $arr_any))
    local.get $path
    global.get $__s0
    call $__str_eq
    (if (result (ref null $str))
      (then
    global.get $__s3
    return
      )
      (else
        ref.null $str
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
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
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
        array.get $arr_any
    ref.cast (ref null $str)
        local.set $p
    local.get $p
    global.get $__s3
    call $__str_eq
    i32.eqz
    (if
      (then
    local.get $__out0
    local.get $__acc0
    local.get $__iter0
    local.get $__idx0
    array.get $arr_any
    array.set $arr_any
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
    i32.const 0
    local.get $__acc0
    call $__arr_slice_any
    local.set $pieces
    local.get $pieces
    global.get $separator
    call $__arr_join_any
    local.set $joined
    local.get $isAbs
    (if (result (ref null $str))
      (then
    global.get $separator
    local.get $joined
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
      )
      (else
    local.get $joined
    global.get $__s0
    call $__str_eq
    (if (result (ref null $str))
      (then
    global.get $__s3
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
  (func $commonPrefixCount (param $a (ref null $arr_any)) (param $b (ref null $arr_any)) (param $i i32) (result i32)
    (local $ai (ref null $str))
    (local $__bp_nullish i32)
    (local $bi (ref null $str))
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__4 (ref null $str))
    (local $__opt1 (ref null $str))
    (local $__bp_nullish__5 (ref null $str))
    local.get $i
    local.get $a
    array.len
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
    array.len
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
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__4
    local.get $__bp_nullish__4
      )
      (else
    global.get $__s0
      )
    )
    local.set $ai
    local.get $b
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt1
    local.set $__bp_nullish__5
    local.get $__bp_nullish__5
      )
      (else
    global.get $__s0
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
    global.get $__s5
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
  (func $makeUps (param $n i32) (result (ref null $arr_any))
    (local $__mem0 i32)
    local.get $n
    i32.const 0
    i32.le_s
    (if (result (ref null $arr_any))
      (then
    array.new_fixed $arr_any 0
      )
      (else
    local.get $n
    i32.const 1
    global.get $__s6
    call $__i32_sub_chk
    call $makeUps
    global.get $__s7
    call $__arr_prepend_any
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
  (func $relative (export "relative") (param $src (ref null $str)) (param $dst (ref null $str)) (result (ref null $str))
    (local $srcParts (ref null $arr_any))
    (local $dstParts (ref null $arr_any))
    (local $common i32)
    (local $ups (ref null $arr_any))
    (local $downs (ref null $arr_any))
    (local $combined (ref null $arr_any))
    (local $joined (ref null $str))
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
    array.len
    local.get $common
    global.get $__s8
    call $__i32_sub_chk
    call $makeUps
    local.set $ups
    local.get $dstParts
    local.get $common
    local.get $dstParts
    array.len
    call $__arr_slice_any
    local.set $downs
    local.get $ups
    local.get $downs
    call $__arr_concat_any
    local.set $combined
    local.get $combined
    global.get $separator
    call $__arr_join_any
    local.set $joined
    local.get $joined
    global.get $__s0
    call $__str_eq
    (if (result (ref null $str))
      (then
    global.get $__s3
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
  (func $applyPieces (param $acc (ref null $arr_any)) (param $pieces (ref null $arr_any)) (result (ref null $arr_any))
    (local $__mem0 i32)
    (local $p (ref null $str))
    (local $__bp_nullish i32)
    (local $rest (ref null $arr_any))
    (local $nextAcc (ref null $arr_any))
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__6 (ref null $str))
    (loop $__tail (result (ref null $arr_any))
    local.get $pieces
    array.len
    i32.const 0
    i32.eq
    (if (result (ref null $arr_any))
      (then
    local.get $acc
    return
      )
      (else
        ref.null $arr_any
      )
    )
    drop
    local.get $pieces
    i32.const 0
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__6
    local.get $__bp_nullish__6
      )
      (else
    global.get $__s0
      )
    )
    local.set $p
    local.get $pieces
    i32.const 1
    local.get $pieces
    array.len
    call $__arr_slice_any
    local.set $rest
    local.get $p
    global.get $__s7
    call $__str_eq
    (if (result (ref null $arr_any))
      (then
    local.get $acc
    array.len
    i32.const 0
    i32.eq
    (if (result (ref null $arr_any))
      (then
    local.get $acc
      )
      (else
    local.get $acc
    i32.const 0
    local.get $acc
    array.len
    i32.const 1
    global.get $__s9
    call $__i32_sub_chk
    call $__arr_slice_any
      )
    )
      )
      (else
    local.get $acc
    local.get $p
    array.new_fixed $arr_any 1
    call $__arr_concat_any
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
  (func $resolveStep (param $state (ref null $rec_PathAccum)) (param $seg (ref null $str)) (result (ref null $rec_PathAccum))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $pieces (ref null $arr_any))
    (local $nextIsAbs i32)
    (local $baseParts (ref null $arr_any))
    local.get $seg
    call $split
    local.set $pieces
    local.get $seg
    call $isAbsolute
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $state
    struct.get $rec_PathAccum $f0
      )
    )
    local.set $nextIsAbs
    local.get $seg
    call $isAbsolute
    (if (result (ref null $arr_any))
      (then
    array.new_fixed $arr_any 0
      )
      (else
    local.get $state
    struct.get $rec_PathAccum $f1
      )
    )
    local.set $baseParts
    local.get $nextIsAbs
    local.get $baseParts
    local.get $pieces
    call $applyPieces
    struct.new $rec_PathAccum
    return
  )
  (func $resolveAll (param $segments (ref null $arr_any)) (param $i i32) (param $state (ref null $rec_PathAccum)) (result (ref null $rec_PathAccum))
    (local $seg (ref null $str))
    (local $__bp_nullish i32)
    (local $next (ref null $rec_PathAccum))
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__7 (ref null $str))
    (loop $__tail (result (ref null $rec_PathAccum))
    local.get $i
    local.get $segments
    array.len
    i32.ge_s
    (if (result (ref null $rec_PathAccum))
      (then
    local.get $state
    return
      )
      (else
        ref.null $rec_PathAccum
      )
    )
    drop
    local.get $segments
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__7
    local.get $__bp_nullish__7
      )
      (else
    global.get $__s0
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
    global.get $__s10
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
  (func $resolve (export "resolve") (param $segments (ref null $arr_any)) (result (ref null $str))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $finalState (ref null $rec_PathAccum))
    (local $joined (ref null $str))
    local.get $segments
    i32.const 0
    i32.const 0
    array.new_fixed $arr_any 0
    struct.new $rec_PathAccum
    call $resolveAll
    local.set $finalState
    local.get $finalState
    struct.get $rec_PathAccum $f1
    global.get $separator
    call $__arr_join_any
    local.set $joined
    local.get $finalState
    struct.get $rec_PathAccum $f0
    (if (result (ref null $str))
      (then
    global.get $separator
    local.get $joined
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
      )
      (else
    local.get $joined
    global.get $__s0
    call $__str_eq
    (if (result (ref null $str))
      (then
    global.get $__s3
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
  (func $withoutExtension (export "withoutExtension") (param $p (ref null $str)) (result (ref null $str))
    (local $ext (ref null $str))
    (local $n i32)
    (local $stem (ref null $str))
    (local $__gc9 i32)
    (local $__gc10 i32)
    (local $__gc11 (ref null $str))
    (local $__gc12 i32)
    local.get $p
    call $extname
    local.set $ext
    local.get $p
    call $__std_text_length
    local.set $n
    local.get $ext
    global.get $__s0
    call $__str_eq
    (if (result (ref null $str))
      (then
    local.get $p
      )
      (else
    local.get $p
    i32.const 0
    local.get $n
    local.get $ext
    call $__std_text_length
    global.get $__s11
    call $__i32_sub_chk
    local.set $__gc9
    local.set $__gc10
    local.set $__gc11
    global.get $__heap_ptr
    local.set $__gc12
    local.get $__gc11
    call $__gc_to_lin_str
    local.get $__gc10
    local.get $__gc9
    call $__std_text_slice
    call $__lin_to_gc_str
    local.get $__gc12
    global.set $__heap_ptr
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
  (func $isInside (export "isInside") (param $parent (ref null $str)) (param $child (ref null $str)) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $up (ref null $str))
    (local $down (ref null $str))
    (local $rel (ref null $str))
    (local $escapes i32)
    (local $__gc13 (ref null $str))
    (local $__gc14 (ref null $str))
    (local $__gc15 i32)
    local.get $parent
    array.new_fixed $arr_any 1
    call $resolve
    local.set $up
    local.get $parent
    local.get $child
    array.new_fixed $arr_any 2
    call $resolve
    local.set $down
    local.get $up
    local.get $down
    call $relative
    local.set $rel
    local.get $rel
    global.get $__s7
    call $__str_eq
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $rel
    global.get $__s12
    local.set $__gc13
    local.set $__gc14
    global.get $__heap_ptr
    local.set $__gc15
    local.get $__gc14
    call $__gc_to_lin_str
    local.get $__gc13
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc15
    global.set $__heap_ptr
      )
    )
    local.set $escapes
    local.get $escapes
    i32.const 0
    i32.eq
    return
  )
  ;; ── tests ────────────────────────────────────────────────────────────────────
  (func $__init_globals
    global.get $__s13
    global.set $separator
    global.get $__s14
    global.set $delimiter
  )
  (func $__arr_slice_any (param $xs (ref null $arr_any)) (param $a i32) (param $b i32) (result (ref null $arr_any))
    (local $len i32)
    (local $from i32)
    (local $to i32)
    (local $n i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $len
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $len
    local.get $a
    i32.add
    local.set $from
    local.get $from
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $from
      )
    )
      )
      (else
    local.get $a
    local.set $from
    local.get $from
    local.get $len
    i32.gt_s
    (if
      (then
    local.get $len
    local.set $from
      )
    )
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $len
    local.get $b
    i32.add
    local.set $to
    local.get $to
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $to
      )
    )
      )
      (else
    local.get $b
    local.set $to
    local.get $to
    local.get $len
    i32.gt_s
    (if
      (then
    local.get $len
    local.set $to
      )
    )
      )
    )
    local.get $to
    local.get $from
    i32.sub
    local.set $n
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $n
      )
    )
    local.get $n
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    local.get $from
    local.get $n
    array.copy $arr_any $arr_any
    local.get $r
  )
  (func $__arr_at_opt_any (param $xs (ref null $arr_any)) (param $i i32) (result anyref)
    local.get $i
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $i
    local.get $xs
    array.len
    i32.add
    local.set $i
      )
    )
    local.get $i
    i32.const 0
    i32.lt_s
    local.get $i
    local.get $xs
    array.len
    i32.ge_s
    i32.or
    (if (result anyref)
      (then
    ref.null any
      )
      (else
    local.get $xs
    local.get $i
    array.get $arr_any
      )
    )
  )
  (func $__arr_join_any (param $xs (ref null $arr_any)) (param $sep (ref null $str)) (result (ref null $str))
    (local $n i32)
    (local $i i32)
    (local $acc (ref null $str))
    local.get $xs
    array.len
    local.set $n
    i32.const 0
    array.new_default $str
    local.set $acc
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    local.get $acc
    local.get $sep
    call $__str_concat
    local.set $acc
      )
    )
    local.get $acc
    local.get $xs
    local.get $i
    array.get $arr_any
    ref.cast (ref null $str)
    call $__str_concat
    local.set $acc
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $acc
  )
  (func $__arr_prepend_any (param $xs (ref null $arr_any)) (param $x anyref) (result (ref null $arr_any))
    (local $n i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $x
    array.set $arr_any
    local.get $r
    i32.const 1
    local.get $xs
    i32.const 0
    local.get $n
    array.copy $arr_any $arr_any
    local.get $r
  )
  (func $__arr_concat_any (param $xs (ref null $arr_any)) (param $ys (ref null $arr_any)) (result (ref null $arr_any))
    (local $la i32)
    (local $lb i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $la
    local.get $ys
    array.len
    local.set $lb
    local.get $la
    local.get $lb
    i32.add
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $la
    array.copy $arr_any $arr_any
    local.get $r
    local.get $la
    local.get $ys
    i32.const 0
    local.get $lb
    array.copy $arr_any $arr_any
    local.get $r
  )
  (func $__lin_to_gc_strs (param $p i32) (result (ref null $arr_any))
    (local $n i32)
    (local $i i32)
    (local $r (ref null $arr_any))
    local.get $p
    i32.load
    local.set $n
    local.get $n
    array.new_default $arr_any
    local.set $r
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $r
    local.get $i
    local.get $p
    local.get $i
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    call $__lin_to_gc_str
    array.set $arr_any
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $r
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
  (func $__write_bytes (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__print_nl
    i32.const 8
    i32.const 10
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  ;; separator between the arguments of a multi-argument `@print`
  (func $__print_sp
    i32.const 8
    i32.const 32
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i32 (param $n i32)
    local.get $n
    call $__print_i32_raw
    call $__print_nl
  )
  (func $__print_i32_raw (param $n i32)
    (local $buf i32) (local $len i32) (local $neg i32) (local $d i32)
    (local $i i32) (local $j i32) (local $tmp i32)
    i32.const 64
    local.set $buf
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 1
        local.set $neg
        i32.const 0
        local.get $n
        i32.sub
        local.set $n
      )
    )
    (block $done
      (loop $digits
        local.get $n
        i32.const 10
        i32.rem_u
        i32.const 48
        i32.add
        local.set $d
        local.get $buf
        local.get $len
        i32.add
        local.get $d
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
        local.get $n
        i32.const 10
        i32.div_u
        local.set $n
        local.get $n
        i32.const 0
        i32.gt_u
        br_if $digits
      )
    )
    ;; reverse
    i32.const 0
    local.set $i
    local.get $len
    i32.const 1
    i32.sub
    local.set $j
    (block $rdone
      (loop $rev
        local.get $i
        local.get $j
        i32.ge_u
        br_if $rdone
        local.get $buf
        local.get $i
        i32.add
        i32.load8_u
        local.set $tmp
        local.get $buf
        local.get $i
        i32.add
        local.get $buf
        local.get $j
        i32.add
        i32.load8_u
        i32.store8
        local.get $buf
        local.get $j
        i32.add
        local.get $tmp
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        local.get $j
        i32.const 1
        i32.sub
        local.set $j
        br $rev
      )
    )
    ;; add neg sign + newline
    ;; shift the digits one byte right to make room for '-'
    ;; (dst = buf+1, NOT buf+len: the latter moved them `len`
    ;;  bytes and printed -12 as -21)
    local.get $neg
    (if
      (then
        local.get $buf
        i32.const 1
        i32.add
        local.get $buf
        local.get $len
        call $__memmove
        local.get $buf
        i32.const 45
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
      )
    )
    local.get $buf
    local.get $len
    call $__write_bytes
  )
  (func $__memmove (param $dst i32) (param $src i32) (param $len i32)
    (local $i i32)
    local.get $len
    i32.const 1
    i32.sub
    local.set $i
    (block $done
      (loop $loop
        local.get $i
        i32.const 0
        i32.lt_s
        br_if $done
        local.get $dst
        local.get $i
        i32.add
        local.get $src
        local.get $i
        i32.add
        i32.load8_u
        i32.store8
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        br $loop
      )
    )
  )
  (func $__str_concat (param $a (ref null $str)) (param $b (ref null $str)) (result (ref null $str))
    (local $r (ref null $str)) (local $alen i32) (local $blen i32)
    local.get $a
    array.len
    local.set $alen
    local.get $b
    array.len
    local.set $blen
    local.get $alen
    local.get $blen
    i32.add
    array.new_default $str
    local.set $r
    local.get $r
    i32.const 0
    local.get $a
    i32.const 0
    local.get $alen
    array.copy $str $str
    local.get $r
    local.get $alen
    local.get $b
    i32.const 0
    local.get $blen
    array.copy $str $str
    local.get $r
  )
  (func $__str_eq (param $a (ref null $str)) (param $b (ref null $str)) (result i32)
    (local $i i32) (local $n i32) (local $an i32) (local $bn i32)
    local.get $a
    ref.is_null
    local.set $an
    local.get $b
    ref.is_null
    local.set $bn
    local.get $an
    local.get $bn
    i32.or
    (if
      (then
        local.get $an
        local.get $bn
        i32.and
        return
      )
    )
    local.get $a
    array.len
    local.set $n
    local.get $n
    local.get $b
    array.len
    i32.ne
    (if
      (then
        i32.const 0
        return
      )
    )
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $a
        local.get $i
        array.get_u $str
        local.get $b
        local.get $i
        array.get_u $str
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
  (func $__write_err (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 2
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__assert_fail (param $where i32) (param $msg i32)
    local.get $where
    i32.const 4
    i32.add
    local.get $where
    i32.load
    call $__write_err
    i32.const 188
    i64.const 8390880602276044858
    i64.store
    i32.const 196
    i64.const 7811882119909502825
    i64.store
    i32.const 204
    i32.const 101
    i32.store8
    i32.const 205
    i32.const 100
    i32.store8
    i32.const 188
    i32.const 18
    call $__write_err
    local.get $msg
    (if
      (then
        i32.const 188
        i32.const 8250
        i32.store
        i32.const 188
        i32.const 2
        call $__write_err
        local.get $msg
        i32.const 4
        i32.add
        local.get $msg
        i32.load
        call $__write_err
      )
    )
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
  )
  (func $__panic_fail (param $msg (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    i32.const 188
    i64.const 9071397899755888
    i64.store
    i32.const 188
    i32.const 7
    call $__write_err
    local.get $msg
    array.len
    local.set $n
    global.get $__heap_ptr
    local.set $top
    local.get $n
    call $__alloc
    local.set $p
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $msg
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
    local.get $n
    call $__write_err
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
    local.get $top
    global.set $__heap_ptr
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
        local.get $site
        call $__chk_fail
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
            local.get $site
            call $__chk_fail
            unreachable
          )
        )
      )
    )
    local.get $r
  )
  (func $__gc_to_lin_str (param $s (ref null $str)) (result i32)
    (local $n i32) (local $p i32) (local $i i32)
    local.get $s
    array.len
    local.set $n
    local.get $n
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $s
        local.get $i
        array.get_u $str
        i32.store8 offset=4
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
  )
  (func $__lin_to_gc_str (param $p i32) (result (ref null $str))
    (local $r (ref null $str)) (local $n i32) (local $i i32)
    local.get $p
    i32.load
    local.set $n
    local.get $n
    array.new_default $str
    local.set $r
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $r
        local.get $i
        local.get $p
        local.get $i
        i32.add
        i32.load8_u offset=4
        array.set $str
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $r
  )
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  ;; std-wasm (decision 440): its functions, transpiled from std_wasm.wasm
  (global $__std_sp (mut i32) (i32.const 1408))
  (func $__std_sp_check (param $sp i32) (result i32)
    local.get $sp
    i32.const 256
    i32.lt_s
    (if
      (then unreachable)
    )
    local.get $sp
  )
  ;; __std_f4 — from std_wasm.wasm (sha256 b4b6f06748d6)
  ;; __std_f21 — from std_wasm.wasm (sha256 61b86fc4b3a0)
  ;; __std_f23 — from std_wasm.wasm (sha256 2448159130cb)
  ;; __std_f88 — from std_wasm.wasm (sha256 59c161f4ae70)
  ;; __std_f91 — from std_wasm.wasm (sha256 18a947e25763)
  ;; __std_f120 — from std_wasm.wasm (sha256 bd4cb38df48b)
  ;; __std_f265 — from std_wasm.wasm (sha256 8097395f0640)
  ;; __std_f267 — from std_wasm.wasm (sha256 5ac39cdc3016)
  ;; __std_f268 — from std_wasm.wasm (sha256 cda2fb2bf3e4)
  ;; __std_f446 — from std_wasm.wasm (sha256 d13a98c08300)
  ;; std:text.slice — from std_wasm.wasm (sha256 051c966cf248)
  ;; std:text.startsWith — from std_wasm.wasm (sha256 322b10039271)
  ;; __std_f523 — from std_wasm.wasm (sha256 2904f8c0427d)
  ;; std:text.split — from std_wasm.wasm (sha256 d23f0fc25558)
  ;; std-wasm's .wat leaves (front 164 s3)
  (func $__std_text_length (param $s (ref null $str)) (result i32)
    (local $i i32)
    (local $len i32)
    (local $n i32)
    local.get $s
    array.len
    local.set $len
    (block $done
      (loop $next
        local.get $i
        local.get $len
        i32.ge_u
        br_if $done
        local.get $s
        local.get $i
        array.get_u $str
        i32.const 0xC0
        i32.and
        i32.const 0x80
        i32.ne
        local.get $n
        i32.add
        local.set $n
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $next
      )
    )
    local.get $n
  )
  (data $__d0 "")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "integer overflow: - on i32 at src/path.bp:40:23")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "integer overflow: - on i32 at src/path.bp:50:33")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 ".")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "integer overflow: - on i32 at src/path.bp:68:28")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "integer overflow: + on i32 at src/path.bp:114:52")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "integer overflow: - on i32 at src/path.bp:120:42")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "..")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "integer overflow: - on i32 at src/path.bp:135:39")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "integer overflow: - on i32 at src/path.bp:159:63")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "integer overflow: + on i32 at src/path.bp:175:35")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 "integer overflow: - on i32 at src/path.bp:205:51")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (data $__d12 "../")
  (global $__s12 (mut (ref null $str)) (ref.null $str))
  (data $__d13 "/")
  (global $__s13 (mut (ref null $str)) (ref.null $str))
  (data $__d14 ":")
  (global $__s14 (mut (ref null $str)) (ref.null $str))
  (func $__init_strs
    i32.const 0
    i32.const 0
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 47
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 47
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 1
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 47
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 48
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 48
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 2
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 48
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 48
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 48
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 48
    array.new_data $str $__d11
    global.set $__s11
    i32.const 0
    i32.const 3
    array.new_data $str $__d12
    global.set $__s12
    i32.const 0
    i32.const 1
    array.new_data $str $__d13
    global.set $__s13
    i32.const 0
    i32.const 1
    array.new_data $str $__d14
    global.set $__s14
    call $__init_globals
  )
  (@custom "botopink.needs" "gc\0a")
)
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

----- WASM TEXT -- std/failure.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $closure (sub (struct (field $idx i32) (field $mark i32))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $task (struct (field $state (mut i32)) (field $waiters (mut (ref null $waiter))) (field $value (mut anyref)) (field $frame (mut structref)) (field $kind i32) (field $next (mut (ref null $task))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $rec_Failure (struct (field $f0 (mut (ref null $str))) (field $f1 (mut (ref null $str)))))
    (type $frame0 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $closure))) (field $s1 (mut i32)) (field $s2 (mut i32)) (field $s3 (mut i32)) (field $s4 (mut (ref null $result))) (field $s5 (mut (ref null $task))) (field $s6 (mut (ref null $task))) (field $s7 (mut (ref null $str)))))
    (type $waiter (struct (field $next (mut (ref null $waiter))) (field $kind i32) (field $target (ref null $task)) (field $slot i32)))
    (type $arr_any (array (mut anyref)))
    (type $exn (struct (field $msg (ref null $str)) (field $print i32)))
  )
  (memory (export "memory") 1)
  (tag $__bp_panic (param anyref))
  (table funcref (elem))
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; std/failure — the two records a failure that is not a typed error carries
  ;; (decisions 431, 492).
  ;; 
  ;; `HostError` is what a host binding that writes `result: true` answers on
  ;; the `Error` side: the host's message and `kind`, always `"host"`.
  ;; `Failure` is what `attempt` answers on the `Error` side: `kind` is `panic`
  ;; (`panic`, `@todo`, `x!`, an overflow, a division by zero), `host` (a raise
  ;; from a binding without `result: true`) or `crash` (a VM or emitted-code
  ;; fault, a wasm trap).
  ;; 
  ;; `attempt(f)` runs `f` and answers `Ok` of its value, or `Error(Failure)`
  ;; for a raise it caught — the one way to contain a crash (decision 431 (3)).
  ;; `attemptTask(f)` is its `Async` form (decision 494): the task `f` answers,
  ;; awaited, or the `Failure` it crashed with — a `Async<Result<…>>` read
  ;; back by `await` like any failing task (decision 432). The kinds
  ;; (decision 492): a `panic` / `@todo` (and so `x!`), a failed `assert`
  ;; and an integer overflow or division by zero are `panic`, their message
  ;; the text the program wrote. A raise of a binding declared outside std without
  ;; `result: true` is `host` (decision 546), its message the host's text — on
  ;; commonJS an `Error`'s `message`, else `String(e)`, the call run through
  ;; `__bp_host_mark`, which marks it `__bp_host`; any raise nothing marked is
  ;; `crash`, its message the same text. On erlang and beam a
  ;; host raise is the raise of a binding declared outside std without `result:
  ;; true` — a library's or the program's, whose calls are wrapped to mark it
  ;; (decision 546) — its message the reason by `~tp` (decision 489's reading);
  ;; a raise nothing marked, a failing match or a std binding's, is `crash`,
  ;; its message the reason by `~tp` too.
  ;; 
  ;; Both are bodyless: each backend wraps the call (a JavaScript `try` /
  ;; rejection handler, an erlang `try … catch`; beam compiles the erlang
  ;; form). On wasm (decision 518) each is a private body over `caught`, the
  ;; `wasi: .Attempt` adapter: the thunk runs inside a `try_table` that
  ;; catches the program's aborts (wasm exception handling), so the binding
  ;; declares `needs: [.Exceptions]` and a program reaching it runs with the
  ;; host's exceptions on (`-W exceptions=y` on wasmtime). On wasm an abort
  ;; is `panic`; a trap (an overflow or a division by zero there, a host
  ;; fault) is no exception and is not caught. `attemptTask` contains what
  ;; the thunk raises before the task's first `await`.
  ;; Decision 606 (2) — the abort `attempt` catches as a `panic` `Failure`: the program stops
  ;; with `panic: <message>` (decision 535) unless an `attempt` above it answers the `Failure`.
  ;; Imported where it is used, `import {failure.panic} from "std";` (`import {failure.panic};`
  ;; inside std); `panic("not implemented")` is what `todo` was.
  ;; declare fn panic — no wasm implementation (host-backed)
  ;; The Node forms read an abort by the `__bp_panic` mark the backend puts on
  ;; every one it raises — `panic`, `@todo`, an integer overflow or division
  ;; by zero, a failed `assert` (whose mark carries its message) — or a test
  ;; body's `assert` (`__bp_assert_loc`); the Erlang forms by the reasons the
  ;; backends raise for them (`{panic, M}`, `{todo, M}`, `{integer_overflow,
  ;; M}`, `{bp_assert, M, Where}`). `attemptTask` answers a failing task
  ;; (decision 432): marked `__bp_fails`, resolved with the value, rejected with
  ;; the `Failure` (`__bp_failure`); a failing task `f` answers is read as
  ;; `await` reads it.
  ;; attempt — .Wasm(body: attemptOnWasm)
  (func $attempt (export "attempt") (param $f (ref null $closure)) (result (ref null $result))
    local.get $f
    call $attemptOnWasm
  )
  ;; attemptTask — .Wasm(body: attemptTaskOnWasm)
  (func $attemptTask (export "attemptTask") (param $f (ref null $closure)) (result (ref null $task))
    local.get $f
    call $attemptTaskOnWasm
  )
  ;; wasm's form (decision 518): the thunk's value, or the message of the abort
  ;; it raised — `Error` of the abort's text, which `attempt` makes a `panic`.
  ;; The bodies over it are compiled on every target, so it has a form on each;
  ;; only wasm calls it (`attempt`'s own forms answer elsewhere).
  ;; caught — .Wasm(wasi: .Attempt)
  (func $caught (param $f (ref null $closure)) (result (ref null $result))
    local.get $f
    call $__wasi_attempt
  )
  (func $attemptOnWasm (param $f (ref null $closure)) (result (ref null $result))
    (local $__mem0 i32)
    (local $v i32)
    (local $m i32)
    (local $__case_0 (ref null $result))
    (local $v__0 anyref)
    (local $m__1 (ref null $str))
    local.get $f
    call $caught
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    local.set $v__0
    i32.const 0
    local.get $v__0
    struct.new $result
    return
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $m__1
    i32.const 1
    local.get $m__1
    global.get $__s0
    struct.new $rec_Failure
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  ;; The task the thunk started — or the `Failure` it raised before its first
  ;; `await` — and then its value.
  ;; @Async — a state machine (decision 392)
  (func $attemptTaskOnWasm (param $f (ref null $closure)) (result (ref null $task))
    (local $__fr (ref null $frame0))
    struct.new_default $frame0 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $f
    struct.set $frame0 $s0
    i32.const 0 ;; attemptTaskOnWasm__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $attemptTaskOnWasm__body (param $__task (ref null $task)) (result (ref null $result))
    (local $f (ref null $closure))
    (local $__mem0 i32)
    (local $t i32)
    (local $m i32)
    (local $__frame (ref null $frame0))
    (local $__seek i32)
    (local $__state i32)
    (local $__case_0_0 (ref null $result))
    (local $t__2 (ref null $task))
    (local $__aw1 (ref null $task))
    (local $m__3 (ref null $str))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame0)
    local.set $__frame
    local.get $__frame
    struct.get $frame0 $s0
    local.set $f
    local.get $__frame
    struct.get $frame0 $s1
    local.set $__mem0
    local.get $__frame
    struct.get $frame0 $s2
    local.set $t
    local.get $__frame
    struct.get $frame0 $s3
    local.set $m
    local.get $__frame
    struct.get $frame0 $s4
    local.set $__case_0_0
    local.get $__frame
    struct.get $frame0 $s5
    local.set $t__2
    local.get $__frame
    struct.get $frame0 $s6
    local.set $__aw1
    local.get $__frame
    struct.get $frame0 $s7
    local.set $m__3
    local.get $__frame
    struct.get $frame0 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $f
    call $caught
    local.set $__case_0_0
      )
    )
    local.get $__case_0_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0_0
    struct.get $result $payload
    ref.cast (ref null $task)
    local.set $t__2
    i32.const 0
    (block $__aw1
    local.get $__seek
    (if
      (then
    local.get $__state
    i32.const 1
    i32.eq
    (if
      (then
    i32.const 0
    local.set $__seek
    br $__aw1 ;; resumed here
      )
    )
    br $__aw1 ;; resuming past this await
      )
    )
    local.get $t__2
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $f
    struct.set $frame0 $s0
    local.get $__frame
    local.get $__mem0
    struct.set $frame0 $s1
    local.get $__frame
    local.get $t
    struct.set $frame0 $s2
    local.get $__frame
    local.get $m
    struct.set $frame0 $s3
    local.get $__frame
    local.get $__case_0_0
    struct.set $frame0 $s4
    local.get $__frame
    local.get $t__2
    struct.set $frame0 $s5
    local.get $__frame
    local.get $__aw1
    struct.set $frame0 $s6
    local.get $__frame
    local.get $m__3
    struct.set $frame0 $s7
    local.get $__frame
    i32.const 1
    struct.set $frame0 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $result
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    struct.new $result
    return
      )
      (else
    local.get $__case_0_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0_0
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $m__3
    i32.const 1
    local.get $m__3
    global.get $__s0
    struct.new $rec_Failure
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  (func $attemptTaskOnWasm__step (param $__task (ref null $task))
    (local $__v (ref null $result))
    local.get $__task
    call $attemptTaskOnWasm__body
    local.set $__v
    global.get $__task_suspended
    (if
      (then
    i32.const 0
    global.set $__task_suspended
    return
      )
    )
    local.get $__task
    local.get $__v
    call $__task_settle
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
  (global $__task_head (mut (ref null $task)) (ref.null $task))
  (global $__task_tail (mut (ref null $task)) (ref.null $task))
  (global $__task_suspended (mut i32) (i32.const 0))
  (func $__task_new (param $kind i32) (param $frame structref) (result (ref null $task))
    i32.const 0
    ref.null $waiter
    ref.null any
    local.get $frame
    local.get $kind
    ref.null $task
    ref.null any
    i32.const 0
    struct.new $task
  )
  (func $__task_start (param $kind i32) (param $frame structref) (result (ref null $task))
    (local $t (ref null $task))
    local.get $kind
    local.get $frame
    call $__task_new
    local.tee $t
    call $__task_resume
    local.get $t
  )
  (func $__task_pending (param $t (ref null $task)) (result i32)
    local.get $t
    struct.get $task $state
    i32.eqz
  )
  (func $__task_listen (param $t (ref null $task)) (param $kind i32) (param $target (ref null $task)) (param $index i32)
    (local $n (ref null $waiter))
    local.get $t
    struct.get $task $waiters
    local.get $kind
    local.get $target
    local.get $index
    struct.new $waiter
    local.set $n
    local.get $t
    local.get $n
    struct.set $task $waiters
  )
  (func $__task_wait (param $t (ref null $task)) (param $w (ref null $task))
    local.get $t
    i32.const 0
    local.get $w
    i32.const 0
    call $__task_listen
  )
  (func $__task_settle (param $t (ref null $task)) (param $v anyref)
    local.get $t
    local.get $v
    struct.set $task $value
    local.get $t
    call $__task_wake
  )
  (func $__task_wake (param $t (ref null $task))
    (local $n (ref null $waiter)) (local $m (ref null $waiter)) (local $r (ref null $waiter)) (local $k i32) (local $w (ref null $task))
    local.get $t
    struct.get $task $state
    (if
      (then
        return
      )
    )
    local.get $t
    i32.const 1
    struct.set $task $state
    local.get $t
    struct.get $task $waiters
    local.set $n
    local.get $t
    ref.null $waiter
    struct.set $task $waiters
    local.get $t
    ref.null struct
    struct.set $task $frame
    (block $brk
      (loop $cont
        local.get $n
        ref.is_null
        br_if $brk
        local.get $n
        struct.get $waiter $next
        local.set $m
        local.get $n
        local.get $r
        struct.set $waiter $next
        local.get $n
        local.set $r
        local.get $m
        local.set $n
        br $cont
      )
    )
    (block $brk
      (loop $cont
        local.get $r
        ref.is_null
        br_if $brk
        local.get $r
        struct.get $waiter $kind
        local.set $k
        local.get $r
        struct.get $waiter $target
        local.set $w
        local.get $k
        i32.eqz
        (if
          (then
            local.get $w
            call $__task_enqueue
          )
        )
        local.get $k
        i32.const 1
        i32.eq
        (if
          (then
            local.get $w
            struct.get $task $state
            i32.eqz
            (if
              (then
                local.get $w
                local.get $t
                struct.get $task $value
                struct.set $task $value
                local.get $w
                call $__task_wake
              )
            )
          )
        )
        local.get $k
        i32.const 2
        i32.eq
        (if
          (then
            local.get $w
            struct.get $task $aux
            ref.cast (ref null $arr_any)
            local.get $r
            struct.get $waiter $slot
            local.get $t
            struct.get $task $value
            array.set $arr_any
            local.get $w
            local.get $w
            struct.get $task $left
            i32.const 1
            i32.sub
            struct.set $task $left
            local.get $w
            struct.get $task $left
            i32.eqz
            (if
              (then
                local.get $w
                local.get $w
                struct.get $task $aux
                struct.set $task $value
                local.get $w
                ref.null any
                struct.set $task $aux
                local.get $w
                call $__task_wake
              )
            )
          )
        )
        local.get $r
        struct.get $waiter $next
        local.set $r
        br $cont
      )
    )
  )
  (func $__task_enqueue (param $t (ref null $task))
    local.get $t
    ref.null $task
    struct.set $task $next
    global.get $__task_tail
    ref.is_null
    (if
      (then
        local.get $t
        global.set $__task_head
      )
      (else
        global.get $__task_tail
        local.get $t
        struct.set $task $next
      )
    )
    local.get $t
    global.set $__task_tail
  )
  (func $__task_drain
    (local $t (ref null $task))
    (block $brk
      (loop $cont
        global.get $__task_head
        local.tee $t
        ref.is_null
        br_if $brk
        local.get $t
        struct.get $task $next
        global.set $__task_head
        global.get $__task_head
        ref.is_null
        (if
          (then
            ref.null $task
            global.set $__task_tail
          )
        )
        local.get $t
        call $__task_resume
        br $cont
      )
    )
  )
  (func $__task_block_on (param $t (ref null $task)) (result (ref null $task))
    (local $r (ref null $task))
    (block $brk
      (loop $cont
        local.get $t
        struct.get $task $state
        br_if $brk
        global.get $__task_head
        local.tee $r
        ref.is_null
        (if
          (then
            unreachable
          )
        )
        local.get $r
        struct.get $task $next
        global.set $__task_head
        global.get $__task_head
        ref.is_null
        (if
          (then
            ref.null $task
            global.set $__task_tail
          )
        )
        local.get $r
        call $__task_resume
        br $cont
      )
    )
    local.get $t
  )
  (func $__task_finish
    (block $brk
      (loop $cont
        call $__task_drain
        call $__task_host_poll
        i32.eqz
        br_if $brk
        br $cont
      )
    )
  )
  (func $__task_resume (param $t (ref null $task))
    (local $k i32)
    local.get $t
    struct.get $task $kind ;; kind
    local.set $k
    local.get $k
    i32.const 0
    i32.eq
    (if
      (then
    local.get $t
    call $attemptTaskOnWasm__step
    return
      )
    )
    unreachable
  )
  (func $__task_host_poll (result i32)
    i32.const 0
  )
  (func $__wasi_attempt (param $f (ref null $closure)) (result (ref null $result))
    (local $v anyref) (local $m (ref null $str))
    (block $caught (result anyref)
      (try_table (result anyref) (catch $__bp_panic $caught)
        local.get $f
        local.get $f
        struct.get $closure $idx
        call_indirect (param (ref null $closure)) (result anyref)
      )
      local.set $v
      i32.const 0
      local.get $v
      struct.new $result
      return
    )
    ref.cast (ref null $exn)
    struct.get $exn $msg
    local.set $m
    i32.const 1
    local.get $m
    struct.new $result
  )
  (data $__d0 "panic")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 5
    array.new_data $str $__d0
    global.set $__s0
  )
  (@custom "botopink.needs" "exceptions\0agc\0a")
)
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- std/io/random.bp
```botopink
//// std/io/random — pseudo-random number primitives (cross-backend).
////
//// Reference:
////   Node.js  — https://nodejs.org/api/  (the `Math.random` global)
////   Erlang   — https://www.erlang.org/doc/apps/stdlib/rand.html
////
//// `float()` returns a uniform `[0.0, 1.0)` sample on every backend.
//// Higher-level helpers (`coin`/`pick`) compose `float()` — portable +
//// no host call beyond the uniform sample. Seedable RNGs are deferred:
//// Node has no built-in seedable PRNG behind `Math.random`, so any
//// seed/state surface needs a userland PRNG; ship that in a follow-up
//// once the test infra is ready for reproducible draws.
////
//// NOT A CSPRNG: everything above `secureToken` is `Math.random` /
//// `rand:uniform`, predictable to anyone who sees enough draws. A token, a
//// session id, a nonce or a UUID comes from `secureToken` / `uuidV4`, which
//// read the host's cryptographic source (`crypto.randomBytes`,
//// `crypto:strong_rand_bytes/1`) — or `crypto.randomBytes` for hex.

import {compiler};

#[compiler.external(.JavaScript("Math.random()"), .Erlang("rand:uniform()"), .Wasm(std: "random.float"))]
pub declare fn float() -> f64;

// Seed the Node-side userland PRNG (Mulberry32) shipped via the sidecar
// at `libs/std/src/sidecars/random.mjs`. After seeding, `seededFloat()`
// draws from the reproducible stream. `float()` itself stays on
// `Math.random`; explicit-stream callers opt into determinism by using
// `seededFloat` after `seed`.
// Node: `require('./sidecars/random.mjs').seed($0)` — the CLI's sidecar
// shipper copies the `.mjs` next to the emitted module.
// Erlang: `rand:seed/2` with the `exsplus` algorithm + a `{S, S, S}`
// triple. `S` is folded to an integer via the i64 input.
#[compiler.external(
    .JavaScript("""require('./sidecars/random.mjs').seed($0)"""),
    .Erlang("""(fun(__S) -> rand:seed(exsplus, {__S, __S, __S}) end)($0)"""),
    .Wasm(std: "random.seed"),
)]
pub declare fn seed(s: i32) -> void;

// Draw from the seeded PRNG when a `seed` call has been made; otherwise
// falls through to the unseeded `float()` baseline. Erlang's `rand`
// module reads from the process dictionary's seed state directly, so
// the same `rand:uniform/0` call after `seed` produces the reproducible
// stream automatically.
#[compiler.external(
    .JavaScript("""require('./sidecars/random.mjs').seededFloat()"""),
    .Erlang("rand:uniform()"),
    .Wasm(std: "random.seededFloat"),
)]
pub declare fn seededFloat() -> f64;

// 50/50 boolean draw. `float() >= 0.5` picks the upper half of the
// uniform sample — identically distributed on every backend that has
// a uniform `float()`.
pub fn coin() -> bool {
    return float() >= 0.5;
}

// Random integer in the closed interval `[lo, hi]`. When `lo > hi` the
// range is empty and the result is `lo` (a defensive default — the
// alternative is to `panic`, which the @assert-style tests would
// rather catch at the call site).
pub fn intInRange(lo: i32, hi: i32) -> i32 {
    if (lo >= hi) return lo;
    val span = (hi - lo) + 1;
    val product = float() * span;
    val offset = floorWalk(0, 1.0, product, span);
    return lo + offset;
}

// Pick a random element from a non-empty array. Returns `null` for the
// empty array — the call site should default with `?? …` rather
// than panic. Uses a walk-up integer floor (no `Math.floor` import) so
// the body stays self-contained.
pub fn pick<T>(xs: array<T>) -> ?T {
    val n = xs.length;
    if (n == 0) return null;
    // `float() * n` mixes f64 × i32 — inference promotes to f64.
    val product = float() * n;
    val idx = floorWalk(0, 1.0, product, n);
    return xs.at(idx);
}

// Internal: integer floor of a non-negative `product` < `upper`. Walks
// `start` up from 0 while `threshold (= start + 1)` still fits below
// `product`. O(upper) — fine for the small `array<T>` arities `pick`
// targets in tests.
fn floorWalk(start: i32, threshold: f64, product: f64, upper: i32) -> i32 {
    if (start + 1 > upper) return start;
    if (threshold > product) return start;
    return floorWalk(start + 1, threshold + 1.0, product, upper);
}

// Fisher-Yates shuffle. Returns a fresh array whose elements are a
// permutation of `xs`. The pure-bp shape was deferred (the deferral
// note used to live here) because `array<T>::at(i)` returns `?T` and
// extracting T without a sentinel value of T is circular. Solution:
// host-backed `pub declare fn shuffle<T>(xs)` — the host owns the
// in-place swap; the bp side only declares the signature and the
// per-target template.
//
// Node: classic Fisher-Yates over the input array, returning a fresh
// copy (the input is not mutated — matches the immutable-by-default
// botopink contract for return values). `random.seed` from this same
// module seeds the sidecar PRNG; subsequent `shuffle` draws are
// reproducible after `seed(s)`.
//
// Erlang: `[X || {_, X} <- lists:sort([{rand:uniform(), Y} || Y <- $0])]`
// — the Schwartzian-transform shuffle: pair each element with a
// random key, sort by key, strip the keys. Stable across `rand:seed`
// state (the same `rand` server `seed/2` controls both `uniform/0`
// here and `seededFloat()` above).
//
// Beam/wasm: out of scope at v1 (no `lists:sort` template, no
// `Math.random` equivalent in wat3); the matrix will report
// `MissingExternalTarget` on a `shuffle(...)` call from those backends
// until the corresponding shim lands.
#[compiler.external(
    .JavaScript("""(function(__A){ var __O = __A.slice(); for (var __I = __O.length - 1; __I > 0; __I--) { var __J = Math.floor(Math.random() * (__I + 1)); var __T = __O[__I]; __O[__I] = __O[__J]; __O[__J] = __T; } return __O; })($0)"""),
    .Erlang("""[__X || {_, __X} <- lists:sort([{rand:uniform(), __Y} || __Y <- $0])]"""),
    .Wasm(body: shuffleBody),
)]
pub declare fn shuffle<T>(xs: array<T>) -> array<T>;

// ── 1.0.10-beta front 01 additions ──────────────────────────────────────────
//
// The CSPRNG half. Everything ABOVE is `Math.random` / `rand:uniform` — fine
// for a shuffle, wrong for anything an attacker must not guess. A token, a
// session id, a nonce or a UUID comes from the two functions below, which
// read the host's cryptographically strong source.

// `bytes` strong random bytes as base64url without padding — URL-, cookie-
// and header-safe. 32 bytes answer 43 characters.
// Node: `crypto.randomBytes(n).toString('base64url')`.
// Erlang: `crypto:strong_rand_bytes/1` + `base64:encode/2` in `urlsafe`
// mode without padding (OTP 26+).
#[compiler.external(
    .JavaScript("""require('crypto').randomBytes($0).toString('base64url')"""),
    .Erlang("""base64:encode(crypto:strong_rand_bytes($0), #{mode => urlsafe, padding => false})"""),
    .Wasm(body: secureTokenBody),
)]
pub declare fn secureToken(bytes: i32) -> string;

// A random (version 4) UUID, lowercase: 122 strong random bits with the
// version nibble set to `4` and the variant bits to `10` (RFC 9562 §5.4).
// Node: `crypto.randomUUID()`.
// Erlang: 16 strong random bytes, the version/variant bits rewritten in the
// binary pattern — the bit work lives in the template because botopink has
// no bitwise operators (`language-gaps.md`).
#[compiler.external(
    .JavaScript("""require('crypto').randomUUID()"""),
    .Erlang("""(fun() -> <<__A:32, __B:16, _:4, __C:12, _:2, __D:14, __E:48>> = crypto:strong_rand_bytes(16), iolist_to_binary(io_lib:format("~8.16.0b-~4.16.0b-4~3.16.0b-~4.16.0b-~12.16.0b", [__A, __B, __C, __D bor 16#8000, __E])) end)()"""),
    .Wasm(body: uuidV4Body),
)]
pub declare fn uuidV4() -> string;

// ── tests ────────────────────────────────────────────────────────────────────

test "random.float lies in [0.0, 1.0)" {
    val r = float();
    assert r >= 0.0;
    assert r < 1.0;
}

test "random.coin draws either truth value" {
    val b = coin();
    assert b == true || b == false;
}

test "random.pick from non-empty array returns a member" {
    val xs = [1, 2, 3];
    val r = pick(xs) ?? 99;
    assert r >= 1;
    assert r <= 3;
}

test "random.pick from empty array returns null" {
    val empty: array<i32> = [];
    assert pick(empty) ?? 99 == 99;
}

test "random.intInRange yields a value in the closed interval" {
    val r = intInRange(1, 6);
    assert r >= 1;
    assert r <= 6;
}

test "random.intInRange on a one-element range returns that element" {
    assert intInRange(7, 7) == 7;
}

test "random.intInRange on an inverted range returns the low bound" {
    assert intInRange(10, 5) == 10;
}

test "random.seed + seededFloat draws are reproducible" {
    seed(42);
    val a = seededFloat();
    seed(42);
    val b = seededFloat();
    assert a == b;
}

test "random.seededFloat lies in [0.0, 1.0)" {
    val r = seededFloat();
    assert r >= 0.0;
    assert r < 1.0;
}

test "random.shuffle preserves length" {
    val xs = [1, 2, 3, 4, 5];
    val ys = shuffle(xs);
    assert ys.length == 5;
}

test "random.shuffle preserves the multiset (sum)" {
    val xs = [1, 2, 3, 4, 5];
    val ys = shuffle(xs);
    // Sum is permutation-invariant — every element still appears once.
    var s = 0;
    ys.forEach({ y ->
        s = s + y;
    });
    assert s == 15;
}

test "random.shuffle of an empty array is empty" {
    val empty: array<i32> = [];
    assert shuffle(empty).length == 0;
}

test "random.shuffle of a single-element array preserves it" {
    val xs = [42];
    val ys = shuffle(xs);
    assert ys.length == 1;
    assert ys.at(0) ?? 0 == 42;
}

test "random.secureToken(32) is 43 base64url characters" {
    val t = secureToken(32);
    assert t.length == 43;
    assert t.contains("+").negate();
    assert t.contains("/").negate();
    assert t.contains("=").negate();
}

test "random.secureToken draws differ" {
    assert secureToken(16) != secureToken(16);
    assert secureToken(0) == "";
}

test "random.uuidV4 has the version 4 layout" {
    val u = uuidV4();
    val groups = u.split("-");
    assert u.length == 36;
    assert groups.length == 5;
    assert (groups.at(0) ?? "").length == 8;
    assert (groups.at(1) ?? "").length == 4;
    assert (groups.at(2) ?? "").length == 4;
    assert (groups.at(3) ?? "").length == 4;
    assert (groups.at(4) ?? "").length == 12;
    assert (groups.at(2) ?? "").startsWith("4");
    val variant = (groups.at(3) ?? "").slice(0, 1);
    assert "89ab".contains(variant);
    assert u.split("").filter({ c -> "0123456789abcdef-".contains(c) }).length
        == 36;
    assert uuidV4() != u;
}

// ── randomBytes (was `crypto.randomBytes`) ───────────────────────────────────

// `n` cryptographically-secure random bytes as a hex string of length
// `2 * n` (each byte rendered as two lowercase hex chars). The hex shape
// sidesteps the `array<u8>` cross-backend representation gap — Node
// `Buffer` and Erlang `binary()` don't share a bp-side type. Callers
// that need bytes parse the hex back themselves.
// Node: `require('crypto').randomBytes(n).toString('hex')`.
// Erlang: `crypto:strong_rand_bytes/1` + the same per-byte hex format
// string used by the hashes above.
#[compiler.external(
    .JavaScript("""require('crypto').randomBytes($0).toString('hex')"""),
    .Erlang("""list_to_binary([io_lib:format("~2.16.0b", [__B]) || __B <- binary_to_list(crypto:strong_rand_bytes($0))])"""),
    .Wasm(body: randomBytesBody),
)]
pub declare fn randomBytes(n: i32) -> string;

test "random.randomBytes(16) returns 32 hex chars" {
    val h = randomBytes(16);
    assert h.length == 32;
}

test "random.randomBytes(0) is empty" {
    val h = randomBytes(0);
    assert h.length == 0;
}

// ── the wasm bodies (decision 238) ──────────────────────────────────────────
// wasm has no host for these cells, so each names one of the private bodies
// below with `#[compiler.external(.Wasm(fn: …))]`; commonJS and erlang call their
// host. On wasm `float()` is `std: "random.float"` — 53 bits of WASI's
// `random_get`, the host's cryptographic source — so the token, UUID and
// byte bodies draw from it a byte at a time (`randomByte`: ⌊u · 256⌋ of a
// 53-bit uniform `u` is exactly uniform). `seed` / `seededFloat` are
// std-wasm's seeded stream (decision 451, `std: "random.…"`), drawn as the
// commonJS sidecar does (Mulberry32): the same draws after the same `seed`; a
// draw before any seed is the host's (`float()`'s source). At comptime the
// same cells answer, and a draw before any seed is refused — a build has no
// entropy.

// Selection shuffle: each step moves a uniformly drawn element of what is
// left to the output — a uniform permutation, as the Node cell's
// Fisher-Yates; the elements are moved as one-element slices, never read.
fn shuffleBody<T>(xs: array<T>) -> array<T> {
    var rest = xs;
    var out = xs.slice(0, 0);
    while (rest.length > 0) {
        val j = wholeOf((float() * rest.length).floor());
        out = out.append(rest.slice(j, j + 1));
        rest = rest.slice(0, j).append(rest.slice(j + 1, rest.length));
    }
    return out;
}

fn secureTokenBody(bytes: i32) -> string {
    return base64UrlOf(randomBytesOf(bytes));
}

// RFC 9562 §5.4: 16 random bytes, the version nibble 4, the variant `10`.
fn uuidV4Body() -> string {
    val b = randomBytesOf(16);
    val version = 64 + b.at(6) ?? 0 % 16;
    val variant = 128 + b.at(8) ?? 0 % 64;
    return hexOf(b.slice(0, 4))
        + "-"
        + hexOf(b.slice(4, 6))
        + "-"
        + hexOf([version, b.at(7) ?? 0])
        + "-"
        + hexOf([variant, b.at(9) ?? 0])
        + "-"
        + hexOf(b.slice(10, 16));
}

fn randomBytesBody(n: i32) -> string {
    return hexOf(randomBytesOf(n));
}

fn randomByte() -> i32 {
    return wholeOf((float() * 256.0).floor());
}

fn randomBytesOf(n: i32) -> array<i32> {
    var out: array<i32> = [];
    var i = 0;
    while (i < n) {
        out = out.append([randomByte()]);
        i = i + 1;
    }
    return out;
}

fn hexDigit(n: i32) -> string {
    return "0123456789abcdef".at(n) ?? "";
}

fn hexOf(bytes: array<i32>) -> string {
    return bytes.map({ b -> hexDigit(b / 16) + hexDigit(b % 16) }).join("");
}

// RFC 4648 §5 base64url, unpadded.
fn base64UrlOf(bytes: array<i32>) -> string {
    val alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    var out = "";
    var g = 0;
    while (3 * g < bytes.length) {
        val n = bytes.length - 3 * g;
        val b0 = bytes.at(3 * g) ?? 0;
        val b1 = if (n > 1) {
            bytes.at(3 * g + 1) ?? 0;
        } else 0;
        val b2 = if (n > 2) {
            bytes.at(3 * g + 2) ?? 0;
        } else 0;
        out = out
            + alphabet.at(b0 / 4) ?? ""
            + alphabet.at((b0 % 4) * 16 + b1 / 16) ?? "";
        if (n > 1) out = out + alphabet.at((b1 % 16) * 4 + b2 / 64) ?? "";
        if (n > 2) out = out + alphabet.at(b2 % 64) ?? "";
        g = g + 1;
    }
    return out;
}

// A whole `v` in [0, 2^31) as an `i32`.
fn wholeOf(v: f64) -> i32 {
    var r = 0;
    var rest = v;
    var bit = 1073741824;
    var weight = 1073741824.0;
    while (bit > 0) {
        if (rest >= weight) {
            r = r + bit;
            rest = rest - weight;
        }
        bit = bit / 2;
        weight = weight / 2.0;
    }
    return r;
}

```

----- WASM TEXT -- std/io/random.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_any (array (mut anyref)))
    (type $arr_i32 (array (mut i32)))
    (type $box_i32 (struct (field $v i32)))
  )
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "random_get" (func $random_get (param i32 i32) (result i32)))
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 272))
  ;; std/io/random — pseudo-random number primitives (cross-backend).
  ;; 
  ;; Reference:
  ;;   Node.js  — https://nodejs.org/api/  (the `Math.random` global)
  ;;   Erlang   — https://www.erlang.org/doc/apps/stdlib/rand.html
  ;; 
  ;; `float()` returns a uniform `[0.0, 1.0)` sample on every backend.
  ;; Higher-level helpers (`coin`/`pick`) compose `float()` — portable +
  ;; no host call beyond the uniform sample. Seedable RNGs are deferred:
  ;; Node has no built-in seedable PRNG behind `Math.random`, so any
  ;; seed/state surface needs a userland PRNG; ship that in a follow-up
  ;; once the test infra is ready for reproducible draws.
  ;; 
  ;; NOT A CSPRNG: everything above `secureToken` is `Math.random` /
  ;; `rand:uniform`, predictable to anyone who sees enough draws. A token, a
  ;; session id, a nonce or a UUID comes from `secureToken` / `uuidV4`, which
  ;; read the host's cryptographic source (`crypto.randomBytes`,
  ;; `crypto:strong_rand_bytes/1`) — or `crypto.randomBytes` for hex.
  ;; float — .Wasm(std: "random.float")
  (func $float (export "float") (result f64)
    call $__std_random_float
  )
  ;; Seed the Node-side userland PRNG (Mulberry32) shipped via the sidecar
  ;; at `libs/std/src/sidecars/random.mjs`. After seeding, `seededFloat()`
  ;; draws from the reproducible stream. `float()` itself stays on
  ;; `Math.random`; explicit-stream callers opt into determinism by using
  ;; `seededFloat` after `seed`.
  ;; Node: `require('./sidecars/random.mjs').seed($0)` — the CLI's sidecar
  ;; shipper copies the `.mjs` next to the emitted module.
  ;; Erlang: `rand:seed/2` with the `exsplus` algorithm + a `{S, S, S}`
  ;; triple. `S` is folded to an integer via the i64 input.
  ;; seed — .Wasm(std: "random.seed")
  (func $seed (export "seed") (param $s i32)
    local.get $s
    call $__std_random_seed
  )
  ;; Draw from the seeded PRNG when a `seed` call has been made; otherwise
  ;; falls through to the unseeded `float()` baseline. Erlang's `rand`
  ;; module reads from the process dictionary's seed state directly, so
  ;; the same `rand:uniform/0` call after `seed` produces the reproducible
  ;; stream automatically.
  ;; seededFloat — .Wasm(std: "random.seededFloat")
  (func $seededFloat (export "seededFloat") (result f64)
    call $__std_random_seededFloat
  )
  ;; 50/50 boolean draw. `float() >= 0.5` picks the upper half of the
  ;; uniform sample — identically distributed on every backend that has
  ;; a uniform `float()`.
  (func $coin (export "coin") (result i32)
    call $float
    f64.const 0.5
    f64.ge
    return
  )
  ;; Random integer in the closed interval `[lo, hi]`. When `lo > hi` the
  ;; range is empty and the result is `lo` (a defensive default — the
  ;; alternative is to `panic`, which the @assert-style tests would
  ;; rather catch at the call site).
  (func $intInRange (export "intInRange") (param $lo i32) (param $hi i32) (result i32)
    (local $span i32)
    (local $product f64)
    (local $offset i32)
    local.get $lo
    local.get $hi
    i32.ge_s
    (if (result i32)
      (then
    local.get $lo
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $hi
    local.get $lo
    global.get $__s0
    call $__i32_sub_chk
    i32.const 1
    global.get $__s1
    call $__i32_add_chk
    local.set $span
    call $float
    local.get $span
    f64.convert_i32_s
    f64.mul
    local.set $product
    i32.const 0
    f64.const 1.0
    local.get $product
    local.get $span
    call $floorWalk
    local.set $offset
    local.get $lo
    local.get $offset
    global.get $__s2
    call $__i32_add_chk
    return
  )
  ;; Pick a random element from a non-empty array. Returns `null` for the
  ;; empty array — the call site should default with `?? …` rather
  ;; than panic. Uses a walk-up integer floor (no `Math.floor` import) so
  ;; the body stays self-contained.
  (func $pick (export "pick") (param $xs (ref null $arr_any)) (result anyref)
    (local $n i32)
    (local $product f64)
    (local $idx i32)
    local.get $xs
    array.len
    local.set $n
    local.get $n
    i32.const 0
    i32.eq
    (if (result anyref)
      (then
    ref.null any
    return
      )
      (else
        ref.null any
      )
    )
    drop
    call $float
    local.get $n
    f64.convert_i32_s
    f64.mul
    local.set $product
    i32.const 0
    f64.const 1.0
    local.get $product
    local.get $n
    call $floorWalk
    local.set $idx
    local.get $xs
    local.get $idx
    call $__arr_at_opt_any
    return
  )
  ;; Internal: integer floor of a non-negative `product` < `upper`. Walks
  ;; `start` up from 0 while `threshold (= start + 1)` still fits below
  ;; `product`. O(upper) — fine for the small `array<T>` arities `pick`
  ;; targets in tests.
  (func $floorWalk (param $start i32) (param $threshold f64) (param $product f64) (param $upper i32) (result i32)
    (loop $__tail (result i32)
    local.get $start
    i32.const 1
    global.get $__s3
    call $__i32_add_chk
    local.get $upper
    i32.gt_s
    (if (result i32)
      (then
    local.get $start
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $threshold
    local.get $product
    f64.gt
    (if (result i32)
      (then
    local.get $start
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $start
    i32.const 1
    global.get $__s4
    call $__i32_add_chk
    local.get $threshold
    f64.const 1.0
    f64.add
    local.get $product
    local.get $upper
    local.set $upper
    local.set $product
    local.set $threshold
    local.set $start
    br $__tail ;; tail call
    )
  )
  ;; Fisher-Yates shuffle. Returns a fresh array whose elements are a
  ;; permutation of `xs`. The pure-bp shape was deferred (the deferral
  ;; note used to live here) because `array<T>::at(i)` returns `?T` and
  ;; extracting T without a sentinel value of T is circular. Solution:
  ;; host-backed `pub declare fn shuffle<T>(xs)` — the host owns the
  ;; in-place swap; the bp side only declares the signature and the
  ;; per-target template.
  ;; 
  ;; Node: classic Fisher-Yates over the input array, returning a fresh
  ;; copy (the input is not mutated — matches the immutable-by-default
  ;; botopink contract for return values). `random.seed` from this same
  ;; module seeds the sidecar PRNG; subsequent `shuffle` draws are
  ;; reproducible after `seed(s)`.
  ;; 
  ;; Erlang: `[X || {_, X} <- lists:sort([{rand:uniform(), Y} || Y <- $0])]`
  ;; — the Schwartzian-transform shuffle: pair each element with a
  ;; random key, sort by key, strip the keys. Stable across `rand:seed`
  ;; state (the same `rand` server `seed/2` controls both `uniform/0`
  ;; here and `seededFloat()` above).
  ;; 
  ;; Beam/wasm: out of scope at v1 (no `lists:sort` template, no
  ;; `Math.random` equivalent in wat3); the matrix will report
  ;; `MissingExternalTarget` on a `shuffle(...)` call from those backends
  ;; until the corresponding shim lands.
  ;; shuffle — .Wasm(body: shuffleBody)
  (func $shuffle (export "shuffle") (param $xs (ref null $arr_any)) (result (ref null $arr_any))
    local.get $xs
    call $shuffleBody
  )
  ;; ── 1.0.10-beta front 01 additions ──────────────────────────────────────────
  ;; 
  ;; The CSPRNG half. Everything ABOVE is `Math.random` / `rand:uniform` — fine
  ;; for a shuffle, wrong for anything an attacker must not guess. A token, a
  ;; session id, a nonce or a UUID comes from the two functions below, which
  ;; read the host's cryptographically strong source.
  ;; `bytes` strong random bytes as base64url without padding — URL-, cookie-
  ;; and header-safe. 32 bytes answer 43 characters.
  ;; Node: `crypto.randomBytes(n).toString('base64url')`.
  ;; Erlang: `crypto:strong_rand_bytes/1` + `base64:encode/2` in `urlsafe`
  ;; mode without padding (OTP 26+).
  ;; secureToken — .Wasm(body: secureTokenBody)
  (func $secureToken (export "secureToken") (param $bytes i32) (result (ref null $str))
    local.get $bytes
    call $secureTokenBody
  )
  ;; A random (version 4) UUID, lowercase: 122 strong random bits with the
  ;; version nibble set to `4` and the variant bits to `10` (RFC 9562 §5.4).
  ;; Node: `crypto.randomUUID()`.
  ;; Erlang: 16 strong random bytes, the version/variant bits rewritten in the
  ;; binary pattern — the bit work lives in the template because botopink has
  ;; no bitwise operators (`language-gaps.md`).
  ;; uuidV4 — .Wasm(body: uuidV4Body)
  (func $uuidV4 (export "uuidV4") (result (ref null $str))
    call $uuidV4Body
  )
  ;; ── tests ────────────────────────────────────────────────────────────────────
  ;; ── randomBytes (was `crypto.randomBytes`) ───────────────────────────────────
  ;; `n` cryptographically-secure random bytes as a hex string of length
  ;; `2 * n` (each byte rendered as two lowercase hex chars). The hex shape
  ;; sidesteps the `array<u8>` cross-backend representation gap — Node
  ;; `Buffer` and Erlang `binary()` don't share a bp-side type. Callers
  ;; that need bytes parse the hex back themselves.
  ;; Node: `require('crypto').randomBytes(n).toString('hex')`.
  ;; Erlang: `crypto:strong_rand_bytes/1` + the same per-byte hex format
  ;; string used by the hashes above.
  ;; randomBytes — .Wasm(body: randomBytesBody)
  (func $randomBytes (export "randomBytes") (param $n i32) (result (ref null $str))
    local.get $n
    call $randomBytesBody
  )
  ;; ── the wasm bodies (decision 238) ──────────────────────────────────────────
  ;; wasm has no host for these cells, so each names one of the private bodies
  ;; below with `#[compiler.external(.Wasm(fn: …))]`; commonJS and erlang call their
  ;; host. On wasm `float()` is `std: "random.float"` — 53 bits of WASI's
  ;; `random_get`, the host's cryptographic source — so the token, UUID and
  ;; byte bodies draw from it a byte at a time (`randomByte`: ⌊u · 256⌋ of a
  ;; 53-bit uniform `u` is exactly uniform). `seed` / `seededFloat` are
  ;; std-wasm's seeded stream (decision 451, `std: "random.…"`), drawn as the
  ;; commonJS sidecar does (Mulberry32): the same draws after the same `seed`; a
  ;; draw before any seed is the host's (`float()`'s source). At comptime the
  ;; same cells answer, and a draw before any seed is refused — a build has no
  ;; entropy.
  ;; Selection shuffle: each step moves a uniformly drawn element of what is
  ;; left to the output — a uniform permutation, as the Node cell's
  ;; Fisher-Yates; the elements are moved as one-element slices, never read.
  (func $shuffleBody (param $xs (ref null $arr_any)) (result (ref null $arr_any))
    (local $rest (ref null $arr_any))
    (local $out (ref null $arr_any))
    (local $j i32)
    local.get $xs
    local.set $rest
    local.get $xs
    i32.const 0
    i32.const 0
    call $__arr_slice_any
    local.set $out
    (block $__break
      (loop $__continue
    local.get $rest
    array.len
    i32.const 0
    i32.gt_s
        i32.eqz
        br_if $__break
    call $float
    local.get $rest
    array.len
    f64.convert_i32_s
    f64.mul
    f64.floor
    call $wholeOf
    local.set $j
    local.get $out
    local.get $rest
    local.get $j
    local.get $j
    i32.const 1
    global.get $__s5
    call $__i32_add_chk
    call $__arr_slice_any
    call $__arr_concat_any
    local.set $out
    local.get $rest
    i32.const 0
    local.get $j
    call $__arr_slice_any
    local.get $rest
    local.get $j
    i32.const 1
    global.get $__s6
    call $__i32_add_chk
    local.get $rest
    array.len
    call $__arr_slice_any
    call $__arr_concat_any
    local.set $rest
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $out
    return
  )
  (func $secureTokenBody (param $bytes i32) (result (ref null $str))
    local.get $bytes
    call $randomBytesOf
    call $base64UrlOf
    return
  )
  ;; RFC 9562 §5.4: 16 random bytes, the version nibble 4, the variant `10`.
  (func $uuidV4Body (result (ref null $str))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $b (ref null $arr_i32))
    (local $version i32)
    (local $__bp_nullish i32)
    (local $variant i32)
    (local $__opt0 anyref)
    (local $__opt1 anyref)
    (local $__opt2 anyref)
    (local $__opt3 anyref)
    i32.const 16
    call $randomBytesOf
    local.set $b
    i32.const 64
    local.get $b
    i32.const 6
    call $__arr_at_opt_i32
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result i32)
      (then
    local.get $__opt0
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 0
      )
    )
    i32.const 16
    global.get $__s7
    call $__i32_nz
    i32.rem_s
    global.get $__s8
    call $__i32_add_chk
    local.set $version
    i32.const 128
    local.get $b
    i32.const 8
    call $__arr_at_opt_i32
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result i32)
      (then
    local.get $__opt1
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 0
      )
    )
    i32.const 64
    global.get $__s9
    call $__i32_nz
    i32.rem_s
    global.get $__s10
    call $__i32_add_chk
    local.set $variant
    local.get $b
    i32.const 0
    i32.const 4
    call $__arr_slice_i32
    call $hexOf
    global.get $__s11
    call $__str_concat
    local.get $b
    i32.const 4
    i32.const 6
    call $__arr_slice_i32
    call $hexOf
    call $__str_concat
    global.get $__s11
    call $__str_concat
    local.get $version
    local.get $b
    i32.const 7
    call $__arr_at_opt_i32
    local.tee $__opt2
    ref.is_null
    i32.eqz
    (if (result i32)
      (then
    local.get $__opt2
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 0
      )
    )
    array.new_fixed $arr_i32 2
    call $hexOf
    call $__str_concat
    global.get $__s11
    call $__str_concat
    local.get $variant
    local.get $b
    i32.const 9
    call $__arr_at_opt_i32
    local.tee $__opt3
    ref.is_null
    i32.eqz
    (if (result i32)
      (then
    local.get $__opt3
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 0
      )
    )
    array.new_fixed $arr_i32 2
    call $hexOf
    call $__str_concat
    global.get $__s11
    call $__str_concat
    local.get $b
    i32.const 10
    i32.const 16
    call $__arr_slice_i32
    call $hexOf
    call $__str_concat
    return
  )
  (func $randomBytesBody (param $n i32) (result (ref null $str))
    local.get $n
    call $randomBytesOf
    call $hexOf
    return
  )
  (func $randomByte (result i32)
    call $float
    f64.const 256.0
    f64.mul
    f64.floor
    call $wholeOf
    return
  )
  (func $randomBytesOf (param $n i32) (result (ref null $arr_i32))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $out (ref null $arr_i32))
    (local $i i32)
    array.new_fixed $arr_i32 0
    local.set $out
    i32.const 0
    local.set $i
    (block $__break
      (loop $__continue
    local.get $i
    local.get $n
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $out
    call $randomByte
    array.new_fixed $arr_i32 1
    call $__arr_concat_i32
    local.set $out
    local.get $i
    i32.const 1
    global.get $__s12
    call $__i32_add_chk
    local.set $i
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $out
    return
  )
  (func $hexDigit (param $n i32) (result (ref null $str))
    (local $__bp_nullish i32)
    (local $__opt0 (ref null $str))
    (local $__gc0 i32)
    (local $__gc1 (ref null $str))
    (local $__gc2 i32)
    (local $__gc3 i32)
    (local $__bp_nullish__0 (ref null $str))
    global.get $__s13
    local.get $n
    local.set $__gc0
    local.set $__gc1
    global.get $__heap_ptr
    local.set $__gc2
    local.get $__gc1
    call $__gc_to_lin_str
    local.get $__gc0
    call $__std_text_at
    local.tee $__gc3
    i32.eqz
    (if (result (ref null $str))
      (then
    ref.null $str
      )
      (else
    local.get $__gc3
    call $__lin_to_gc_str
      )
    )
    local.get $__gc2
    global.set $__heap_ptr
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__0
    local.get $__bp_nullish__0
      )
      (else
    global.get $__s14
      )
    )
    return
  )
  (func $hexOf (param $bytes (ref null $arr_i32)) (result (ref null $str))
    (local $__iter0 (ref null $arr_i32))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $b i32)
    (local $__out0 (ref null $arr_any))
    local.get $bytes
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
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
        array.get $arr_i32
        local.set $b
    local.get $__out0
    local.get $__idx0
    local.get $b
    i32.const 16
    global.get $__s15
    global.get $__s16
    call $__i32_divs
    call $hexDigit
    local.get $b
    i32.const 16
    global.get $__s17
    call $__i32_nz
    i32.rem_s
    call $hexDigit
    call $__str_concat
    array.set $arr_any
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    global.get $__s14
    call $__arr_join_any
    return
  )
  ;; RFC 4648 §5 base64url, unpadded.
  (func $base64UrlOf (param $bytes (ref null $arr_i32)) (result (ref null $str))
    (local $alphabet (ref null $str))
    (local $out (ref null $str))
    (local $g i32)
    (local $n i32)
    (local $b0 i32)
    (local $__bp_nullish i32)
    (local $b1 i32)
    (local $b2 i32)
    (local $__opt0 anyref)
    (local $__opt1 anyref)
    (local $__opt2 anyref)
    (local $__opt3 (ref null $str))
    (local $__gc4 i32)
    (local $__gc5 (ref null $str))
    (local $__gc6 i32)
    (local $__gc7 i32)
    (local $__bp_nullish__1 (ref null $str))
    (local $__opt4 (ref null $str))
    (local $__gc8 i32)
    (local $__gc9 (ref null $str))
    (local $__gc10 i32)
    (local $__gc11 i32)
    (local $__bp_nullish__2 (ref null $str))
    (local $__opt5 (ref null $str))
    (local $__gc12 i32)
    (local $__gc13 (ref null $str))
    (local $__gc14 i32)
    (local $__gc15 i32)
    (local $__bp_nullish__3 (ref null $str))
    (local $__opt6 (ref null $str))
    (local $__gc16 i32)
    (local $__gc17 (ref null $str))
    (local $__gc18 i32)
    (local $__gc19 i32)
    (local $__bp_nullish__4 (ref null $str))
    global.get $__s18
    local.set $alphabet
    global.get $__s14
    local.set $out
    i32.const 0
    local.set $g
    (block $__break
      (loop $__continue
    i32.const 3
    local.get $g
    global.get $__s19
    call $__i32_mul_chk
    local.get $bytes
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $bytes
    array.len
    i32.const 3
    local.get $g
    global.get $__s20
    call $__i32_mul_chk
    global.get $__s21
    call $__i32_sub_chk
    local.set $n
    local.get $bytes
    i32.const 3
    local.get $g
    global.get $__s22
    call $__i32_mul_chk
    call $__arr_at_opt_i32
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result i32)
      (then
    local.get $__opt0
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 0
      )
    )
    local.set $b0
    local.get $n
    i32.const 1
    i32.gt_s
    (if (result i32)
      (then
    local.get $bytes
    i32.const 3
    local.get $g
    global.get $__s23
    call $__i32_mul_chk
    i32.const 1
    global.get $__s24
    call $__i32_add_chk
    call $__arr_at_opt_i32
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result i32)
      (then
    local.get $__opt1
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 0
      )
    )
      )
      (else
    i32.const 0
      )
    )
    local.set $b1
    local.get $n
    i32.const 2
    i32.gt_s
    (if (result i32)
      (then
    local.get $bytes
    i32.const 3
    local.get $g
    global.get $__s25
    call $__i32_mul_chk
    i32.const 2
    global.get $__s26
    call $__i32_add_chk
    call $__arr_at_opt_i32
    local.tee $__opt2
    ref.is_null
    i32.eqz
    (if (result i32)
      (then
    local.get $__opt2
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    i32.const 0
      )
    )
      )
      (else
    i32.const 0
      )
    )
    local.set $b2
    local.get $out
    local.get $alphabet
    local.get $b0
    i32.const 4
    global.get $__s27
    global.get $__s28
    call $__i32_divs
    local.set $__gc4
    local.set $__gc5
    global.get $__heap_ptr
    local.set $__gc6
    local.get $__gc5
    call $__gc_to_lin_str
    local.get $__gc4
    call $__std_text_at
    local.tee $__gc7
    i32.eqz
    (if (result (ref null $str))
      (then
    ref.null $str
      )
      (else
    local.get $__gc7
    call $__lin_to_gc_str
      )
    )
    local.get $__gc6
    global.set $__heap_ptr
    local.tee $__opt3
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt3
    local.set $__bp_nullish__1
    local.get $__bp_nullish__1
      )
      (else
    global.get $__s14
      )
    )
    call $__str_concat
    local.get $alphabet
    local.get $b0
    i32.const 4
    global.get $__s29
    call $__i32_nz
    i32.rem_s
    i32.const 16
    global.get $__s30
    call $__i32_mul_chk
    local.get $b1
    i32.const 16
    global.get $__s31
    global.get $__s32
    call $__i32_divs
    global.get $__s33
    call $__i32_add_chk
    local.set $__gc8
    local.set $__gc9
    global.get $__heap_ptr
    local.set $__gc10
    local.get $__gc9
    call $__gc_to_lin_str
    local.get $__gc8
    call $__std_text_at
    local.tee $__gc11
    i32.eqz
    (if (result (ref null $str))
      (then
    ref.null $str
      )
      (else
    local.get $__gc11
    call $__lin_to_gc_str
      )
    )
    local.get $__gc10
    global.set $__heap_ptr
    local.tee $__opt4
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt4
    local.set $__bp_nullish__2
    local.get $__bp_nullish__2
      )
      (else
    global.get $__s14
      )
    )
    call $__str_concat
    local.set $out
    local.get $n
    i32.const 1
    i32.gt_s
    (if (result i32)
      (then
    local.get $out
    local.get $alphabet
    local.get $b1
    i32.const 16
    global.get $__s34
    call $__i32_nz
    i32.rem_s
    i32.const 4
    global.get $__s35
    call $__i32_mul_chk
    local.get $b2
    i32.const 64
    global.get $__s36
    global.get $__s37
    call $__i32_divs
    global.get $__s38
    call $__i32_add_chk
    local.set $__gc12
    local.set $__gc13
    global.get $__heap_ptr
    local.set $__gc14
    local.get $__gc13
    call $__gc_to_lin_str
    local.get $__gc12
    call $__std_text_at
    local.tee $__gc15
    i32.eqz
    (if (result (ref null $str))
      (then
    ref.null $str
      )
      (else
    local.get $__gc15
    call $__lin_to_gc_str
      )
    )
    local.get $__gc14
    global.set $__heap_ptr
    local.tee $__opt5
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt5
    local.set $__bp_nullish__3
    local.get $__bp_nullish__3
      )
      (else
    global.get $__s14
      )
    )
    call $__str_concat
    local.set $out
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $n
    i32.const 2
    i32.gt_s
    (if (result i32)
      (then
    local.get $out
    local.get $alphabet
    local.get $b2
    i32.const 64
    global.get $__s39
    call $__i32_nz
    i32.rem_s
    local.set $__gc16
    local.set $__gc17
    global.get $__heap_ptr
    local.set $__gc18
    local.get $__gc17
    call $__gc_to_lin_str
    local.get $__gc16
    call $__std_text_at
    local.tee $__gc19
    i32.eqz
    (if (result (ref null $str))
      (then
    ref.null $str
      )
      (else
    local.get $__gc19
    call $__lin_to_gc_str
      )
    )
    local.get $__gc18
    global.set $__heap_ptr
    local.tee $__opt6
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt6
    local.set $__bp_nullish__4
    local.get $__bp_nullish__4
      )
      (else
    global.get $__s14
      )
    )
    call $__str_concat
    local.set $out
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $g
    i32.const 1
    global.get $__s40
    call $__i32_add_chk
    local.set $g
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $out
    return
  )
  ;; A whole `v` in [0, 2^31) as an `i32`.
  (func $wholeOf (param $v f64) (result i32)
    (local $r i32)
    (local $rest f64)
    (local $bit i32)
    (local $weight f64)
    i32.const 0
    local.set $r
    local.get $v
    local.set $rest
    i32.const 1073741824
    local.set $bit
    f64.const 1073741824.0
    local.set $weight
    (block $__break
      (loop $__continue
    local.get $bit
    i32.const 0
    i32.gt_s
        i32.eqz
        br_if $__break
    local.get $rest
    local.get $weight
    f64.ge
    (if (result i32)
      (then
    local.get $r
    local.get $bit
    global.get $__s41
    call $__i32_add_chk
    local.set $r
    local.get $rest
    local.get $weight
    f64.sub
    local.set $rest
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $bit
    i32.const 2
    global.get $__s42
    global.get $__s43
    call $__i32_divs
    local.set $bit
    local.get $weight
    f64.const 2.0
    f64.div
    local.set $weight
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $r
    return
  )
  (func $__arr_at_opt_any (param $xs (ref null $arr_any)) (param $i i32) (result anyref)
    local.get $i
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $i
    local.get $xs
    array.len
    i32.add
    local.set $i
      )
    )
    local.get $i
    i32.const 0
    i32.lt_s
    local.get $i
    local.get $xs
    array.len
    i32.ge_s
    i32.or
    (if (result anyref)
      (then
    ref.null any
      )
      (else
    local.get $xs
    local.get $i
    array.get $arr_any
      )
    )
  )
  (func $__arr_slice_any (param $xs (ref null $arr_any)) (param $a i32) (param $b i32) (result (ref null $arr_any))
    (local $len i32)
    (local $from i32)
    (local $to i32)
    (local $n i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $len
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $len
    local.get $a
    i32.add
    local.set $from
    local.get $from
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $from
      )
    )
      )
      (else
    local.get $a
    local.set $from
    local.get $from
    local.get $len
    i32.gt_s
    (if
      (then
    local.get $len
    local.set $from
      )
    )
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $len
    local.get $b
    i32.add
    local.set $to
    local.get $to
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $to
      )
    )
      )
      (else
    local.get $b
    local.set $to
    local.get $to
    local.get $len
    i32.gt_s
    (if
      (then
    local.get $len
    local.set $to
      )
    )
      )
    )
    local.get $to
    local.get $from
    i32.sub
    local.set $n
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $n
      )
    )
    local.get $n
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    local.get $from
    local.get $n
    array.copy $arr_any $arr_any
    local.get $r
  )
  (func $__arr_concat_any (param $xs (ref null $arr_any)) (param $ys (ref null $arr_any)) (result (ref null $arr_any))
    (local $la i32)
    (local $lb i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $la
    local.get $ys
    array.len
    local.set $lb
    local.get $la
    local.get $lb
    i32.add
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $la
    array.copy $arr_any $arr_any
    local.get $r
    local.get $la
    local.get $ys
    i32.const 0
    local.get $lb
    array.copy $arr_any $arr_any
    local.get $r
  )
  (func $__arr_at_opt_i32 (param $xs (ref null $arr_i32)) (param $i i32) (result anyref)
    local.get $i
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $i
    local.get $xs
    array.len
    i32.add
    local.set $i
      )
    )
    local.get $i
    i32.const 0
    i32.lt_s
    local.get $i
    local.get $xs
    array.len
    i32.ge_s
    i32.or
    (if (result anyref)
      (then
    ref.null any
      )
      (else
    local.get $xs
    local.get $i
    array.get $arr_i32
    struct.new $box_i32
      )
    )
  )
  (func $__arr_slice_i32 (param $xs (ref null $arr_i32)) (param $a i32) (param $b i32) (result (ref null $arr_i32))
    (local $len i32)
    (local $from i32)
    (local $to i32)
    (local $n i32)
    (local $r (ref null $arr_i32))
    local.get $xs
    array.len
    local.set $len
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $len
    local.get $a
    i32.add
    local.set $from
    local.get $from
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $from
      )
    )
      )
      (else
    local.get $a
    local.set $from
    local.get $from
    local.get $len
    i32.gt_s
    (if
      (then
    local.get $len
    local.set $from
      )
    )
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $len
    local.get $b
    i32.add
    local.set $to
    local.get $to
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $to
      )
    )
      )
      (else
    local.get $b
    local.set $to
    local.get $to
    local.get $len
    i32.gt_s
    (if
      (then
    local.get $len
    local.set $to
      )
    )
      )
    )
    local.get $to
    local.get $from
    i32.sub
    local.set $n
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $n
      )
    )
    local.get $n
    array.new_default $arr_i32
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    local.get $from
    local.get $n
    array.copy $arr_i32 $arr_i32
    local.get $r
  )
  (func $__arr_concat_i32 (param $xs (ref null $arr_i32)) (param $ys (ref null $arr_i32)) (result (ref null $arr_i32))
    (local $la i32)
    (local $lb i32)
    (local $r (ref null $arr_i32))
    local.get $xs
    array.len
    local.set $la
    local.get $ys
    array.len
    local.set $lb
    local.get $la
    local.get $lb
    i32.add
    array.new_default $arr_i32
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $la
    array.copy $arr_i32 $arr_i32
    local.get $r
    local.get $la
    local.get $ys
    i32.const 0
    local.get $lb
    array.copy $arr_i32 $arr_i32
    local.get $r
  )
  (func $__arr_join_any (param $xs (ref null $arr_any)) (param $sep (ref null $str)) (result (ref null $str))
    (local $n i32)
    (local $i i32)
    (local $acc (ref null $str))
    local.get $xs
    array.len
    local.set $n
    i32.const 0
    array.new_default $str
    local.set $acc
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    local.get $acc
    local.get $sep
    call $__str_concat
    local.set $acc
      )
    )
    local.get $acc
    local.get $xs
    local.get $i
    array.get $arr_any
    ref.cast (ref null $str)
    call $__str_concat
    local.set $acc
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $acc
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
  (func $__write_bytes (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__print_nl
    i32.const 8
    i32.const 10
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  ;; separator between the arguments of a multi-argument `@print`
  (func $__print_sp
    i32.const 8
    i32.const 32
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i32 (param $n i32)
    local.get $n
    call $__print_i32_raw
    call $__print_nl
  )
  (func $__print_i32_raw (param $n i32)
    (local $buf i32) (local $len i32) (local $neg i32) (local $d i32)
    (local $i i32) (local $j i32) (local $tmp i32)
    i32.const 64
    local.set $buf
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 1
        local.set $neg
        i32.const 0
        local.get $n
        i32.sub
        local.set $n
      )
    )
    (block $done
      (loop $digits
        local.get $n
        i32.const 10
        i32.rem_u
        i32.const 48
        i32.add
        local.set $d
        local.get $buf
        local.get $len
        i32.add
        local.get $d
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
        local.get $n
        i32.const 10
        i32.div_u
        local.set $n
        local.get $n
        i32.const 0
        i32.gt_u
        br_if $digits
      )
    )
    ;; reverse
    i32.const 0
    local.set $i
    local.get $len
    i32.const 1
    i32.sub
    local.set $j
    (block $rdone
      (loop $rev
        local.get $i
        local.get $j
        i32.ge_u
        br_if $rdone
        local.get $buf
        local.get $i
        i32.add
        i32.load8_u
        local.set $tmp
        local.get $buf
        local.get $i
        i32.add
        local.get $buf
        local.get $j
        i32.add
        i32.load8_u
        i32.store8
        local.get $buf
        local.get $j
        i32.add
        local.get $tmp
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        local.get $j
        i32.const 1
        i32.sub
        local.set $j
        br $rev
      )
    )
    ;; add neg sign + newline
    ;; shift the digits one byte right to make room for '-'
    ;; (dst = buf+1, NOT buf+len: the latter moved them `len`
    ;;  bytes and printed -12 as -21)
    local.get $neg
    (if
      (then
        local.get $buf
        i32.const 1
        i32.add
        local.get $buf
        local.get $len
        call $__memmove
        local.get $buf
        i32.const 45
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
      )
    )
    local.get $buf
    local.get $len
    call $__write_bytes
  )
  (func $__memmove (param $dst i32) (param $src i32) (param $len i32)
    (local $i i32)
    local.get $len
    i32.const 1
    i32.sub
    local.set $i
    (block $done
      (loop $loop
        local.get $i
        i32.const 0
        i32.lt_s
        br_if $done
        local.get $dst
        local.get $i
        i32.add
        local.get $src
        local.get $i
        i32.add
        i32.load8_u
        i32.store8
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        br $loop
      )
    )
  )
  (func $__str_concat (param $a (ref null $str)) (param $b (ref null $str)) (result (ref null $str))
    (local $r (ref null $str)) (local $alen i32) (local $blen i32)
    local.get $a
    array.len
    local.set $alen
    local.get $b
    array.len
    local.set $blen
    local.get $alen
    local.get $blen
    i32.add
    array.new_default $str
    local.set $r
    local.get $r
    i32.const 0
    local.get $a
    i32.const 0
    local.get $alen
    array.copy $str $str
    local.get $r
    local.get $alen
    local.get $b
    i32.const 0
    local.get $blen
    array.copy $str $str
    local.get $r
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
  (func $__write_err (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 2
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__assert_fail (param $where i32) (param $msg i32)
    local.get $where
    i32.const 4
    i32.add
    local.get $where
    i32.load
    call $__write_err
    i32.const 188
    i64.const 8390880602276044858
    i64.store
    i32.const 196
    i64.const 7811882119909502825
    i64.store
    i32.const 204
    i32.const 101
    i32.store8
    i32.const 205
    i32.const 100
    i32.store8
    i32.const 188
    i32.const 18
    call $__write_err
    local.get $msg
    (if
      (then
        i32.const 188
        i32.const 8250
        i32.store
        i32.const 188
        i32.const 2
        call $__write_err
        local.get $msg
        i32.const 4
        i32.add
        local.get $msg
        i32.load
        call $__write_err
      )
    )
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
  )
  (func $__panic_fail (param $msg (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    i32.const 188
    i64.const 9071397899755888
    i64.store
    i32.const 188
    i32.const 7
    call $__write_err
    local.get $msg
    array.len
    local.set $n
    global.get $__heap_ptr
    local.set $top
    local.get $n
    call $__alloc
    local.set $p
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $msg
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
    local.get $n
    call $__write_err
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
    local.get $top
    global.set $__heap_ptr
  )
  (func $__wasi_random_f64 (result f64)
    i32.const 208
    i32.const 8
    call $random_get
    (if
      (then
        unreachable
      )
    )
    i32.const 208
    i64.load
    i64.const 11
    i64.shr_u
    f64.convert_i64_u
    f64.const 1.1102230246251565e-16
    f64.mul
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
        local.get $site
        call $__chk_fail
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
            local.get $site
            call $__chk_fail
            unreachable
          )
        )
      )
    )
    local.get $r
  )
  (func $__gc_to_lin_str (param $s (ref null $str)) (result i32)
    (local $n i32) (local $p i32) (local $i i32)
    local.get $s
    array.len
    local.set $n
    local.get $n
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $s
        local.get $i
        array.get_u $str
        i32.store8 offset=4
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
  )
  (func $__lin_to_gc_str (param $p i32) (result (ref null $str))
    (local $r (ref null $str)) (local $n i32) (local $i i32)
    local.get $p
    i32.load
    local.set $n
    local.get $n
    array.new_default $str
    local.set $r
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $r
        local.get $i
        local.get $p
        local.get $i
        i32.add
        i32.load8_u offset=4
        array.set $str
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $r
  )
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  (func $__i32_divs (param $a i32) (param $b i32) (param $site (ref null $str)) (param $osite (ref null $str)) (result i32)
    local.get $b
    i32.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    i32.const -2147483648
    i32.eq
    local.get $b
    i32.const -1
    i32.eq
    i32.and
    (if
      (then
        local.get $osite
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    local.get $b
    i32.div_s
  )
  (func $__i64_divs (param $a i64) (param $b i64) (param $site (ref null $str)) (param $osite (ref null $str)) (result i64)
    local.get $b
    i64.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    i64.const -9223372036854775808
    i64.eq
    local.get $b
    i64.const -1
    i64.eq
    i32.and
    (if
      (then
        local.get $osite
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    local.get $b
    i64.div_s
  )
  (func $__i32_nz (param $b i32) (param $site (ref null $str)) (result i32)
    local.get $b
    i32.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $b
  )
  (func $__i64_nz (param $b i64) (param $site (ref null $str)) (result i64)
    local.get $b
    i64.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $b
  )
  (global $__random_state (mut i64) (i64.const -1))
  ;; std-wasm (decision 440): its functions, transpiled from std_wasm.wasm
  (global $__std_sp (mut i32) (i32.const 272))
  (func $__std_sp_check (param $sp i32) (result i32)
    local.get $sp
    i32.const 256
    i32.lt_s
    (if
      (then unreachable)
    )
    local.get $sp
  )
  ;; __std_f4 — from std_wasm.wasm (sha256 b4b6f06748d6)
  ;; __std_f267 — from std_wasm.wasm (sha256 5ac39cdc3016)
  ;; __std_f268 — from std_wasm.wasm (sha256 cda2fb2bf3e4)
  ;; __std_f306 — from std_wasm.wasm (sha256 237bb4237dcb)
  ;; std:text.at — from std_wasm.wasm (sha256 037f981d6200)
  ;; std-wasm's .wat leaves (front 164 s3)
  (func $__std_random_float (result f64)
    call $__wasi_random_f64
  )
  (func $__std_random_seed (param $s i32)
    local.get $s
    i64.extend_i32_u
    global.set $__random_state
  )
  (func $__std_random_seededFloat (result f64)
    (local $s i32)
    (local $t i32)
    global.get $__random_state
    i64.const 0
    i64.lt_s
    (if
      (then
        call $__wasi_random_f64
        return
      )
    )
    global.get $__random_state
    i32.wrap_i64
    i32.const 0x6D2B79F5
    i32.add
    local.tee $s
    i64.extend_i32_u
    global.set $__random_state
    local.get $s
    local.get $s
    i32.const 15
    i32.shr_u
    i32.xor
    local.get $s
    i32.const 1
    i32.or
    i32.mul
    local.set $t
    local.get $t
    local.get $t
    local.get $t
    i32.const 7
    i32.shr_u
    i32.xor
    local.get $t
    i32.const 61
    i32.or
    i32.mul
    i32.add
    local.get $t
    i32.xor
    local.set $t
    local.get $t
    local.get $t
    i32.const 14
    i32.shr_u
    i32.xor
    f64.convert_i32_u
    f64.const 4294967296.0
    f64.div
  )
  (data $__d0 "integer overflow: - on i32 at src/io/random.bp:66:20")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "integer overflow: + on i32 at src/io/random.bp:66:26")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "integer overflow: + on i32 at src/io/random.bp:69:15")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "integer overflow: + on i32 at src/io/random.bp:90:15")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "integer overflow: + on i32 at src/io/random.bp:92:28")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "integer overflow: + on i32 at src/io/random.bp:319:42")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "integer overflow: + on i32 at src/io/random.bp:320:53")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "integer division by zero: % on i32 at src/io/random.bp:332:37")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "integer overflow: + on i32 at src/io/random.bp:332:22")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "integer division by zero: % on i32 at src/io/random.bp:333:38")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "integer overflow: + on i32 at src/io/random.bp:333:23")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 "-")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (data $__d12 "integer overflow: + on i32 at src/io/random.bp:358:15")
  (global $__s12 (mut (ref null $str)) (ref.null $str))
  (data $__d13 "0123456789abcdef")
  (global $__s13 (mut (ref null $str)) (ref.null $str))
  (data $__d14 "")
  (global $__s14 (mut (ref null $str)) (ref.null $str))
  (data $__d15 "integer division by zero: / on i32 at src/io/random.bp:368:40")
  (global $__s15 (mut (ref null $str)) (ref.null $str))
  (data $__d16 "integer overflow: / on i32 at src/io/random.bp:368:40")
  (global $__s16 (mut (ref null $str)) (ref.null $str))
  (data $__d17 "integer division by zero: % on i32 at src/io/random.bp:368:59")
  (global $__s17 (mut (ref null $str)) (ref.null $str))
  (data $__d18 "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
  (global $__s18 (mut (ref null $str)) (ref.null $str))
  (data $__d19 "integer overflow: * on i32 at src/io/random.bp:376:14")
  (global $__s19 (mut (ref null $str)) (ref.null $str))
  (data $__d20 "integer overflow: * on i32 at src/io/random.bp:377:34")
  (global $__s20 (mut (ref null $str)) (ref.null $str))
  (data $__d21 "integer overflow: - on i32 at src/io/random.bp:377:30")
  (global $__s21 (mut (ref null $str)) (ref.null $str))
  (data $__d22 "integer overflow: * on i32 at src/io/random.bp:378:29")
  (global $__s22 (mut (ref null $str)) (ref.null $str))
  (data $__d23 "integer overflow: * on i32 at src/io/random.bp:380:24")
  (global $__s23 (mut (ref null $str)) (ref.null $str))
  (data $__d24 "integer overflow: + on i32 at src/io/random.bp:380:28")
  (global $__s24 (mut (ref null $str)) (ref.null $str))
  (data $__d25 "integer overflow: * on i32 at src/io/random.bp:383:24")
  (global $__s25 (mut (ref null $str)) (ref.null $str))
  (data $__d26 "integer overflow: + on i32 at src/io/random.bp:383:28")
  (global $__s26 (mut (ref null $str)) (ref.null $str))
  (data $__d27 "integer division by zero: / on i32 at src/io/random.bp:386:30")
  (global $__s27 (mut (ref null $str)) (ref.null $str))
  (data $__d28 "integer overflow: / on i32 at src/io/random.bp:386:30")
  (global $__s28 (mut (ref null $str)) (ref.null $str))
  (data $__d29 "integer division by zero: % on i32 at src/io/random.bp:387:31")
  (global $__s29 (mut (ref null $str)) (ref.null $str))
  (data $__d30 "integer overflow: * on i32 at src/io/random.bp:387:36")
  (global $__s30 (mut (ref null $str)) (ref.null $str))
  (data $__d31 "integer division by zero: / on i32 at src/io/random.bp:387:46")
  (global $__s31 (mut (ref null $str)) (ref.null $str))
  (data $__d32 "integer overflow: / on i32 at src/io/random.bp:387:46")
  (global $__s32 (mut (ref null $str)) (ref.null $str))
  (data $__d33 "integer overflow: + on i32 at src/io/random.bp:387:41")
  (global $__s33 (mut (ref null $str)) (ref.null $str))
  (data $__d34 "integer division by zero: % on i32 at src/io/random.bp:388:48")
  (global $__s34 (mut (ref null $str)) (ref.null $str))
  (data $__d35 "integer overflow: * on i32 at src/io/random.bp:388:54")
  (global $__s35 (mut (ref null $str)) (ref.null $str))
  (data $__d36 "integer division by zero: / on i32 at src/io/random.bp:388:63")
  (global $__s36 (mut (ref null $str)) (ref.null $str))
  (data $__d37 "integer overflow: / on i32 at src/io/random.bp:388:63")
  (global $__s37 (mut (ref null $str)) (ref.null $str))
  (data $__d38 "integer overflow: + on i32 at src/io/random.bp:388:58")
  (global $__s38 (mut (ref null $str)) (ref.null $str))
  (data $__d39 "integer division by zero: % on i32 at src/io/random.bp:389:47")
  (global $__s39 (mut (ref null $str)) (ref.null $str))
  (data $__d40 "integer overflow: + on i32 at src/io/random.bp:390:15")
  (global $__s40 (mut (ref null $str)) (ref.null $str))
  (data $__d41 "integer overflow: + on i32 at src/io/random.bp:403:19")
  (global $__s41 (mut (ref null $str)) (ref.null $str))
  (data $__d42 "integer division by zero: / on i32 at src/io/random.bp:406:19")
  (global $__s42 (mut (ref null $str)) (ref.null $str))
  (data $__d43 "integer overflow: / on i32 at src/io/random.bp:406:19")
  (global $__s43 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 52
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 52
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 52
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 52
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 52
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 53
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 53
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 61
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 53
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 61
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 53
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 1
    array.new_data $str $__d11
    global.set $__s11
    i32.const 0
    i32.const 53
    array.new_data $str $__d12
    global.set $__s12
    i32.const 0
    i32.const 16
    array.new_data $str $__d13
    global.set $__s13
    i32.const 0
    i32.const 0
    array.new_data $str $__d14
    global.set $__s14
    i32.const 0
    i32.const 61
    array.new_data $str $__d15
    global.set $__s15
    i32.const 0
    i32.const 53
    array.new_data $str $__d16
    global.set $__s16
    i32.const 0
    i32.const 61
    array.new_data $str $__d17
    global.set $__s17
    i32.const 0
    i32.const 64
    array.new_data $str $__d18
    global.set $__s18
    i32.const 0
    i32.const 53
    array.new_data $str $__d19
    global.set $__s19
    i32.const 0
    i32.const 53
    array.new_data $str $__d20
    global.set $__s20
    i32.const 0
    i32.const 53
    array.new_data $str $__d21
    global.set $__s21
    i32.const 0
    i32.const 53
    array.new_data $str $__d22
    global.set $__s22
    i32.const 0
    i32.const 53
    array.new_data $str $__d23
    global.set $__s23
    i32.const 0
    i32.const 53
    array.new_data $str $__d24
    global.set $__s24
    i32.const 0
    i32.const 53
    array.new_data $str $__d25
    global.set $__s25
    i32.const 0
    i32.const 53
    array.new_data $str $__d26
    global.set $__s26
    i32.const 0
    i32.const 61
    array.new_data $str $__d27
    global.set $__s27
    i32.const 0
    i32.const 53
    array.new_data $str $__d28
    global.set $__s28
    i32.const 0
    i32.const 61
    array.new_data $str $__d29
    global.set $__s29
    i32.const 0
    i32.const 53
    array.new_data $str $__d30
    global.set $__s30
    i32.const 0
    i32.const 61
    array.new_data $str $__d31
    global.set $__s31
    i32.const 0
    i32.const 53
    array.new_data $str $__d32
    global.set $__s32
    i32.const 0
    i32.const 53
    array.new_data $str $__d33
    global.set $__s33
    i32.const 0
    i32.const 61
    array.new_data $str $__d34
    global.set $__s34
    i32.const 0
    i32.const 53
    array.new_data $str $__d35
    global.set $__s35
    i32.const 0
    i32.const 61
    array.new_data $str $__d36
    global.set $__s36
    i32.const 0
    i32.const 53
    array.new_data $str $__d37
    global.set $__s37
    i32.const 0
    i32.const 53
    array.new_data $str $__d38
    global.set $__s38
    i32.const 0
    i32.const 61
    array.new_data $str $__d39
    global.set $__s39
    i32.const 0
    i32.const 53
    array.new_data $str $__d40
    global.set $__s40
    i32.const 0
    i32.const 53
    array.new_data $str $__d41
    global.set $__s41
    i32.const 0
    i32.const 61
    array.new_data $str $__d42
    global.set $__s42
    i32.const 0
    i32.const 53
    array.new_data $str $__d43
    global.set $__s43
  )
  (@custom "botopink.needs" "gc\0a")
)
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
//// (`*Sync` on Node, blocking BIFs on Erlang, `wasi:filesystem` on wasm: the runner
//// preopens the root and the working directory, decision 992), and a path is read as
//// the process reads it — a relative one against the working directory — on every target.

import {path.relative, failure, failure.HostError, failure.HostErrorName, io.random, compiler};

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
    .Wasm(body: readBytesWasm),
)]
declare fn rawReadBytes(path: string) -> Result<bytes, HostError>;

// Write `contents` to `path`, creating or truncating.
// Node: `writeFileSync($0, $1)`. Erlang: `file:write_file/2`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').writeFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
    .Wasm(body: writeBytesWasm),
)]
declare fn rawWriteBytes(path: string, contents: bytes) -> Result<i32, HostError>;

// Append `contents` to `path`, creating it when it is not there.
// Node: `appendFileSync($0, $1)`. Erlang: `file:write_file/3` with `append`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').appendFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__P, __C) -> case file:write_file(__P, __C, [append]) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
    .Wasm(body: appendTextWasm),
)]
declare fn rawAppendText(path: string, contents: string) -> Result<i32, HostError>;

// The offset of the first byte that starts a sequence that is not UTF-8 (a byte no sequence
// starts with, a sequence cut short, an overlong form, a surrogate, a code point past U+10FFFF),
// or -1 when every byte is part of a valid sequence — the same offset on every target.
// Node: a scan of the bytes. Erlang: `unicode:characters_to_binary/3`, whose `Good` prefix is the offset.
#[compiler.external(
    .JavaScript("""((__b) => { const __n = __b.length; let __i = 0; while (__i < __n) { const __c = __b[__i]; if (__c < 128) { __i++; continue } let __k; if (__c >= 194 && __c <= 223) __k = 1; else if (__c >= 224 && __c <= 239) __k = 2; else if (__c >= 240 && __c <= 244) __k = 3; else return __i; if (__i + __k >= __n) return __i; let __lo = 128, __hi = 191; if (__c === 224) __lo = 160; else if (__c === 237) __hi = 159; else if (__c === 240) __lo = 144; else if (__c === 244) __hi = 143; const __d = __b[__i + 1]; if (__d < __lo || __d > __hi) return __i; for (let __j = 2; __j <= __k; __j++) { const __e = __b[__i + __j]; if (__e < 128 || __e > 191) return __i } __i += __k + 1 } return -1 })($0)"""),
    .Erlang("""(fun(__B) -> case unicode:characters_to_binary(__B, utf8, utf8) of __S when is_binary(__S) -> -1; {error, __G, _} -> byte_size(__G); {incomplete, __G, _} -> byte_size(__G) end end)($0)"""),
    .Wasm(body: utf8OffsetWasm),
)]
declare fn utf8Offset(bytes: bytes) -> i64;

// `line` without its line terminator: one trailing `\n`, and the `\r` before it.
// Node: `subarray`. Erlang: `binary:part/3`.
#[compiler.external(
    .JavaScript("""((__b) => { let __n = __b.length; if (__n > 0 && __b[__n - 1] === 10) { __n--; if (__n > 0 && __b[__n - 1] === 13) __n-- } return __b.subarray(0, __n) })($0)"""),
    .Erlang("""(fun(__B) -> __N = byte_size(__B), if __N >= 2 -> case binary:part(__B, __N - 2, 2) of <<13, 10>> -> binary:part(__B, 0, __N - 2); <<_, 10>> -> binary:part(__B, 0, __N - 1); _ -> __B end; __N =:= 1 -> case __B of <<10>> -> <<>>; _ -> __B end; true -> __B end end)($0)"""),
    .Wasm(body: stripEolWasm),
)]
declare fn stripEol(line: bytes) -> bytes;

// The handle of the file at `path`, open for reading. A directory is `isdir` on both hosts
// (Node opens one; the template refuses it). The handle is host-owned and opaque: a `{ fd,
// mem, pos, buf }` object on Node, an io device on Erlang (a stream reads it in its own process).
#[compiler.external(
    .JavaScript("""(() => { const __fs = require('fs'); const __p = $0; const __fd = __fs.openSync(__p, 'r'); if (__fs.fstatSync(__fd).isDirectory()) { __fs.closeSync(__fd); throw new Error('EISDIR: illegal operation on a directory, open ' + JSON.stringify(__p)) } return { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } })()""", result: true),
    .Erlang("""(fun(__P) -> case file:open(__P, [read, binary, read_ahead]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: openWasm),
)]
declare fn rawOpen(path: string) -> Result<unknown, HostError>;

// The handle of the file at `path`, open for writing: created, or truncated.
#[compiler.external(
    .JavaScript("""(() => { const __fd = require('fs').openSync($0, 'w'); return { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } })()""", result: true),
    .Erlang("""(fun(__P) -> case file:open(__P, [write, binary, raw]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: createWasm),
)]
declare fn rawCreate(path: string) -> Result<unknown, HostError>;

// A handle over bytes held in memory — what an `Asset` opens as. The position is a field
// on Node and a `counters` cell on Erlang.
#[compiler.external(
    .JavaScript("""({ fd: -1, mem: $0, pos: 0, buf: new Uint8Array(0) })"""),
    .Erlang("""{mem, $0, counters:new(1, [])}"""),
    .Wasm(body: memHandleWasm),
)]
declare fn memHandle(bytes: bytes) -> unknown;

// The size of the file behind `handle`, in bytes. On Erlang it reads `path`.
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; return __h.mem ? __h.mem.length : require('fs').fstatSync(__h.fd).size })()""", result: true),
    .Erlang("""(fun(__H, __P) -> case __H of {mem, __B, _} -> {ok, byte_size(__B)}; _ -> case file:read_file_info(__P) of {ok, __I} -> {ok, element(2, __I)}; {error, __R} -> {error, __R} end end end)($0, $1)""", result: true),
    .Wasm(body: sizeWasm),
)]
declare fn rawSize(handle: unknown, path: string) -> Result<i64, HostError>;

// Up to `n` bytes (n > 0) from the handle's position; empty at the end.
#[compiler.external(
    .JavaScript("""(() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = $0; const __n = $1; if (__h.buf.length > 0) { const __k = Math.min(__n, __h.buf.length); const __o = new Uint8Array(__h.buf.subarray(0, __k)); __h.buf = __h.buf.subarray(__k); return __o } return new Uint8Array(__more(__h, __n)) })()""", result: true),
    .Erlang("""(fun(__H, __N) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Len = min(__N, byte_size(__B) - __Pos), counters:add(__C, 1, __Len), {ok, binary:part(__B, __Pos, __Len)}; _ -> case file:read(__H, __N) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __R} end end end)($0, $1)""", result: true),
    .Wasm(body: readWasm),
)]
declare fn rawRead(handle: unknown, n: i32) -> Result<bytes, HostError>;

// Every byte from the handle's position to the end.
#[compiler.external(
    .JavaScript("""(() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = $0; const __parts = []; if (__h.buf.length > 0) { __parts.push(__h.buf); __h.buf = new Uint8Array(0) } for (;;) { const __r = __more(__h, 65536); if (__r.length === 0) break; __parts.push(new Uint8Array(__r)) } let __t = 0; for (const __x of __parts) __t += __x.length; const __o = new Uint8Array(__t); let __p = 0; for (const __x of __parts) { __o.set(__x, __p); __p += __x.length } return __o })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), counters:add(__C, 1, byte_size(__B) - __Pos), {ok, binary:part(__B, __Pos, byte_size(__B) - __Pos)}; _ -> (fun __L(__Acc) -> case file:read(__H, 65536) of {ok, __D} -> __L([__Acc, __D]); eof -> {ok, iolist_to_binary(__Acc)}; {error, __R} -> {error, __R} end end)([]) end end)($0)""", result: true),
    .Wasm(body: readAllWasm),
)]
declare fn rawReadAll(handle: unknown) -> Result<bytes, HostError>;

// The next line, terminator included; empty at the end.
#[compiler.external(
    .JavaScript("""(() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = $0; for (;;) { const __i = __h.buf.indexOf(10); if (__i >= 0) { const __l = new Uint8Array(__h.buf.subarray(0, __i + 1)); __h.buf = __h.buf.subarray(__i + 1); return __l } const __r = __more(__h, 65536); if (__r.length === 0) { const __l = __h.buf; __h.buf = new Uint8Array(0); return __l } const __nb = new Uint8Array(__h.buf.length + __r.length); __nb.set(__h.buf, 0); __nb.set(__r, __h.buf.length); __h.buf = __nb } })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Rest = binary:part(__B, __Pos, byte_size(__B) - __Pos), case binary:match(__Rest, <<10>>) of nomatch -> counters:add(__C, 1, byte_size(__Rest)), {ok, __Rest}; {__At, _} -> counters:add(__C, 1, __At + 1), {ok, binary:part(__Rest, 0, __At + 1)} end; _ -> case file:read_line(__H) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __R} end end end)($0)""", result: true),
    .Wasm(body: readLineWasm),
)]
declare fn rawReadLine(handle: unknown) -> Result<bytes, HostError>;

// The SHA-256 of the whole file behind the handle, lowercase hex — from its first byte,
// whatever the position, which it leaves where it was. On Erlang `file:pread` leaves the
// position undefined (OTP moves it), so the position is read first and restored.
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; const __hs = require('crypto').createHash('sha256'); if (__h.mem) { __hs.update(__h.mem) } else { const __b = new Uint8Array(65536); let __pos = 0; for (;;) { const __k = require('fs').readSync(__h.fd, __b, 0, 65536, __pos); if (__k === 0) break; __hs.update(__b.subarray(0, __k)); __pos += __k } } return __hs.digest('hex') })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, __B, _} -> {ok, string:lowercase(binary:encode_hex(crypto:hash(sha256, __B)))}; _ -> {ok, __Cur} = file:position(__H, cur), __L = fun __Lp(__Pos, __Ctx) -> case file:pread(__H, __Pos, 65536) of {ok, __D} -> __Lp(__Pos + byte_size(__D), crypto:hash_update(__Ctx, __D)); eof -> crypto:hash_final(__Ctx); {error, __R} -> erlang:error(__R) end end, __Digest = __L(0, crypto:hash_init(sha256)), {ok, _} = file:position(__H, __Cur), {ok, string:lowercase(binary:encode_hex(__Digest))} end end)($0)""", result: true),
    .Wasm(body: hashWasm),
)]
declare fn rawHash(handle: unknown) -> Result<string, HostError>;

// Write `bytes` at the handle's position; answers how many.
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; const __b = $1; let __o = 0; while (__o < __b.length) __o += require('fs').writeSync(__h.fd, __b, __o, __b.length - __o); return __b.length })()""", result: true),
    .Erlang("""(fun(__H, __B) -> case file:write(__H, __B) of ok -> {ok, byte_size(__B)}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
    .Wasm(body: writeWasm),
)]
declare fn rawWrite(handle: unknown, bytes: bytes) -> Result<i32, HostError>;

// Close the handle. A failure to close is not reported (a `Closeable`'s `close` answers nothing).
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; if (!__h.mem) require('fs').closeSync(__h.fd); return 0 })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, _, _} -> {ok, 0}; _ -> case file:close(__H) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end end)($0)""", result: true),
    .Wasm(body: closeWasm),
)]
declare fn rawClose(handle: unknown) -> Result<i32, HostError>;

// Write `contents` to `path`, creating or truncating. Reds with the
// host's I/O error message.
// Node: `require('fs').writeFileSync($0, $1)`.
// Erlang: `file:write_file/2`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').writeFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
    .Wasm(body: writeTextWasm),
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
    .Wasm(body: existsWasm),
)]
pub declare fn exists(path: string) -> bool;

// List the names of the directory entries at `path` (relative).
// Node: `require('fs').readdirSync($0)`.
// Erlang: `file:list_dir/1` returns `{ok, [string()]}`, in the directory's
// order: sorted here by bytes (`lists:sort` on binaries), as `readdirSync` and
// wasm's `listWasm` answer them, so every target lists one order (decision 992).
#[compiler.external(
    .JavaScript("""(() => { return require('fs').readdirSync($0) })()""", result: true),
    .Erlang("""(fun(__P) -> case file:list_dir(__P) of {ok, __L} -> {ok, lists:sort([list_to_binary(__N) || __N <- __L])}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: listWasm),
)]
declare fn rawList(path: string) -> Result<string[], HostError>;

// Create directory at `path`. Use `mkdirRecursive` to create
// intermediate parents.
// Node: `require('fs').mkdirSync($0)`.
// Erlang: `file:make_dir/1`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').mkdirSync($0); return 0 })()""", result: true),
    .Erlang("""(fun(__P) -> case file:make_dir(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: mkdirWasm),
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
    .Wasm(body: mkdirRecursiveWasm),
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
    .Wasm(body: rmWasm),
)]
declare fn rawRm(path: string) -> Result<i32, HostError>;

// Copy file from `src` to `dest`. Reds when `src` is missing or
// `dest` already exists (Node's default `copyFileSync` semantics).
// Node: `require('fs').copyFileSync($0, $1)`.
// Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).
#[compiler.external(
    .JavaScript("""(() => { require('fs').copyFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__S, __D) -> case file:copy(__S, __D) of {ok, _} -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
    .Wasm(body: copyWasm),
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
    .Wasm(body: statWasm),
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
    .Wasm(body: walkWasm),
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
    .Wasm(body: globWasm),
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
    .Wasm(body: removeTreeWasm),
)]
declare fn rawRemoveTree(path: string) -> Result<i32, HostError>;

// Internal, test scaffolding: a fresh, unique, empty directory under the
// host's tmpdir. Private — every `walk`/`glob` test makes its fixture tree in
// one of these and removes it with `removeTree`, so a run leaves nothing under
// the host's tmpdir.
#[compiler.external(
    .JavaScript("""require('fs').mkdtempSync(require('path').join(require('os').tmpdir(), 'bp-std-fs-'))"""),
    .Erlang("""(fun() -> __T = case os:getenv("TMPDIR") of false -> "/tmp"; __V -> __V end, __D = filename:join(__T, "bp-std-fs-" ++ integer_to_list(erlang:unique_integer([positive]))), ok = file:make_dir(__D), unicode:characters_to_binary(__D) end)()"""),
    .Wasm(body: scratchDirWasm),
)]
declare fn scratchDir() -> string;

// Internal, test scaffolding: the working directory (what a relative root is
// read against) and a symbolic link `link` → `target`.
#[compiler.external(
    .JavaScript("process.cwd()"),
    .Erlang("""(fun() -> {ok, __D} = file:get_cwd(), unicode:characters_to_binary(__D) end)()"""),
    .Wasm(body: workingDirWasm),
)]
declare fn workingDir() -> string;

#[compiler.external(
    .JavaScript("""require('fs').symlinkSync($0, $1)"""),
    .Erlang("""(fun(__T, __L) -> ok = file:make_symlink(__T, __L), ok end)($0, $1)"""),
    .Wasm(body: linkToWasm),
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

// `lift` for each answer type: the generic one is the wasm backend's to specialise, and a
// `bytes` or a handle it does not (decision 992).
fn liftBytes(path: string, r: Result<bytes, HostError>) -> Result<bytes, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftI32(path: string, r: Result<i32, HostError>) -> Result<i32, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftI64(path: string, r: Result<i64, HostError>) -> Result<i64, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftString(path: string, r: Result<string, HostError>) -> Result<string, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftStrings(path: string, r: Result<string[], HostError>) -> Result<string[], FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftStat(path: string, r: Result<FileStat, HostError>) -> Result<FileStat, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftWalked(path: string, r: Result<Walked, HostError>) -> Result<Walked, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftHandle(path: string, r: Result<unknown, HostError>) -> Result<unknown, FsError> {
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
    .Wasm(body: readOnlyWasm),
)]
declare fn rawReadOnly(handle: unknown) -> bool;

// ── whole-file shortcuts ─────────────────────────────────────────────────────

// The file's bytes.
pub fn readBytes(path: string) -> Result<bytes, FsError> {
    val b = try liftBytes(path, rawReadBytes(path));
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
    val n = try liftI32(path, rawWriteBytes(path, contents));
    return n;
}

pub fn writeText(path: string, contents: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawWriteText(path, contents));
    return n;
}

// Append `contents`, creating the file when it is not there.
pub fn appendText(path: string, contents: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawAppendText(path, contents));
    return n;
}

// ── metadata and directories ─────────────────────────────────────────────────

pub fn stat(path: string) -> Result<FileStat, FsError> {
    val s = try liftStat(path, rawStat(path));
    return s;
}

pub fn list(path: string) -> Result<string[], FsError> {
    val names = try liftStrings(path, rawList(path));
    return names;
}

pub fn mkdir(path: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawMkdir(path));
    return n;
}

pub fn mkdirRecursive(path: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawMkdirRecursive(path));
    return n;
}

pub fn rm(path: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawRm(path));
    return n;
}

pub fn removeTree(path: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawRemoveTree(path));
    return n;
}

pub fn copy(src: string, dest: string) -> Result<i32, FsError> {
    val n = try liftI32(src, rawCopy(src, dest));
    return n;
}

pub fn walk(root: string) -> Result<string[], FsError> {
    val found = try liftWalked(root, rawWalk(root));
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
    .Wasm(body: memHandleWasm),
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
        val n = try liftI64(self.location, rawSize(self.handle, self.location));
        return n;
    }

    // Up to `n` bytes from the position; empty at the end of the file.
    pub fn read(self: Self, n: i32) -> Result<bytes, FsError> {
        if (n <= 0) return bytes.fromUtf8("");
        val b = try liftBytes(self.location, rawRead(self.handle, n));
        return b;
    }

    // Every byte from the position to the end.
    pub fn bytes(self: Self) -> Result<bytes, FsError> {
        val b = try liftBytes(self.location, rawReadAll(self.handle));
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
        var consumed = 0;
        while (true) {
            val raw = try liftBytes(self.location, rawReadLine(self.handle));
            if (raw.length == 0) break;
            val line = stripEol(raw);
            val offset = utf8Offset(line);
            if (offset >= 0l)
                throw FsError.InvalidUtf8(path: self.location, offset: consumed.toI64()
                    + offset);
            val width: i32 = raw.length;
            consumed = consumed + width;
            yield line.toUtf8().unwrapOr("");
        }
    }

    // The SHA-256 of the whole file, lowercase hex.
    pub fn hash(self: Self) -> Result<string, FsError> {
        val h = try liftString(self.location, rawHash(self.handle));
        return h;
    }

    // Write `b` at the position; answers the number of bytes written.
    pub fn write(self: Self, b: bytes) -> Result<i32, FsError> {
        if (rawReadOnly(self.handle))
            throw FsError.Other(path: self.location, message: "the file is open for reading");
        val n = try liftI32(self.location, rawWrite(self.handle, b));
        return n;
    }

    // Close the file. Closing twice is harmless; a failure to close is not reported.
    pub fn close(self: Self) -> void {
        val closed = rawClose(self.handle);
    }
}

// Open the file at `path` for reading. A directory is `IsDirectory` on every target.
pub fn open(path: string) -> Result<File, FsError> {
    val h = try liftHandle(path, rawOpen(path));
    return File(location: path, handle: h);
}

// Open the file at `path` for writing: created, or truncated.
pub fn create(path: string) -> Result<File, FsError> {
    val h = try liftHandle(path, rawCreate(path));
    return File(location: path, handle: h);
}

// An `Asset` (`@embed`, decisions 519, 538) as a `File`: the embedded bytes, read
// like a file on disk — no `Result`, the build proved the file exists — and
// closing it is a no-op.
pub fn openAsset(asset: Asset) -> File {
    return File(location: asset.path, handle: memoryHandle(asset.bytes));
}

// ── the wasm bodies (decision 992) ───────────────────────────────────────────
// `io.fs` on wasm answers what it answers on commonJS, erlang and beam: the same functions
// over the file system of the process, the same paths (a relative one is read against the
// working directory, an absolute one as it is), the same answers and the same errors. The
// host is `wasi:filesystem`, reached through std-wasm's leaves (`modules/std-wasm/wat/fs.wat`;
// the `wasi…` declarations below), which the runner serves with the root and the working
// directory preopened (`needs: [.Filesystem]`, no flag). A leaf answers a host failure as
// `-(1 + code)`, `code` the ordinal of `wasi:filesystem`'s `error-code`, or as the `Error`
// of a `Result<_, i32>` holding the code; `wasiError` writes it as Node's text
// (`ENOENT: …`), which `fsError` reads as it reads every target's.

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.cwd", needs: [.Filesystem]),
)]
declare fn wasiCwd() -> string;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.getenv", needs: [.Filesystem]),
)]
declare fn wasiGetenv(name: string) -> string;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.open", needs: [.Filesystem]),
)]
declare fn wasiOpen(path: string, mode: i32) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.openMem", needs: [.Filesystem]),
)]
declare fn wasiOpenMem(data: bytes) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.close", needs: [.Filesystem]),
)]
declare fn wasiClose(block: i32) -> void;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.isMem", needs: [.Filesystem]),
)]
declare fn wasiIsMem(block: i32) -> bool;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.tell", needs: [.Filesystem]),
)]
declare fn wasiTell(block: i32) -> i64;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.seek", needs: [.Filesystem]),
)]
declare fn wasiSeek(block: i32, position: i64) -> void;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.size", needs: [.Filesystem]),
)]
declare fn wasiSize(block: i32) -> Result<i64, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.sizeRaw", needs: [.Filesystem]),
)]
declare fn wasiSizeRaw(block: i32) -> i64;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.read", needs: [.Filesystem]),
)]
declare fn wasiRead(block: i32, n: i32) -> Result<bytes, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.readAll", needs: [.Filesystem]),
)]
declare fn wasiReadAll(block: i32) -> Result<bytes, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.readLine", needs: [.Filesystem]),
)]
declare fn wasiReadLine(block: i32) -> Result<bytes, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.write", needs: [.Filesystem]),
)]
declare fn wasiWrite(block: i32, data: bytes) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.statKind", needs: [.Filesystem]),
)]
declare fn wasiStatKind(path: string, follow: i32) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.statSize", needs: [.Filesystem]),
)]
declare fn wasiStatSize(path: string) -> Result<i64, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.statMtime", needs: [.Filesystem]),
)]
declare fn wasiStatMtime(path: string) -> Result<i64, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.list", needs: [.Filesystem]),
)]
declare fn wasiList(path: string) -> Result<string[], i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.mkdir", needs: [.Filesystem]),
)]
declare fn wasiMkdir(path: string) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.rmdir", needs: [.Filesystem]),
)]
declare fn wasiRmdir(path: string) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.unlink", needs: [.Filesystem]),
)]
declare fn wasiUnlink(path: string) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.symlink", needs: [.Filesystem]),
)]
declare fn wasiSymlink(target: string, link: string) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "bytes.at"),
)]
declare fn wasiByteAt(data: bytes, index: i32) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "hash.sha256Hex"),
)]
declare fn wasiSha256(data: bytes) -> string;

// The POSIX name of the host's error `code`, and its text.
fn wasiName(code: i32) -> string {
    val names = [
        "EACCES", "EAGAIN", "EALREADY", "EBADF", "EBUSY", "EDEADLK", "EDQUOT", "EEXIST",
        "EFBIG", "EILSEQ", "EINPROGRESS", "EINTR", "EINVAL", "EIO", "EISDIR", "ELOOP",
        "EMLINK", "EMSGSIZE", "ENAMETOOLONG", "ENODEV", "ENOENT", "ENOLCK", "ENOMEM",
        "ENOSPC", "ENOTDIR", "ENOTEMPTY", "ENOTRECOVERABLE", "ENOTSUP", "ENOTTY",
        "ENXIO", "EOVERFLOW", "EPERM", "EPIPE", "EROFS", "ESPIPE", "ETXTBSY", "EXDEV",
    ];
    return names.at(code) ?? "EIO";
}

fn wasiText(code: i32) -> string {
    val texts = [
        "permission denied", "resource temporarily unavailable",
        "connection already in progress", "bad file descriptor", "resource busy or locked",
        "resource deadlock avoided", "disk quota exceeded", "file already exists",
        "file too large", "illegal byte sequence", "operation in progress",
        "interrupted system call", "invalid argument", "i/o error",
        "illegal operation on a directory", "too many symbolic links encountered",
        "too many links", "message too long", "name too long", "no such device",
        "no such file or directory", "no locks available", "not enough memory",
        "no space left on device", "not a directory", "directory not empty",
        "state not recoverable", "operation not supported",
        "inappropriate ioctl for device", "no such device or address",
        "value too large for defined data type", "operation not permitted", "broken pipe",
        "read-only file system", "invalid seek", "text file busy",
        "cross-device link not permitted",
    ];
    return texts.at(code) ?? "i/o error";
}

// The `HostError` of the host's error `code`: `ENOENT: no such file or directory`.
fn wasiError(code: i32) -> HostError {
    return HostError(
        message: wasiName(code) + ": " + wasiText(code),
        kind: "host",
        name: HostErrorName.Error,
        detail: null,
    );
}

// The `Ok` of a leaf's answer, its `Error` the `HostError` of the code.
fn okBytes(r: Result<bytes, i32>) -> Result<bytes, HostError> {
    case r {
        Ok(b) -> return b;
        Error(code) -> throw wasiError(code);
    }
}

fn okStrings(r: Result<string[], i32>) -> Result<string[], HostError> {
    case r {
        Ok(xs) -> return xs;
        Error(code) -> throw wasiError(code);
    }
}

fn okSize(r: Result<i64, i32>) -> Result<i64, HostError> {
    case r {
        Ok(n) -> return n;
        Error(code) -> throw wasiError(code);
    }
}

// `path` without the slashes it begins with: the host reads a path relative to the root it preopens.
fn withoutRoot(path: string) -> string {
    var p = path;
    while (p.startsWith("/")) {
        p = p.slice(1);
    }
    return p;
}

// `name` inside `dir`, `dir` empty being the root.
fn joinPath(dir: string, name: string) -> string {
    if (dir == "") return name;
    return dir + "/" + name;
}

// `path` as the host reads it: absolute, as it is; relative, from the working directory. The empty
// path is no file (`ENOENT`), as it is on every target.
fn resolve(path: string) -> Result<string, HostError> {
    if (path == "") throw wasiError(20);
    if (path.startsWith("/")) return withoutRoot(path);
    val cwd = wasiCwd();
    if (cwd == "" || cwd == "/") return path;
    return withoutRoot(cwd + "/" + path);
}

// The file a handle holds: the handle block `rawOpen`, `rawCreate` and `memHandle` answered.
fn blockOf(handle: unknown) -> i32 {
    var block = 0;
    if (handle is i32) {
        val b: i32 = handle;
        block = b;
    }
    return block;
}

// Whether `a` sorts before `b` by the bytes of their UTF-8 (string `<` is not a wasm GC operation).
fn bytesBefore(a: string, b: string) -> bool {
    val x = bytes.fromUtf8(a);
    val y = bytes.fromUtf8(b);
    val nx = x.length();
    val ny = y.length();
    var i = 0;
    while (i < nx && i < ny) {
        val cx = wasiByteAt(x, i);
        val cy = wasiByteAt(y, i);
        if (cx != cy) return cx < cy;
        i = i + 1;
    }
    return nx < ny;
}

// The names sorted by the bytes of their UTF-8, none twice: what `readdirSync` answers on Node.
fn sortedStrings(xs: array<string>) -> array<string> {
    var out: array<string> = [];
    var i = 0;
    while (i < xs.length) {
        val x = xs.at(i) ?? "";
        i = i + 1;
        var j = 0;
        while (j < out.length && bytesBefore(out.at(j) ?? "", x)) {
            j = j + 1;
        }
        if (j < out.length && (out.at(j) ?? "") == x) continue;
        out = out.slice(0, j).append([x]).append(out.slice(j));
    }
    return out;
}

fn readBytesWasm(path: string) -> Result<bytes, HostError> {
    val p = try resolve(path);
    val h = wasiOpen(p, 0);
    if (h < 0) throw wasiError(-1 - h);
    val r = wasiReadAll(h);
    wasiClose(h);
    val b = try okBytes(r);
    return b;
}

fn writeBytesWasm(path: string, contents: bytes) -> Result<i32, HostError> {
    val p = try resolve(path);
    val h = wasiOpen(p, 1);
    if (h < 0) throw wasiError(-1 - h);
    val n = wasiWrite(h, contents);
    wasiClose(h);
    if (n < 0) throw wasiError(-1 - n);
    return 0;
}

fn writeTextWasm(path: string, contents: string) -> Result<i32, HostError> {
    val n = try writeBytesWasm(path, bytes.fromUtf8(contents));
    return n;
}

fn appendTextWasm(path: string, contents: string) -> Result<i32, HostError> {
    val p = try resolve(path);
    val h = wasiOpen(p, 2);
    if (h < 0) throw wasiError(-1 - h);
    val at = wasiSizeRaw(h);
    if (at < 0l) {
        wasiClose(h);
        throw wasiError(13);
    }
    wasiSeek(h, at);
    val n = wasiWrite(h, bytes.fromUtf8(contents));
    wasiClose(h);
    if (n < 0) throw wasiError(-1 - n);
    return 0;
}

// The offset of the first byte that starts a sequence that is not UTF-8, `-1` when there is none.
fn utf8OffsetWasm(data: bytes) -> i64 {
    val n = data.length();
    var i = 0;
    while (i < n) {
        val c = wasiByteAt(data, i);
        if (c < 128) {
            i = i + 1;
            continue;
        }
        var k = 0;
        if (c >= 194 && c <= 223) {
            k = 1;
        } else if (c >= 224 && c <= 239) {
            k = 2;
        } else if (c >= 240 && c <= 244) {
            k = 3;
        } else {
            return i.toI64();
        }
        if (i + k >= n) return i.toI64();
        var lo = 128;
        var hi = 191;
        if (c == 224) {
            lo = 160;
        } else if (c == 237) {
            hi = 159;
        } else if (c == 240) {
            lo = 144;
        } else if (c == 244) {
            hi = 143;
        }
        val d = wasiByteAt(data, i + 1);
        if (d < lo || d > hi) return i.toI64();
        var j = 2;
        while (j <= k) {
            val e = wasiByteAt(data, i + j);
            if (e < 128 || e > 191) return i.toI64();
            j = j + 1;
        }
        i = i + k + 1;
    }
    return -1l;
}

fn stripEolWasm(line: bytes) -> bytes {
    var n = line.length();
    if (n > 0 && wasiByteAt(line, n - 1) == 10) {
        n = n - 1;
        if (n > 0 && wasiByteAt(line, n - 1) == 13) n = n - 1;
    }
    return line.slice(0, n);
}

fn openWasm(path: string) -> Result<unknown, HostError> {
    val p = try resolve(path);
    val h = wasiOpen(p, 0);
    if (h < 0) throw wasiError(-1 - h);
    val handle: unknown = h;
    return handle;
}

fn createWasm(path: string) -> Result<unknown, HostError> {
    val p = try resolve(path);
    val h = wasiOpen(p, 1);
    if (h < 0) throw wasiError(-1 - h);
    val handle: unknown = h;
    return handle;
}

fn memHandleWasm(data: bytes) -> unknown {
    val handle: unknown = wasiOpenMem(data);
    return handle;
}

fn sizeWasm(handle: unknown, path: string) -> Result<i64, HostError> {
    val n = try okSize(wasiSize(blockOf(handle)));
    return n;
}

fn readWasm(handle: unknown, n: i32) -> Result<bytes, HostError> {
    val b = try okBytes(wasiRead(blockOf(handle), n));
    return b;
}

fn readAllWasm(handle: unknown) -> Result<bytes, HostError> {
    val b = try okBytes(wasiReadAll(blockOf(handle)));
    return b;
}

fn readLineWasm(handle: unknown) -> Result<bytes, HostError> {
    val b = try okBytes(wasiReadLine(blockOf(handle)));
    return b;
}

// The SHA-256 of the whole file, the position where it was.
fn hashWasm(handle: unknown) -> Result<string, HostError> {
    val block = blockOf(handle);
    val at = wasiTell(block);
    wasiSeek(block, 0l);
    val r = wasiReadAll(block);
    wasiSeek(block, at);
    val b = try okBytes(r);
    return wasiSha256(b);
}

fn writeWasm(handle: unknown, data: bytes) -> Result<i32, HostError> {
    val n = wasiWrite(blockOf(handle), data);
    if (n < 0) throw wasiError(-1 - n);
    return n;
}

fn closeWasm(handle: unknown) -> Result<i32, HostError> {
    wasiClose(blockOf(handle));
    return 0;
}

fn readOnlyWasm(handle: unknown) -> bool {
    return wasiIsMem(blockOf(handle));
}

fn existsWasm(path: string) -> bool {
    return case resolve(path) {
        Ok(p) -> wasiStatKind(p, 1) >= 0;
        Error(_) -> false;
    };
}

fn listWasm(path: string) -> Result<string[], HostError> {
    val p = try resolve(path);
    val names = try okStrings(wasiList(p));
    return sortedStrings(names);
}

fn mkdirWasm(path: string) -> Result<i32, HostError> {
    val p = try resolve(path);
    val r = wasiMkdir(p);
    if (r < 0) throw wasiError(-1 - r);
    return 0;
}

// The directory and every missing one above it. One that is there is `Ok`; a file in the way is
// `EEXIST` when it is the directory asked for, `ENOTDIR` when it is above it.
fn mkdirRecursiveWasm(path: string) -> Result<i32, HostError> {
    val p = try resolve(path);
    var parts: array<string> = [];
    val pieces = p.split("/");
    var i = 0;
    while (i < pieces.length) {
        val piece = pieces.at(i) ?? "";
        i = i + 1;
        if (piece != "" && piece != ".") parts = parts.append([piece]);
    }
    var prefix = "";
    var k = 0;
    while (k < parts.length) {
        prefix = joinPath(prefix, parts.at(k) ?? "");
        k = k + 1;
        val kind = wasiStatKind(prefix, 1);
        if (kind == 3) continue;
        if (kind >= 0) {
            if (k == parts.length) throw wasiError(7);
            throw wasiError(24);
        }
        val made = wasiMkdir(prefix);
        if (made < 0) throw wasiError(-1 - made);
    }
    return 0;
}

// The FILE at `path`: a directory is `EISDIR`, whatever it holds.
fn rmWasm(path: string) -> Result<i32, HostError> {
    val p = try resolve(path);
    val kind = wasiStatKind(p, 0);
    if (kind < 0) throw wasiError(-1 - kind);
    if (kind == 3) throw wasiError(14);
    val r = wasiUnlink(p);
    if (r < 0) throw wasiError(-1 - r);
    return 0;
}

fn copyWasm(src: string, dest: string) -> Result<i32, HostError> {
    val contents = try readBytesWasm(src);
    val written = try writeBytesWasm(dest, contents);
    return 0;
}

fn statWasm(path: string) -> Result<FileStat, HostError> {
    val p = try resolve(path);
    val kind = wasiStatKind(p, 1);
    if (kind < 0) throw wasiError(-1 - kind);
    val size = try okSize(wasiStatSize(p));
    val seconds = try okSize(wasiStatMtime(p));
    return FileStat(size: size, mtime: seconds * 1000l, isDir: kind == 3);
}

// The regular files under `root` and the links whose target is missing, as paths relative to it, in
// directory order: a work list of directories, not a recursion (a recursive `try` is not lowered on wasm).
fn walkWasm(root: string) -> Result<Walked, HostError> {
    val p = try resolve(root);
    val kind = wasiStatKind(p, 1);
    if (kind < 0) throw wasiError(-1 - kind);
    if (kind != 3) throw wasiError(24);
    var dirs: array<string> = [p];
    var rels: array<string> = [""];
    var files: array<string> = [];
    var dangling: array<string> = [];
    var next = 0;
    while (next < dirs.length) {
        val dir = dirs.at(next) ?? "";
        val rel = rels.at(next) ?? "";
        next = next + 1;
        val names = try okStrings(wasiList(dir));
        var i = 0;
        while (i < names.length) {
            val name = names.at(i) ?? "";
            i = i + 1;
            val full = joinPath(dir, name);
            val sub = joinPath(rel, name);
            val entry = wasiStatKind(full, 1);
            if (entry < 0 && entry != -21) throw wasiError(-1 - entry);
            if (entry == 3) {
                dirs = dirs.append([full]);
                rels = rels.append([sub]);
            }
            if (entry == 6) files = files.append([sub]);
            if (entry == -21) dangling = dangling.append([sub]);
        }
    }
    return Walked(files: sortedStrings(files), dangling: sortedStrings(dangling));
}

// Whether the segment holds a wildcard.
fn isMagic(seg: string) -> bool {
    return seg.contains("*") || seg.contains("?") || seg.contains("[") || seg.contains("{");
}

// A segment with its `{a,b}` alternatives written out, nested ones too; one that is never closed is a name.
fn expandBraces(seg: string) -> array<string> {
    val cs = seg.chars();
    var open = -1;
    var i = 0;
    while (i < cs.length) {
        if ((cs.at(i) ?? "") == "{") {
            open = i;
            break;
        }
        i = i + 1;
    }
    if (open < 0) return [seg];
    var depth = 0;
    var close = -1;
    var cuts: array<i32> = [];
    var j = open;
    var closed = false;
    while (j < cs.length && !closed) {
        val c = cs.at(j) ?? "";
        // Separate `if`s, not an `else if` chain: wasm's GC lowering refuses
        // an `if` nesting one beside an `else if` that appends (B-170).
        if (c == "{") depth = depth + 1;
        if (c == "}") depth = depth - 1;
        if (c == "}" && depth == 0) {
            close = j;
            closed = true;
        }
        if (c == "," && depth == 1) cuts = cuts.append([j]);
        j = j + 1;
    }
    if (close < 0) return [seg];
    val head = cs.slice(0, open).join("");
    val tail = cs.slice(close + 1).join("");
    var out: array<string> = [];
    var start = open + 1;
    var k = 0;
    while (k <= cuts.length) {
        var stop = close;
        if (k < cuts.length) stop = cuts.at(k) ?? close;
        val alt = cs.slice(start, stop).join("");
        out = out.append(expandBraces(head + alt + tail));
        start = stop + 1;
        k = k + 1;
    }
    return out;
}

// The `]` that closes the class opened at `at`, `-1` when there is none (the `[` is then a name).
fn classEnd(pat: array<string>, at: i32) -> i32 {
    var j = at + 1;
    if (j < pat.length && ((pat.at(j) ?? "") == "!" || (pat.at(j) ?? "") == "^")) j = j + 1;
    if (j < pat.length && (pat.at(j) ?? "") == "]") j = j + 1;
    while (j < pat.length) {
        if ((pat.at(j) ?? "") == "]") return j;
        j = j + 1;
    }
    return -1;
}

// Whether `ch` is in the class written between `first` and `stop` (`!` or `^` first negates it, `a-z` is a range).
fn classHas(pat: array<string>, first: i32, stop: i32, ch: string) -> bool {
    var i = first;
    var negate = false;
    if (i < stop && ((pat.at(i) ?? "") == "!" || (pat.at(i) ?? "") == "^")) {
        negate = true;
        i = i + 1;
    }
    var found = false;
    while (i < stop) {
        val lo = pat.at(i) ?? "";
        if (i + 2 < stop && (pat.at(i + 1) ?? "") == "-") {
            val hi = pat.at(i + 2) ?? "";
            // By code point: a class range is one character each side, and
            // wasm lowers no ordering of strings (B-170).
            val c = ch.charCodeAt(0);
            if (lo.charCodeAt(0) <= c && c <= hi.charCodeAt(0)) found = true;
            i = i + 3;
        } else {
            if (lo == ch) found = true;
            i = i + 1;
        }
    }
    return found != negate;
}

// `name` against one pattern without braces: `*`, `?`, `[…]`.
fn globMatch(pat: array<string>, begin: i32, name: array<string>, offset: i32) -> bool {
    var p = begin;
    var n = offset;
    while (p < pat.length) {
        val c = pat.at(p) ?? "";
        if (c == "*") {
            while (p < pat.length && (pat.at(p) ?? "") == "*") {
                p = p + 1;
            }
            if (p == pat.length) return true;
            var k = n;
            while (k <= name.length) {
                if (globMatch(pat, p, name, k)) return true;
                k = k + 1;
            }
            return false;
        }
        if (n >= name.length) return false;
        val ch = name.at(n) ?? "";
        if (c == "?") {
            p = p + 1;
            n = n + 1;
        } else if (c == "[") {
            val end = classEnd(pat, p);
            if (end < 0) {
                if (ch != "[") return false;
                p = p + 1;
                n = n + 1;
            } else {
                if (!classHas(pat, p + 1, end, ch)) return false;
                p = end + 1;
                n = n + 1;
            }
        } else {
            if (c != ch) return false;
            p = p + 1;
            n = n + 1;
        }
    }
    return n == name.length;
}

fn segmentMatches(seg: string, name: string) -> bool {
    val alts = expandBraces(seg);
    val chars = name.chars();
    var i = 0;
    while (i < alts.length) {
        if (globMatch((alts.at(i) ?? "").chars(), 0, chars, 0)) return true;
        i = i + 1;
    }
    return false;
}

// The names in `dir` the segment matches; a dot name only when the segment itself begins with the dot.
fn globNames(dir: string, seg: string) -> array<string> {
    val listed: array<string> = case wasiList(dir) {
        Ok(xs) -> xs;
        Error(_) -> [];
    };
    var out: array<string> = [];
    var i = 0;
    while (i < listed.length) {
        val name = listed.at(i) ?? "";
        i = i + 1;
        if (name.startsWith(".") && !seg.startsWith(".")) continue;
        if (seg == "*" || segmentMatches(seg, name)) out = out.append([name]);
    }
    return out;
}

// The entries `segs` from `i` match under `dir` (`rel` its path from the root of the glob), added to `out`. A
// wildcard continues into real directories only; a name goes through a link.
fn globWalk(segs: array<string>, i: i32, dir: string, rel: string, out: array<string>) -> array<string> {
    var acc = out;
    if (i == segs.length) {
        if (rel != "") acc = acc.append([rel]);
        return acc;
    }
    val seg = segs.at(i) ?? "";
    val last = i == segs.length - 1;
    if (seg == "**") {
        if (!last) acc = globWalk(segs, i + 1, dir, rel, acc);
        val names = globNames(dir, "*");
        var k = 0;
        while (k < names.length) {
            val name = names.at(k) ?? "";
            k = k + 1;
            val full = joinPath(dir, name);
            val sub = joinPath(rel, name);
            if (last) acc = acc.append([sub]);
            if (wasiStatKind(full, 0) == 3) acc = globWalk(segs, i, full, sub, acc);
        }
        return acc;
    }
    if (!isMagic(seg)) {
        val full = joinPath(dir, seg);
        val sub = joinPath(rel, seg);
        if (last) {
            if (wasiStatKind(full, 0) >= 0) acc = acc.append([sub]);
        } else if (wasiStatKind(full, 1) == 3) {
            acc = globWalk(segs, i + 1, full, sub, acc);
        }
        return acc;
    }
    val names = globNames(dir, seg);
    var k = 0;
    while (k < names.length) {
        val name = names.at(k) ?? "";
        k = k + 1;
        val full = joinPath(dir, name);
        val sub = joinPath(rel, name);
        if (last) {
            acc = acc.append([sub]);
        } else if (wasiStatKind(full, 0) == 3) {
            acc = globWalk(segs, i + 1, full, sub, acc);
        }
    }
    return acc;
}

fn globWasm(pattern: string, root: string) -> string[] {
    val resolved = resolve(root);
    if (resolved.isError()) return [];
    val base = resolved.unwrapOr("");
    var segs: array<string> = [];
    val pieces = pattern.split("/");
    var i = 0;
    while (i < pieces.length) {
        val piece = pieces.at(i) ?? "";
        i = i + 1;
        if (piece != "" && piece != ".") segs = segs.append([piece]);
    }
    val found = globWalk(segs, 0, base, "", []);
    var kept: array<string> = [];
    var k = 0;
    while (k < found.length) {
        val entry = found.at(k) ?? "";
        k = k + 1;
        if (!pattern.endsWith("/") || wasiStatKind(joinPath(base, entry), 0) == 3) kept = kept.append([entry]);
    }
    return sortedStrings(kept);
}

// A path that is not there is `Ok`: the caller wanted it gone. A link is removed, never followed. The
// directories are found first, then the files removed, then the directories from the deepest.
fn removeTreeWasm(path: string) -> Result<i32, HostError> {
    val p = try resolve(path);
    val top = wasiStatKind(p, 0);
    if (top == -21) return 0;
    if (top < 0) throw wasiError(-1 - top);
    if (top != 3) {
        val r = wasiUnlink(p);
        if (r < 0) throw wasiError(-1 - r);
        return 0;
    }
    var dirs: array<string> = [p];
    var next = 0;
    while (next < dirs.length) {
        val dir = dirs.at(next) ?? "";
        next = next + 1;
        val names = try okStrings(wasiList(dir));
        var i = 0;
        while (i < names.length) {
            val full = joinPath(dir, names.at(i) ?? "");
            i = i + 1;
            val kind = wasiStatKind(full, 0);
            if (kind < 0 && kind != -21) throw wasiError(-1 - kind);
            if (kind == 3) dirs = dirs.append([full]);
            if (kind >= 0 && kind != 3) {
                val r = wasiUnlink(full);
                if (r < 0) throw wasiError(-1 - r);
            }
        }
    }
    var k = dirs.length;
    while (k > 0) {
        k = k - 1;
        val r = wasiRmdir(dirs.at(k) ?? "");
        if (r < 0) throw wasiError(-1 - r);
    }
    return 0;
}

// A fresh, unique, empty directory under the host's temporary directory.
fn scratchDirWasm() -> string {
    var base = wasiGetenv("TMPDIR");
    if (base == "") base = "/tmp";
    var attempt = 0;
    while (attempt < 100) {
        val dir = base + "/bp-std-fs-" + random.randomBytes(6);
        if (wasiMkdir(withoutRoot(dir)) == 0) return dir;
        attempt = attempt + 1;
    }
    failure.panic("io.fs: no scratch directory could be made");
    return base;
}

fn workingDirWasm() -> string {
    val cwd = wasiCwd();
    if (cwd == "") return "/";
    return cwd;
}

fn linkToWasm(target: string, link: string) -> void {
    val l = resolve(link);
    if (l.isError()) failure.panic("io.fs: no link path");
    val r = wasiSymlink(target, l.unwrapOr(""));
    if (r < 0) failure.panic(wasiError(-1 - r).message);
    return;
}

// A host without `chmod` denies this user nothing: the permission tests have nothing to check there.
fn denyAllWasm(path: string) -> bool {
    return false;
}

fn allowAllWasm(path: string) -> void {
    return;
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
    .Wasm(body: denyAllWasm),
)]
declare fn denyAll(path: string) -> bool;

#[compiler.external(
    .JavaScript("""require('fs').chmodSync($0, 0o700)"""),
    .Erlang("""(fun(__P) -> ok = file:change_mode(__P, 8#700), ok end)($0)"""),
    .Wasm(body: allowAllWasm),
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

----- WASM TEXT -- std/io/fs.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $box_i32 (sub (struct (field $v i32))))
    (type $box_i64 (struct (field $v i64)))
    (type $arr_any (array (mut anyref)))
    (type $arr_i32 (array (mut i32)))
    (type $closure (sub (struct (field $idx i32) (field $mark i32))))
    (type $rec_Failure (struct (field $f0 (mut (ref null $str))) (field $f1 (mut (ref null $str)))))
    (type $var_FsError_NotFound (struct (field $f0 (mut (ref null $str)))))
    (type $var_FsError_PermissionDenied (struct (field $f0 (mut (ref null $str)))))
    (type $var_FsError_IsDirectory (struct (field $f0 (mut (ref null $str)))))
    (type $var_FsError_NotDirectory (struct (field $f0 (mut (ref null $str)))))
    (type $var_FsError_AlreadyExists (struct (field $f0 (mut (ref null $str)))))
    (type $var_FsError_InvalidUtf8 (struct (field $f0 (mut (ref null $str))) (field $f1 (mut i64))))
    (type $var_FsError_Other (struct (field $f0 (mut (ref null $str))) (field $f1 (mut (ref null $str)))))
    (type $rec_HostError (struct (field $f0 (mut (ref null $str))) (field $f1 (mut (ref null $str))) (field $f2 (mut i32)) (field $f3 (mut (ref null $str)))))
    (type $rec_FileStat (struct (field $f0 (mut i64)) (field $f1 (mut i64)) (field $f2 (mut i32))))
    (type $rec_Walked (struct (field $f0 (mut (ref null $arr_any))) (field $f1 (mut (ref null $arr_any)))))
    (type $rec_File (struct (field $f0 (mut (ref null $str))) (field $f1 (mut anyref))))
    (type $gen (struct (field $state (mut i32)) (field $kind i32) (field $frame (mut structref)) (field $value (mut anyref)) (field $src (mut (ref null $gen))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $frame0 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $rec_File))) (field $s1 (mut i32)) (field $s2 (mut (ref null $str))) (field $s3 (mut (ref null $result))) (field $s4 (mut i32))))
    (type $frame1 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $rec_File))) (field $s1 (mut i32)) (field $s2 (mut i32)) (field $s3 (mut (ref null $str))) (field $s4 (mut (ref null $str))) (field $s5 (mut i64)) (field $s6 (mut i32)) (field $s7 (mut (ref null $result))) (field $s8 (mut i32)) (field $s9 (mut i32)) (field $s10 (mut i32)) (field $s11 (mut (ref null $result))) (field $s12 (mut (ref null $str))) (field $s13 (mut (ref null $str))) (field $s14 (mut i32))))
    (type $rec_Asset (struct (field $f0 (mut (ref null $str))) (field $f1 (mut (ref null $str))) (field $f2 (mut i64)) (field $f3 (mut (ref null $str)))))
    (type $box_bool (sub final $box_i32 (struct (field $v i32))))
    (type $box_f64 (struct (field $v f64)))
  )
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "random_get" (func $random_get (param i32 i32) (result i32)))
  (import "bp_fs" "open" (func $__fs_open (param i32 i32 i32) (result i32)))
  (import "bp_fs" "close" (func $__fs_close (param i32)))
  (import "bp_fs" "read" (func $__fs_read (param i32 i64 i32 i32) (result i32)))
  (import "bp_fs" "write" (func $__fs_write (param i32 i64 i32 i32) (result i32)))
  (import "bp_fs" "stat" (func $__fs_stat (param i32 i32) (result i32)))
  (import "bp_fs" "stat_at" (func $__fs_stat_at (param i32 i32 i32 i32) (result i32)))
  (import "bp_fs" "readdir_open" (func $__fs_readdir_open (param i32 i32) (result i32)))
  (import "bp_fs" "readdir_next" (func $__fs_readdir_next (param i32 i32 i32) (result i32)))
  (import "bp_fs" "readdir_close" (func $__fs_readdir_close (param i32)))
  (import "bp_fs" "mkdir" (func $__fs_mkdir (param i32 i32) (result i32)))
  (import "bp_fs" "rmdir" (func $__fs_rmdir (param i32 i32) (result i32)))
  (import "bp_fs" "unlink" (func $__fs_unlink (param i32 i32) (result i32)))
  (import "bp_fs" "symlink" (func $__fs_symlink (param i32 i32 i32 i32) (result i32)))
  (import "bp_fs" "getenv" (func $__fs_getenv (param i32 i32 i32 i32) (result i32)))
  (import "bp_fs" "cwd" (func $__fs_cwd (param i32 i32) (result i32)))
  (memory (export "memory") 1)
  (start $__init_strs)
  (global $__heap_ptr (mut i32) (i32.const 9152))
  (global $separator (mut (ref null $str)) (ref.null $str))
  (global $delimiter (mut (ref null $str)) (ref.null $str))
  (func $split (param $path (ref null $str)) (result (ref null $arr_any))
    (local $raw (ref null $arr_any))
    (local $__gc0 (ref null $str))
    (local $__gc1 (ref null $str))
    (local $__gc2 i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $str))
    (local $__out0 (ref null $arr_any))
    local.get $path
    global.get $separator
    local.set $__gc0
    local.set $__gc1
    global.get $__heap_ptr
    local.set $__gc2
    local.get $__gc1
    call $__gc_to_lin_str
    local.get $__gc0
    call $__gc_to_lin_str
    call $__std_text_split
    call $__lin_to_gc_strs
    local.get $__gc2
    global.set $__heap_ptr
    local.set $raw
    local.get $raw
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
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
        array.get $arr_any
    ref.cast (ref null $str)
        local.set $p
    local.get $p
    global.get $__s0
    call $__str_eq
    i32.eqz
    (if
      (then
    local.get $__out0
    local.get $__acc0
    local.get $__iter0
    local.get $__idx0
    array.get $arr_any
    array.set $arr_any
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
    i32.const 0
    local.get $__acc0
    call $__arr_slice_any
    return
  )
  (func $isAbsolute (param $path (ref null $str)) (result i32)
    (local $__gc3 (ref null $str))
    (local $__gc4 (ref null $str))
    (local $__gc5 i32)
    local.get $path
    global.get $separator
    local.set $__gc3
    local.set $__gc4
    global.get $__heap_ptr
    local.set $__gc5
    local.get $__gc4
    call $__gc_to_lin_str
    local.get $__gc3
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc5
    global.set $__heap_ptr
    return
  )
  (func $join (param $parts (ref null $arr_any)) (result (ref null $str))
    (local $__mem0 i32)
    (local $isAbs i32)
    (local $__bp_nullish i32)
    (local $collapsed (ref null $arr_any))
    (local $joined (ref null $str))
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__0 (ref null $str))
    (local $__iter1 (ref null $arr_any))
    (local $__idx1 i32)
    (local $__len1 i32)
    (local $__acc1 i32)
    (local $p (ref null $str))
    (local $__out1 (ref null $arr_any))
    (local $__iter2 (ref null $arr_any))
    (local $__idx2 i32)
    (local $__len2 i32)
    (local $__acc2 i32)
    (local $__out2 (ref null $arr_any))
    local.get $parts
    array.len
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    i32.const 0
      )
      (else
    local.get $parts
    i32.const 0
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__0
    local.get $__bp_nullish__0
      )
      (else
    global.get $__s0
      )
    )
    call $isAbsolute
      )
    )
    local.set $isAbs
    local.get $parts
    local.set $__iter1
    local.get $__iter1
    array.len
    local.set $__len1
    i32.const 0
    local.set $__idx1
    local.get $__len1
    array.new_default $arr_any
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
        array.get $arr_any
    ref.cast (ref null $str)
        local.set $p
    local.get $__out1
    local.get $__idx1
    local.get $p
    call $split
    global.get $separator
    call $__arr_join_any
    array.set $arr_any
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
    array.len
    local.set $__len2
    i32.const 0
    local.set $__idx2
    local.get $__len2
    array.new_default $arr_any
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
        array.get $arr_any
    ref.cast (ref null $str)
        local.set $p
    local.get $p
    global.get $__s0
    call $__str_eq
    i32.eqz
    (if
      (then
    local.get $__out2
    local.get $__acc2
    local.get $__iter2
    local.get $__idx2
    array.get $arr_any
    array.set $arr_any
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
    i32.const 0
    local.get $__acc2
    call $__arr_slice_any
    global.get $separator
    call $__arr_join_any
    local.set $joined
    local.get $isAbs
    (if (result (ref null $str))
      (then
    global.get $separator
    local.get $joined
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
      )
      (else
    local.get $joined
      )
    )
    return
  )
  (func $commonPrefixCount (param $a (ref null $arr_any)) (param $b (ref null $arr_any)) (param $i i32) (result i32)
    (local $ai (ref null $str))
    (local $__bp_nullish i32)
    (local $bi (ref null $str))
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__1 (ref null $str))
    (local $__opt1 (ref null $str))
    (local $__bp_nullish__2 (ref null $str))
    local.get $i
    local.get $a
    array.len
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
    array.len
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
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__1
    local.get $__bp_nullish__1
      )
      (else
    global.get $__s0
      )
    )
    local.set $ai
    local.get $b
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt1
    local.set $__bp_nullish__2
    local.get $__bp_nullish__2
      )
      (else
    global.get $__s0
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
    global.get $__s1
    call $__i32_add_chk
    call $commonPrefixCount
      )
      (else
    local.get $i
      )
    )
    return
  )
  (func $makeUps (param $n i32) (result (ref null $arr_any))
    (local $__mem0 i32)
    local.get $n
    i32.const 0
    i32.le_s
    (if (result (ref null $arr_any))
      (then
    array.new_fixed $arr_any 0
      )
      (else
    local.get $n
    i32.const 1
    global.get $__s2
    call $__i32_sub_chk
    call $makeUps
    global.get $__s3
    call $__arr_prepend_any
      )
    )
    return
  )
  (func $relative (param $src (ref null $str)) (param $dst (ref null $str)) (result (ref null $str))
    (local $srcParts (ref null $arr_any))
    (local $dstParts (ref null $arr_any))
    (local $common i32)
    (local $ups (ref null $arr_any))
    (local $downs (ref null $arr_any))
    (local $combined (ref null $arr_any))
    (local $joined (ref null $str))
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
    array.len
    local.get $common
    global.get $__s4
    call $__i32_sub_chk
    call $makeUps
    local.set $ups
    local.get $dstParts
    local.get $common
    local.get $dstParts
    array.len
    call $__arr_slice_any
    local.set $downs
    local.get $ups
    local.get $downs
    call $__arr_concat_any
    local.set $combined
    local.get $combined
    global.get $separator
    call $__arr_join_any
    local.set $joined
    local.get $joined
    global.get $__s0
    call $__str_eq
    (if (result (ref null $str))
      (then
    global.get $__s5
      )
      (else
    local.get $joined
      )
    )
    return
  )
  ;; declare fn panic — no wasm implementation (host-backed)
  ;; attempt — .Wasm(body: attemptOnWasm)
  ;; float — .Wasm(std: "random.float")
  (func $float (result f64)
    call $__std_random_float
  )
  ;; randomBytes — .Wasm(body: randomBytesBody)
  (func $randomBytes (param $n i32) (result (ref null $str))
    local.get $n
    call $randomBytesBody
  )
  (func $randomBytesBody (param $n i32) (result (ref null $str))
    local.get $n
    call $randomBytesOf
    call $hexOf
    return
  )
  (func $randomByte (result i32)
    call $float
    f64.const 256.0
    f64.mul
    f64.floor
    call $wholeOf
    return
  )
  (func $randomBytesOf (param $n i32) (result (ref null $arr_i32))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $out (ref null $arr_i32))
    (local $i i32)
    array.new_fixed $arr_i32 0
    local.set $out
    i32.const 0
    local.set $i
    (block $__break
      (loop $__continue
    local.get $i
    local.get $n
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $out
    call $randomByte
    array.new_fixed $arr_i32 1
    call $__arr_concat_i32
    local.set $out
    local.get $i
    i32.const 1
    global.get $__s7
    call $__i32_add_chk
    local.set $i
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $out
    return
  )
  (func $hexDigit (param $n i32) (result (ref null $str))
    (local $__bp_nullish i32)
    (local $__opt0 (ref null $str))
    (local $__gc6 i32)
    (local $__gc7 (ref null $str))
    (local $__gc8 i32)
    (local $__gc9 i32)
    (local $__bp_nullish__5 (ref null $str))
    global.get $__s8
    local.get $n
    local.set $__gc6
    local.set $__gc7
    global.get $__heap_ptr
    local.set $__gc8
    local.get $__gc7
    call $__gc_to_lin_str
    local.get $__gc6
    call $__std_text_at
    local.tee $__gc9
    i32.eqz
    (if (result (ref null $str))
      (then
    ref.null $str
      )
      (else
    local.get $__gc9
    call $__lin_to_gc_str
      )
    )
    local.get $__gc8
    global.set $__heap_ptr
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__5
    local.get $__bp_nullish__5
      )
      (else
    global.get $__s0
      )
    )
    return
  )
  (func $hexOf (param $bytes (ref null $arr_i32)) (result (ref null $str))
    (local $__iter0 (ref null $arr_i32))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $b i32)
    (local $__out0 (ref null $arr_any))
    local.get $bytes
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
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
        array.get $arr_i32
        local.set $b
    local.get $__out0
    local.get $__idx0
    local.get $b
    i32.const 16
    global.get $__s9
    global.get $__s10
    call $__i32_divs
    call $hexDigit
    local.get $b
    i32.const 16
    global.get $__s11
    call $__i32_nz
    i32.rem_s
    call $hexDigit
    call $__str_concat
    array.set $arr_any
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    global.get $__s0
    call $__arr_join_any
    return
  )
  (func $wholeOf (param $v f64) (result i32)
    (local $r i32)
    (local $rest f64)
    (local $bit i32)
    (local $weight f64)
    i32.const 0
    local.set $r
    local.get $v
    local.set $rest
    i32.const 1073741824
    local.set $bit
    f64.const 1073741824.0
    local.set $weight
    (block $__break
      (loop $__continue
    local.get $bit
    i32.const 0
    i32.gt_s
        i32.eqz
        br_if $__break
    local.get $rest
    local.get $weight
    f64.ge
    (if (result i32)
      (then
    local.get $r
    local.get $bit
    global.get $__s12
    call $__i32_add_chk
    local.set $r
    local.get $rest
    local.get $weight
    f64.sub
    local.set $rest
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $bit
    i32.const 2
    global.get $__s13
    global.get $__s14
    call $__i32_divs
    local.set $bit
    local.get $weight
    f64.const 2.0
    f64.div
    local.set $weight
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $r
    return
  )
  ;; std/io/fs — the file system, cross-backend (decision 540).
  ;; 
  ;; Reference:
  ;;   Rust     — https://doc.rust-lang.org/std/fs/ (`read`, `read_to_string`,
  ;;              `File`, `io::ErrorKind`)
  ;;   Java     — https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/nio/file/Files.html
  ;;   Erlang   — https://www.erlang.org/doc/man/file.html
  ;;   Node.js  — https://nodejs.org/api/fs.html
  ;; 
  ;; Every function that can fail answers `Result<…, FsError>`: the same OS error is
  ;; the same `FsError` variant on every target (`ENOENT`, `enoent` → `NotFound`),
  ;; and `Other.message` is the host's own text. The whole-file shortcuts
  ;; (`readBytes`, `readText`, `writeBytes`, `writeText`, `appendText`), `stat`, and
  ;; the directory functions (`exists`, `list`, `mkdir`, `mkdirRecursive`, `rm`,
  ;; `removeTree`, `copy`, `walk`, `glob`) are followed by the handle: `open`
  ;; and `create` answer a `File`, a `Closeable` closed by the writer with `defer`.
  ;; 
  ;; The host cells (`raw…`) write `result: true` (decisions 431, 490) and answer
  ;; `Result<R, HostError>` — Node's `ENOENT: …`, erlang's `enoent` as its `message` —
  ;; and `lift` reads that message as the `FsError` of the path the caller wrote
  ;; (decision 486); no cell catches by hand. All operations are synchronous
  ;; (`*Sync` on Node, blocking BIFs on Erlang, `wasi:filesystem` on wasm: the runner
  ;; preopens the root and the working directory, decision 992), and a path is read as
  ;; the process reads it — a relative one against the working directory — on every target.
  ;; The error of every `io.fs` function (decision 540). `path` is the path the
  ;; caller wrote (for `copy`, the source; for `walk`, the root).
  (func $FsError_message (param $self anyref) (result (ref null $str))
    (local $path (ref null $str))
    (local $offset i64)
    (local $message (ref null $str))
    (local $__case_0 anyref)
    local.get $self
    local.set $__case_0
    local.get $__case_0
    ref.test (ref null $var_FsError_NotFound)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_FsError_NotFound)
    struct.get $var_FsError_NotFound $f0
    local.set $path
    global.get $__s15
    local.get $path
    call $__str_concat
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_FsError_PermissionDenied)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_FsError_PermissionDenied)
    struct.get $var_FsError_PermissionDenied $f0
    local.set $path
    global.get $__s16
    local.get $path
    call $__str_concat
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_FsError_IsDirectory)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_FsError_IsDirectory)
    struct.get $var_FsError_IsDirectory $f0
    local.set $path
    global.get $__s17
    local.get $path
    call $__str_concat
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_FsError_NotDirectory)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_FsError_NotDirectory)
    struct.get $var_FsError_NotDirectory $f0
    local.set $path
    global.get $__s18
    local.get $path
    call $__str_concat
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_FsError_AlreadyExists)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_FsError_AlreadyExists)
    struct.get $var_FsError_AlreadyExists $f0
    local.set $path
    global.get $__s19
    local.get $path
    call $__str_concat
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_FsError_InvalidUtf8)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_FsError_InvalidUtf8)
    struct.get $var_FsError_InvalidUtf8 $f0
    local.set $path
    local.get $__case_0
    ref.cast (ref null $var_FsError_InvalidUtf8)
    struct.get $var_FsError_InvalidUtf8 $f1
    local.set $offset
    global.get $__s20
    local.get $path
    call $__str_concat
    global.get $__s21
    call $__str_concat
    local.get $offset
    call $__std_number_i64ToString
    call $__str_concat
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_FsError_Other)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_FsError_Other)
    struct.get $var_FsError_Other $f0
    local.set $path
    local.get $__case_0
    ref.cast (ref null $var_FsError_Other)
    struct.get $var_FsError_Other $f1
    local.set $message
    local.get $path
    global.get $__s22
    call $__str_concat
    local.get $message
    call $__str_concat
      )
      (else
    ref.null $str
      )
    )
      )
    )
      )
    )
      )
    )
      )
    )
      )
    )
      )
    )
    return
  )
  ;; Read the whole file as bytes.
  ;; Node: `readFileSync($0)` copied into a plain `Uint8Array`.
  ;; Erlang: `file:read_file/1`.
  ;; rawReadBytes — .Wasm(body: readBytesWasm)
  (func $rawReadBytes (param $path (ref null $str)) (result (ref null $result))
    local.get $path
    call $readBytesWasm
  )
  ;; Write `contents` to `path`, creating or truncating.
  ;; Node: `writeFileSync($0, $1)`. Erlang: `file:write_file/2`.
  ;; rawWriteBytes — .Wasm(body: writeBytesWasm)
  (func $rawWriteBytes (param $path (ref null $str)) (param $contents (ref null $str)) (result (ref null $result))
    local.get $path
    local.get $contents
    call $writeBytesWasm
  )
  ;; Append `contents` to `path`, creating it when it is not there.
  ;; Node: `appendFileSync($0, $1)`. Erlang: `file:write_file/3` with `append`.
  ;; rawAppendText — .Wasm(body: appendTextWasm)
  (func $rawAppendText (param $path (ref null $str)) (param $contents (ref null $str)) (result (ref null $result))
    local.get $path
    local.get $contents
    call $appendTextWasm
  )
  ;; The offset of the first byte that starts a sequence that is not UTF-8 (a byte no sequence
  ;; starts with, a sequence cut short, an overlong form, a surrogate, a code point past U+10FFFF),
  ;; or -1 when every byte is part of a valid sequence — the same offset on every target.
  ;; Node: a scan of the bytes. Erlang: `unicode:characters_to_binary/3`, whose `Good` prefix is the offset.
  ;; utf8Offset — .Wasm(body: utf8OffsetWasm)
  (func $utf8Offset (param $bytes (ref null $str)) (result i64)
    local.get $bytes
    call $utf8OffsetWasm
  )
  ;; `line` without its line terminator: one trailing `\n`, and the `\r` before it.
  ;; Node: `subarray`. Erlang: `binary:part/3`.
  ;; stripEol — .Wasm(body: stripEolWasm)
  (func $stripEol (param $line (ref null $str)) (result (ref null $str))
    local.get $line
    call $stripEolWasm
  )
  ;; The handle of the file at `path`, open for reading. A directory is `isdir` on both hosts
  ;; (Node opens one; the template refuses it). The handle is host-owned and opaque: a `{ fd,
  ;; mem, pos, buf }` object on Node, an io device on Erlang (a stream reads it in its own process).
  ;; rawOpen — .Wasm(body: openWasm)
  (func $rawOpen (param $path (ref null $str)) (result (ref null $result))
    local.get $path
    call $openWasm
  )
  ;; The handle of the file at `path`, open for writing: created, or truncated.
  ;; rawCreate — .Wasm(body: createWasm)
  (func $rawCreate (param $path (ref null $str)) (result (ref null $result))
    local.get $path
    call $createWasm
  )
  ;; A handle over bytes held in memory — what an `Asset` opens as. The position is a field
  ;; on Node and a `counters` cell on Erlang.
  ;; memHandle — .Wasm(body: memHandleWasm)
  (func $memHandle (param $bytes (ref null $str)) (result anyref)
    local.get $bytes
    call $memHandleWasm
  )
  ;; The size of the file behind `handle`, in bytes. On Erlang it reads `path`.
  ;; rawSize — .Wasm(body: sizeWasm)
  (func $rawSize (param $handle anyref) (param $path (ref null $str)) (result (ref null $result))
    local.get $handle
    local.get $path
    call $sizeWasm
  )
  ;; Up to `n` bytes (n > 0) from the handle's position; empty at the end.
  ;; rawRead — .Wasm(body: readWasm)
  (func $rawRead (param $handle anyref) (param $n i32) (result (ref null $result))
    local.get $handle
    local.get $n
    call $readWasm
  )
  ;; Every byte from the handle's position to the end.
  ;; rawReadAll — .Wasm(body: readAllWasm)
  (func $rawReadAll (param $handle anyref) (result (ref null $result))
    local.get $handle
    call $readAllWasm
  )
  ;; The next line, terminator included; empty at the end.
  ;; rawReadLine — .Wasm(body: readLineWasm)
  (func $rawReadLine (param $handle anyref) (result (ref null $result))
    local.get $handle
    call $readLineWasm
  )
  ;; The SHA-256 of the whole file behind the handle, lowercase hex — from its first byte,
  ;; whatever the position, which it leaves where it was. On Erlang `file:pread` leaves the
  ;; position undefined (OTP moves it), so the position is read first and restored.
  ;; rawHash — .Wasm(body: hashWasm)
  (func $rawHash (param $handle anyref) (result (ref null $result))
    local.get $handle
    call $hashWasm
  )
  ;; Write `bytes` at the handle's position; answers how many.
  ;; rawWrite — .Wasm(body: writeWasm)
  (func $rawWrite (param $handle anyref) (param $bytes (ref null $str)) (result (ref null $result))
    local.get $handle
    local.get $bytes
    call $writeWasm
  )
  ;; Close the handle. A failure to close is not reported (a `Closeable`'s `close` answers nothing).
  ;; rawClose — .Wasm(body: closeWasm)
  (func $rawClose (param $handle anyref) (result (ref null $result))
    local.get $handle
    call $closeWasm
  )
  ;; Write `contents` to `path`, creating or truncating. Reds with the
  ;; host's I/O error message.
  ;; Node: `require('fs').writeFileSync($0, $1)`.
  ;; Erlang: `file:write_file/2`.
  ;; rawWriteText — .Wasm(body: writeTextWasm)
  (func $rawWriteText (param $path (ref null $str)) (param $contents (ref null $str)) (result (ref null $result))
    local.get $path
    local.get $contents
    call $writeTextWasm
  )
  ;; Whether a path exists, of any kind: a regular file, a directory, a
  ;; character or block device (`/dev/null`), a FIFO or a socket. A symbolic
  ;; link is followed — one whose target is missing is `false`, the answer
  ;; every read through it would give.
  ;; Node: `require('fs').existsSync($0)` (a `stat`).
  ;; Erlang: `file:read_file_info/1` (a `stat`; `filelib:is_file/1`, which it
  ;; replaces, answers only regular files and directories, so `/dev/null`
  ;; was `false` on erlang and `true` on commonJS).
  ;; exists — .Wasm(body: existsWasm)
  (func $exists (export "exists") (param $path (ref null $str)) (result i32)
    local.get $path
    call $existsWasm
  )
  ;; List the names of the directory entries at `path` (relative).
  ;; Node: `require('fs').readdirSync($0)`.
  ;; Erlang: `file:list_dir/1` returns `{ok, [string()]}`, in the directory's
  ;; order: sorted here by bytes (`lists:sort` on binaries), as `readdirSync` and
  ;; wasm's `listWasm` answer them, so every target lists one order (decision 992).
  ;; rawList — .Wasm(body: listWasm)
  (func $rawList (param $path (ref null $str)) (result (ref null $result))
    local.get $path
    call $listWasm
  )
  ;; Create directory at `path`. Use `mkdirRecursive` to create
  ;; intermediate parents.
  ;; Node: `require('fs').mkdirSync($0)`.
  ;; Erlang: `file:make_dir/1`.
  ;; rawMkdir — .Wasm(body: mkdirWasm)
  (func $rawMkdir (param $path (ref null $str)) (result (ref null $result))
    local.get $path
    call $mkdirWasm
  )
  ;; Create the directory at `path` and every missing directory above it. A
  ;; directory that is already there is `Ok` too; a path that exists as anything
  ;; else (a file) is an `Error`. What the snapshot library (`snap`) makes the
  ;; directory of a `.snap` with (decision 391).
  ;; Node: `require('fs').mkdirSync($0, { recursive: true })`.
  ;; Erlang: `filelib:ensure_path/1`.
  ;; rawMkdirRecursive — .Wasm(body: mkdirRecursiveWasm)
  (func $rawMkdirRecursive (param $path (ref null $str)) (result (ref null $result))
    local.get $path
    call $mkdirRecursiveWasm
  )
  ;; Delete the FILE at `path`. A directory — empty or not — is `IsDirectory` on
  ;; both hosts (Node's `ERR_FS_EISDIR`; Erlang's `eperm` is read as `eisdir` after
  ;; a `read_link_info`, so the variant is the same); `removeTree` removes one.
  ;; Node: `require('fs').rmSync($0)`.
  ;; Erlang: `file:delete/1`.
  ;; rawRm — .Wasm(body: rmWasm)
  (func $rawRm (param $path (ref null $str)) (result (ref null $result))
    local.get $path
    call $rmWasm
  )
  ;; Copy file from `src` to `dest`. Reds when `src` is missing or
  ;; `dest` already exists (Node's default `copyFileSync` semantics).
  ;; Node: `require('fs').copyFileSync($0, $1)`.
  ;; Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).
  ;; rawCopy — .Wasm(body: copyWasm)
  (func $rawCopy (param $src (ref null $str)) (param $dest (ref null $str)) (result (ref null $result))
    local.get $src
    local.get $dest
    call $copyWasm
  )
  ;; File metadata. Returns a `FileStat { size, mtime, isDir }` on
  ;; success. `mtime` is epoch milliseconds (matching `time.nowMillis()`);
  ;; `size` is in bytes.
  ;; Node: `statSync($0, { bigint: true })`, so `size` and the nanosecond
  ;; `mtimeNs` arrive exact at any size; `mtime` is `mtimeNs` floored to whole
  ;; seconds, × 1000, and both answer decision 319's canonical form (a `number`
  ;; within ±(2^53 − 1), a `BigInt` beyond) — never a `number` rounded past 2^53.
  ;; Erlang: `file:read_file_info/1` returns a `#file_info` record; the
  ;; template projects the `size`, `mtime`, and `type` fields. Its `mtime` is
  ;; whole seconds × 1000. One value on every target: whole seconds (decision 499).
  ;; rawStat — .Wasm(body: statWasm)
  (func $rawStat (param $path (ref null $str)) (result (ref null $result))
    local.get $path
    call $statWasm
  )
  ;; ── 1.0.10-beta front 01 additions ──────────────────────────────────────────
  ;; Every REGULAR FILE under `root`, recursively, as paths relative to `root`
  ;; with `/` separators, sorted — the same set on both targets (the two hosts
  ;; walk in different orders, so the list is sorted rather than left as found),
  ;; and the same paths however the root is spelled: `dir`, `dir/`, `dir/.`,
  ;; `./dir`, `dir/sub/..`, absolute or relative to the working directory.
  ;; Directories are not listed; a link is followed (a link to a file is listed
  ;; under its own name, a link to a directory is walked). An `Error`: a missing
  ;; or non-directory `root`, a directory under it that cannot be read, and a
  ;; DANGLING link (decision 178) — `fs.walk: dangling link "<relative path>"`,
  ;; the same text on both targets, naming the first one in sorted order.
  ;; Node: `readdirSync(root, { recursive: true })` answers files AND directories
  ;; relative to `root`; the template sorts them, keeps the entries `statSync`
  ;; says are files, and answers the dangling-link `Error` for the first entry
  ;; `statSync` cannot find (`throwIfNoEntry: false`).
  ;; Erlang: the template walks `file:list_dir/1` itself and BUILDS each relative
  ;; path from the names it descended through. It never cuts a prefix off a full
  ;; path: `filelib:fold_files/5` answers full paths `filename:join/2` has
  ;; normalised (`dir/.` + `app` is `dir/app`), so a prefix measured on the root
  ;; as written cut two characters too many when the root ended in `/.`.
  ;; rawWalk — .Wasm(body: walkWasm)
  (func $rawWalk (param $root (ref null $str)) (result (ref null $result))
    local.get $root
    call $walkWasm
  )
  ;; The entries under `root` matching the glob `pattern`, as paths relative to
  ;; `root` with `/` separators, sorted, each once. The pattern is read segment
  ;; by segment, by ONE rule on both targets (decision 177 — the narrower of what
  ;; the two hosts did):
  ;;   - `**` is zero or more directories; a segment with `*`, `?`, `[…]` or
  ;;     `{a,b}` matches the names of one directory; any other segment is a name.
  ;;   - `*` and `**` (and `?`, `[…]`, `{…}`) do NOT match a name that starts
  ;;     with `.` — a segment matches one only when the segment itself starts
  ;;     with the dot (`.*`, `.config/*.json`).
  ;;   - the walk does NOT descend through a link to a directory: `**` and a
  ;;     wildcard segment continue into real directories only. The link is still
  ;;     a NAME — `*` lists it — and a segment that names it (`linked/*.bp`) goes
  ;;     through it, because the pattern wrote it.
  ;;   - the last segment matches an entry of any kind (file, directory, link,
  ;;     dangling or not); a final `**` is every entry at every depth; a trailing
  ;;     `/` keeps real directories only.
  ;; An alternative of `{a,b}` cannot hold a `/` (the pattern is split first). A
  ;; root that does not exist answers `Ok([])`; so does a directory that cannot
  ;; be read. Both cells are the same walk; only the match of ONE segment against
  ;; ONE directory is the host's — `fs.globSync(segment, { cwd })` (Node 22+),
  ;; `filelib:wildcard/2` — with the dot rule applied over its answer, since
  ;; `filelib:wildcard` matches dot names and `globSync` matches `{.a,b}`.
  ;; rawGlob — .Wasm(body: globWasm)
  (func $rawGlob (param $pattern (ref null $str)) (param $root (ref null $str)) (result (ref null $arr_any))
    local.get $pattern
    local.get $root
    call $globWasm
  )
  ;; Remove `path` and everything under it: a file, a link (the link, never its
  ;; target) or a directory tree. A path that is not there is `Ok` too — the
  ;; caller wanted it gone. What a test fixture is cleared with, and what the
  ;; snapshot engine's tests clear their scratch directories with (1.0.11-beta
  ;; front 97).
  ;; Node: `rmSync(path, { recursive: true, force: true })`.
  ;; Erlang: `file:del_dir_r/1`.
  ;; rawRemoveTree — .Wasm(body: removeTreeWasm)
  (func $rawRemoveTree (param $path (ref null $str)) (result (ref null $result))
    local.get $path
    call $removeTreeWasm
  )
  ;; Internal, test scaffolding: a fresh, unique, empty directory under the
  ;; host's tmpdir. Private — every `walk`/`glob` test makes its fixture tree in
  ;; one of these and removes it with `removeTree`, so a run leaves nothing under
  ;; the host's tmpdir.
  ;; scratchDir — .Wasm(body: scratchDirWasm)
  (func $scratchDir (result (ref null $str))
    call $scratchDirWasm
  )
  ;; Internal, test scaffolding: the working directory (what a relative root is
  ;; read against) and a symbolic link `link` → `target`.
  ;; workingDir — .Wasm(body: workingDirWasm)
  (func $workingDir (result (ref null $str))
    call $workingDirWasm
  )
  ;; linkTo — .Wasm(body: linkToWasm)
  (func $linkTo (param $target (ref null $str)) (param $link (ref null $str))
    local.get $target
    local.get $link
    call $linkToWasm
  )
  ;; ── the typed error ──────────────────────────────────────────────────────────
  ;; The `FsError` of `path` a host's failure is (decision 486), read from its code: Node's `ENOENT: …`, erlang's `enoent`.
  (func $fsError (param $path (ref null $str)) (param $e (ref null $rec_HostError)) (result anyref)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    (local $__mem5 i32)
    (local $u (ref null $str))
    (local $__gc10 (ref null $str))
    (local $__gc11 i32)
    (local $__gc12 (ref null $str))
    (local $__gc13 (ref null $str))
    (local $__gc14 i32)
    (local $__gc15 (ref null $str))
    (local $__gc16 (ref null $str))
    (local $__gc17 i32)
    (local $__gc18 (ref null $str))
    (local $__gc19 (ref null $str))
    (local $__gc20 i32)
    (local $__gc21 (ref null $str))
    (local $__gc22 (ref null $str))
    (local $__gc23 i32)
    (local $__gc24 (ref null $str))
    (local $__gc25 (ref null $str))
    (local $__gc26 i32)
    (local $__gc27 (ref null $str))
    (local $__gc28 (ref null $str))
    (local $__gc29 i32)
    (local $__gc30 (ref null $str))
    (local $__gc31 (ref null $str))
    (local $__gc32 i32)
    local.get $e
    struct.get $rec_HostError $f0
    local.set $__gc10
    global.get $__heap_ptr
    local.set $__gc11
    local.get $__gc10
    call $__gc_to_lin_str
    call $__std_text_toUpper
    call $__lin_to_gc_str
    local.get $__gc11
    global.set $__heap_ptr
    local.set $u
    local.get $u
    global.get $__s23
    local.set $__gc12
    local.set $__gc13
    global.get $__heap_ptr
    local.set $__gc14
    local.get $__gc13
    call $__gc_to_lin_str
    local.get $__gc12
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc14
    global.set $__heap_ptr
    (if (result anyref)
      (then
    local.get $path
    struct.new $var_FsError_NotFound
    return
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $u
    global.get $__s24
    local.set $__gc15
    local.set $__gc16
    global.get $__heap_ptr
    local.set $__gc17
    local.get $__gc16
    call $__gc_to_lin_str
    local.get $__gc15
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc17
    global.set $__heap_ptr
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $u
    global.get $__s25
    local.set $__gc18
    local.set $__gc19
    global.get $__heap_ptr
    local.set $__gc20
    local.get $__gc19
    call $__gc_to_lin_str
    local.get $__gc18
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc20
    global.set $__heap_ptr
      )
    )
    (if (result anyref)
      (then
    local.get $path
    struct.new $var_FsError_PermissionDenied
    return
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $u
    global.get $__s26
    local.set $__gc21
    local.set $__gc22
    global.get $__heap_ptr
    local.set $__gc23
    local.get $__gc22
    call $__gc_to_lin_str
    local.get $__gc21
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc23
    global.set $__heap_ptr
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $u
    global.get $__s27
    local.set $__gc24
    local.set $__gc25
    global.get $__heap_ptr
    local.set $__gc26
    local.get $__gc25
    call $__gc_to_lin_str
    local.get $__gc24
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc26
    global.set $__heap_ptr
      )
    )
    (if (result anyref)
      (then
    local.get $path
    struct.new $var_FsError_IsDirectory
    return
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $u
    global.get $__s28
    local.set $__gc27
    local.set $__gc28
    global.get $__heap_ptr
    local.set $__gc29
    local.get $__gc28
    call $__gc_to_lin_str
    local.get $__gc27
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc29
    global.set $__heap_ptr
    (if (result anyref)
      (then
    local.get $path
    struct.new $var_FsError_NotDirectory
    return
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $u
    global.get $__s29
    local.set $__gc30
    local.set $__gc31
    global.get $__heap_ptr
    local.set $__gc32
    local.get $__gc31
    call $__gc_to_lin_str
    local.get $__gc30
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc32
    global.set $__heap_ptr
    (if (result anyref)
      (then
    local.get $path
    struct.new $var_FsError_AlreadyExists
    return
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $path
    local.get $e
    struct.get $rec_HostError $f0
    struct.new $var_FsError_Other
    return
  )
  ;; A host cell's answer, its failure read as an `FsError` of `path`.
  (func $lift (param $path (ref null $str)) (param $r (ref null $result)) (result (ref null $result))
    (local $v i32)
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $v__6 anyref)
    (local $e__7 (ref null $rec_HostError))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    local.set $v__6
    i32.const 0
    local.get $v__6
    struct.new $result
    return
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $rec_HostError)
    local.set $e__7
    i32.const 1
    local.get $path
    local.get $e__7
    call $fsError
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  ;; `lift` for each answer type: the generic one is the wasm backend's to specialise, and a
  ;; `bytes` or a handle it does not (decision 992).
  (func $liftBytes (param $path (ref null $str)) (param $r (ref null $result)) (result (ref null $result))
    (local $v i32)
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $v__8 (ref null $str))
    (local $e__9 (ref null $rec_HostError))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $v__8
    i32.const 0
    local.get $v__8
    struct.new $result
    return
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $rec_HostError)
    local.set $e__9
    i32.const 1
    local.get $path
    local.get $e__9
    call $fsError
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  (func $liftI32 (param $path (ref null $str)) (param $r (ref null $result)) (result (ref null $result))
    (local $v i32)
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $e__10 (ref null $rec_HostError))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $v
    i32.const 0
    local.get $v
    struct.new $box_i32
    struct.new $result
    return
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $rec_HostError)
    local.set $e__10
    i32.const 1
    local.get $path
    local.get $e__10
    call $fsError
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  (func $liftI64 (param $path (ref null $str)) (param $r (ref null $result)) (result (ref null $result))
    (local $v i32)
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $v__11 i64)
    (local $e__12 (ref null $rec_HostError))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $box_i64)
    struct.get $box_i64 $v
    local.set $v__11
    i32.const 0
    local.get $v__11
    struct.new $box_i64
    struct.new $result
    return
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $rec_HostError)
    local.set $e__12
    i32.const 1
    local.get $path
    local.get $e__12
    call $fsError
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  (func $liftString (param $path (ref null $str)) (param $r (ref null $result)) (result (ref null $result))
    (local $v i32)
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $v__13 (ref null $str))
    (local $e__14 (ref null $rec_HostError))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $v__13
    i32.const 0
    local.get $v__13
    struct.new $result
    return
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $rec_HostError)
    local.set $e__14
    i32.const 1
    local.get $path
    local.get $e__14
    call $fsError
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  (func $liftStrings (param $path (ref null $str)) (param $r (ref null $result)) (result (ref null $result))
    (local $v i32)
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $v__15 (ref null $arr_any))
    (local $e__16 (ref null $rec_HostError))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $arr_any)
    local.set $v__15
    i32.const 0
    local.get $v__15
    struct.new $result
    return
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $rec_HostError)
    local.set $e__16
    i32.const 1
    local.get $path
    local.get $e__16
    call $fsError
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  (func $liftStat (param $path (ref null $str)) (param $r (ref null $result)) (result (ref null $result))
    (local $v i32)
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $v__17 (ref null $rec_FileStat))
    (local $e__18 (ref null $rec_HostError))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $rec_FileStat)
    local.set $v__17
    i32.const 0
    local.get $v__17
    struct.new $result
    return
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $rec_HostError)
    local.set $e__18
    i32.const 1
    local.get $path
    local.get $e__18
    call $fsError
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  (func $liftWalked (param $path (ref null $str)) (param $r (ref null $result)) (result (ref null $result))
    (local $v i32)
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $v__19 (ref null $rec_Walked))
    (local $e__20 (ref null $rec_HostError))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $rec_Walked)
    local.set $v__19
    i32.const 0
    local.get $v__19
    struct.new $result
    return
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $rec_HostError)
    local.set $e__20
    i32.const 1
    local.get $path
    local.get $e__20
    call $fsError
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  (func $liftHandle (param $path (ref null $str)) (param $r (ref null $result)) (result (ref null $result))
    (local $v i32)
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $v__21 anyref)
    (local $e__22 (ref null $rec_HostError))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    local.set $v__21
    i32.const 0
    local.get $v__21
    struct.new $result
    return
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $rec_HostError)
    local.set $e__22
    i32.const 1
    local.get $path
    local.get $e__22
    call $fsError
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  ;; The text of `b`, or `InvalidUtf8` at the first invalid byte.
  (func $decode (param $path (ref null $str)) (param $b (ref null $str)) (result (ref null $result))
    (local $__mem0 i32)
    (local $offset i64)
    (local $__gc33 (ref null $result))
    (local $__gc34 (ref null $str))
    (local $__gc35 (ref null $str))
    (local $__gc36 i32)
    local.get $b
    call $utf8Offset
    local.set $offset
    local.get $offset
    i32.const 0
    i64.extend_i32_s
    i64.ge_s
    (if (result (ref null $result))
      (then
    i32.const 1
    local.get $path
    local.get $offset
    struct.new $var_FsError_InvalidUtf8
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    local.get $b
    local.set $__gc34
    local.get $__gc34
    local.set $__gc35
    global.get $__heap_ptr
    local.set $__gc36
    local.get $__gc35
    call $__gc_to_lin_str
    call $__std_bytes_isUtf8
    local.get $__gc36
    global.set $__heap_ptr
    (if (result (ref null $result))
      (then
    i32.const 0
    local.get $__gc34
    struct.new $result
      )
      (else
    i32.const 1
    global.get $__s30
    struct.new $result
      )
    )
    local.tee $__gc33
    struct.get $result $tag
    (if (result (ref null $str))
      (then
    global.get $__s0
      )
      (else
    local.get $__gc33
    struct.get $result $payload
    ref.cast (ref null $str)
      )
    )
    struct.new $result
    return
  )
  ;; What `rawWalk` finds under a root: the regular files, and the links whose
  ;; target is missing, both as paths relative to the root, sorted.
  ;; Whether the handle is one over bytes held in memory (an `Asset`'s), which cannot be written.
  ;; rawReadOnly — .Wasm(body: readOnlyWasm)
  (func $rawReadOnly (param $handle anyref) (result i32)
    local.get $handle
    call $readOnlyWasm
  )
  ;; ── whole-file shortcuts ─────────────────────────────────────────────────────
  ;; The file's bytes.
  (func $readBytes (export "readBytes") (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $b (ref null $str))
    (local $__gc37 (ref null $result))
    local.get $path
    local.get $path
    call $rawReadBytes
    call $liftBytes
    local.set $__gc37
    local.get $__gc37
    struct.get $result $tag
    (if
      (then
    local.get $__gc37
    return ;; propagate Error
      )
    )
    local.get $__gc37
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $b
    i32.const 0
    local.get $b
    struct.new $result
    return
  )
  ;; The file as UTF-8 text. Bytes that are not UTF-8 are `InvalidUtf8` on every
  ;; target — never node's silent U+FFFD nor erlang's unchecked binary.
  (func $readText (export "readText") (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $_try1 i32)
    (local $b (ref null $str))
    (local $s (ref null $str))
    (local $__gc38 (ref null $result))
    (local $__gc39 (ref null $result))
    local.get $path
    call $readBytes
    local.set $__gc38
    local.get $__gc38
    struct.get $result $tag
    (if
      (then
    local.get $__gc38
    return ;; propagate Error
      )
    )
    local.get $__gc38
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $b
    local.get $path
    local.get $b
    call $decode
    local.set $__gc39
    local.get $__gc39
    struct.get $result $tag
    (if
      (then
    local.get $__gc39
    return ;; propagate Error
      )
    )
    local.get $__gc39
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $s
    i32.const 0
    local.get $s
    struct.new $result
    return
  )
  ;; Write `contents` to `path`, creating or truncating.
  (func $writeBytes (export "writeBytes") (param $path (ref null $str)) (param $contents (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $n i32)
    (local $__gc40 (ref null $result))
    local.get $path
    local.get $path
    local.get $contents
    call $rawWriteBytes
    call $liftI32
    local.set $__gc40
    local.get $__gc40
    struct.get $result $tag
    (if
      (then
    local.get $__gc40
    return ;; propagate Error
      )
    )
    local.get $__gc40
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $n
    i32.const 0
    local.get $n
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $writeText (export "writeText") (param $path (ref null $str)) (param $contents (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $n i32)
    (local $__gc41 (ref null $result))
    local.get $path
    local.get $path
    local.get $contents
    call $rawWriteText
    call $liftI32
    local.set $__gc41
    local.get $__gc41
    struct.get $result $tag
    (if
      (then
    local.get $__gc41
    return ;; propagate Error
      )
    )
    local.get $__gc41
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $n
    i32.const 0
    local.get $n
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Append `contents`, creating the file when it is not there.
  (func $appendText (export "appendText") (param $path (ref null $str)) (param $contents (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $n i32)
    (local $__gc42 (ref null $result))
    local.get $path
    local.get $path
    local.get $contents
    call $rawAppendText
    call $liftI32
    local.set $__gc42
    local.get $__gc42
    struct.get $result $tag
    (if
      (then
    local.get $__gc42
    return ;; propagate Error
      )
    )
    local.get $__gc42
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $n
    i32.const 0
    local.get $n
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; ── metadata and directories ─────────────────────────────────────────────────
  (func $stat (export "stat") (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $s (ref null $rec_FileStat))
    (local $__gc43 (ref null $result))
    local.get $path
    local.get $path
    call $rawStat
    call $liftStat
    local.set $__gc43
    local.get $__gc43
    struct.get $result $tag
    (if
      (then
    local.get $__gc43
    return ;; propagate Error
      )
    )
    local.get $__gc43
    struct.get $result $payload
    ref.cast (ref null $rec_FileStat)
    local.set $s
    i32.const 0
    local.get $s
    struct.new $result
    return
  )
  (func $list (export "list") (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $names (ref null $arr_any))
    (local $__gc44 (ref null $result))
    local.get $path
    local.get $path
    call $rawList
    call $liftStrings
    local.set $__gc44
    local.get $__gc44
    struct.get $result $tag
    (if
      (then
    local.get $__gc44
    return ;; propagate Error
      )
    )
    local.get $__gc44
    struct.get $result $payload
    ref.cast (ref null $arr_any)
    local.set $names
    i32.const 0
    local.get $names
    struct.new $result
    return
  )
  (func $mkdir (export "mkdir") (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $n i32)
    (local $__gc45 (ref null $result))
    local.get $path
    local.get $path
    call $rawMkdir
    call $liftI32
    local.set $__gc45
    local.get $__gc45
    struct.get $result $tag
    (if
      (then
    local.get $__gc45
    return ;; propagate Error
      )
    )
    local.get $__gc45
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $n
    i32.const 0
    local.get $n
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $mkdirRecursive (export "mkdirRecursive") (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $n i32)
    (local $__gc46 (ref null $result))
    local.get $path
    local.get $path
    call $rawMkdirRecursive
    call $liftI32
    local.set $__gc46
    local.get $__gc46
    struct.get $result $tag
    (if
      (then
    local.get $__gc46
    return ;; propagate Error
      )
    )
    local.get $__gc46
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $n
    i32.const 0
    local.get $n
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $rm (export "rm") (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $n i32)
    (local $__gc47 (ref null $result))
    local.get $path
    local.get $path
    call $rawRm
    call $liftI32
    local.set $__gc47
    local.get $__gc47
    struct.get $result $tag
    (if
      (then
    local.get $__gc47
    return ;; propagate Error
      )
    )
    local.get $__gc47
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $n
    i32.const 0
    local.get $n
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $removeTree (export "removeTree") (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $n i32)
    (local $__gc48 (ref null $result))
    local.get $path
    local.get $path
    call $rawRemoveTree
    call $liftI32
    local.set $__gc48
    local.get $__gc48
    struct.get $result $tag
    (if
      (then
    local.get $__gc48
    return ;; propagate Error
      )
    )
    local.get $__gc48
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $n
    i32.const 0
    local.get $n
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $copy (export "copy") (param $src (ref null $str)) (param $dest (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $n i32)
    (local $__gc49 (ref null $result))
    local.get $src
    local.get $src
    local.get $dest
    call $rawCopy
    call $liftI32
    local.set $__gc49
    local.get $__gc49
    struct.get $result $tag
    (if
      (then
    local.get $__gc49
    return ;; propagate Error
      )
    )
    local.get $__gc49
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $n
    i32.const 0
    local.get $n
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $walk (export "walk") (param $root (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $found (ref null $rec_Walked))
    (local $first (ref null $str))
    (local $__bp_nullish i32)
    (local $__gc50 (ref null $result))
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__23 (ref null $str))
    local.get $root
    local.get $root
    call $rawWalk
    call $liftWalked
    local.set $__gc50
    local.get $__gc50
    struct.get $result $tag
    (if
      (then
    local.get $__gc50
    return ;; propagate Error
      )
    )
    local.get $__gc50
    struct.get $result $payload
    ref.cast (ref null $rec_Walked)
    local.set $found
    local.get $found
    struct.get $rec_Walked $f1
    array.len
    i32.const 0
    i32.gt_s
    (if (result (ref null $result))
      (then
    local.get $found
    struct.get $rec_Walked $f1
    i32.const 0
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__23
    local.get $__bp_nullish__23
      )
      (else
    global.get $__s0
      )
    )
    local.set $first
    i32.const 1
    local.get $root
    global.get $__s31
    local.get $first
    global.get $__s32
    array.new_fixed $arr_any 3
    global.get $__s0
    call $__arr_join_any
    struct.new $var_FsError_Other
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    local.get $found
    struct.get $rec_Walked $f0
    struct.new $result
    return
  )
  (func $glob (export "glob") (param $pattern (ref null $str)) (param $root (ref null $str)) (result (ref null $result))
    i32.const 0
    local.get $pattern
    local.get $root
    call $rawGlob
    struct.new $result
    return
  )
  ;; The host's handle over embedded bytes: read like a file, never closed on disk.
  ;; memoryHandle — .Wasm(body: memHandleWasm)
  (func $memoryHandle (param $bytes (ref null $str)) (result anyref)
    local.get $bytes
    call $memHandleWasm
  )
  ;; ── the handle ───────────────────────────────────────────────────────────────
  ;; An open file (decision 540 (3)). `location` is the path it was opened with and
  ;; `handle` the host's — opaque, never read by a program. Closed by the writer:
  ;; `val f = try fs.open(p); defer f.close();`.
  (func $File_path (param $self (ref null $rec_File)) (result (ref null $str))
    local.get $self
    struct.get $rec_File $f0
    return
  )
  (func $File_size (param $self (ref null $rec_File)) (result (ref null $result))
    (local $_try0 i32)
    (local $n i64)
    (local $__gc51 (ref null $result))
    local.get $self
    struct.get $rec_File $f0
    local.get $self
    struct.get $rec_File $f1
    local.get $self
    struct.get $rec_File $f0
    call $rawSize
    call $liftI64
    local.set $__gc51
    local.get $__gc51
    struct.get $result $tag
    (if
      (then
    local.get $__gc51
    return ;; propagate Error
      )
    )
    local.get $__gc51
    struct.get $result $payload
    ref.cast (ref null $box_i64)
    struct.get $box_i64 $v
    local.set $n
    i32.const 0
    local.get $n
    struct.new $box_i64
    struct.new $result
    return
  )
  (func $File_read (param $self (ref null $rec_File)) (param $n i32) (result (ref null $result))
    (local $_try0 i32)
    (local $b (ref null $str))
    (local $__gc52 (ref null $result))
    local.get $n
    i32.const 0
    i32.le_s
    (if (result (ref null $result))
      (then
    i32.const 0
    global.get $__s0
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $self
    struct.get $rec_File $f0
    local.get $self
    struct.get $rec_File $f1
    local.get $n
    call $rawRead
    call $liftBytes
    local.set $__gc52
    local.get $__gc52
    struct.get $result $tag
    (if
      (then
    local.get $__gc52
    return ;; propagate Error
      )
    )
    local.get $__gc52
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $b
    i32.const 0
    local.get $b
    struct.new $result
    return
  )
  (func $File_bytes (param $self (ref null $rec_File)) (result (ref null $result))
    (local $_try0 i32)
    (local $b (ref null $str))
    (local $__gc53 (ref null $result))
    local.get $self
    struct.get $rec_File $f0
    local.get $self
    struct.get $rec_File $f1
    call $rawReadAll
    call $liftBytes
    local.set $__gc53
    local.get $__gc53
    struct.get $result $tag
    (if
      (then
    local.get $__gc53
    return ;; propagate Error
      )
    )
    local.get $__gc53
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $b
    i32.const 0
    local.get $b
    struct.new $result
    return
  )
  (func $File_text (param $self (ref null $rec_File)) (result (ref null $result))
    (local $_try0 i32)
    (local $_try1 i32)
    (local $b (ref null $str))
    (local $s (ref null $str))
    (local $__gc54 (ref null $result))
    (local $__gc55 (ref null $result))
    local.get $self
    call $File_bytes
    local.set $__gc54
    local.get $__gc54
    struct.get $result $tag
    (if
      (then
    local.get $__gc54
    return ;; propagate Error
      )
    )
    local.get $__gc54
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $b
    local.get $self
    struct.get $rec_File $f0
    local.get $b
    call $decode
    local.set $__gc55
    local.get $__gc55
    struct.get $result $tag
    (if
      (then
    local.get $__gc55
    return ;; propagate Error
      )
    )
    local.get $__gc55
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $s
    i32.const 0
    local.get $s
    struct.new $result
    return
  )
  (func $File_chunks (param $self (ref null $rec_File)) (param $size i32) (result (ref null $gen))
    (local $__fr (ref null $frame0))
    struct.new_default $frame0 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $self
    struct.set $frame0 $s0
    local.get $__fr
    local.get $size
    struct.set $frame0 $s1
    i32.const 0 ;; live
    i32.const 5 ;; File_chunks__body
    local.get $__fr
    ref.null any
    ref.null $gen
    ref.null any ;; the environment
    i32.const 0
    struct.new $gen ;; runs nothing until its first next
  )
  (func $File_chunks__body (param $__gen (ref null $gen)) (result i32)
    (local $self (ref null $rec_File))
    (local $size i32)
    (local $b (ref null $str))
    (local $__frame (ref null $frame0))
    (local $__seek i32)
    (local $__state i32)
    (local $__gc56 (ref null $result))
    (local $__cnd0 i32)
    local.get $__gen
    struct.get $gen $frame
    ref.cast (ref null $frame0)
    local.set $__frame
    local.get $__frame
    struct.get $frame0 $s0
    local.set $self
    local.get $__frame
    struct.get $frame0 $s1
    local.set $size
    local.get $__frame
    struct.get $frame0 $s2
    local.set $b
    local.get $__frame
    struct.get $frame0 $s3
    local.set $__gc56
    local.get $__frame
    struct.get $frame0 $s4
    local.set $__cnd0
    local.get $__frame
    struct.get $frame0 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    (block $__break
      (loop $__continue
    local.get $__seek
    (if (result i32)
      (then
    i32.const 1 ;; re-entering: inside an iteration
      )
      (else
    i32.const 1
      )
    )
        i32.eqz
        br_if $__break
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $self
    local.get $size
    call $File_read
    local.set $__gc56
    local.get $__gc56
    struct.get $result $tag
    (if
      (then
    local.get $__gen
    local.get $__gc56
    struct.set $gen $value ;; the Error, the last yitem
    local.get $__gen
    i32.const 1
    struct.set $gen $state ;; ended after it
    i32.const 1
    return ;; an yitem
      )
    )
    local.get $__gc56
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $b
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd0 ;; the condition, read back
      )
      (else
    local.get $b
    array.len
    i32.const 0
    i32.eq
    local.tee $__cnd0
      )
    )
    (if (result (ref null $gen))
      (then
    br $__break
      )
      (else
        ref.null $gen
      )
    )
    drop
      )
    )
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    (block $__yd1
    local.get $__seek
    (if
      (then
    local.get $__state
    i32.const 1
    i32.eq
    (if
      (then
    i32.const 0
    local.set $__seek
      )
    )
    br $__yd1 ;; resumed after this yield, or seeking past it
      )
    )
    local.get $__gen
    i32.const 0
    local.get $b
    struct.new $result
    struct.set $gen $value ;; the yitem
    local.get $__frame
    local.get $self
    struct.set $frame0 $s0
    local.get $__frame
    local.get $size
    struct.set $frame0 $s1
    local.get $__frame
    local.get $b
    struct.set $frame0 $s2
    local.get $__frame
    local.get $__gc56
    struct.set $frame0 $s3
    local.get $__frame
    local.get $__cnd0
    struct.set $frame0 $s4
    local.get $__frame
    i32.const 1
    struct.set $frame0 $resume ;; the resume index
    i32.const 1
    return ;; an yitem
    )
      )
    )
        br $__continue
      )
    )
    i32.const 0
    drop
      )
    )
    i32.const 0 ;; the sequence ended
  )
  (func $File_lines (param $self (ref null $rec_File)) (result (ref null $gen))
    (local $__fr (ref null $frame1))
    struct.new_default $frame1 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $self
    struct.set $frame1 $s0
    i32.const 0 ;; live
    i32.const 6 ;; File_lines__body
    local.get $__fr
    ref.null any
    ref.null $gen
    ref.null any ;; the environment
    i32.const 0
    struct.new $gen ;; runs nothing until its first next
  )
  (func $File_lines__body (param $__gen (ref null $gen)) (result i32)
    (local $self (ref null $rec_File))
    (local $__mem0 i32)
    (local $consumed i32)
    (local $raw (ref null $str))
    (local $line (ref null $str))
    (local $offset i64)
    (local $width i32)
    (local $__frame (ref null $frame1))
    (local $__seek i32)
    (local $__state i32)
    (local $__gc57 (ref null $result))
    (local $__cnd0 i32)
    (local $__cnd1 i32)
    (local $__conv0 i32)
    (local $__gc58 (ref null $result))
    (local $__gc59 (ref null $str))
    (local $__gc60 (ref null $str))
    (local $__gc61 i32)
    local.get $__gen
    struct.get $gen $frame
    ref.cast (ref null $frame1)
    local.set $__frame
    local.get $__frame
    struct.get $frame1 $s0
    local.set $self
    local.get $__frame
    struct.get $frame1 $s1
    local.set $__mem0
    local.get $__frame
    struct.get $frame1 $s2
    local.set $consumed
    local.get $__frame
    struct.get $frame1 $s3
    local.set $raw
    local.get $__frame
    struct.get $frame1 $s4
    local.set $line
    local.get $__frame
    struct.get $frame1 $s5
    local.set $offset
    local.get $__frame
    struct.get $frame1 $s6
    local.set $width
    local.get $__frame
    struct.get $frame1 $s7
    local.set $__gc57
    local.get $__frame
    struct.get $frame1 $s8
    local.set $__cnd0
    local.get $__frame
    struct.get $frame1 $s9
    local.set $__cnd1
    local.get $__frame
    struct.get $frame1 $s10
    local.set $__conv0
    local.get $__frame
    struct.get $frame1 $s11
    local.set $__gc58
    local.get $__frame
    struct.get $frame1 $s12
    local.set $__gc59
    local.get $__frame
    struct.get $frame1 $s13
    local.set $__gc60
    local.get $__frame
    struct.get $frame1 $s14
    local.set $__gc61
    local.get $__frame
    struct.get $frame1 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    (if
      (then
    i32.const 0
    local.set $consumed
      )
    )
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 2
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    (block $__break
      (loop $__continue
    local.get $__seek
    (if (result i32)
      (then
    i32.const 1 ;; re-entering: inside an iteration
      )
      (else
    i32.const 1
      )
    )
        i32.eqz
        br_if $__break
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $self
    struct.get $rec_File $f0
    local.get $self
    struct.get $rec_File $f1
    call $rawReadLine
    call $liftBytes
    local.set $__gc57
    local.get $__gc57
    struct.get $result $tag
    (if
      (then
    local.get $__gen
    local.get $__gc57
    struct.set $gen $value ;; the Error, the last yitem
    local.get $__gen
    i32.const 1
    struct.set $gen $state ;; ended after it
    i32.const 1
    return ;; an yitem
      )
    )
    local.get $__gc57
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $raw
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd0 ;; the condition, read back
      )
      (else
    local.get $raw
    array.len
    i32.const 0
    i32.eq
    local.tee $__cnd0
      )
    )
    (if (result (ref null $gen))
      (then
    br $__break
      )
      (else
        ref.null $gen
      )
    )
    drop
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $raw
    call $stripEol
    local.set $line
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $line
    call $utf8Offset
    local.set $offset
      )
    )
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd1 ;; the condition, read back
      )
      (else
    local.get $offset
    i32.const 0
    i64.extend_i32_s
    i64.ge_s
    local.tee $__cnd1
      )
    )
    (if (result (ref null $gen))
      (then
    (block $__yd1
    local.get $__seek
    (if
      (then
    local.get $__state
    i32.const 1
    i32.eq
    (if
      (then
    i32.const 0
    local.set $__seek
      )
    )
    br $__yd1 ;; resumed after this yield, or seeking past it
      )
    )
    local.get $__gen
    i32.const 1
    local.get $self
    struct.get $rec_File $f0
    local.get $consumed
    local.set $__conv0
    local.get $__conv0
    i64.extend_i32_s
    local.get $offset
    global.get $__s33
    call $__i64_add_chk
    struct.new $var_FsError_InvalidUtf8
    struct.new $result
    struct.set $gen $value ;; the yitem
    local.get $__frame
    local.get $self
    struct.set $frame1 $s0
    local.get $__frame
    local.get $__mem0
    struct.set $frame1 $s1
    local.get $__frame
    local.get $consumed
    struct.set $frame1 $s2
    local.get $__frame
    local.get $raw
    struct.set $frame1 $s3
    local.get $__frame
    local.get $line
    struct.set $frame1 $s4
    local.get $__frame
    local.get $offset
    struct.set $frame1 $s5
    local.get $__frame
    local.get $width
    struct.set $frame1 $s6
    local.get $__frame
    local.get $__gc57
    struct.set $frame1 $s7
    local.get $__frame
    local.get $__cnd0
    struct.set $frame1 $s8
    local.get $__frame
    local.get $__cnd1
    struct.set $frame1 $s9
    local.get $__frame
    local.get $__conv0
    struct.set $frame1 $s10
    local.get $__frame
    local.get $__gc58
    struct.set $frame1 $s11
    local.get $__frame
    local.get $__gc59
    struct.set $frame1 $s12
    local.get $__frame
    local.get $__gc60
    struct.set $frame1 $s13
    local.get $__frame
    local.get $__gc61
    struct.set $frame1 $s14
    local.get $__frame
    i32.const 1
    struct.set $frame1 $resume ;; the resume index
    i32.const 1
    return ;; an yitem
    )
    i32.const 0 ;; the sequence ended
    return
      )
      (else
        ref.null $gen
      )
    )
    drop
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $raw
    array.len
    local.set $width
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $consumed
    local.get $width
    global.get $__s34
    call $__i32_add_chk
    local.set $consumed
      )
    )
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 2
    i32.ge_u
    local.get $__state
    i32.const 2
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    (block $__yd2
    local.get $__seek
    (if
      (then
    local.get $__state
    i32.const 2
    i32.eq
    (if
      (then
    i32.const 0
    local.set $__seek
      )
    )
    br $__yd2 ;; resumed after this yield, or seeking past it
      )
    )
    local.get $__gen
    i32.const 0
    local.get $line
    local.set $__gc59
    local.get $__gc59
    local.set $__gc60
    global.get $__heap_ptr
    local.set $__gc61
    local.get $__gc60
    call $__gc_to_lin_str
    call $__std_bytes_isUtf8
    local.get $__gc61
    global.set $__heap_ptr
    (if (result (ref null $result))
      (then
    i32.const 0
    local.get $__gc59
    struct.new $result
      )
      (else
    i32.const 1
    global.get $__s30
    struct.new $result
      )
    )
    local.tee $__gc58
    struct.get $result $tag
    (if (result (ref null $str))
      (then
    global.get $__s0
      )
      (else
    local.get $__gc58
    struct.get $result $payload
    ref.cast (ref null $str)
      )
    )
    struct.new $result
    struct.set $gen $value ;; the yitem
    local.get $__frame
    local.get $self
    struct.set $frame1 $s0
    local.get $__frame
    local.get $__mem0
    struct.set $frame1 $s1
    local.get $__frame
    local.get $consumed
    struct.set $frame1 $s2
    local.get $__frame
    local.get $raw
    struct.set $frame1 $s3
    local.get $__frame
    local.get $line
    struct.set $frame1 $s4
    local.get $__frame
    local.get $offset
    struct.set $frame1 $s5
    local.get $__frame
    local.get $width
    struct.set $frame1 $s6
    local.get $__frame
    local.get $__gc57
    struct.set $frame1 $s7
    local.get $__frame
    local.get $__cnd0
    struct.set $frame1 $s8
    local.get $__frame
    local.get $__cnd1
    struct.set $frame1 $s9
    local.get $__frame
    local.get $__conv0
    struct.set $frame1 $s10
    local.get $__frame
    local.get $__gc58
    struct.set $frame1 $s11
    local.get $__frame
    local.get $__gc59
    struct.set $frame1 $s12
    local.get $__frame
    local.get $__gc60
    struct.set $frame1 $s13
    local.get $__frame
    local.get $__gc61
    struct.set $frame1 $s14
    local.get $__frame
    i32.const 2
    struct.set $frame1 $resume ;; the resume index
    i32.const 1
    return ;; an yitem
    )
      )
    )
        br $__continue
      )
    )
    i32.const 0
    drop
      )
    )
    i32.const 0 ;; the sequence ended
  )
  (func $File_hash (param $self (ref null $rec_File)) (result (ref null $result))
    (local $_try0 i32)
    (local $h (ref null $str))
    (local $__gc62 (ref null $result))
    local.get $self
    struct.get $rec_File $f0
    local.get $self
    struct.get $rec_File $f1
    call $rawHash
    call $liftString
    local.set $__gc62
    local.get $__gc62
    struct.get $result $tag
    (if
      (then
    local.get $__gc62
    return ;; propagate Error
      )
    )
    local.get $__gc62
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $h
    i32.const 0
    local.get $h
    struct.new $result
    return
  )
  (func $File_write (param $self (ref null $rec_File)) (param $b (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $__mem0 i32)
    (local $n i32)
    (local $__gc63 (ref null $result))
    local.get $self
    struct.get $rec_File $f1
    call $rawReadOnly
    (if (result (ref null $result))
      (then
    i32.const 1
    local.get $self
    struct.get $rec_File $f0
    global.get $__s35
    struct.new $var_FsError_Other
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $self
    struct.get $rec_File $f0
    local.get $self
    struct.get $rec_File $f1
    local.get $b
    call $rawWrite
    call $liftI32
    local.set $__gc63
    local.get $__gc63
    struct.get $result $tag
    (if
      (then
    local.get $__gc63
    return ;; propagate Error
      )
    )
    local.get $__gc63
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $n
    i32.const 0
    local.get $n
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $File_close (param $self (ref null $rec_File))
    (local $closed (ref null $result))
    local.get $self
    struct.get $rec_File $f1
    call $rawClose
    local.set $closed
  )
  ;; Open the file at `path` for reading. A directory is `IsDirectory` on every target.
  (func $open (export "open") (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $__mem0 i32)
    (local $h anyref)
    (local $__gc64 (ref null $result))
    local.get $path
    local.get $path
    call $rawOpen
    call $liftHandle
    local.set $__gc64
    local.get $__gc64
    struct.get $result $tag
    (if
      (then
    local.get $__gc64
    return ;; propagate Error
      )
    )
    local.get $__gc64
    struct.get $result $payload
    local.set $h
    i32.const 0
    local.get $path
    local.get $h
    struct.new $rec_File
    struct.new $result
    return
  )
  ;; Open the file at `path` for writing: created, or truncated.
  (func $create (export "create") (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $__mem0 i32)
    (local $h anyref)
    (local $__gc65 (ref null $result))
    local.get $path
    local.get $path
    call $rawCreate
    call $liftHandle
    local.set $__gc65
    local.get $__gc65
    struct.get $result $tag
    (if
      (then
    local.get $__gc65
    return ;; propagate Error
      )
    )
    local.get $__gc65
    struct.get $result $payload
    local.set $h
    i32.const 0
    local.get $path
    local.get $h
    struct.new $rec_File
    struct.new $result
    return
  )
  ;; An `Asset` (`@embed`, decisions 519, 538) as a `File`: the embedded bytes, read
  ;; like a file on disk — no `Result`, the build proved the file exists — and
  ;; closing it is a no-op.
  (func $openAsset (export "openAsset") (param $asset (ref null $rec_Asset)) (result (ref null $rec_File))
    (local $__mem0 i32)
    local.get $asset
    struct.get $rec_Asset $f0
    local.get $asset
    struct.get $rec_Asset $f1
    call $memoryHandle
    struct.new $rec_File
    return
  )
  ;; ── the wasm bodies (decision 992) ───────────────────────────────────────────
  ;; `io.fs` on wasm answers what it answers on commonJS, erlang and beam: the same functions
  ;; over the file system of the process, the same paths (a relative one is read against the
  ;; working directory, an absolute one as it is), the same answers and the same errors. The
  ;; host is `wasi:filesystem`, reached through std-wasm's leaves (`modules/std-wasm/wat/fs.wat`;
  ;; the `wasi…` declarations below), which the runner serves with the root and the working
  ;; directory preopened (`needs: [.Filesystem]`, no flag). A leaf answers a host failure as
  ;; `-(1 + code)`, `code` the ordinal of `wasi:filesystem`'s `error-code`, or as the `Error`
  ;; of a `Result<_, i32>` holding the code; `wasiError` writes it as Node's text
  ;; (`ENOENT: …`), which `fsError` reads as it reads every target's.
  ;; wasiCwd — .Wasm(std: "fs.cwd")
  (func $wasiCwd (result (ref null $str))
    call $__std_fs_cwd
  )
  ;; wasiGetenv — .Wasm(std: "fs.getenv")
  (func $wasiGetenv (param $name (ref null $str)) (result (ref null $str))
    local.get $name
    call $__std_fs_getenv
  )
  ;; wasiOpen — .Wasm(std: "fs.open")
  (func $wasiOpen (param $path (ref null $str)) (param $mode i32) (result i32)
    local.get $path
    local.get $mode
    call $__std_fs_open
  )
  ;; wasiOpenMem — .Wasm(std: "fs.openMem")
  (func $wasiOpenMem (param $data (ref null $str)) (result i32)
    local.get $data
    call $__std_fs_openMem
  )
  ;; wasiClose — .Wasm(std: "fs.close")
  (func $wasiClose (param $block i32)
    local.get $block
    call $__std_fs_close
  )
  ;; wasiIsMem — .Wasm(std: "fs.isMem")
  (func $wasiIsMem (param $block i32) (result i32)
    local.get $block
    call $__std_fs_isMem
  )
  ;; wasiTell — .Wasm(std: "fs.tell")
  (func $wasiTell (param $block i32) (result i64)
    local.get $block
    call $__std_fs_tell
  )
  ;; wasiSeek — .Wasm(std: "fs.seek")
  (func $wasiSeek (param $block i32) (param $position i64)
    local.get $block
    local.get $position
    call $__std_fs_seek
  )
  ;; wasiSize — .Wasm(std: "fs.size")
  (func $wasiSize (param $block i32) (result (ref null $result))
    local.get $block
    call $__std_fs_size
  )
  ;; wasiSizeRaw — .Wasm(std: "fs.sizeRaw")
  (func $wasiSizeRaw (param $block i32) (result i64)
    local.get $block
    call $__std_fs_sizeRaw
  )
  ;; wasiRead — .Wasm(std: "fs.read")
  (func $wasiRead (param $block i32) (param $n i32) (result (ref null $result))
    local.get $block
    local.get $n
    call $__std_fs_read
  )
  ;; wasiReadAll — .Wasm(std: "fs.readAll")
  (func $wasiReadAll (param $block i32) (result (ref null $result))
    local.get $block
    call $__std_fs_readAll
  )
  ;; wasiReadLine — .Wasm(std: "fs.readLine")
  (func $wasiReadLine (param $block i32) (result (ref null $result))
    local.get $block
    call $__std_fs_readLine
  )
  ;; wasiWrite — .Wasm(std: "fs.write")
  (func $wasiWrite (param $block i32) (param $data (ref null $str)) (result i32)
    local.get $block
    local.get $data
    call $__std_fs_write
  )
  ;; wasiStatKind — .Wasm(std: "fs.statKind")
  (func $wasiStatKind (param $path (ref null $str)) (param $follow i32) (result i32)
    local.get $path
    local.get $follow
    call $__std_fs_statKind
  )
  ;; wasiStatSize — .Wasm(std: "fs.statSize")
  (func $wasiStatSize (param $path (ref null $str)) (result (ref null $result))
    local.get $path
    call $__std_fs_statSize
  )
  ;; wasiStatMtime — .Wasm(std: "fs.statMtime")
  (func $wasiStatMtime (param $path (ref null $str)) (result (ref null $result))
    local.get $path
    call $__std_fs_statMtime
  )
  ;; wasiList — .Wasm(std: "fs.list")
  (func $wasiList (param $path (ref null $str)) (result (ref null $result))
    local.get $path
    call $__std_fs_list
  )
  ;; wasiMkdir — .Wasm(std: "fs.mkdir")
  (func $wasiMkdir (param $path (ref null $str)) (result i32)
    local.get $path
    call $__std_fs_mkdir
  )
  ;; wasiRmdir — .Wasm(std: "fs.rmdir")
  (func $wasiRmdir (param $path (ref null $str)) (result i32)
    local.get $path
    call $__std_fs_rmdir
  )
  ;; wasiUnlink — .Wasm(std: "fs.unlink")
  (func $wasiUnlink (param $path (ref null $str)) (result i32)
    local.get $path
    call $__std_fs_unlink
  )
  ;; wasiSymlink — .Wasm(std: "fs.symlink")
  (func $wasiSymlink (param $target (ref null $str)) (param $link (ref null $str)) (result i32)
    local.get $target
    local.get $link
    call $__std_fs_symlink
  )
  ;; wasiByteAt — .Wasm(std: "bytes.at")
  (func $wasiByteAt (param $data (ref null $str)) (param $index i32) (result i32)
    local.get $data
    local.get $index
    call $__std_bytes_at
  )
  ;; wasiSha256 — .Wasm(std: "hash.sha256Hex")
  (func $wasiSha256 (param $data (ref null $str)) (result (ref null $str))
    local.get $data
    call $__std_hash_sha256Hex
  )
  ;; The POSIX name of the host's error `code`, and its text.
  (func $wasiName (param $code i32) (result (ref null $str))
    (local $__mem0 i32)
    (local $names (ref null $arr_any))
    (local $__bp_nullish i32)
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__24 (ref null $str))
    global.get $__s24
    global.get $__s36
    global.get $__s37
    global.get $__s38
    global.get $__s39
    global.get $__s40
    global.get $__s41
    global.get $__s29
    global.get $__s42
    global.get $__s43
    global.get $__s44
    global.get $__s45
    global.get $__s46
    global.get $__s47
    global.get $__s26
    global.get $__s48
    global.get $__s49
    global.get $__s50
    global.get $__s51
    global.get $__s52
    global.get $__s23
    global.get $__s53
    global.get $__s54
    global.get $__s55
    global.get $__s28
    global.get $__s56
    global.get $__s57
    global.get $__s58
    global.get $__s59
    global.get $__s60
    global.get $__s61
    global.get $__s25
    global.get $__s62
    global.get $__s63
    global.get $__s64
    global.get $__s65
    global.get $__s66
    array.new_fixed $arr_any 37
    local.set $names
    local.get $names
    local.get $code
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__24
    local.get $__bp_nullish__24
      )
      (else
    global.get $__s47
      )
    )
    return
  )
  (func $wasiText (param $code i32) (result (ref null $str))
    (local $__mem0 i32)
    (local $texts (ref null $arr_any))
    (local $__bp_nullish i32)
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__25 (ref null $str))
    global.get $__s67
    global.get $__s68
    global.get $__s69
    global.get $__s70
    global.get $__s71
    global.get $__s72
    global.get $__s73
    global.get $__s74
    global.get $__s75
    global.get $__s76
    global.get $__s77
    global.get $__s78
    global.get $__s79
    global.get $__s80
    global.get $__s81
    global.get $__s82
    global.get $__s83
    global.get $__s84
    global.get $__s85
    global.get $__s86
    global.get $__s87
    global.get $__s88
    global.get $__s89
    global.get $__s90
    global.get $__s91
    global.get $__s92
    global.get $__s93
    global.get $__s94
    global.get $__s95
    global.get $__s96
    global.get $__s97
    global.get $__s98
    global.get $__s99
    global.get $__s100
    global.get $__s101
    global.get $__s102
    global.get $__s103
    array.new_fixed $arr_any 37
    local.set $texts
    local.get $texts
    local.get $code
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__25
    local.get $__bp_nullish__25
      )
      (else
    global.get $__s80
      )
    )
    return
  )
  ;; The `HostError` of the host's error `code`: `ENOENT: no such file or directory`.
  (func $wasiError (param $code i32) (result (ref null $rec_HostError))
    (local $__mem0 i32)
    local.get $code
    call $wasiName
    global.get $__s22
    call $__str_concat
    local.get $code
    call $wasiText
    call $__str_concat
    global.get $__s104
    i32.const 0 ;; HostErrorName.Error
    ref.null $str
    struct.new $rec_HostError
    return
  )
  ;; The `Ok` of a leaf's answer, its `Error` the `HostError` of the code.
  (func $okBytes (param $r (ref null $result)) (result (ref null $result))
    (local $b i32)
    (local $code i32)
    (local $__case_0 (ref null $result))
    (local $b__26 (ref null $str))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $b__26
    i32.const 0
    local.get $b__26
    struct.new $result
    return
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $code
    i32.const 1
    local.get $code
    call $wasiError
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  (func $okStrings (param $r (ref null $result)) (result (ref null $result))
    (local $xs i32)
    (local $code i32)
    (local $__case_0 (ref null $result))
    (local $xs__27 (ref null $arr_any))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $arr_any)
    local.set $xs__27
    i32.const 0
    local.get $xs__27
    struct.new $result
    return
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $code
    i32.const 1
    local.get $code
    call $wasiError
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  (func $okSize (param $r (ref null $result)) (result (ref null $result))
    (local $n i32)
    (local $code i32)
    (local $__case_0 (ref null $result))
    (local $n__28 i64)
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $box_i64)
    struct.get $box_i64 $v
    local.set $n__28
    i32.const 0
    local.get $n__28
    struct.new $box_i64
    struct.new $result
    return
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $code
    i32.const 1
    local.get $code
    call $wasiError
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  ;; `path` without the slashes it begins with: the host reads a path relative to the root it preopens.
  (func $withoutRoot (param $path (ref null $str)) (result (ref null $str))
    (local $p (ref null $str))
    (local $__gc66 (ref null $str))
    (local $__gc67 (ref null $str))
    (local $__gc68 i32)
    (local $__gc69 i32)
    (local $__gc70 i32)
    (local $__gc71 (ref null $str))
    (local $__gc72 i32)
    local.get $path
    local.set $p
    (block $__break
      (loop $__continue
    local.get $p
    global.get $__s105
    local.set $__gc66
    local.set $__gc67
    global.get $__heap_ptr
    local.set $__gc68
    local.get $__gc67
    call $__gc_to_lin_str
    local.get $__gc66
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc68
    global.set $__heap_ptr
        i32.eqz
        br_if $__break
    local.get $p
    i32.const 1
    i32.const 2147483647
    local.set $__gc69
    local.set $__gc70
    local.set $__gc71
    global.get $__heap_ptr
    local.set $__gc72
    local.get $__gc71
    call $__gc_to_lin_str
    local.get $__gc70
    local.get $__gc69
    call $__std_text_slice
    call $__lin_to_gc_str
    local.get $__gc72
    global.set $__heap_ptr
    local.set $p
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $p
    return
  )
  ;; `name` inside `dir`, `dir` empty being the root.
  (func $joinPath (param $dir (ref null $str)) (param $name (ref null $str)) (result (ref null $str))
    local.get $dir
    global.get $__s0
    call $__str_eq
    (if (result (ref null $str))
      (then
    local.get $name
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    local.get $dir
    global.get $__s105
    call $__str_concat
    local.get $name
    call $__str_concat
    return
  )
  ;; `path` as the host reads it: absolute, as it is; relative, from the working directory. The empty
  ;; path is no file (`ENOENT`), as it is on every target.
  (func $resolve (param $path (ref null $str)) (result (ref null $result))
    (local $cwd (ref null $str))
    (local $__gc73 (ref null $str))
    (local $__gc74 (ref null $str))
    (local $__gc75 i32)
    local.get $path
    global.get $__s0
    call $__str_eq
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 20
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $path
    global.get $__s105
    local.set $__gc73
    local.set $__gc74
    global.get $__heap_ptr
    local.set $__gc75
    local.get $__gc74
    call $__gc_to_lin_str
    local.get $__gc73
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc75
    global.set $__heap_ptr
    (if (result (ref null $result))
      (then
    i32.const 0
    local.get $path
    call $withoutRoot
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    call $wasiCwd
    local.set $cwd
    local.get $cwd
    global.get $__s0
    call $__str_eq
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $cwd
    global.get $__s105
    call $__str_eq
      )
    )
    (if (result (ref null $result))
      (then
    i32.const 0
    local.get $path
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    local.get $cwd
    global.get $__s105
    call $__str_concat
    local.get $path
    call $__str_concat
    call $withoutRoot
    struct.new $result
    return
  )
  ;; The file a handle holds: the handle block `rawOpen`, `rawCreate` and `memHandle` answered.
  (func $blockOf (param $handle anyref) (result i32)
    (local $block i32)
    (local $b i32)
    (local $handle__is29 i32)
    i32.const 0
    local.set $block
    local.get $handle
    i32.const -2147483648
    i32.const 2147483647
    call $__unk_int_in
    (if (result i32)
      (then
    local.get $handle
    call $__unk_as_i32
    local.set $handle__is29
    local.get $handle__is29
    local.set $b
    local.get $b
    local.set $block
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $block
    return
  )
  ;; Whether `a` sorts before `b` by the bytes of their UTF-8 (string `<` is not a wasm GC operation).
  (func $bytesBefore (param $a (ref null $str)) (param $b (ref null $str)) (result i32)
    (local $x (ref null $str))
    (local $y (ref null $str))
    (local $nx i32)
    (local $ny i32)
    (local $i i32)
    (local $cx i32)
    (local $cy i32)
    local.get $a
    local.set $x
    local.get $b
    local.set $y
    local.get $x
    array.len
    local.set $nx
    local.get $y
    array.len
    local.set $ny
    i32.const 0
    local.set $i
    (block $__break
      (loop $__continue
    local.get $i
    local.get $nx
    i32.lt_s
    (if (result i32)
      (then
    local.get $i
    local.get $ny
    i32.lt_s
      )
      (else
    i32.const 0
      )
    )
        i32.eqz
        br_if $__break
    local.get $x
    local.get $i
    call $wasiByteAt
    local.set $cx
    local.get $y
    local.get $i
    call $wasiByteAt
    local.set $cy
    local.get $cx
    local.get $cy
    i32.ne
    (if (result i32)
      (then
    local.get $cx
    local.get $cy
    i32.lt_s
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $i
    i32.const 1
    global.get $__s106
    call $__i32_add_chk
    local.set $i
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $nx
    local.get $ny
    i32.lt_s
    return
  )
  ;; The names sorted by the bytes of their UTF-8, none twice: what `readdirSync` answers on Node.
  (func $sortedStrings (param $xs (ref null $arr_any)) (result (ref null $arr_any))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $out (ref null $arr_any))
    (local $i i32)
    (local $x (ref null $str))
    (local $__bp_nullish i32)
    (local $j i32)
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__30 (ref null $str))
    (local $__opt1 (ref null $str))
    (local $__bp_nullish__31 (ref null $str))
    (local $__opt2 (ref null $str))
    (local $__bp_nullish__32 (ref null $str))
    array.new_fixed $arr_any 0
    local.set $out
    i32.const 0
    local.set $i
    (block $__break
      (loop $__continue
    local.get $i
    local.get $xs
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
        (block $__next
    local.get $xs
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__30
    local.get $__bp_nullish__30
      )
      (else
    global.get $__s0
      )
    )
    local.set $x
    local.get $i
    i32.const 1
    global.get $__s107
    call $__i32_add_chk
    local.set $i
    i32.const 0
    local.set $j
    (block $__break
      (loop $__continue
    local.get $j
    local.get $out
    array.len
    i32.lt_s
    (if (result i32)
      (then
    local.get $out
    local.get $j
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt1
    local.set $__bp_nullish__31
    local.get $__bp_nullish__31
      )
      (else
    global.get $__s0
      )
    )
    local.get $x
    call $bytesBefore
      )
      (else
    i32.const 0
      )
    )
        i32.eqz
        br_if $__break
    local.get $j
    i32.const 1
    global.get $__s108
    call $__i32_add_chk
    local.set $j
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $j
    local.get $out
    array.len
    i32.lt_s
    (if (result i32)
      (then
    local.get $out
    local.get $j
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt2
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt2
    local.set $__bp_nullish__32
    local.get $__bp_nullish__32
      )
      (else
    global.get $__s0
      )
    )
    local.get $x
    call $__str_eq
      )
      (else
    i32.const 0
      )
    )
    (if (result (ref null $arr_any))
      (then
    br $__next
      )
      (else
        ref.null $arr_any
      )
    )
    drop
    local.get $out
    i32.const 0
    local.get $j
    call $__arr_slice_any
    local.get $x
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.get $out
    local.get $j
    i32.const 2147483647
    call $__arr_slice_any
    call $__arr_concat_any
    local.set $out
        )
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $out
    return
  )
  (func $readBytesWasm (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $_try1 i32)
    (local $p (ref null $str))
    (local $h i32)
    (local $r (ref null $result))
    (local $b (ref null $str))
    (local $__gc76 (ref null $result))
    (local $__gc77 (ref null $result))
    local.get $path
    call $resolve
    local.set $__gc76
    local.get $__gc76
    struct.get $result $tag
    (if
      (then
    local.get $__gc76
    return ;; propagate Error
      )
    )
    local.get $__gc76
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $p
    local.get $p
    i32.const 0
    call $wasiOpen
    local.set $h
    local.get $h
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s109
    call $__i32_sub_chk
    local.get $h
    global.get $__s110
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $h
    call $wasiReadAll
    local.set $r
    local.get $h
    call $wasiClose
    local.get $r
    call $okBytes
    local.set $__gc77
    local.get $__gc77
    struct.get $result $tag
    (if
      (then
    local.get $__gc77
    return ;; propagate Error
      )
    )
    local.get $__gc77
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $b
    i32.const 0
    local.get $b
    struct.new $result
    return
  )
  (func $writeBytesWasm (param $path (ref null $str)) (param $contents (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $p (ref null $str))
    (local $h i32)
    (local $n i32)
    (local $__gc78 (ref null $result))
    local.get $path
    call $resolve
    local.set $__gc78
    local.get $__gc78
    struct.get $result $tag
    (if
      (then
    local.get $__gc78
    return ;; propagate Error
      )
    )
    local.get $__gc78
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $p
    local.get $p
    i32.const 1
    call $wasiOpen
    local.set $h
    local.get $h
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s111
    call $__i32_sub_chk
    local.get $h
    global.get $__s112
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $h
    local.get $contents
    call $wasiWrite
    local.set $n
    local.get $h
    call $wasiClose
    local.get $n
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s113
    call $__i32_sub_chk
    local.get $n
    global.get $__s114
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $writeTextWasm (param $path (ref null $str)) (param $contents (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $n i32)
    (local $__gc79 (ref null $result))
    local.get $path
    local.get $contents
    call $writeBytesWasm
    local.set $__gc79
    local.get $__gc79
    struct.get $result $tag
    (if
      (then
    local.get $__gc79
    return ;; propagate Error
      )
    )
    local.get $__gc79
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $n
    i32.const 0
    local.get $n
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $appendTextWasm (param $path (ref null $str)) (param $contents (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $p (ref null $str))
    (local $h i32)
    (local $at i64)
    (local $n i32)
    (local $__gc80 (ref null $result))
    local.get $path
    call $resolve
    local.set $__gc80
    local.get $__gc80
    struct.get $result $tag
    (if
      (then
    local.get $__gc80
    return ;; propagate Error
      )
    )
    local.get $__gc80
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $p
    local.get $p
    i32.const 2
    call $wasiOpen
    local.set $h
    local.get $h
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s115
    call $__i32_sub_chk
    local.get $h
    global.get $__s116
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $h
    call $wasiSizeRaw
    local.set $at
    local.get $at
    i32.const 0
    i64.extend_i32_s
    i64.lt_s
    (if (result (ref null $result))
      (then
    local.get $h
    call $wasiClose
    i32.const 1
    i32.const 13
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $h
    local.get $at
    call $wasiSeek
    local.get $h
    local.get $contents
    call $wasiWrite
    local.set $n
    local.get $h
    call $wasiClose
    local.get $n
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s117
    call $__i32_sub_chk
    local.get $n
    global.get $__s118
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; The offset of the first byte that starts a sequence that is not UTF-8, `-1` when there is none.
  (func $utf8OffsetWasm (param $data (ref null $str)) (result i64)
    (local $n i32)
    (local $i i32)
    (local $c i32)
    (local $k i32)
    (local $lo i32)
    (local $hi i32)
    (local $d i32)
    (local $j i32)
    (local $e i32)
    (local $__conv0 i32)
    (local $__conv1 i32)
    (local $__conv2 i32)
    (local $__conv3 i32)
    local.get $data
    array.len
    local.set $n
    i32.const 0
    local.set $i
    (block $__break
      (loop $__continue
    local.get $i
    local.get $n
    i32.lt_s
        i32.eqz
        br_if $__break
        (block $__next
    local.get $data
    local.get $i
    call $wasiByteAt
    local.set $c
    local.get $c
    i32.const 128
    i32.lt_s
    (if (result i64)
      (then
    local.get $i
    i32.const 1
    global.get $__s119
    call $__i32_add_chk
    local.set $i
    br $__next
      )
      (else
        i64.const 0
      )
    )
    drop
    i32.const 0
    local.set $k
    local.get $c
    i32.const 194
    i32.ge_s
    (if (result i32)
      (then
    local.get $c
    i32.const 223
    i32.le_s
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    i32.const 1
    local.set $k
    i32.const 0
      )
      (else
    local.get $c
    i32.const 224
    i32.ge_s
    (if (result i32)
      (then
    local.get $c
    i32.const 239
    i32.le_s
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    i32.const 2
    local.set $k
    i32.const 0
      )
      (else
    local.get $c
    i32.const 240
    i32.ge_s
    (if (result i32)
      (then
    local.get $c
    i32.const 244
    i32.le_s
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    i32.const 3
    local.set $k
    i32.const 0
      )
      (else
    local.get $i
    local.set $__conv0
    local.get $__conv0
    i64.extend_i32_s
    return
      )
    )
      )
    )
      )
    )
    drop
    local.get $i
    local.get $k
    global.get $__s120
    call $__i32_add_chk
    local.get $n
    i32.ge_s
    (if (result i64)
      (then
    local.get $i
    local.set $__conv1
    local.get $__conv1
    i64.extend_i32_s
    return
      )
      (else
        i64.const 0
      )
    )
    drop
    i32.const 128
    local.set $lo
    i32.const 191
    local.set $hi
    local.get $c
    i32.const 224
    i32.eq
    (if (result i32)
      (then
    i32.const 160
    local.set $lo
    i32.const 0
      )
      (else
    local.get $c
    i32.const 237
    i32.eq
    (if (result i32)
      (then
    i32.const 159
    local.set $hi
    i32.const 0
      )
      (else
    local.get $c
    i32.const 240
    i32.eq
    (if (result i32)
      (then
    i32.const 144
    local.set $lo
    i32.const 0
      )
      (else
    local.get $c
    i32.const 244
    i32.eq
    (if (result i32)
      (then
    i32.const 143
    local.set $hi
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
      )
    )
      )
    )
      )
    )
    drop
    local.get $data
    local.get $i
    i32.const 1
    global.get $__s121
    call $__i32_add_chk
    call $wasiByteAt
    local.set $d
    local.get $d
    local.get $lo
    i32.lt_s
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $d
    local.get $hi
    i32.gt_s
      )
    )
    (if (result i64)
      (then
    local.get $i
    local.set $__conv2
    local.get $__conv2
    i64.extend_i32_s
    return
      )
      (else
        i64.const 0
      )
    )
    drop
    i32.const 2
    local.set $j
    (block $__break
      (loop $__continue
    local.get $j
    local.get $k
    i32.le_s
        i32.eqz
        br_if $__break
    local.get $data
    local.get $i
    local.get $j
    global.get $__s122
    call $__i32_add_chk
    call $wasiByteAt
    local.set $e
    local.get $e
    i32.const 128
    i32.lt_s
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $e
    i32.const 191
    i32.gt_s
      )
    )
    (if (result i64)
      (then
    local.get $i
    local.set $__conv3
    local.get $__conv3
    i64.extend_i32_s
    return
      )
      (else
        i64.const 0
      )
    )
    drop
    local.get $j
    i32.const 1
    global.get $__s123
    call $__i32_add_chk
    local.set $j
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $i
    local.get $k
    global.get $__s124
    call $__i32_add_chk
    i32.const 1
    global.get $__s125
    call $__i32_add_chk
    local.set $i
        )
        br $__continue
      )
    )
    i32.const 0
    drop
    i32.const 0
    i32.const 1
    global.get $__s126
    call $__i32_sub_chk
    i64.extend_i32_s
    return
  )
  (func $stripEolWasm (param $line (ref null $str)) (result (ref null $str))
    (local $n i32)
    (local $__gc81 i32)
    (local $__gc82 i32)
    (local $__gc83 (ref null $str))
    (local $__gc84 i32)
    local.get $line
    array.len
    local.set $n
    local.get $n
    i32.const 0
    i32.gt_s
    (if (result i32)
      (then
    local.get $line
    local.get $n
    i32.const 1
    global.get $__s127
    call $__i32_sub_chk
    call $wasiByteAt
    i32.const 10
    i32.eq
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    local.get $n
    i32.const 1
    global.get $__s128
    call $__i32_sub_chk
    local.set $n
    local.get $n
    i32.const 0
    i32.gt_s
    (if (result i32)
      (then
    local.get $line
    local.get $n
    i32.const 1
    global.get $__s129
    call $__i32_sub_chk
    call $wasiByteAt
    i32.const 13
    i32.eq
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    local.get $n
    i32.const 1
    global.get $__s130
    call $__i32_sub_chk
    local.set $n
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $line
    i32.const 0
    local.get $n
    local.set $__gc81
    local.set $__gc82
    local.set $__gc83
    global.get $__heap_ptr
    local.set $__gc84
    local.get $__gc83
    call $__gc_to_lin_str
    local.get $__gc82
    local.get $__gc81
    call $__std_bytes_slice
    call $__lin_to_gc_str
    local.get $__gc84
    global.set $__heap_ptr
    return
  )
  (func $openWasm (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $p (ref null $str))
    (local $h i32)
    (local $handle anyref)
    (local $__gc85 (ref null $result))
    local.get $path
    call $resolve
    local.set $__gc85
    local.get $__gc85
    struct.get $result $tag
    (if
      (then
    local.get $__gc85
    return ;; propagate Error
      )
    )
    local.get $__gc85
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $p
    local.get $p
    i32.const 0
    call $wasiOpen
    local.set $h
    local.get $h
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s131
    call $__i32_sub_chk
    local.get $h
    global.get $__s132
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $h
    struct.new $box_i32
    local.set $handle
    i32.const 0
    local.get $handle
    struct.new $result
    return
  )
  (func $createWasm (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $p (ref null $str))
    (local $h i32)
    (local $handle anyref)
    (local $__gc86 (ref null $result))
    local.get $path
    call $resolve
    local.set $__gc86
    local.get $__gc86
    struct.get $result $tag
    (if
      (then
    local.get $__gc86
    return ;; propagate Error
      )
    )
    local.get $__gc86
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $p
    local.get $p
    i32.const 1
    call $wasiOpen
    local.set $h
    local.get $h
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s133
    call $__i32_sub_chk
    local.get $h
    global.get $__s134
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $h
    struct.new $box_i32
    local.set $handle
    i32.const 0
    local.get $handle
    struct.new $result
    return
  )
  (func $memHandleWasm (param $data (ref null $str)) (result anyref)
    (local $handle anyref)
    local.get $data
    call $wasiOpenMem
    struct.new $box_i32
    local.set $handle
    local.get $handle
    return
  )
  (func $sizeWasm (param $handle anyref) (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $n i64)
    (local $__gc87 (ref null $result))
    local.get $handle
    call $blockOf
    call $wasiSize
    call $okSize
    local.set $__gc87
    local.get $__gc87
    struct.get $result $tag
    (if
      (then
    local.get $__gc87
    return ;; propagate Error
      )
    )
    local.get $__gc87
    struct.get $result $payload
    ref.cast (ref null $box_i64)
    struct.get $box_i64 $v
    local.set $n
    i32.const 0
    local.get $n
    struct.new $box_i64
    struct.new $result
    return
  )
  (func $readWasm (param $handle anyref) (param $n i32) (result (ref null $result))
    (local $_try0 i32)
    (local $b (ref null $str))
    (local $__gc88 (ref null $result))
    local.get $handle
    call $blockOf
    local.get $n
    call $wasiRead
    call $okBytes
    local.set $__gc88
    local.get $__gc88
    struct.get $result $tag
    (if
      (then
    local.get $__gc88
    return ;; propagate Error
      )
    )
    local.get $__gc88
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $b
    i32.const 0
    local.get $b
    struct.new $result
    return
  )
  (func $readAllWasm (param $handle anyref) (result (ref null $result))
    (local $_try0 i32)
    (local $b (ref null $str))
    (local $__gc89 (ref null $result))
    local.get $handle
    call $blockOf
    call $wasiReadAll
    call $okBytes
    local.set $__gc89
    local.get $__gc89
    struct.get $result $tag
    (if
      (then
    local.get $__gc89
    return ;; propagate Error
      )
    )
    local.get $__gc89
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $b
    i32.const 0
    local.get $b
    struct.new $result
    return
  )
  (func $readLineWasm (param $handle anyref) (result (ref null $result))
    (local $_try0 i32)
    (local $b (ref null $str))
    (local $__gc90 (ref null $result))
    local.get $handle
    call $blockOf
    call $wasiReadLine
    call $okBytes
    local.set $__gc90
    local.get $__gc90
    struct.get $result $tag
    (if
      (then
    local.get $__gc90
    return ;; propagate Error
      )
    )
    local.get $__gc90
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $b
    i32.const 0
    local.get $b
    struct.new $result
    return
  )
  ;; The SHA-256 of the whole file, the position where it was.
  (func $hashWasm (param $handle anyref) (result (ref null $result))
    (local $_try0 i32)
    (local $block i32)
    (local $at i64)
    (local $r (ref null $result))
    (local $b (ref null $str))
    (local $__gc91 (ref null $result))
    local.get $handle
    call $blockOf
    local.set $block
    local.get $block
    call $wasiTell
    local.set $at
    local.get $block
    i32.const 0
    i64.extend_i32_s
    call $wasiSeek
    local.get $block
    call $wasiReadAll
    local.set $r
    local.get $block
    local.get $at
    call $wasiSeek
    local.get $r
    call $okBytes
    local.set $__gc91
    local.get $__gc91
    struct.get $result $tag
    (if
      (then
    local.get $__gc91
    return ;; propagate Error
      )
    )
    local.get $__gc91
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $b
    i32.const 0
    local.get $b
    call $wasiSha256
    struct.new $result
    return
  )
  (func $writeWasm (param $handle anyref) (param $data (ref null $str)) (result (ref null $result))
    (local $n i32)
    local.get $handle
    call $blockOf
    local.get $data
    call $wasiWrite
    local.set $n
    local.get $n
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s135
    call $__i32_sub_chk
    local.get $n
    global.get $__s136
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    local.get $n
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $closeWasm (param $handle anyref) (result (ref null $result))
    local.get $handle
    call $blockOf
    call $wasiClose
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $readOnlyWasm (param $handle anyref) (result i32)
    local.get $handle
    call $blockOf
    call $wasiIsMem
    return
  )
  (func $existsWasm (param $path (ref null $str)) (result i32)
    (local $p i32)
    (local $__case_0 (ref null $result))
    (local $p__33 (ref null $str))
    local.get $path
    call $resolve
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result i32)
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $p__33
    local.get $p__33
    i32.const 1
    call $wasiStatKind
    i32.const 0
    i32.ge_s
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result i32)
      (then
    i32.const 0
      )
      (else
    i32.const 0
      )
    )
      )
    )
    return
  )
  (func $listWasm (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $_try1 i32)
    (local $p (ref null $str))
    (local $names (ref null $arr_any))
    (local $__gc92 (ref null $result))
    (local $__gc93 (ref null $result))
    local.get $path
    call $resolve
    local.set $__gc92
    local.get $__gc92
    struct.get $result $tag
    (if
      (then
    local.get $__gc92
    return ;; propagate Error
      )
    )
    local.get $__gc92
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $p
    local.get $p
    call $wasiList
    call $okStrings
    local.set $__gc93
    local.get $__gc93
    struct.get $result $tag
    (if
      (then
    local.get $__gc93
    return ;; propagate Error
      )
    )
    local.get $__gc93
    struct.get $result $payload
    ref.cast (ref null $arr_any)
    local.set $names
    i32.const 0
    local.get $names
    call $sortedStrings
    struct.new $result
    return
  )
  (func $mkdirWasm (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $p (ref null $str))
    (local $r i32)
    (local $__gc94 (ref null $result))
    local.get $path
    call $resolve
    local.set $__gc94
    local.get $__gc94
    struct.get $result $tag
    (if
      (then
    local.get $__gc94
    return ;; propagate Error
      )
    )
    local.get $__gc94
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $p
    local.get $p
    call $wasiMkdir
    local.set $r
    local.get $r
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s137
    call $__i32_sub_chk
    local.get $r
    global.get $__s138
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; The directory and every missing one above it. One that is there is `Ok`; a file in the way is
  ;; `EEXIST` when it is the directory asked for, `ENOTDIR` when it is above it.
  (func $mkdirRecursiveWasm (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $p (ref null $str))
    (local $parts (ref null $arr_any))
    (local $pieces (ref null $arr_any))
    (local $i i32)
    (local $piece (ref null $str))
    (local $__bp_nullish i32)
    (local $prefix (ref null $str))
    (local $k i32)
    (local $kind i32)
    (local $made i32)
    (local $__gc95 (ref null $result))
    (local $__gc96 (ref null $str))
    (local $__gc97 (ref null $str))
    (local $__gc98 i32)
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__34 (ref null $str))
    (local $__opt1 (ref null $str))
    (local $__bp_nullish__35 (ref null $str))
    local.get $path
    call $resolve
    local.set $__gc95
    local.get $__gc95
    struct.get $result $tag
    (if
      (then
    local.get $__gc95
    return ;; propagate Error
      )
    )
    local.get $__gc95
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $p
    array.new_fixed $arr_any 0
    local.set $parts
    local.get $p
    global.get $__s105
    local.set $__gc96
    local.set $__gc97
    global.get $__heap_ptr
    local.set $__gc98
    local.get $__gc97
    call $__gc_to_lin_str
    local.get $__gc96
    call $__gc_to_lin_str
    call $__std_text_split
    call $__lin_to_gc_strs
    local.get $__gc98
    global.set $__heap_ptr
    local.set $pieces
    i32.const 0
    local.set $i
    (block $__break
      (loop $__continue
    local.get $i
    local.get $pieces
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $pieces
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__34
    local.get $__bp_nullish__34
      )
      (else
    global.get $__s0
      )
    )
    local.set $piece
    local.get $i
    i32.const 1
    global.get $__s139
    call $__i32_add_chk
    local.set $i
    local.get $piece
    global.get $__s0
    call $__str_eq
    i32.eqz
    (if (result i32)
      (then
    local.get $piece
    global.get $__s5
    call $__str_eq
    i32.eqz
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    local.get $parts
    local.get $piece
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $parts
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
        br $__continue
      )
    )
    i32.const 0
    drop
    global.get $__s0
    local.set $prefix
    i32.const 0
    local.set $k
    (block $__break
      (loop $__continue
    local.get $k
    local.get $parts
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
        (block $__next
    local.get $prefix
    local.get $parts
    local.get $k
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt1
    local.set $__bp_nullish__35
    local.get $__bp_nullish__35
      )
      (else
    global.get $__s0
      )
    )
    call $joinPath
    local.set $prefix
    local.get $k
    i32.const 1
    global.get $__s140
    call $__i32_add_chk
    local.set $k
    local.get $prefix
    i32.const 1
    call $wasiStatKind
    local.set $kind
    local.get $kind
    i32.const 3
    i32.eq
    (if (result (ref null $result))
      (then
    br $__next
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $kind
    i32.const 0
    i32.ge_s
    (if (result (ref null $result))
      (then
    local.get $k
    local.get $parts
    array.len
    i32.eq
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 7
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 1
    i32.const 24
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $prefix
    call $wasiMkdir
    local.set $made
    local.get $made
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s141
    call $__i32_sub_chk
    local.get $made
    global.get $__s142
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
        )
        br $__continue
      )
    )
    i32.const 0
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; The FILE at `path`: a directory is `EISDIR`, whatever it holds.
  (func $rmWasm (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $p (ref null $str))
    (local $kind i32)
    (local $r i32)
    (local $__gc99 (ref null $result))
    local.get $path
    call $resolve
    local.set $__gc99
    local.get $__gc99
    struct.get $result $tag
    (if
      (then
    local.get $__gc99
    return ;; propagate Error
      )
    )
    local.get $__gc99
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $p
    local.get $p
    i32.const 0
    call $wasiStatKind
    local.set $kind
    local.get $kind
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s143
    call $__i32_sub_chk
    local.get $kind
    global.get $__s144
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $kind
    i32.const 3
    i32.eq
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 14
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $p
    call $wasiUnlink
    local.set $r
    local.get $r
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s145
    call $__i32_sub_chk
    local.get $r
    global.get $__s146
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $copyWasm (param $src (ref null $str)) (param $dest (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $_try1 i32)
    (local $contents (ref null $str))
    (local $written i32)
    (local $__gc100 (ref null $result))
    (local $__gc101 (ref null $result))
    local.get $src
    call $readBytesWasm
    local.set $__gc100
    local.get $__gc100
    struct.get $result $tag
    (if
      (then
    local.get $__gc100
    return ;; propagate Error
      )
    )
    local.get $__gc100
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $contents
    local.get $dest
    local.get $contents
    call $writeBytesWasm
    local.set $__gc101
    local.get $__gc101
    struct.get $result $tag
    (if
      (then
    local.get $__gc101
    return ;; propagate Error
      )
    )
    local.get $__gc101
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $written
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $statWasm (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $_try1 i32)
    (local $_try2 i32)
    (local $__mem0 i32)
    (local $p (ref null $str))
    (local $kind i32)
    (local $size i64)
    (local $seconds i64)
    (local $__gc102 (ref null $result))
    (local $__gc103 (ref null $result))
    (local $__gc104 (ref null $result))
    local.get $path
    call $resolve
    local.set $__gc102
    local.get $__gc102
    struct.get $result $tag
    (if
      (then
    local.get $__gc102
    return ;; propagate Error
      )
    )
    local.get $__gc102
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $p
    local.get $p
    i32.const 1
    call $wasiStatKind
    local.set $kind
    local.get $kind
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s147
    call $__i32_sub_chk
    local.get $kind
    global.get $__s148
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $p
    call $wasiStatSize
    call $okSize
    local.set $__gc103
    local.get $__gc103
    struct.get $result $tag
    (if
      (then
    local.get $__gc103
    return ;; propagate Error
      )
    )
    local.get $__gc103
    struct.get $result $payload
    ref.cast (ref null $box_i64)
    struct.get $box_i64 $v
    local.set $size
    local.get $p
    call $wasiStatMtime
    call $okSize
    local.set $__gc104
    local.get $__gc104
    struct.get $result $tag
    (if
      (then
    local.get $__gc104
    return ;; propagate Error
      )
    )
    local.get $__gc104
    struct.get $result $payload
    ref.cast (ref null $box_i64)
    struct.get $box_i64 $v
    local.set $seconds
    i32.const 0
    local.get $size
    local.get $seconds
    i32.const 1000
    i64.extend_i32_s
    global.get $__s149
    call $__i64_mul_chk
    local.get $kind
    i32.const 3
    i32.eq
    struct.new $rec_FileStat
    struct.new $result
    return
  )
  ;; The regular files under `root` and the links whose target is missing, as paths relative to it, in
  ;; directory order: a work list of directories, not a recursion (a recursive `try` is not lowered on wasm).
  (func $walkWasm (param $root (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    (local $__mem5 i32)
    (local $__mem6 i32)
    (local $__mem7 i32)
    (local $__mem8 i32)
    (local $p (ref null $str))
    (local $kind i32)
    (local $dirs (ref null $arr_any))
    (local $rels (ref null $arr_any))
    (local $files (ref null $arr_any))
    (local $dangling (ref null $arr_any))
    (local $next i32)
    (local $dir (ref null $str))
    (local $__bp_nullish i32)
    (local $rel (ref null $str))
    (local $names (ref null $arr_any))
    (local $i i32)
    (local $name (ref null $str))
    (local $full (ref null $str))
    (local $sub (ref null $str))
    (local $entry i32)
    (local $__gc105 (ref null $result))
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__36 (ref null $str))
    (local $__opt1 (ref null $str))
    (local $__bp_nullish__37 (ref null $str))
    (local $__gc106 (ref null $result))
    (local $__opt2 (ref null $str))
    (local $__bp_nullish__38 (ref null $str))
    local.get $root
    call $resolve
    local.set $__gc105
    local.get $__gc105
    struct.get $result $tag
    (if
      (then
    local.get $__gc105
    return ;; propagate Error
      )
    )
    local.get $__gc105
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $p
    local.get $p
    i32.const 1
    call $wasiStatKind
    local.set $kind
    local.get $kind
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s150
    call $__i32_sub_chk
    local.get $kind
    global.get $__s151
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $kind
    i32.const 3
    i32.ne
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 24
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $p
    array.new_fixed $arr_any 1
    local.set $dirs
    global.get $__s0
    array.new_fixed $arr_any 1
    local.set $rels
    array.new_fixed $arr_any 0
    local.set $files
    array.new_fixed $arr_any 0
    local.set $dangling
    i32.const 0
    local.set $next
    (block $__break
      (loop $__continue
    local.get $next
    local.get $dirs
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $dirs
    local.get $next
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__36
    local.get $__bp_nullish__36
      )
      (else
    global.get $__s0
      )
    )
    local.set $dir
    local.get $rels
    local.get $next
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt1
    local.set $__bp_nullish__37
    local.get $__bp_nullish__37
      )
      (else
    global.get $__s0
      )
    )
    local.set $rel
    local.get $next
    i32.const 1
    global.get $__s152
    call $__i32_add_chk
    local.set $next
    local.get $dir
    call $wasiList
    call $okStrings
    local.set $__gc106
    local.get $__gc106
    struct.get $result $tag
    (if
      (then
    local.get $__gc106
    return ;; propagate Error
      )
    )
    local.get $__gc106
    struct.get $result $payload
    ref.cast (ref null $arr_any)
    local.set $names
    i32.const 0
    local.set $i
    (block $__break
      (loop $__continue
    local.get $i
    local.get $names
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $names
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt2
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt2
    local.set $__bp_nullish__38
    local.get $__bp_nullish__38
      )
      (else
    global.get $__s0
      )
    )
    local.set $name
    local.get $i
    i32.const 1
    global.get $__s153
    call $__i32_add_chk
    local.set $i
    local.get $dir
    local.get $name
    call $joinPath
    local.set $full
    local.get $rel
    local.get $name
    call $joinPath
    local.set $sub
    local.get $full
    i32.const 1
    call $wasiStatKind
    local.set $entry
    local.get $entry
    i32.const 0
    i32.lt_s
    (if (result i32)
      (then
    local.get $entry
    i32.const 0
    i32.const 21
    global.get $__s154
    call $__i32_sub_chk
    i32.ne
      )
      (else
    i32.const 0
      )
    )
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s155
    call $__i32_sub_chk
    local.get $entry
    global.get $__s156
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $entry
    i32.const 3
    i32.eq
    (if (result i32)
      (then
    local.get $dirs
    local.get $full
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $dirs
    local.get $rels
    local.get $sub
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $rels
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $entry
    i32.const 6
    i32.eq
    (if (result i32)
      (then
    local.get $files
    local.get $sub
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $files
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $entry
    i32.const 0
    i32.const 21
    global.get $__s157
    call $__i32_sub_chk
    i32.eq
    (if (result i32)
      (then
    local.get $dangling
    local.get $sub
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $dangling
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
        br $__continue
      )
    )
    i32.const 0
    drop
        br $__continue
      )
    )
    i32.const 0
    drop
    i32.const 0
    local.get $files
    call $sortedStrings
    local.get $dangling
    call $sortedStrings
    struct.new $rec_Walked
    struct.new $result
    return
  )
  ;; Whether the segment holds a wildcard.
  (func $isMagic (param $seg (ref null $str)) (result i32)
    (local $__gc107 (ref null $str))
    (local $__gc108 (ref null $str))
    (local $__gc109 i32)
    (local $__gc110 (ref null $str))
    (local $__gc111 (ref null $str))
    (local $__gc112 i32)
    (local $__gc113 (ref null $str))
    (local $__gc114 (ref null $str))
    (local $__gc115 i32)
    (local $__gc116 (ref null $str))
    (local $__gc117 (ref null $str))
    (local $__gc118 i32)
    local.get $seg
    global.get $__s158
    local.set $__gc107
    local.set $__gc108
    global.get $__heap_ptr
    local.set $__gc109
    local.get $__gc108
    call $__gc_to_lin_str
    local.get $__gc107
    call $__gc_to_lin_str
    call $__std_text_contains
    local.get $__gc109
    global.set $__heap_ptr
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $seg
    global.get $__s159
    local.set $__gc110
    local.set $__gc111
    global.get $__heap_ptr
    local.set $__gc112
    local.get $__gc111
    call $__gc_to_lin_str
    local.get $__gc110
    call $__gc_to_lin_str
    call $__std_text_contains
    local.get $__gc112
    global.set $__heap_ptr
      )
    )
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $seg
    global.get $__s160
    local.set $__gc113
    local.set $__gc114
    global.get $__heap_ptr
    local.set $__gc115
    local.get $__gc114
    call $__gc_to_lin_str
    local.get $__gc113
    call $__gc_to_lin_str
    call $__std_text_contains
    local.get $__gc115
    global.set $__heap_ptr
      )
    )
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $seg
    global.get $__s161
    local.set $__gc116
    local.set $__gc117
    global.get $__heap_ptr
    local.set $__gc118
    local.get $__gc117
    call $__gc_to_lin_str
    local.get $__gc116
    call $__gc_to_lin_str
    call $__std_text_contains
    local.get $__gc118
    global.set $__heap_ptr
      )
    )
    return
  )
  ;; A segment with its `{a,b}` alternatives written out, nested ones too; one that is never closed is a name.
  (func $expandBraces (param $seg (ref null $str)) (result (ref null $arr_any))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    (local $cs (ref null $arr_any))
    (local $open i32)
    (local $i i32)
    (local $depth i32)
    (local $close i32)
    (local $cuts (ref null $arr_i32))
    (local $j i32)
    (local $closed i32)
    (local $c (ref null $str))
    (local $__bp_nullish i32)
    (local $head (ref null $str))
    (local $tail (ref null $str))
    (local $out (ref null $arr_any))
    (local $start i32)
    (local $k i32)
    (local $stop i32)
    (local $alt (ref null $str))
    (local $__gc119 (ref null $str))
    (local $__gc120 i32)
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__39 (ref null $str))
    (local $__opt1 (ref null $str))
    (local $__bp_nullish__40 (ref null $str))
    (local $__opt2 anyref)
    local.get $seg
    local.set $__gc119
    global.get $__heap_ptr
    local.set $__gc120
    local.get $__gc119
    call $__gc_to_lin_str
    call $__std_text_chars
    call $__lin_to_gc_strs
    local.get $__gc120
    global.set $__heap_ptr
    local.set $cs
    i32.const 0
    i32.const 1
    global.get $__s162
    call $__i32_sub_chk
    local.set $open
    i32.const 0
    local.set $i
    (block $__break
      (loop $__continue
    local.get $i
    local.get $cs
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $cs
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__39
    local.get $__bp_nullish__39
      )
      (else
    global.get $__s0
      )
    )
    global.get $__s161
    call $__str_eq
    (if (result (ref null $arr_any))
      (then
    local.get $i
    local.set $open
    br $__break
      )
      (else
        ref.null $arr_any
      )
    )
    drop
    local.get $i
    i32.const 1
    global.get $__s163
    call $__i32_add_chk
    local.set $i
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $open
    i32.const 0
    i32.lt_s
    (if (result (ref null $arr_any))
      (then
    local.get $seg
    array.new_fixed $arr_any 1
    return
      )
      (else
        ref.null $arr_any
      )
    )
    drop
    i32.const 0
    local.set $depth
    i32.const 0
    i32.const 1
    global.get $__s164
    call $__i32_sub_chk
    local.set $close
    array.new_fixed $arr_i32 0
    local.set $cuts
    local.get $open
    local.set $j
    i32.const 0
    local.set $closed
    (block $__break
      (loop $__continue
    local.get $j
    local.get $cs
    array.len
    i32.lt_s
    (if (result i32)
      (then
    local.get $closed
    i32.eqz
      )
      (else
    i32.const 0
      )
    )
        i32.eqz
        br_if $__break
    local.get $cs
    local.get $j
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt1
    local.set $__bp_nullish__40
    local.get $__bp_nullish__40
      )
      (else
    global.get $__s0
      )
    )
    local.set $c
    local.get $c
    global.get $__s161
    call $__str_eq
    (if (result i32)
      (then
    local.get $depth
    i32.const 1
    global.get $__s165
    call $__i32_add_chk
    local.set $depth
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $c
    global.get $__s166
    call $__str_eq
    (if (result i32)
      (then
    local.get $depth
    i32.const 1
    global.get $__s167
    call $__i32_sub_chk
    local.set $depth
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $c
    global.get $__s166
    call $__str_eq
    (if (result i32)
      (then
    local.get $depth
    i32.const 0
    i32.eq
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    local.get $j
    local.set $close
    i32.const 1
    local.set $closed
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $c
    global.get $__s168
    call $__str_eq
    (if (result i32)
      (then
    local.get $depth
    i32.const 1
    i32.eq
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    local.get $cuts
    local.get $j
    array.new_fixed $arr_i32 1
    call $__arr_concat_i32
    local.set $cuts
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $j
    i32.const 1
    global.get $__s169
    call $__i32_add_chk
    local.set $j
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $close
    i32.const 0
    i32.lt_s
    (if (result (ref null $arr_any))
      (then
    local.get $seg
    array.new_fixed $arr_any 1
    return
      )
      (else
        ref.null $arr_any
      )
    )
    drop
    local.get $cs
    i32.const 0
    local.get $open
    call $__arr_slice_any
    global.get $__s0
    call $__arr_join_any
    local.set $head
    local.get $cs
    local.get $close
    i32.const 1
    global.get $__s170
    call $__i32_add_chk
    i32.const 2147483647
    call $__arr_slice_any
    global.get $__s0
    call $__arr_join_any
    local.set $tail
    array.new_fixed $arr_any 0
    local.set $out
    local.get $open
    i32.const 1
    global.get $__s171
    call $__i32_add_chk
    local.set $start
    i32.const 0
    local.set $k
    (block $__break
      (loop $__continue
    local.get $k
    local.get $cuts
    array.len
    i32.le_s
        i32.eqz
        br_if $__break
    local.get $close
    local.set $stop
    local.get $k
    local.get $cuts
    array.len
    i32.lt_s
    (if (result i32)
      (then
    local.get $cuts
    local.get $k
    call $__arr_at_opt_i32
    local.tee $__opt2
    ref.is_null
    i32.eqz
    (if (result i32)
      (then
    local.get $__opt2
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    local.get $close
      )
    )
    local.set $stop
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $cs
    local.get $start
    local.get $stop
    call $__arr_slice_any
    global.get $__s0
    call $__arr_join_any
    local.set $alt
    local.get $out
    local.get $head
    local.get $alt
    call $__str_concat
    local.get $tail
    call $__str_concat
    call $expandBraces
    call $__arr_concat_any
    local.set $out
    local.get $stop
    i32.const 1
    global.get $__s172
    call $__i32_add_chk
    local.set $start
    local.get $k
    i32.const 1
    global.get $__s173
    call $__i32_add_chk
    local.set $k
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $out
    return
  )
  ;; The `]` that closes the class opened at `at`, `-1` when there is none (the `[` is then a name).
  (func $classEnd (param $pat (ref null $arr_any)) (param $at i32) (result i32)
    (local $j i32)
    (local $__opt0 (ref null $str))
    (local $__bp_nullish (ref null $str))
    (local $__opt1 (ref null $str))
    (local $__opt2 (ref null $str))
    (local $__opt3 (ref null $str))
    local.get $at
    i32.const 1
    global.get $__s174
    call $__i32_add_chk
    local.set $j
    local.get $j
    local.get $pat
    array.len
    i32.lt_s
    (if (result i32)
      (then
    local.get $pat
    local.get $j
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    global.get $__s0
      )
    )
    global.get $__s175
    call $__str_eq
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $pat
    local.get $j
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt1
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    global.get $__s0
      )
    )
    global.get $__s176
    call $__str_eq
      )
    )
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    local.get $j
    i32.const 1
    global.get $__s177
    call $__i32_add_chk
    local.set $j
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $j
    local.get $pat
    array.len
    i32.lt_s
    (if (result i32)
      (then
    local.get $pat
    local.get $j
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt2
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt2
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    global.get $__s0
      )
    )
    global.get $__s178
    call $__str_eq
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    local.get $j
    i32.const 1
    global.get $__s179
    call $__i32_add_chk
    local.set $j
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    (block $__break
      (loop $__continue
    local.get $j
    local.get $pat
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $pat
    local.get $j
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt3
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt3
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    global.get $__s0
      )
    )
    global.get $__s178
    call $__str_eq
    (if (result i32)
      (then
    local.get $j
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $j
    i32.const 1
    global.get $__s180
    call $__i32_add_chk
    local.set $j
        br $__continue
      )
    )
    i32.const 0
    drop
    i32.const 0
    i32.const 1
    global.get $__s181
    call $__i32_sub_chk
    return
  )
  ;; Whether `ch` is in the class written between `first` and `stop` (`!` or `^` first negates it, `a-z` is a range).
  (func $classHas (param $pat (ref null $arr_any)) (param $first i32) (param $stop i32) (param $ch (ref null $str)) (result i32)
    (local $i i32)
    (local $negate i32)
    (local $found i32)
    (local $lo (ref null $str))
    (local $__bp_nullish i32)
    (local $hi (ref null $str))
    (local $c i32)
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__41 (ref null $str))
    (local $__opt1 (ref null $str))
    (local $__bp_nullish__42 (ref null $str))
    (local $__opt2 (ref null $str))
    (local $__bp_nullish__43 (ref null $str))
    (local $__opt3 (ref null $str))
    (local $__bp_nullish__44 (ref null $str))
    (local $__opt4 (ref null $str))
    (local $__bp_nullish__45 (ref null $str))
    local.get $first
    local.set $i
    i32.const 0
    local.set $negate
    local.get $i
    local.get $stop
    i32.lt_s
    (if (result i32)
      (then
    local.get $pat
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__41
    local.get $__bp_nullish__41
      )
      (else
    global.get $__s0
      )
    )
    global.get $__s175
    call $__str_eq
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $pat
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt1
    local.set $__bp_nullish__42
    local.get $__bp_nullish__42
      )
      (else
    global.get $__s0
      )
    )
    global.get $__s176
    call $__str_eq
      )
    )
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    i32.const 1
    local.set $negate
    local.get $i
    i32.const 1
    global.get $__s182
    call $__i32_add_chk
    local.set $i
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    i32.const 0
    local.set $found
    (block $__break
      (loop $__continue
    local.get $i
    local.get $stop
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $pat
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt2
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt2
    local.set $__bp_nullish__43
    local.get $__bp_nullish__43
      )
      (else
    global.get $__s0
      )
    )
    local.set $lo
    local.get $i
    i32.const 2
    global.get $__s183
    call $__i32_add_chk
    local.get $stop
    i32.lt_s
    (if (result i32)
      (then
    local.get $pat
    local.get $i
    i32.const 1
    global.get $__s184
    call $__i32_add_chk
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt3
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt3
    local.set $__bp_nullish__44
    local.get $__bp_nullish__44
      )
      (else
    global.get $__s0
      )
    )
    global.get $__s185
    call $__str_eq
      )
      (else
    i32.const 0
      )
    )
    (if
      (then
    local.get $pat
    local.get $i
    i32.const 2
    global.get $__s186
    call $__i32_add_chk
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt4
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt4
    local.set $__bp_nullish__45
    local.get $__bp_nullish__45
      )
      (else
    global.get $__s0
      )
    )
    local.set $hi
    local.get $ch
    i32.const 0
    call $__std_text_charCodeAt
    local.set $c
    local.get $lo
    i32.const 0
    call $__std_text_charCodeAt
    local.get $c
    i32.le_s
    (if (result i32)
      (then
    local.get $c
    local.get $hi
    i32.const 0
    call $__std_text_charCodeAt
    i32.le_s
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    i32.const 1
    local.set $found
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $i
    i32.const 3
    global.get $__s187
    call $__i32_add_chk
    local.set $i
      )
      (else
    local.get $lo
    local.get $ch
    call $__str_eq
    (if (result i32)
      (then
    i32.const 1
    local.set $found
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $i
    i32.const 1
    global.get $__s188
    call $__i32_add_chk
    local.set $i
      )
    )
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $found
    local.get $negate
    i32.ne
    return
  )
  ;; `name` against one pattern without braces: `*`, `?`, `[…]`.
  (func $globMatch (param $pat (ref null $arr_any)) (param $begin i32) (param $name (ref null $arr_any)) (param $offset i32) (result i32)
    (local $p i32)
    (local $n i32)
    (local $c (ref null $str))
    (local $__bp_nullish i32)
    (local $k i32)
    (local $ch (ref null $str))
    (local $end i32)
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__46 (ref null $str))
    (local $__opt1 (ref null $str))
    (local $__bp_nullish__47 (ref null $str))
    (local $__opt2 (ref null $str))
    (local $__bp_nullish__48 (ref null $str))
    local.get $begin
    local.set $p
    local.get $offset
    local.set $n
    (block $__break
      (loop $__continue
    local.get $p
    local.get $pat
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $pat
    local.get $p
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__46
    local.get $__bp_nullish__46
      )
      (else
    global.get $__s0
      )
    )
    local.set $c
    local.get $c
    global.get $__s158
    call $__str_eq
    (if (result i32)
      (then
    (block $__break
      (loop $__continue
    local.get $p
    local.get $pat
    array.len
    i32.lt_s
    (if (result i32)
      (then
    local.get $pat
    local.get $p
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt1
    local.set $__bp_nullish__47
    local.get $__bp_nullish__47
      )
      (else
    global.get $__s0
      )
    )
    global.get $__s158
    call $__str_eq
      )
      (else
    i32.const 0
      )
    )
        i32.eqz
        br_if $__break
    local.get $p
    i32.const 1
    global.get $__s189
    call $__i32_add_chk
    local.set $p
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $p
    local.get $pat
    array.len
    i32.eq
    (if (result i32)
      (then
    i32.const 1
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $n
    local.set $k
    (block $__break
      (loop $__continue
    local.get $k
    local.get $name
    array.len
    i32.le_s
        i32.eqz
        br_if $__break
    local.get $pat
    local.get $p
    local.get $name
    local.get $k
    call $globMatch
    (if (result i32)
      (then
    i32.const 1
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $k
    i32.const 1
    global.get $__s190
    call $__i32_add_chk
    local.set $k
        br $__continue
      )
    )
    i32.const 0
    drop
    i32.const 0
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $n
    local.get $name
    array.len
    i32.ge_s
    (if (result i32)
      (then
    i32.const 0
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $name
    local.get $n
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt2
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt2
    local.set $__bp_nullish__48
    local.get $__bp_nullish__48
      )
      (else
    global.get $__s0
      )
    )
    local.set $ch
    local.get $c
    global.get $__s159
    call $__str_eq
    (if (result i32)
      (then
    local.get $p
    i32.const 1
    global.get $__s191
    call $__i32_add_chk
    local.set $p
    local.get $n
    i32.const 1
    global.get $__s192
    call $__i32_add_chk
    local.set $n
    i32.const 0
      )
      (else
    local.get $c
    global.get $__s160
    call $__str_eq
    (if (result i32)
      (then
    local.get $pat
    local.get $p
    call $classEnd
    local.set $end
    local.get $end
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $ch
    global.get $__s160
    call $__str_eq
    i32.eqz
    (if (result i32)
      (then
    i32.const 0
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $p
    i32.const 1
    global.get $__s193
    call $__i32_add_chk
    local.set $p
    local.get $n
    i32.const 1
    global.get $__s194
    call $__i32_add_chk
    local.set $n
      )
      (else
    local.get $pat
    local.get $p
    i32.const 1
    global.get $__s195
    call $__i32_add_chk
    local.get $end
    local.get $ch
    call $classHas
    i32.eqz
    (if (result i32)
      (then
    i32.const 0
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $end
    i32.const 1
    global.get $__s196
    call $__i32_add_chk
    local.set $p
    local.get $n
    i32.const 1
    global.get $__s197
    call $__i32_add_chk
    local.set $n
      )
    )
    i32.const 0
      )
      (else
    local.get $c
    local.get $ch
    call $__str_eq
    i32.eqz
    (if (result i32)
      (then
    i32.const 0
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $p
    i32.const 1
    global.get $__s198
    call $__i32_add_chk
    local.set $p
    local.get $n
    i32.const 1
    global.get $__s199
    call $__i32_add_chk
    local.set $n
    i32.const 0
      )
    )
      )
    )
    drop
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $n
    local.get $name
    array.len
    i32.eq
    return
  )
  (func $segmentMatches (param $seg (ref null $str)) (param $name (ref null $str)) (result i32)
    (local $alts (ref null $arr_any))
    (local $chars (ref null $arr_any))
    (local $i i32)
    (local $__gc121 (ref null $str))
    (local $__gc122 i32)
    (local $__opt0 (ref null $str))
    (local $__bp_nullish (ref null $str))
    (local $__gc123 (ref null $str))
    (local $__gc124 i32)
    local.get $seg
    call $expandBraces
    local.set $alts
    local.get $name
    local.set $__gc121
    global.get $__heap_ptr
    local.set $__gc122
    local.get $__gc121
    call $__gc_to_lin_str
    call $__std_text_chars
    call $__lin_to_gc_strs
    local.get $__gc122
    global.set $__heap_ptr
    local.set $chars
    i32.const 0
    local.set $i
    (block $__break
      (loop $__continue
    local.get $i
    local.get $alts
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $alts
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    global.get $__s0
      )
    )
    local.set $__gc123
    global.get $__heap_ptr
    local.set $__gc124
    local.get $__gc123
    call $__gc_to_lin_str
    call $__std_text_chars
    call $__lin_to_gc_strs
    local.get $__gc124
    global.set $__heap_ptr
    i32.const 0
    local.get $chars
    i32.const 0
    call $globMatch
    (if (result i32)
      (then
    i32.const 1
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $i
    i32.const 1
    global.get $__s200
    call $__i32_add_chk
    local.set $i
        br $__continue
      )
    )
    i32.const 0
    drop
    i32.const 0
    return
  )
  ;; The names in `dir` the segment matches; a dot name only when the segment itself begins with the dot.
  (func $globNames (param $dir (ref null $str)) (param $seg (ref null $str)) (result (ref null $arr_any))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $listed (ref null $arr_any))
    (local $xs i32)
    (local $out (ref null $arr_any))
    (local $i i32)
    (local $name (ref null $str))
    (local $__bp_nullish i32)
    (local $__case_0 (ref null $result))
    (local $xs__49 (ref null $arr_any))
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__50 (ref null $str))
    (local $__gc125 (ref null $str))
    (local $__gc126 (ref null $str))
    (local $__gc127 i32)
    (local $__gc128 (ref null $str))
    (local $__gc129 (ref null $str))
    (local $__gc130 i32)
    local.get $dir
    call $wasiList
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $arr_any))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $arr_any)
    local.set $xs__49
    local.get $xs__49
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $arr_any))
      (then
    array.new_fixed $arr_any 0
      )
      (else
    ref.null $arr_any
      )
    )
      )
    )
    local.set $listed
    array.new_fixed $arr_any 0
    local.set $out
    i32.const 0
    local.set $i
    (block $__break
      (loop $__continue
    local.get $i
    local.get $listed
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
        (block $__next
    local.get $listed
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__50
    local.get $__bp_nullish__50
      )
      (else
    global.get $__s0
      )
    )
    local.set $name
    local.get $i
    i32.const 1
    global.get $__s201
    call $__i32_add_chk
    local.set $i
    local.get $name
    global.get $__s5
    local.set $__gc125
    local.set $__gc126
    global.get $__heap_ptr
    local.set $__gc127
    local.get $__gc126
    call $__gc_to_lin_str
    local.get $__gc125
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc127
    global.set $__heap_ptr
    (if (result i32)
      (then
    local.get $seg
    global.get $__s5
    local.set $__gc128
    local.set $__gc129
    global.get $__heap_ptr
    local.set $__gc130
    local.get $__gc129
    call $__gc_to_lin_str
    local.get $__gc128
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc130
    global.set $__heap_ptr
    i32.eqz
      )
      (else
    i32.const 0
      )
    )
    (if (result (ref null $arr_any))
      (then
    br $__next
      )
      (else
        ref.null $arr_any
      )
    )
    drop
    local.get $seg
    global.get $__s158
    call $__str_eq
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $seg
    local.get $name
    call $segmentMatches
      )
    )
    (if (result i32)
      (then
    local.get $out
    local.get $name
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $out
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
        )
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $out
    return
  )
  ;; The entries `segs` from `i` match under `dir` (`rel` its path from the root of the glob), added to `out`. A
  ;; wildcard continues into real directories only; a name goes through a link.
  (func $globWalk (param $segs (ref null $arr_any)) (param $i i32) (param $dir (ref null $str)) (param $rel (ref null $str)) (param $out (ref null $arr_any)) (result (ref null $arr_any))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $acc (ref null $arr_any))
    (local $seg (ref null $str))
    (local $__bp_nullish i32)
    (local $last i32)
    (local $names (ref null $arr_any))
    (local $k i32)
    (local $name (ref null $str))
    (local $full (ref null $str))
    (local $sub (ref null $str))
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__51 (ref null $str))
    (local $__opt1 (ref null $str))
    (local $__bp_nullish__52 (ref null $str))
    (local $__opt2 (ref null $str))
    (local $__bp_nullish__53 (ref null $str))
    local.get $out
    local.set $acc
    local.get $i
    local.get $segs
    array.len
    i32.eq
    (if (result (ref null $arr_any))
      (then
    local.get $rel
    global.get $__s0
    call $__str_eq
    i32.eqz
    (if (result i32)
      (then
    local.get $acc
    local.get $rel
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $acc
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $acc
    return
      )
      (else
        ref.null $arr_any
      )
    )
    drop
    local.get $segs
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__51
    local.get $__bp_nullish__51
      )
      (else
    global.get $__s0
      )
    )
    local.set $seg
    local.get $i
    local.get $segs
    array.len
    i32.const 1
    global.get $__s202
    call $__i32_sub_chk
    i32.eq
    local.set $last
    local.get $seg
    global.get $__s203
    call $__str_eq
    (if (result (ref null $arr_any))
      (then
    local.get $last
    i32.eqz
    (if (result i32)
      (then
    local.get $segs
    local.get $i
    i32.const 1
    global.get $__s204
    call $__i32_add_chk
    local.get $dir
    local.get $rel
    local.get $acc
    call $globWalk
    local.set $acc
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $dir
    global.get $__s158
    call $globNames
    local.set $names
    i32.const 0
    local.set $k
    (block $__break
      (loop $__continue
    local.get $k
    local.get $names
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $names
    local.get $k
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt1
    local.set $__bp_nullish__52
    local.get $__bp_nullish__52
      )
      (else
    global.get $__s0
      )
    )
    local.set $name
    local.get $k
    i32.const 1
    global.get $__s205
    call $__i32_add_chk
    local.set $k
    local.get $dir
    local.get $name
    call $joinPath
    local.set $full
    local.get $rel
    local.get $name
    call $joinPath
    local.set $sub
    local.get $last
    (if (result i32)
      (then
    local.get $acc
    local.get $sub
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $acc
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $full
    i32.const 0
    call $wasiStatKind
    i32.const 3
    i32.eq
    (if (result i32)
      (then
    local.get $segs
    local.get $i
    local.get $full
    local.get $sub
    local.get $acc
    call $globWalk
    local.set $acc
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $acc
    return
      )
      (else
        ref.null $arr_any
      )
    )
    drop
    local.get $seg
    call $isMagic
    i32.eqz
    (if (result (ref null $arr_any))
      (then
    local.get $dir
    local.get $seg
    call $joinPath
    local.set $full
    local.get $rel
    local.get $seg
    call $joinPath
    local.set $sub
    local.get $last
    (if (result i32)
      (then
    local.get $full
    i32.const 0
    call $wasiStatKind
    i32.const 0
    i32.ge_s
    (if (result i32)
      (then
    local.get $acc
    local.get $sub
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $acc
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
      )
      (else
    local.get $full
    i32.const 1
    call $wasiStatKind
    i32.const 3
    i32.eq
    (if (result i32)
      (then
    local.get $segs
    local.get $i
    i32.const 1
    global.get $__s206
    call $__i32_add_chk
    local.get $full
    local.get $sub
    local.get $acc
    call $globWalk
    local.set $acc
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
      )
    )
    drop
    local.get $acc
    return
      )
      (else
        ref.null $arr_any
      )
    )
    drop
    local.get $dir
    local.get $seg
    call $globNames
    local.set $names
    i32.const 0
    local.set $k
    (block $__break
      (loop $__continue
    local.get $k
    local.get $names
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $names
    local.get $k
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt2
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt2
    local.set $__bp_nullish__53
    local.get $__bp_nullish__53
      )
      (else
    global.get $__s0
      )
    )
    local.set $name
    local.get $k
    i32.const 1
    global.get $__s207
    call $__i32_add_chk
    local.set $k
    local.get $dir
    local.get $name
    call $joinPath
    local.set $full
    local.get $rel
    local.get $name
    call $joinPath
    local.set $sub
    local.get $last
    (if (result i32)
      (then
    local.get $acc
    local.get $sub
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $acc
    i32.const 0
      )
      (else
    local.get $full
    i32.const 0
    call $wasiStatKind
    i32.const 3
    i32.eq
    (if (result i32)
      (then
    local.get $segs
    local.get $i
    i32.const 1
    global.get $__s208
    call $__i32_add_chk
    local.get $full
    local.get $sub
    local.get $acc
    call $globWalk
    local.set $acc
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
      )
    )
    drop
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $acc
    return
  )
  (func $globWasm (param $pattern (ref null $str)) (param $root (ref null $str)) (result (ref null $arr_any))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    (local $__mem5 i32)
    (local $resolved (ref null $result))
    (local $base (ref null $str))
    (local $segs (ref null $arr_any))
    (local $pieces (ref null $arr_any))
    (local $i i32)
    (local $piece (ref null $str))
    (local $__bp_nullish i32)
    (local $found (ref null $arr_any))
    (local $kept (ref null $arr_any))
    (local $k i32)
    (local $entry (ref null $str))
    (local $__gc131 (ref null $result))
    (local $__gc132 (ref null $str))
    (local $__gc133 (ref null $str))
    (local $__gc134 i32)
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__54 (ref null $str))
    (local $__opt1 (ref null $str))
    (local $__bp_nullish__55 (ref null $str))
    (local $__gc135 (ref null $str))
    (local $__gc136 (ref null $str))
    (local $__gc137 i32)
    local.get $root
    call $resolve
    local.set $resolved
    local.get $resolved
    struct.get $result $tag
    i32.const 0
    i32.ne
    (if (result (ref null $arr_any))
      (then
    array.new_fixed $arr_any 0
    return
      )
      (else
        ref.null $arr_any
      )
    )
    drop
    local.get $resolved
    local.tee $__gc131
    struct.get $result $tag
    (if (result (ref null $str))
      (then
    global.get $__s0
      )
      (else
    local.get $__gc131
    struct.get $result $payload
    ref.cast (ref null $str)
      )
    )
    local.set $base
    array.new_fixed $arr_any 0
    local.set $segs
    local.get $pattern
    global.get $__s105
    local.set $__gc132
    local.set $__gc133
    global.get $__heap_ptr
    local.set $__gc134
    local.get $__gc133
    call $__gc_to_lin_str
    local.get $__gc132
    call $__gc_to_lin_str
    call $__std_text_split
    call $__lin_to_gc_strs
    local.get $__gc134
    global.set $__heap_ptr
    local.set $pieces
    i32.const 0
    local.set $i
    (block $__break
      (loop $__continue
    local.get $i
    local.get $pieces
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $pieces
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__54
    local.get $__bp_nullish__54
      )
      (else
    global.get $__s0
      )
    )
    local.set $piece
    local.get $i
    i32.const 1
    global.get $__s209
    call $__i32_add_chk
    local.set $i
    local.get $piece
    global.get $__s0
    call $__str_eq
    i32.eqz
    (if (result i32)
      (then
    local.get $piece
    global.get $__s5
    call $__str_eq
    i32.eqz
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    local.get $segs
    local.get $piece
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $segs
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $segs
    i32.const 0
    local.get $base
    global.get $__s0
    array.new_fixed $arr_any 0
    call $globWalk
    local.set $found
    array.new_fixed $arr_any 0
    local.set $kept
    i32.const 0
    local.set $k
    (block $__break
      (loop $__continue
    local.get $k
    local.get $found
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $found
    local.get $k
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt1
    local.set $__bp_nullish__55
    local.get $__bp_nullish__55
      )
      (else
    global.get $__s0
      )
    )
    local.set $entry
    local.get $k
    i32.const 1
    global.get $__s210
    call $__i32_add_chk
    local.set $k
    local.get $pattern
    global.get $__s105
    local.set $__gc135
    local.set $__gc136
    global.get $__heap_ptr
    local.set $__gc137
    local.get $__gc136
    call $__gc_to_lin_str
    local.get $__gc135
    call $__gc_to_lin_str
    call $__std_text_endsWith
    local.get $__gc137
    global.set $__heap_ptr
    i32.eqz
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $base
    local.get $entry
    call $joinPath
    i32.const 0
    call $wasiStatKind
    i32.const 3
    i32.eq
      )
    )
    (if (result i32)
      (then
    local.get $kept
    local.get $entry
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $kept
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $kept
    call $sortedStrings
    return
  )
  ;; A path that is not there is `Ok`: the caller wanted it gone. A link is removed, never followed. The
  ;; directories are found first, then the files removed, then the directories from the deepest.
  (func $removeTreeWasm (param $path (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $p (ref null $str))
    (local $top i32)
    (local $r i32)
    (local $dirs (ref null $arr_any))
    (local $next i32)
    (local $dir (ref null $str))
    (local $__bp_nullish i32)
    (local $names (ref null $arr_any))
    (local $i i32)
    (local $full (ref null $str))
    (local $kind i32)
    (local $k i32)
    (local $__gc138 (ref null $result))
    (local $__opt0 (ref null $str))
    (local $__bp_nullish__56 (ref null $str))
    (local $__gc139 (ref null $result))
    (local $__opt1 (ref null $str))
    (local $__bp_nullish__57 (ref null $str))
    (local $__opt2 (ref null $str))
    (local $__bp_nullish__58 (ref null $str))
    local.get $path
    call $resolve
    local.set $__gc138
    local.get $__gc138
    struct.get $result $tag
    (if
      (then
    local.get $__gc138
    return ;; propagate Error
      )
    )
    local.get $__gc138
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $p
    local.get $p
    i32.const 0
    call $wasiStatKind
    local.set $top
    local.get $top
    i32.const 0
    i32.const 21
    global.get $__s211
    call $__i32_sub_chk
    i32.eq
    (if (result (ref null $result))
      (then
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $top
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s212
    call $__i32_sub_chk
    local.get $top
    global.get $__s213
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $top
    i32.const 3
    i32.ne
    (if (result (ref null $result))
      (then
    local.get $p
    call $wasiUnlink
    local.set $r
    local.get $r
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s214
    call $__i32_sub_chk
    local.get $r
    global.get $__s215
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $p
    array.new_fixed $arr_any 1
    local.set $dirs
    i32.const 0
    local.set $next
    (block $__break
      (loop $__continue
    local.get $next
    local.get $dirs
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $dirs
    local.get $next
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $__bp_nullish__56
    local.get $__bp_nullish__56
      )
      (else
    global.get $__s0
      )
    )
    local.set $dir
    local.get $next
    i32.const 1
    global.get $__s216
    call $__i32_add_chk
    local.set $next
    local.get $dir
    call $wasiList
    call $okStrings
    local.set $__gc139
    local.get $__gc139
    struct.get $result $tag
    (if
      (then
    local.get $__gc139
    return ;; propagate Error
      )
    )
    local.get $__gc139
    struct.get $result $payload
    ref.cast (ref null $arr_any)
    local.set $names
    i32.const 0
    local.set $i
    (block $__break
      (loop $__continue
    local.get $i
    local.get $names
    array.len
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $dir
    local.get $names
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt1
    local.set $__bp_nullish__57
    local.get $__bp_nullish__57
      )
      (else
    global.get $__s0
      )
    )
    call $joinPath
    local.set $full
    local.get $i
    i32.const 1
    global.get $__s217
    call $__i32_add_chk
    local.set $i
    local.get $full
    i32.const 0
    call $wasiStatKind
    local.set $kind
    local.get $kind
    i32.const 0
    i32.lt_s
    (if (result i32)
      (then
    local.get $kind
    i32.const 0
    i32.const 21
    global.get $__s218
    call $__i32_sub_chk
    i32.ne
      )
      (else
    i32.const 0
      )
    )
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s219
    call $__i32_sub_chk
    local.get $kind
    global.get $__s220
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $kind
    i32.const 3
    i32.eq
    (if (result i32)
      (then
    local.get $dirs
    local.get $full
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $dirs
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $kind
    i32.const 0
    i32.ge_s
    (if (result i32)
      (then
    local.get $kind
    i32.const 3
    i32.ne
      )
      (else
    i32.const 0
      )
    )
    (if (result (ref null $result))
      (then
    local.get $full
    call $wasiUnlink
    local.set $r
    local.get $r
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s221
    call $__i32_sub_chk
    local.get $r
    global.get $__s222
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
      )
      (else
        ref.null $result
      )
    )
    drop
        br $__continue
      )
    )
    i32.const 0
    drop
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $dirs
    array.len
    local.set $k
    (block $__break
      (loop $__continue
    local.get $k
    i32.const 0
    i32.gt_s
        i32.eqz
        br_if $__break
    local.get $k
    i32.const 1
    global.get $__s223
    call $__i32_sub_chk
    local.set $k
    local.get $dirs
    local.get $k
    call $__arr_at_opt_any
    ref.cast (ref null $str)
    local.tee $__opt2
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt2
    local.set $__bp_nullish__58
    local.get $__bp_nullish__58
      )
      (else
    global.get $__s0
      )
    )
    call $wasiRmdir
    local.set $r
    local.get $r
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 0
    i32.const 1
    global.get $__s224
    call $__i32_sub_chk
    local.get $r
    global.get $__s225
    call $__i32_sub_chk
    call $wasiError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
        br $__continue
      )
    )
    i32.const 0
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; A fresh, unique, empty directory under the host's temporary directory.
  (func $scratchDirWasm (result (ref null $str))
    (local $base (ref null $str))
    (local $attempt i32)
    (local $dir (ref null $str))
    global.get $__s226
    call $wasiGetenv
    local.set $base
    local.get $base
    global.get $__s0
    call $__str_eq
    (if (result i32)
      (then
    global.get $__s227
    local.set $base
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    i32.const 0
    local.set $attempt
    (block $__break
      (loop $__continue
    local.get $attempt
    i32.const 100
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $base
    global.get $__s228
    call $__str_concat
    i32.const 6
    call $randomBytes
    call $__str_concat
    local.set $dir
    local.get $dir
    call $withoutRoot
    call $wasiMkdir
    i32.const 0
    i32.eq
    (if (result (ref null $str))
      (then
    local.get $dir
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    local.get $attempt
    i32.const 1
    global.get $__s229
    call $__i32_add_chk
    local.set $attempt
        br $__continue
      )
    )
    i32.const 0
    drop
    global.get $__s230
    call $__panic_fail
    unreachable
    local.get $base
    return
  )
  (func $workingDirWasm (result (ref null $str))
    (local $cwd (ref null $str))
    call $wasiCwd
    local.set $cwd
    local.get $cwd
    global.get $__s0
    call $__str_eq
    (if (result (ref null $str))
      (then
    global.get $__s105
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    local.get $cwd
    return
  )
  (func $linkToWasm (param $target (ref null $str)) (param $link (ref null $str))
    (local $l (ref null $result))
    (local $r i32)
    (local $__gc140 (ref null $result))
    local.get $link
    call $resolve
    local.set $l
    local.get $l
    struct.get $result $tag
    i32.const 0
    i32.ne
    (if (result i32)
      (then
    global.get $__s231
    call $__panic_fail
    unreachable
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $target
    local.get $l
    local.tee $__gc140
    struct.get $result $tag
    (if (result (ref null $str))
      (then
    global.get $__s0
      )
      (else
    local.get $__gc140
    struct.get $result $payload
    ref.cast (ref null $str)
      )
    )
    call $wasiSymlink
    local.set $r
    local.get $r
    i32.const 0
    i32.lt_s
    (if (result i32)
      (then
    i32.const 0
    i32.const 1
    global.get $__s232
    call $__i32_sub_chk
    local.get $r
    global.get $__s233
    call $__i32_sub_chk
    call $wasiError
    struct.get $rec_HostError $f0
    call $__panic_fail
    unreachable
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    return
  )
  ;; A host without `chmod` denies this user nothing: the permission tests have nothing to check there.
  (func $denyAllWasm (param $path (ref null $str)) (result i32)
    i32.const 0
    return
  )
  (func $allowAllWasm (param $path (ref null $str))
    return
  )
  ;; ── tests ────────────────────────────────────────────────────────────────────
  ;; (Inline tests are smoke-grade — they require the host filesystem to be
  ;; writable at the host's `tmpdir()`. The lib-test harness runs each
  ;; inline test as a separate process; the temp filenames are seeded with
  ;; `time.nowMillis()` for cross-run uniqueness.)
  ;; Internal, test scaffolding: `stat(p)`, or a stat no file has.
  (func $statOr (param $p (ref null $str)) (result (ref null $rec_FileStat))
    (local $__mem0 i32)
    (local $s i32)
    (local $__case_0 (ref null $result))
    (local $s__59 (ref null $rec_FileStat))
    local.get $p
    call $stat
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $rec_FileStat))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $rec_FileStat)
    local.set $s__59
    local.get $s__59
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $rec_FileStat))
      (then
    i32.const 0
    i32.const 1
    global.get $__s234
    call $__i32_sub_chk
    i64.extend_i32_s
    i32.const 0
    i32.const 1
    global.get $__s235
    call $__i32_sub_chk
    i64.extend_i32_s
    i32.const 0
    struct.new $rec_FileStat
      )
      (else
    ref.null $rec_FileStat
      )
    )
      )
    )
    return
  )
  ;; Internal, test scaffolding: `<dir>/app/page.bp`, `<dir>/app/blog/page.bp`,
  ;; `<dir>/app/blog/notes.md` — the fixture tree every walk/glob test reads.
  (func $makeFixtureTree (param $dir (ref null $str)) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    local.get $dir
    global.get $__s236
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
    call $mkdir
    drop
    local.get $dir
    global.get $__s237
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
    call $mkdir
    drop
    local.get $dir
    global.get $__s238
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
    global.get $__s239
    call $writeText
    drop
    local.get $dir
    global.get $__s240
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
    global.get $__s241
    call $writeText
    drop
    local.get $dir
    global.get $__s242
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
    global.get $__s243
    call $writeText
    drop
    i32.const 0
  )
  ;; Internal, test scaffolding: what `walk` answers for the fixture tree when
  ;; its root is spelled `<scratch dir><suffix>` — every spelling of one root has
  ;; to answer the same three relative paths.
  (func $walkFixture (param $suffix (ref null $str)) (result (ref null $str))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $dir (ref null $str))
    (local $walked (ref null $arr_any))
    (local $__gc141 (ref null $result))
    call $scratchDir
    local.set $dir
    local.get $dir
    call $makeFixtureTree
    drop
    local.get $dir
    local.get $suffix
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
    call $walk
    local.tee $__gc141
    struct.get $result $tag
    (if (result (ref null $arr_any))
      (then
    global.get $__s244
    array.new_fixed $arr_any 1
      )
      (else
    local.get $__gc141
    struct.get $result $payload
    ref.cast (ref null $arr_any)
      )
    )
    local.set $walked
    local.get $dir
    call $removeTree
    drop
    local.get $walked
    global.get $__s168
    call $__arr_join_any
    return
  )
  ;; Internal, test scaffolding: the same, with the root spelled relative to the
  ;; working directory — `<prefix><path from the cwd to the fixture>`.
  (func $walkFixtureFromCwd (param $prefix (ref null $str)) (result (ref null $str))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $dir (ref null $str))
    (local $root (ref null $str))
    (local $walked (ref null $arr_any))
    (local $__gc142 (ref null $result))
    call $scratchDir
    local.set $dir
    local.get $dir
    call $makeFixtureTree
    drop
    local.get $prefix
    call $workingDir
    local.get $dir
    call $relative
    global.get $__s236
    array.new_fixed $arr_any 3
    global.get $__s0
    call $__arr_join_any
    local.set $root
    local.get $root
    call $walk
    local.tee $__gc142
    struct.get $result $tag
    (if (result (ref null $arr_any))
      (then
    global.get $__s244
    array.new_fixed $arr_any 1
      )
      (else
    local.get $__gc142
    struct.get $result $payload
    ref.cast (ref null $arr_any)
      )
    )
    local.set $walked
    local.get $dir
    call $removeTree
    drop
    local.get $walked
    global.get $__s168
    call $__arr_join_any
    return
  )
  ;; Internal, test scaffolding: the `Error` of `walk(root)`, `""` when it walked.
  (func $walkRefusal (param $root (ref null $str)) (result (ref null $str))
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $e__60 anyref)
    local.get $root
    call $walk
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $str))
      (then
    global.get $__s0
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $str))
      (then
    local.get $__case_0
    struct.get $result $payload
    local.set $e__60
    local.get $e__60
    call $describe
      )
      (else
    ref.null $str
      )
    )
      )
    )
    return
  )
  ;; Internal, test scaffolding: an `FsError` as one line — the variant, the path
  ;; and the message where it holds one (a dangling link is `Other`, decision 178).
  (func $describe (param $e anyref) (result (ref null $str))
    (local $p (ref null $str))
    (local $offset i64)
    (local $message (ref null $str))
    (local $__case_0 anyref)
    local.get $e
    local.set $__case_0
    local.get $__case_0
    ref.test (ref null $var_FsError_NotFound)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_FsError_NotFound)
    struct.get $var_FsError_NotFound $f0
    local.set $p
    global.get $__s245
    local.get $p
    call $__str_concat
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_FsError_PermissionDenied)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_FsError_PermissionDenied)
    struct.get $var_FsError_PermissionDenied $f0
    local.set $p
    global.get $__s246
    local.get $p
    call $__str_concat
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_FsError_IsDirectory)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_FsError_IsDirectory)
    struct.get $var_FsError_IsDirectory $f0
    local.set $p
    global.get $__s247
    local.get $p
    call $__str_concat
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_FsError_NotDirectory)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_FsError_NotDirectory)
    struct.get $var_FsError_NotDirectory $f0
    local.set $p
    global.get $__s248
    local.get $p
    call $__str_concat
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_FsError_AlreadyExists)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_FsError_AlreadyExists)
    struct.get $var_FsError_AlreadyExists $f0
    local.set $p
    global.get $__s249
    local.get $p
    call $__str_concat
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_FsError_InvalidUtf8)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_FsError_InvalidUtf8)
    struct.get $var_FsError_InvalidUtf8 $f0
    local.set $p
    local.get $__case_0
    ref.cast (ref null $var_FsError_InvalidUtf8)
    struct.get $var_FsError_InvalidUtf8 $f1
    local.set $offset
    global.get $__s250
    local.get $p
    call $__str_concat
    global.get $__s251
    call $__str_concat
    local.get $offset
    call $__std_number_i64ToString
    call $__str_concat
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_FsError_Other)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_FsError_Other)
    struct.get $var_FsError_Other $f0
    local.set $p
    local.get $__case_0
    ref.cast (ref null $var_FsError_Other)
    struct.get $var_FsError_Other $f1
    local.set $message
    local.get $message
      )
      (else
    ref.null $str
      )
    )
      )
    )
      )
    )
      )
    )
      )
    )
      )
    )
      )
    )
    return
  )
  ;; Internal, test scaffolding: the fixture tree plus the names decision 177 is
  ;; about — a dot file and a dot directory, a link to a directory, a link to a
  ;; file and a dangling link, all under `<dir>/app`.
  (func $makeGlobTree (param $dir (ref null $str)) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    (local $__mem5 i32)
    (local $__mem6 i32)
    local.get $dir
    call $makeFixtureTree
    drop
    local.get $dir
    global.get $__s252
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
    call $mkdir
    drop
    local.get $dir
    global.get $__s253
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
    global.get $__s254
    call $writeText
    drop
    local.get $dir
    global.get $__s255
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
    global.get $__s256
    call $writeText
    drop
    local.get $dir
    global.get $__s257
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
    global.get $__s258
    call $writeText
    drop
    global.get $__s259
    local.get $dir
    global.get $__s260
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
    call $linkTo
    global.get $__s261
    local.get $dir
    global.get $__s262
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
    call $linkTo
    global.get $__s263
    local.get $dir
    global.get $__s264
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
    call $linkTo
    i32.const 0
  )
  ;; Internal, test scaffolding: what `glob(pattern, <dir>/app)` answers over
  ;; `makeGlobTree`, joined by `,`.
  (func $globbed (param $pattern (ref null $str)) (result (ref null $str))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $dir (ref null $str))
    (local $found (ref null $arr_any))
    (local $__gc143 (ref null $result))
    call $scratchDir
    local.set $dir
    local.get $dir
    call $makeGlobTree
    drop
    local.get $pattern
    local.get $dir
    global.get $__s236
    array.new_fixed $arr_any 2
    global.get $__s0
    call $__arr_join_any
    call $glob
    local.tee $__gc143
    struct.get $result $tag
    (if (result (ref null $arr_any))
      (then
    global.get $__s244
    array.new_fixed $arr_any 1
      )
      (else
    local.get $__gc143
    struct.get $result $payload
    ref.cast (ref null $arr_any)
      )
    )
    local.set $found
    local.get $dir
    call $removeTree
    drop
    local.get $found
    global.get $__s168
    call $__arr_join_any
    return
  )
  ;; ── FsError, readText and the handle ─────────────────────────────────────────
  ;; Internal, test scaffolding: the variant of an `Error`, `"ok"` for an `Ok`.
  (func $variantOf (param $r (ref null $result)) (result (ref null $str))
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $e__61 anyref)
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $str))
      (then
    global.get $__s265
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $str))
      (then
    local.get $__case_0
    struct.get $result $payload
    local.set $e__61
    local.get $e__61
    call $describe
      )
      (else
    ref.null $str
      )
    )
      )
    )
    return
  )
  ;; Internal, test scaffolding: the file a failed `open` falls back to.
  (func $noFile (result (ref null $rec_File))
    (local $__mem0 i32)
    global.get $__s0
    global.get $__s0
    call $memHandle
    struct.new $rec_File
    return
  )
  ;; Internal, test scaffolding: take every permission from `path`; whether that
  ;; denies this user anything (root is denied nothing), and give them back.
  ;; denyAll — .Wasm(body: denyAllWasm)
  (func $denyAll (param $path (ref null $str)) (result i32)
    local.get $path
    call $denyAllWasm
  )
  ;; allowAll — .Wasm(body: allowAllWasm)
  (func $allowAll (param $path (ref null $str))
    local.get $path
    call $allowAllWasm
  )
  (func $__init_globals
    global.get $__s105
    global.set $separator
    global.get $__s266
    global.set $delimiter
  )
  (func $__gen_next (param $g (ref null $gen)) (result i32)
    (local $r i32)
    local.get $g
    struct.get $gen $state
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $g
    call $__gen_resume
    local.tee $r
    i32.eqz
    (if
      (then
    local.get $g
    i32.const 1
    struct.set $gen $state ;; ended
    local.get $g
    ref.null struct
    struct.set $gen $frame ;; its frame dropped
      )
    )
    local.get $r
  )
  (func $__gen_resume (param $g (ref null $gen)) (result i32)
    (local $k i32)
    local.get $g
    struct.get $gen $kind
    local.set $k
    local.get $k
    i32.const 0
    i32.eq
    (if
      (then
    local.get $g
    struct.get $gen $left
    i32.const 0
    i32.le_s
    (if
      (then
    local.get $g
    struct.get $gen $src
    call $__gen_close ;; the count is reached: its source
    i32.const 0
    return
      )
    )
    local.get $g
    local.get $g
    struct.get $gen $left
    i32.const 1
    i32.sub
    struct.set $gen $left
    local.get $g
    struct.get $gen $src
    call $__gen_next
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $g
    local.get $g
    struct.get $gen $src
    struct.get $gen $value
    struct.set $gen $value
    i32.const 1
    return
      )
    )
    local.get $k
    i32.const 1
    i32.eq
    (if
      (then
    (block $__break
      (loop $__continue
    local.get $g
    struct.get $gen $left
    i32.const 0
    i32.le_s
    br_if $__break
    local.get $g
    local.get $g
    struct.get $gen $left
    i32.const 1
    i32.sub
    struct.set $gen $left
    local.get $g
    struct.get $gen $src
    call $__gen_next
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    br $__continue
      )
    )
    local.get $g
    struct.get $gen $src
    call $__gen_next
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $g
    local.get $g
    struct.get $gen $src
    struct.get $gen $value
    struct.set $gen $value
    i32.const 1
    return
      )
    )
    local.get $k
    i32.const 5
    i32.eq
    (if
      (then
    local.get $g
    call $File_chunks__body
    return
      )
    )
    local.get $k
    i32.const 6
    i32.eq
    (if
      (then
    local.get $g
    call $File_lines__body
    return
      )
    )
    unreachable
  )
  (func $__gen_close (param $g (ref null $gen))
    local.get $g
    ref.is_null
    (if
      (then
    return
      )
    )
    local.get $g
    struct.get $gen $kind
    i32.const 5
    i32.lt_u
    (if
      (then
    local.get $g
    struct.get $gen $src
    call $__gen_close ;; its source
      )
      (else
      )
    )
    local.get $g
    i32.const 1
    struct.set $gen $state ;; ended
    local.get $g
    ref.null struct
    struct.set $gen $frame ;; its frame dropped
  )
  (func $__arr_slice_any (param $xs (ref null $arr_any)) (param $a i32) (param $b i32) (result (ref null $arr_any))
    (local $len i32)
    (local $from i32)
    (local $to i32)
    (local $n i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $len
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $len
    local.get $a
    i32.add
    local.set $from
    local.get $from
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $from
      )
    )
      )
      (else
    local.get $a
    local.set $from
    local.get $from
    local.get $len
    i32.gt_s
    (if
      (then
    local.get $len
    local.set $from
      )
    )
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $len
    local.get $b
    i32.add
    local.set $to
    local.get $to
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $to
      )
    )
      )
      (else
    local.get $b
    local.set $to
    local.get $to
    local.get $len
    i32.gt_s
    (if
      (then
    local.get $len
    local.set $to
      )
    )
      )
    )
    local.get $to
    local.get $from
    i32.sub
    local.set $n
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $n
      )
    )
    local.get $n
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    local.get $from
    local.get $n
    array.copy $arr_any $arr_any
    local.get $r
  )
  (func $__arr_at_opt_any (param $xs (ref null $arr_any)) (param $i i32) (result anyref)
    local.get $i
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $i
    local.get $xs
    array.len
    i32.add
    local.set $i
      )
    )
    local.get $i
    i32.const 0
    i32.lt_s
    local.get $i
    local.get $xs
    array.len
    i32.ge_s
    i32.or
    (if (result anyref)
      (then
    ref.null any
      )
      (else
    local.get $xs
    local.get $i
    array.get $arr_any
      )
    )
  )
  (func $__arr_join_any (param $xs (ref null $arr_any)) (param $sep (ref null $str)) (result (ref null $str))
    (local $n i32)
    (local $i i32)
    (local $acc (ref null $str))
    local.get $xs
    array.len
    local.set $n
    i32.const 0
    array.new_default $str
    local.set $acc
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    local.get $acc
    local.get $sep
    call $__str_concat
    local.set $acc
      )
    )
    local.get $acc
    local.get $xs
    local.get $i
    array.get $arr_any
    ref.cast (ref null $str)
    call $__str_concat
    local.set $acc
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $acc
  )
  (func $__arr_prepend_any (param $xs (ref null $arr_any)) (param $x anyref) (result (ref null $arr_any))
    (local $n i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $x
    array.set $arr_any
    local.get $r
    i32.const 1
    local.get $xs
    i32.const 0
    local.get $n
    array.copy $arr_any $arr_any
    local.get $r
  )
  (func $__arr_concat_any (param $xs (ref null $arr_any)) (param $ys (ref null $arr_any)) (result (ref null $arr_any))
    (local $la i32)
    (local $lb i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $la
    local.get $ys
    array.len
    local.set $lb
    local.get $la
    local.get $lb
    i32.add
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $la
    array.copy $arr_any $arr_any
    local.get $r
    local.get $la
    local.get $ys
    i32.const 0
    local.get $lb
    array.copy $arr_any $arr_any
    local.get $r
  )
  (func $__arr_concat_i32 (param $xs (ref null $arr_i32)) (param $ys (ref null $arr_i32)) (result (ref null $arr_i32))
    (local $la i32)
    (local $lb i32)
    (local $r (ref null $arr_i32))
    local.get $xs
    array.len
    local.set $la
    local.get $ys
    array.len
    local.set $lb
    local.get $la
    local.get $lb
    i32.add
    array.new_default $arr_i32
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $la
    array.copy $arr_i32 $arr_i32
    local.get $r
    local.get $la
    local.get $ys
    i32.const 0
    local.get $lb
    array.copy $arr_i32 $arr_i32
    local.get $r
  )
  (func $__unk_int_in (param $v anyref) (param $lo i32) (param $hi i32) (result i32)
    (local $k i32)
    (local $x f64)
    local.get $v
    ref.is_null
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.test (ref null $box_bool)
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i32)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.tee $k
    local.get $lo
    i32.ge_s
    local.get $k
    local.get $hi
    i32.le_s
    i32.and
    return
      )
    )
    local.get $v
    ref.test (ref null $box_f64)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    local.tee $x
    f64.floor
    local.get $x
    f64.ne
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $x
    local.get $lo
    f64.convert_i32_s
    f64.ge
    local.get $x
    local.get $hi
    f64.convert_i32_s
    f64.le
    i32.and
  )
  (func $__unk_as_i32 (param $v anyref) (result i32)
    local.get $v
    ref.test (ref null $box_f64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    i32.trunc_f64_s
    return
      )
    )
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
  )
  (func $__arr_at_opt_i32 (param $xs (ref null $arr_i32)) (param $i i32) (result anyref)
    local.get $i
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $i
    local.get $xs
    array.len
    i32.add
    local.set $i
      )
    )
    local.get $i
    i32.const 0
    i32.lt_s
    local.get $i
    local.get $xs
    array.len
    i32.ge_s
    i32.or
    (if (result anyref)
      (then
    ref.null any
      )
      (else
    local.get $xs
    local.get $i
    array.get $arr_i32
    struct.new $box_i32
      )
    )
  )
  (func $__lin_to_gc_strs (param $p i32) (result (ref null $arr_any))
    (local $n i32)
    (local $i i32)
    (local $r (ref null $arr_any))
    local.get $p
    i32.load
    local.set $n
    local.get $n
    array.new_default $arr_any
    local.set $r
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $r
    local.get $i
    local.get $p
    local.get $i
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    call $__lin_to_gc_str
    array.set $arr_any
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $r
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
  (func $__write_bytes (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__print_nl
    i32.const 8
    i32.const 10
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  ;; separator between the arguments of a multi-argument `@print`
  (func $__print_sp
    i32.const 8
    i32.const 32
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i32 (param $n i32)
    local.get $n
    call $__print_i32_raw
    call $__print_nl
  )
  (func $__print_i32_raw (param $n i32)
    (local $buf i32) (local $len i32) (local $neg i32) (local $d i32)
    (local $i i32) (local $j i32) (local $tmp i32)
    i32.const 64
    local.set $buf
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 1
        local.set $neg
        i32.const 0
        local.get $n
        i32.sub
        local.set $n
      )
    )
    (block $done
      (loop $digits
        local.get $n
        i32.const 10
        i32.rem_u
        i32.const 48
        i32.add
        local.set $d
        local.get $buf
        local.get $len
        i32.add
        local.get $d
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
        local.get $n
        i32.const 10
        i32.div_u
        local.set $n
        local.get $n
        i32.const 0
        i32.gt_u
        br_if $digits
      )
    )
    ;; reverse
    i32.const 0
    local.set $i
    local.get $len
    i32.const 1
    i32.sub
    local.set $j
    (block $rdone
      (loop $rev
        local.get $i
        local.get $j
        i32.ge_u
        br_if $rdone
        local.get $buf
        local.get $i
        i32.add
        i32.load8_u
        local.set $tmp
        local.get $buf
        local.get $i
        i32.add
        local.get $buf
        local.get $j
        i32.add
        i32.load8_u
        i32.store8
        local.get $buf
        local.get $j
        i32.add
        local.get $tmp
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        local.get $j
        i32.const 1
        i32.sub
        local.set $j
        br $rev
      )
    )
    ;; add neg sign + newline
    ;; shift the digits one byte right to make room for '-'
    ;; (dst = buf+1, NOT buf+len: the latter moved them `len`
    ;;  bytes and printed -12 as -21)
    local.get $neg
    (if
      (then
        local.get $buf
        i32.const 1
        i32.add
        local.get $buf
        local.get $len
        call $__memmove
        local.get $buf
        i32.const 45
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
      )
    )
    local.get $buf
    local.get $len
    call $__write_bytes
  )
  (func $__memmove (param $dst i32) (param $src i32) (param $len i32)
    (local $i i32)
    local.get $len
    i32.const 1
    i32.sub
    local.set $i
    (block $done
      (loop $loop
        local.get $i
        i32.const 0
        i32.lt_s
        br_if $done
        local.get $dst
        local.get $i
        i32.add
        local.get $src
        local.get $i
        i32.add
        i32.load8_u
        i32.store8
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        br $loop
      )
    )
  )
  (func $__str_concat (param $a (ref null $str)) (param $b (ref null $str)) (result (ref null $str))
    (local $r (ref null $str)) (local $alen i32) (local $blen i32)
    local.get $a
    array.len
    local.set $alen
    local.get $b
    array.len
    local.set $blen
    local.get $alen
    local.get $blen
    i32.add
    array.new_default $str
    local.set $r
    local.get $r
    i32.const 0
    local.get $a
    i32.const 0
    local.get $alen
    array.copy $str $str
    local.get $r
    local.get $alen
    local.get $b
    i32.const 0
    local.get $blen
    array.copy $str $str
    local.get $r
  )
  (func $__str_eq (param $a (ref null $str)) (param $b (ref null $str)) (result i32)
    (local $i i32) (local $n i32) (local $an i32) (local $bn i32)
    local.get $a
    ref.is_null
    local.set $an
    local.get $b
    ref.is_null
    local.set $bn
    local.get $an
    local.get $bn
    i32.or
    (if
      (then
        local.get $an
        local.get $bn
        i32.and
        return
      )
    )
    local.get $a
    array.len
    local.set $n
    local.get $n
    local.get $b
    array.len
    i32.ne
    (if
      (then
        i32.const 0
        return
      )
    )
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $a
        local.get $i
        array.get_u $str
        local.get $b
        local.get $i
        array.get_u $str
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
  (func $__write_err (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 2
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__assert_fail (param $where i32) (param $msg i32)
    local.get $where
    i32.const 4
    i32.add
    local.get $where
    i32.load
    call $__write_err
    i32.const 188
    i64.const 8390880602276044858
    i64.store
    i32.const 196
    i64.const 7811882119909502825
    i64.store
    i32.const 204
    i32.const 101
    i32.store8
    i32.const 205
    i32.const 100
    i32.store8
    i32.const 188
    i32.const 18
    call $__write_err
    local.get $msg
    (if
      (then
        i32.const 188
        i32.const 8250
        i32.store
        i32.const 188
        i32.const 2
        call $__write_err
        local.get $msg
        i32.const 4
        i32.add
        local.get $msg
        i32.load
        call $__write_err
      )
    )
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
  )
  (func $__panic_fail (param $msg (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    i32.const 188
    i64.const 9071397899755888
    i64.store
    i32.const 188
    i32.const 7
    call $__write_err
    local.get $msg
    array.len
    local.set $n
    global.get $__heap_ptr
    local.set $top
    local.get $n
    call $__alloc
    local.set $p
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $msg
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
    local.get $n
    call $__write_err
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
    local.get $top
    global.set $__heap_ptr
  )
  (func $__wasi_random_f64 (result f64)
    i32.const 208
    i32.const 8
    call $random_get
    (if
      (then
        unreachable
      )
    )
    i32.const 208
    i64.load
    i64.const 11
    i64.shr_u
    f64.convert_i64_u
    f64.const 1.1102230246251565e-16
    f64.mul
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
        local.get $site
        call $__chk_fail
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
            local.get $site
            call $__chk_fail
            unreachable
          )
        )
      )
    )
    local.get $r
  )
  (func $__gc_to_lin_str (param $s (ref null $str)) (result i32)
    (local $n i32) (local $p i32) (local $i i32)
    local.get $s
    array.len
    local.set $n
    local.get $n
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $s
        local.get $i
        array.get_u $str
        i32.store8 offset=4
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
  )
  (func $__lin_to_gc_str (param $p i32) (result (ref null $str))
    (local $r (ref null $str)) (local $n i32) (local $i i32)
    local.get $p
    i32.load
    local.set $n
    local.get $n
    array.new_default $str
    local.set $r
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $r
        local.get $i
        local.get $p
        local.get $i
        i32.add
        i32.load8_u offset=4
        array.set $str
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $r
  )
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  (func $__i32_divs (param $a i32) (param $b i32) (param $site (ref null $str)) (param $osite (ref null $str)) (result i32)
    local.get $b
    i32.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    i32.const -2147483648
    i32.eq
    local.get $b
    i32.const -1
    i32.eq
    i32.and
    (if
      (then
        local.get $osite
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    local.get $b
    i32.div_s
  )
  (func $__i64_divs (param $a i64) (param $b i64) (param $site (ref null $str)) (param $osite (ref null $str)) (result i64)
    local.get $b
    i64.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    i64.const -9223372036854775808
    i64.eq
    local.get $b
    i64.const -1
    i64.eq
    i32.and
    (if
      (then
        local.get $osite
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    local.get $b
    i64.div_s
  )
  (func $__i32_nz (param $b i32) (param $site (ref null $str)) (result i32)
    local.get $b
    i32.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $b
  )
  (func $__i64_nz (param $b i64) (param $site (ref null $str)) (result i64)
    local.get $b
    i64.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $b
  )
  (global $__random_state (mut i64) (i64.const -1))
  ;; std-wasm (decision 440): its functions, transpiled from std_wasm.wasm
  (global $__std_sp (mut i32) (i32.const 9152))
  (func $__std_sp_check (param $sp i32) (result i32)
    local.get $sp
    i32.const 8000
    i32.lt_s
    (if
      (then unreachable)
    )
    local.get $sp
  )
  (data (i32.const 256) "\00\00io_lib:format directive other than ~p ~w ~s ~n ~~\00}\00|\00#{\00badarity\00-Infinity\00badkey\00throw\00short\00exit\00apply of more than 4 arguments\00error\00no_integer\00\" is not an integer\00\" is not a number\00badmap\00badfun\00nan\00null\00string:split/3 other than leading/all\00global\00ok\00both\00badarith\00nomatch\00badmatch\00badarg\00trailing\00leading\00inf\000123456789abcdef\00true\00try_clause\00function_clause\00if_clause\00case_clause\00false\00unsupported_type\00bp_wat_runtime\00\" is out of range\00unicode\00undefined\00float_to_binary/2 with options other than [short]\00binary:replace/4 with options other than [global]\00binary:split/3 with options other than [global]\00[]\00\\\00[\00NaN\000123456789ABCDEF\00#Fun<bp_wat>\00<<>>\00\"/utf8>>\00\">>\00<<\00:\00utf8\00\" overflows f64\00latin1\00-0.0\00,\00integer beyond 64 bits (a bignum)\00float_to_binary/1 (scientific form)\00an unseeded draw: a build has no entropy, call `random.seed` first (decision 451)\00'\00<<\"\00parseInt: \"\00parseFloat: \"\00 after and andalso band begin bnot bor bsl bsr bxor case catch cond div end fun if let maybe not of or orelse receive rem try when xor else \00 error value type name text line start end source message span code args fields label context bindings capture \00 => \00\n\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\07\00\00\00\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\13\03\03\03\03\03\03\03\03\03\03\03\03#\03\034\04\04\04D\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\\n\\r\\t\\b\\f\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\05\00\00\00\00\00\00\00\19\00\00\00\00\00\00\00}\00\00\00\00\00\00\00q\02\00\00\00\00\00\005\0c\00\00\00\00\00\00\t=\00\00\00\00\00\00-1\01\00\00\00\00\00\e1\f5\05\00\00\00\00\00e\cd\1d\00\00\00\00\00\f9\02\95\00\00\00\00\00\dd\0e\e9\02\00\00\00\00QJ\8d\0e\00\00\00\00\95s\c2H\00\00\00\00\e9A\cck\01\00\00\00\8dI\fd\1a\07\00\00\00\c1o\f2\86#\00\00\00\c5.\bc\a2\b1\00\00\00\d9\e9\ac-x\03\00\00=\91`\e4X\11\00\001\d6\e2u\bcV\00\00\f5.nM\ae\b1\01\00\c9\ea&\83gx\08\00\ed\95\c2\8f\05Z*\00\a1\ed\cc\ce\1b\c2\d3\00%\a4\00\n\8b\ca\"\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00@\95YiYUUTU\15UUV\04\05\15A\10TU@EQUD@EPDPUUE\00@\00@@\04D\96eUVUE@ETQA\15@U\91UUUU@Q\05\01\00\00TETTEU\05\04\00\10\04\10\14\04@\00\00\00\01@UU\15AT\04\00\00D\00\01\00\00\00\00@A\00\00DPDEPT\00UUTUeQ\00@\00@\01\00\00\01\00\05\01\00\11TQQTUU\05\00\00\00\00\00\00\01\00\00\00\02\00\00\00\03\00\00\00\04\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\t\00\00\00\00\00\00\00\00\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00>\01?\01\00\00\00\00\00\00\01\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00 4Pe\c0_\c9\a6R\bb\13\cb\ae\c4@\c2\18\06\c8\dfq\00\d5\a8|\f5o\0f\daX\fc'\13nGV5}$ e\02\c7\e7h\e4\8c\a4\1d\e9\e6\02h\d7\cd9ayw\fc\c2@[\ef\16y\8c\deC\ff\a7Q\f9\91\f3\b2x\f5\bd\be\11\e8W\e9\d6\e8\be\e8{\b0T\ac\8f\84\8du\1b\ea#\a4\99\e9\f9\d3\8b\b7\a3q@a\da>\15\ce\e3>\cbs\f9H\08\8c\97\b4'\d5\1bp\10\a2\bf\ef\b9\eb\852\15M\b4M\b4\9b\bbo\19\96\b6\07l\f8\e7\ee\ad6\d9\b4\f5\915\ae\13\"\"\18\afNjhM\91\da\aa=O@t\1e\9f\bd\9e\e0\06\a1\c0\98W\c2\a7\fd\a4\0e\90\17\0e}Iqs\e3 \8f\b2 \d8v\05\14;\12\85=t4\81\13C\b0\ad)z_'\f45\1c\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\10\00\00\00\00\00\00\00\00\b94\032\b7\f4\ad\14\10\db\1a\b3\08\92T\0e\r0}\95\14G\ba\1af\08\8fM&\ad\c6m\f5\98\bf\85\e2\b7E\11\ca\96\85=\92\bd\1d\eb\fc\a1\18`\dc\efR\16<\92\ae\"\0b\b8\c1\b4\83\9d-[\05b\da\1c0L~\8fN\8b\b2[\16\f4R\9f\8bV\a5\12\fb\d4\82vC\ed\8a\f0\8f\e7\f91\15e\19\18P\f1\9b\d9J\13\ee\b4(L\f0\a6\86\c1%\1f\03_\c2p\cb\9eI\16\e6B\88\9cD\eb \14\b0e\086\adn\a5\85\85\f0\ca\14\e2\fd\03\1a\0b\89\99y\d5\b1=\t\d8\da\97:5\eb\cf\10\ac6?^s\bb8\cf>gR\faD\af\ba\15\01\01\02\04\06\07\08\t\n\n\00\00\00\00\00\00\9f\de\e0\c3\f04\f7?\00\90\e6y\7f\cc\d7\bf\1f\e9,jx\13\f7?\00\00\r\c2\eeo\d7\bf\a0\b5\fa\08`\f2\f6?\00\e0Q\13\e3\13\d7\bf}\8c\13\1f\a6\d1\f6?\00x(8[\b8\d6\bf\d1\b4\c5\0bI\b1\f6?\00x\80\90U]\d6\bf\ba\0c/3G\91\f6?\00\00\18v\d0\02\d6\bf#B\"\18\9fq\f6?\00\90\90\86\ca\a8\d5\bf\d9\1e\a5\99OR\f6?\00P\03VCO\d5\bf\c4$\8f\aaV3\f6?\00@k\c37\f6\d4\bf\14\dc\9dk\b3\14\f6?\00P\a8\fd\a7\9d\d4\bfL\\\c6Rd\f6\f5?\00\a8\899\92E\d4\bfO,\91\b5g\d8\f5?\00\b8\b09\f4\ed\d3\bf\de\90[\cb\bc\ba\f5?\00p\8fD\ce\96\d3\bfx\1a\d9\f2a\9d\f5?\00\a0\bd\17\1e@\d3\bf\87VF\12V\80\f5?\00\80F\ef\e2\e9\d2\bf\d3k\e7\ce\97c\f5?\00\e008\1b\94\d2\bf\93\7f\a7\e2%G\f5?\00\88\da\8c\c5>\d2\bf\83E\06B\ff*\f5?\00\90')\e1\e9\d1\bf\df\bd\b2\db\"\0f\f5?\00\f8H+m\95\d1\bf\d7\de4G\8f\f3\f4?\00\f8\b9\9agA\d1\bf@(\de\cfC\d8\f4?\00\98\ef\94\d0\ed\d0\bf\c8\a3x\c0>\bd\f4?\00\10\db\18\a5\9a\d0\bf\8a%\e0\c3\7f\a2\f4?\00\b8cR\e6G\d0\bf4\84\d4$\05\88\f4?\00\f0\86E\"\eb\cf\bf\0b-\19\1b\cem\f4?\00\b0\17uJG\cf\bfT\189\d3\d9S\f4?\000\10=D\a4\ce\bfZ\84\b4D':\f4?\00\b0\e9D\r\02\ce\bf\fb\f8\15A\b5 \f4?\00\f0w)\a2`\cd\bf\b1\f4>\da\82\07\f4?\00\90\95\04\01\c0\cc\bf\8f\feW]\8f\ee\f3?\00\10\89V) \cc\bf\e9L\0b\a0\d9\d5\f3?\00\10\81\8d\17\81\cb\bf+\c1\10\c0`\bd\f3?\00\d0\d3\cc\c9\e2\ca\bf\b8\dau+$\a5\f3?\00\90\12.@E\ca\bf\02\d0\9f\cd\"\8d\f3?\00\f0\1dhw\a8\c9\bf\1cz\84\c5[u\f3?\000Him\0c\c9\bf\e26\adI\ce]\f3?\00\c0E\a6 q\c8\bf@\d4M\98yF\f3?\000\14\b4\8f\d6\c7\bf$\cb\ff\ce\\/\f3?\00pb<\b8<\c7\bfI\r\a1uw\18\f3?\00`7\9b\9a\a3\c6\bf\909>7\c8\01\f3?\00\a0\b7T1\0b\c6\bfA\f8\95\bbN\eb\f2?\000$v}s\c5\bf\d1\a9\19\02\n\d5\f2?\000\c2\8f{\dc\c4\bf*\fd\b7\a8\f9\be\f2?\00\00\d2Q,F\c4\bf\ab\1b\0cz\1c\a9\f2?\00\00\83\bc\8a\b0\c3\bf0\b5\14`r\93\f2?\00\00Ik\99\1b\c3\bf\f5\a1WW\fa}\f2?\00@\a4\90T\87\c2\bf\bf;\1d\9b\b3h\f2?\00\a0y\f8\b9\f3\c1\bf\bd\f5\8f\83\9dS\f2?\00\a0,%\c8`\c1\bf;\08\c9\aa\b7>\f2?\00 \f7W\7f\ce\c0\bf\b6@\a9+\01*\f2?\00\a0\feI\dc<\c0\bf2A\cc\96y\15\f2?\00\80K\bc\bdW\bf\bf\9b\fc\d2\1d \01\f2?\00@@\96\087\be\bf\0bHMI\f4\ec\f1?\00@\f9>\98\17\bd\bfie\8fR\f5\d8\f1?\00\a0\d8Ng\f9\bb\bf|~W\11#\c5\f1?\00`/ y\dc\ba\bf\e9&\cbt|\b1\f1?\00\80(\e7\c3\c0\b9\bf\b6\1a,\0c\01\9e\f1?\00\c0r\b3F\a6\b8\bf\bdp\b6{\b0\8a\f1?\00\00\ac\b3\01\8d\b7\bf\b6\bc\ef%\8aw\f1?\00\008E\f1t\b6\bf\da1L5\8dd\f1?\00\80\87m\0e^\b5\bf\dd_'\90\b9Q\f1?\00\e0\a1\de\\H\b4\bfL\d22\a4\0e?\f1?\00\a0jM\d93\b3\bf\da\f9\10r\8b,\f1?\00`\c5\f8y \b2\bf1\b5\ec(0\1a\f1?\00 b\98F\0e\b1\bf\af4\84\da\fb\07\f1?\00\00\d2jl\fa\af\bf\b3kN\0f\ee\f5\f0?\00@wJ\8d\da\ad\bf\ce\9f*]\06\e4\f0?\00\00\85\e4\ec\bc\ab\bf!\a5,cD\d2\f0?\00\c0\12@\89\a1\a9\bf\1a\98\e2|\a7\c0\f0?\00\c0\023X\88\a7\bf\d16\c6\83/\af\f0?\00\80\d6g^q\a5\bf9\13\a0\98\db\9d\f0?\00\80eI\8a\\\a3\bf\df\e7R\af\ab\8c\f0?\00@\15d\e3I\a1\bf\fb(N/\9f{\f0?\00\80\eb\82\c0r\9e\bf\19\8f5\8c\b5j\f0?\00\80RR\f1U\9a\bf,\f9\ec\a5\eeY\f0?\00\80\81\cfb=\96\bf\90,\d1\cdII\f0?\00\00\aa\8c\fb(\92\bf\a9\ad\f0\c6\c68\f0?\00\00\f9 {1\8c\bf\a92y\13e(\f0?\00\00\aa]5\19\84\bfHs\ea'$\18\f0?\00\00\ec\c2\03\12x\bf\95\b1\14\06\04\08\f0?\00\00$y\t\04`\bf\1a\fa&\f7\1f\e0\ef?\00\00\90\84\f3\efo?t\eaa\c2\1c\a1\ef?\00\00=5A\dc\87?.\99\81\b0\10c\ef?\00\80\c2\c4\a3\ce\93?\cd\ad\ee<\f6%\ef?\00\00\89\14\c1\9f\9b?\e7\13\91\03\c8\e9\ee?\00\00\11\ce\d8\b0\a1?\ab\b1\cbx\80\ae\ee?\00\c0\01\d0[\8a\a5?\9b\0c\9d\a2\1at\ee?\00\80\d8@\83\\\a9?\b5\99\n\83\91:\ee?\00\80W\efj'\ad?V\9a`\t\e0\01\ee?\00\c0\98\e5\98u\b0?\98\bbw\e5\01\ca\ed?\00 \r\e3\f5S\b2?\03\91|\0b\f2\92\ed?\00\008\8b\dd.\b4?\ce\\\fbf\ac\\\ed?\00\c0W\87Y\06\b6?\9d\de^\aa,'\ed?\00\00j5v\da\b7?\cd,k>n\f2\ec?\00`\1cNC\ab\b9?\02y\a7\a2m\be\ec?\00`\r\bb\c7x\bb?m\087m&\8b\ec?\00 \e72\13C\bd?\04X]\bd\94X\ec?\00`\deq1\n\bf?\8c\9f\bb3\b5&\ec?\00@\91+\15g\c0??\e7\ec\ee\83\f5\eb?\00\b0\92\82\85G\c1?\c1\96\dbu\fd\c4\eb?\000\ca\cdn&\c2?(J\86\0c\1e\95\eb?\00P\c5\a6\d7\03\c3?,>\ef\c5\e2e\eb?\00\103<\c3\df\c3?\8b\88\c9gH7\eb?\00\80zk6\ba\c4?J0\1d!K\t\eb?\00\f0\d1(9\93\c5?~\ef\f2\85\e8\db\ea?\00\f0\18$\cdj\c6?\a2=`1\1d\af\ea?\00\90f\ec\f8@\c7?\a7X\d3?\e6\82\ea?\00\f0\1a\f5\c0\15\c8?\8bs\t\ef@W\ea?\00\80\f6T)\e9\c8?'K\ab\90*,\ea?\00@\f8\026\bb\c9?\d1\f2\93\13\a0\01\ea?\00\00,\1c\ed\8b\ca?\1b<\db$\9f\d7\e9?\00\d0\01\\Q[\cb?\90\b1\c7\05%\ae\e9?\00\c0\bc\ccg)\cc?/\ce\97\f2.\85\e9?\00`H\d55\f6\cc?uK\a4\ee\ba\\\e9?\00\c0F4\bd\c1\cd?8H\e7\9d\c64\e9?\00\e0\cf\b8\01\8c\ce?\e6Rg/O\r\e9?\00\90\17\c0\tU\cf?\9d\d7\ff\8eR\e6\e8?\00\b8\1f\12l\0e\d0?|\00\cc\9f\ce\bf\e8?\00\d0\93\0e\b8q\d0?\0e\c3\be\da\c0\99\e8?\00p\86\9ek\d4\d0?\fb\17#\aa't\e8?\00\d0K3\876\d1?\08\9a\b3\ac\00O\e8?\00H#g\r\98\d1?U>e\e8I*\e8?\00\80\cc\e0\ff\f8\d1?`\02\f4\95\01\06\e8?\00hc\d7_Y\d2?)\a3\e0c%\e2\e7?\00\a8\14\t0\b9\d2?\ad\b5\dcw\b3\be\e7?\00`C\10r\18\d3?\c2%\97g\aa\9b\e7?\00\18\ecm&w\d3?W\06\17\f2\07y\e7?\000\af\fbO\d5\d3?\0c\13\d6\db\caV\e7?\00\e0/\e3\ee2\d4?k\b6O\01\00\10\e6?<[B\91l\02~<\95\b4M\03\000\e6?A]\00H\ea\bf\8d<x\d4\94\r\00P\e6?\b7\a5\d6\86\a7\7f\8e<\adoN\07\00p\e6?L%Tk\ea\fca<\ae\0f\df\fe\ff\8f\e6?\fd\0eYL'~|\bc\bc\c5c\07\00\b0\e6?\01\da\dcHh\c1\8a\bc\f6\c1\\\1e\00\d0\e6?\11\93I\9d\1c?\83<>\f6\05\eb\ff\ef\e6?S-\e2\1a\04\80~\bc\80\97\86\0e\00\10\e7?Ry\tqf\ff{<\12\e9g\fc\ff/\e7?$\87\bd&\e2\00\8c<j\11\81\df\ffO\e7?\d2\01\f1n\91\02n\bc\90\9cg\0f\00p\e7?t\9cT\cdq\fcg\bc5\c8~\fa\ff\8f\e7?\83\04\f5\9e\c1\be\81<\e6\c2 \fe\ff\af\e7?ed\cc)\17~p\bc\00\c9?\ed\ff\cf\e7?\1c\8b{\08r\80\80\bcv\1a&\e9\ff\ef\e7?\ae\f9\9dm(\c0\8d<\e8\a3\9c\04\00\10\e8?3L\e5Q\d2\7f\89<\8f,\93\17\000\e8?\81\f30\b6\e9\fe\8a\bc\9cs3\06\00P\e8?\bc5ek\bf\bf\89<\c6\89B \00p\e8?u{\11\f3e\bf\8b\bc\04y\f5\eb\ff\8f\e8?W\cb=\a2n\00\89\bc\df\04\bc\"\00\b0\e8?\nK\e08\df\00}\bc\8a\1b\0c\e5\ff\cf\e8?\05\9f\ffFq\00\88\bcC\8e\91\fc\ff\ef\e8?8pz\d0{\81\83<\c7_\fa\1e\00\10\e9?\03\b4\dfv\91>\89<\b9{F\13\000\e9?v\02\98KN\80\7f<o\07\ee\e6\ffO\e9?.b\ff\d9\f0~\8f\bc\d1\12<\de\ffo\e9?\ba8&\96\aa\82p\bc\r\8aE\f4\ff\8f\e9?\ef\a8d\91\1b\80\87\bc>.\98\dd\ff\af\e9?7\93Z\8a\e0@\87\bcf\fbI\ed\ff\cf\e9?\00\e0\9b\c1\08\ce?<Q\9c\f1 \00\f0\e9?\n[\88'\aa?\8a\bc\06\b0E\11\00\10\ea?V\daX\99H\fft<\fa\f6\bb\07\000\ea?\18m+\8a\ab\be\8c<y\1d\97\10\00P\ea?0yx\dd\ca\fe\88<H.\f5\1d\00p\ea?\db\ab\d8=vA\8f\bcR3Y\1c\00\90\ea?\12v\c2\84\02\bf\8e\bcK>O*\00\b0\ea?_?\ff<\04\fdi\bc\d1\1e\ae\d7\ff\cf\ea?\b4p\90\12\e7>\82\bcx\04Q\ee\ff\ef\ea?\a3\de\0e\e0>\06j<[\re\db\ff\0f\eb?\b9\n\1f8\c8\06Z<W\ca\aa\fe\ff/\eb?\1d<#t\1e\01y\bc\dc\ba\95\d9\ffO\eb?\9f*\86h\10\ffy\bc\9ce\9e$\00p\eb?>O\86\d0E\ff\8a<@\16\87\f9\ff\8f\eb?\f9\c3\c2\96w\fe|<O\cb\04\d2\ff\af\eb?\c4+\f2\ee'\ffc\bcE\\A\d2\ff\cf\eb?!\ea;\ee\b7\ffl\bc\df\tc\f8\ff\ef\eb?\\\0b.\97\03A\81\bcSv\b5\e1\ff\0f\ec?\19j\b7\94d\c1\8b<\e3W\fa\f1\ff/\ec?\ed\c60\8d\ef\fed\bc$\e4\bf\dc\ffO\ec?uG\ec\bch?\84\bc\f7\b9T\ed\ffo\ec?\ec\e0S\f0\a3~\84<\d5\8f\99\eb\ff\8f\ec?\f1\92\f9\8d\06\83s<\9a!%!\00\b0\ec?\04\0e\18d\8e\fdh\bc\9cF\94\dd\ff\cf\ec?r\ea\c7\1c\be~\8e<v\c4\fd\ea\ff\ef\ec?\fe\88\9f\ad9\be\8e<+\f8\9a\16\00\10\ed?qZ\b9\a8\91}u<\1d\f7\0f\r\000\ed?\da\c7pi\90\c1\89<\c4\0fy\ea\ffO\ed?\0c\feX\c57\0eX\bc\e5\87\dc.\00p\ed?D\0f\c1M\d6\80\7f\bc\aa\82\dc!\00\90\ed?\\\\\fd\94\8f|t\bc\83\02k\d8\ff\af\ed?~a!\c5\1d\7f\8c<9Gl)\00\d0\ed?S\b1\ff\b2\9e\01\88<\f5\90D\e5\ff\ef\ed?\89\ccR\c6\d2\00n<\94\f6\ab\cd\ff\0f\ee?\d2i- @\83\7f\bc\dd\c8R\db\ff/\ee?d\08\1b\ca\c1\00{<\ef\16B\f2\ffO\ee?Q\ab\94\b0\a8\ffr<\11^\8a\e8\ffo\ee?Y\be\ef\b1s\f6W\bc\r\ff\9e\11\00\90\ee?\01\c8\0b^\8d\80\84\bcD\17\a5\df\ff\af\ee?\b5 C\d5\06\00x<\a1\7f\12\1a\00\d0\ee?\92\\V`\f8\02P\bc\c4\bc\ba\07\00\f0\ee?\11\e65]D@\85\bc\02\8dz\f5\ff\0f\ef?\05\91\ef91\fbO\bc\c7\8a\e5\1e\000\ef?U\11s\f2\ac\81\8a<\944\82\f5\ffO\ef?C\c7\d7\d4A?\8a<kL\a9\fc\ffo\ef?ux\98\1c\f4\02b\bcA\c4\f9\e1\ff\8f\ef?K\e7w\f4\d1}w<~\e3\e0\d2\ff\af\ef?1\a3|\9a\19\01o\bc\9e\e4w\1c\00\d0\ef?\b1\ac\ceK\ee\81q<1\c3\e0\f7\ff\ef\ef?Z\87p\017\05n\bcn`e\f4\ff\0f\f0?\da\n\1cI\ad~\8a\bcXz\86\f3\ff/\f0?\e0\b2\fc\c3i\7f\97\bc\17\r\fc\fd\ffO\f0?[\94\cb4\fe\bf\97<\82M\cd\03\00p\f0?\cbV\e4\c0\83\00\82<\e8\cb\f2\f9\ff\8f\f0?\1au7\be\df\ffm\bce\da\0c\01\00\b0\f0?\eb&\e6\ae\7f?\91\bc8\d3\a4\01\00\d0\f0?\f7\9fHy\fa}\80<\fd\fd\da\fa\ff\ef\f0?\c0k\d6p\05\04w\bc\96\fd\ba\0b\00\10\f1?b\0bm\84\d4\80\8e<]\f4\e5\fa\ff/\f1?\ef6\fdd\fa\bf\9d<\d9\9a\d5\r\00P\f1?\aeP\12pw\00\9a<\9aU!\0f\00p\f1?\ee\de\e3\e2\f9\fd\8d<&T'\fc\ff\8f\f1?sr;\dc0\00\91<Y<=\12\00\b0\f1?\88\01\03\80y\7f\99<\b7\9e)\f8\ff\cf\f1?g\8c\9f\ab2\f9e\bc\00\d4\8a\f4\ff\ef\f1?\eb[\a7\9d\bf\7f\93<\a4\86\8b\0c\00\10\f2?\"[\fd\91k\80\9f<\03C\85\03\000\f2?3\bf\9f\eb\c2\ff\93<\84\f6\bc\ff\ffO\f2?r..~\e7\01v<\d9!)\f5\ffo\f2?a\0c\7fv\bb\fc\7f<<:\93\14\00\90\f2?+A\02<\ca\02r\bc\13cU\14\00\b0\f2?\02\1f\f23\82\80\92\bc;R\fe\eb\ff\cf\f2?\f2\dcO8~\ff\88\bc\96\ad\b8\0b\00\f0\f2?\c5A0PQ\ff\85\bc\af\e2z\fb\ff\0f\f3?\9d(^\88q\00\81\bc\7f_\ac\fe\ff/\f3?\15\b7\b7?]\ff\91\bcVg\a6\0c\00P\f3?\bd\82\8b\"\82\7f\95<!\f7\fb\11\00p\f3?\cc\d5\r\c4\ba\00\80<\b9/Y\f9\ff\8f\f3?Q\a7\b2-\9d?\94\bcB\d2\dd\04\00\b0\f3?\e18vpk\7f\85<W\c9\b2\f5\ff\cf\f3?1\12\bf\10:\02z<\18\b4\b0\ea\ff\ef\f3?\b0R\b1fm\7f\98<\f4\af2\15\00\10\f4?$\85\19_7\f8g<)\8bG\17\000\f4?CQ\dcr\e6\01\83<c\b4\95\e7\ffO\f4?Z\89\b2\b8i\ff\89<\e0u\04\e8\ffo\f4?T\f2\c2\9b\b1\c0\95\bc\e7\c1o\ef\ff\8f\f4?r*:\f2\t@\9b<\04\a7\be\e5\ff\af\f4?E}\r\bf\b7\ff\94\bc\de'\10\17\00\d0\f4?=j\dcqd\c0\99\bc\e2>\f0\0f\00\f0\f4?\1cS\85\0b\89\7f\97<\d1K\dc\12\00\10\f5?6\a4fqe\04`<z'\05\16\000\f5?\t2#\ce\ce\bf\96\bcLp\db\ec\ffO\f5?\d7\a1\05\05r\02\89\bc\a9T_\ef\ffo\f5?\12d\c9\0e\e6\bf\9b<\12\10\e6\17\00\90\f5?\90\ef\af\81\c5~\88<\92>\c9\03\00\b0\f5?\c0\0c\bf\n\08A\9f\bc\bc\19I\1d\00\d0\f5?)G%\fb*\81\98\bc\89z\b8\e7\ff\ef\f5?\04i\ed\80\b7~\94\bc\00\00\00\00\00\00\e0?\00\00\00\00\00\00\e0\bf\07")
  ;; __std_f4 — from std_wasm.wasm (sha256 b4b6f06748d6)
  ;; __std_f21 — from std_wasm.wasm (sha256 61b86fc4b3a0)
  ;; __std_f23 — from std_wasm.wasm (sha256 2448159130cb)
  ;; __std_f88 — from std_wasm.wasm (sha256 59c161f4ae70)
  ;; __std_f91 — from std_wasm.wasm (sha256 18a947e25763)
  ;; __std_f120 — from std_wasm.wasm (sha256 bd4cb38df48b)
  ;; __std_f122 — from std_wasm.wasm (sha256 889c7b5ca2dc)
  ;; __std_f129 — from std_wasm.wasm (sha256 67dbdd61ea9b)
  ;; __std_f130 — from std_wasm.wasm (sha256 f15aa78ce6d6)
  ;; __std_f131 — from std_wasm.wasm (sha256 2f81dc7302bb)
  ;; __std_f132 — from std_wasm.wasm (sha256 38e98c1edeed)
  ;; __std_f133 — from std_wasm.wasm (sha256 16c99e1a095a)
  ;; __std_f134 — from std_wasm.wasm (sha256 30c514d3cfe8)
  ;; __std_f265 — from std_wasm.wasm (sha256 8097395f0640)
  ;; __std_f267 — from std_wasm.wasm (sha256 5ac39cdc3016)
  ;; __std_f268 — from std_wasm.wasm (sha256 cda2fb2bf3e4)
  ;; __std_f306 — from std_wasm.wasm (sha256 237bb4237dcb)
  ;; __std_f312 — from std_wasm.wasm (sha256 fba83af40177)
  ;; __std_f434 — from std_wasm.wasm (sha256 91fc3314249d)
  ;; __std_f446 — from std_wasm.wasm (sha256 d13a98c08300)
  ;; __std_f448 — from std_wasm.wasm (sha256 0314fe5f477f)
  ;; std:bytes.isUtf8 — from std_wasm.wasm (sha256 50b958e37e0d)
  ;; std:bytes.slice — from std_wasm.wasm (sha256 f3fc51f8c3ed)
  ;; std:text.slice — from std_wasm.wasm (sha256 051c966cf248)
  ;; __std_f500 — from std_wasm.wasm (sha256 6eed520bf8fe)
  ;; std:text.toUpper — from std_wasm.wasm (sha256 72dc7de6cc0d)
  ;; std:text.at — from std_wasm.wasm (sha256 037f981d6200)
  ;; std:text.endsWith — from std_wasm.wasm (sha256 5bd7ccb223bc)
  ;; std:text.startsWith — from std_wasm.wasm (sha256 322b10039271)
  ;; std:text.contains — from std_wasm.wasm (sha256 8f31d2bebba0)
  ;; std:text.chars — from std_wasm.wasm (sha256 8df0db93815d)
  ;; __std_f523 — from std_wasm.wasm (sha256 2904f8c0427d)
  ;; std:text.split — from std_wasm.wasm (sha256 d23f0fc25558)
  ;; std-wasm's .wat leaves (front 164 s3)
  (func $__std_random_float (result f64)
    call $__wasi_random_f64
  )
  (func $__std_number_i64ToString (param $v i64) (result (ref null $str))
    local.get $v
    i64.const 0
    i64.lt_s
    (if (result (ref null $str))
      (then
        i64.const 0
        local.get $v
        i64.sub
        i32.const 1
        call $__std_number_decimal
      )
      (else
        local.get $v
        i32.const 0
        call $__std_number_decimal
      )
    )
  )
  (func $__std_fs_cwd (result (ref null $str))
    (local $mark i32)
    (local $cap i32)
    (local $buf i32)
    (local $n i32)
    (local $out (ref null $str))
    global.get $__heap_ptr
    local.set $mark
    i32.const 512
    local.set $cap
    local.get $cap
    call $__alloc
    local.set $buf
    local.get $buf
    local.get $cap
    call $__fs_cwd
    local.set $n
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $mark
        global.set $__heap_ptr
        i32.const 0
        array.new_default $str
        return
      )
    )
    local.get $n
    local.get $cap
    i32.gt_u
    (if
      (then
        local.get $n
        local.set $cap
        local.get $cap
        call $__alloc
        local.set $buf
        local.get $buf
        local.get $cap
        call $__fs_cwd
        drop
      )
    )
    local.get $buf
    local.get $n
    call $__std_fs_toStr
    local.set $out
    local.get $mark
    global.set $__heap_ptr
    local.get $out
  )
  (func $__std_fs_getenv (param $name (ref null $str)) (result (ref null $str))
    (local $mark i32)
    (local $lin i32)
    (local $cap i32)
    (local $buf i32)
    (local $n i32)
    (local $out (ref null $str))
    global.get $__heap_ptr
    local.set $mark
    local.get $name
    call $__std_fs_stage
    local.set $lin
    i32.const 512
    local.set $cap
    local.get $cap
    call $__alloc
    local.set $buf
    local.get $lin
    i32.const 4
    i32.add
    local.get $lin
    i32.load
    local.get $buf
    local.get $cap
    call $__fs_getenv
    local.set $n
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $mark
        global.set $__heap_ptr
        i32.const 0
        array.new_default $str
        return
      )
    )
    local.get $n
    local.get $cap
    i32.gt_u
    (if
      (then
        local.get $n
        local.set $cap
        local.get $cap
        call $__alloc
        local.set $buf
        local.get $lin
        i32.const 4
        i32.add
        local.get $lin
        i32.load
        local.get $buf
        local.get $cap
        call $__fs_getenv
        drop
      )
    )
    local.get $buf
    local.get $n
    call $__std_fs_toStr
    local.set $out
    local.get $mark
    global.set $__heap_ptr
    local.get $out
  )
  (func $__std_fs_open (param $path (ref null $str)) (param $mode i32) (result i32)
    (local $mark i32)
    (local $lin i32)
    (local $h i32)
    (local $out i32)
    (local $r i32)
    global.get $__heap_ptr
    local.set $mark
    local.get $path
    call $__std_fs_stage
    local.set $lin
    local.get $lin
    i32.const 4
    i32.add
    local.get $lin
    i32.load
    local.get $mode
    call $__fs_open
    local.set $h
    local.get $h
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $mark
        global.set $__heap_ptr
        local.get $h
        return
      )
    )
    local.get $mode
    i32.eqz
    (if
      (then
        i32.const 24
        call $__alloc
        local.set $out
        local.get $h
        local.get $out
        call $__fs_stat
        local.set $r
        local.get $r
        i32.const 0
        i32.lt_s
        (if
          (then
            local.get $h
            call $__fs_close
            local.get $mark
            global.set $__heap_ptr
            local.get $r
            return
          )
        )
        local.get $out
        i32.load
        i32.const 3
        i32.eq
        (if
          (then
            local.get $h
            call $__fs_close
            local.get $mark
            global.set $__heap_ptr
            i32.const -15
            return
          )
        )
      )
    )
    local.get $mark
    global.set $__heap_ptr
    i32.const 0
    local.get $h
    i32.const 0
    call $__std_fs_block
  )
  (func $__std_fs_openMem (param $data (ref null $str)) (result i32)
    (local $n i32)
    (local $p i32)
    (local $i i32)
    local.get $data
    array.len
    local.set $n
    local.get $n
    call $__alloc
    local.set $p
    (block $done
      (loop $each
        local.get $i
        local.get $n
        i32.ge_u
        br_if $done
        local.get $p
        local.get $i
        i32.add
        local.get $data
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $each
      )
    )
    i32.const 1
    local.get $p
    local.get $n
    call $__std_fs_block
  )
  (func $__std_fs_close (param $h i32)
    local.get $h
    i32.load
    i32.eqz
    (if
      (then
        local.get $h
        i32.load offset=4
        call $__fs_close
        local.get $h
        i32.const 2
        i32.store
      )
    )
  )
  (func $__std_fs_isMem (param $h i32) (result i32)
    local.get $h
    i32.load
    i32.const 1
    i32.eq
  )
  (func $__std_fs_tell (param $h i32) (result i64)
    local.get $h
    i64.load offset=8
  )
  (func $__std_fs_seek (param $h i32) (param $pos i64)
    local.get $h
    local.get $pos
    i64.store offset=8
  )
  (func $__std_fs_size (param $h i32) (result (ref null $result))
    (local $n i64)
    local.get $h
    call $__std_fs_sizeRaw
    local.set $n
    local.get $n
    i64.const 0
    i64.lt_s
    (if
      (then
        i32.const -1
        local.get $n
        i32.wrap_i64
        i32.sub
        call $__std_fs_errCode
        return
      )
    )
    local.get $n
    call $__std_fs_okI64
  )
  (func $__std_fs_sizeRaw (param $h i32) (result i64)
    (local $mark i32)
    (local $out i32)
    (local $r i32)
    (local $size i64)
    local.get $h
    i32.load
    i32.const 1
    i32.eq
    (if
      (then
        local.get $h
        i32.load offset=16
        i64.extend_i32_u
        return
      )
    )
    local.get $h
    i32.load
    i32.const 2
    i32.eq
    (if
      (then
        i64.const -4
        return
      )
    )
    global.get $__heap_ptr
    local.set $mark
    i32.const 24
    call $__alloc
    local.set $out
    local.get $h
    i32.load offset=4
    local.get $out
    call $__fs_stat
    local.set $r
    local.get $r
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $mark
        global.set $__heap_ptr
        local.get $r
        i64.extend_i32_s
        return
      )
    )
    local.get $out
    i64.load offset=8
    local.set $size
    local.get $mark
    global.set $__heap_ptr
    local.get $size
  )
  (func $__std_fs_read (param $h i32) (param $n i32) (result (ref null $result))
    (local $mark i32)
    (local $buf i32)
    (local $got i32)
    (local $out (ref null $str))
    global.get $__heap_ptr
    local.set $mark
    local.get $n
    call $__alloc
    local.set $buf
    local.get $h
    local.get $buf
    local.get $n
    call $__std_fs_pull
    local.set $got
    local.get $got
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $mark
        global.set $__heap_ptr
        i32.const -1
        local.get $got
        i32.sub
        call $__std_fs_errCode
        return
      )
    )
    local.get $buf
    local.get $got
    call $__std_fs_toStr
    local.set $out
    local.get $mark
    global.set $__heap_ptr
    local.get $out
    call $__std_fs_okStr
  )
  (func $__std_fs_readAll (param $h i32) (result (ref null $result))
    (local $left i64)
    (local $mark i32)
    (local $cap i32)
    (local $buf i32)
    (local $bigger i32)
    (local $total i32)
    (local $got i32)
    (local $out (ref null $str))
    global.get $__heap_ptr
    local.set $mark
    i32.const 4096
    local.set $cap
    local.get $h
    call $__std_fs_sizeRaw
    local.get $h
    call $__std_fs_tell
    i64.sub
    local.set $left
    local.get $left
    i64.const 4096
    i64.gt_s
    local.get $left
    i64.const 1073741824
    i64.lt_s
    i32.and
    (if
      (then
        local.get $left
        i32.wrap_i64
        i32.const 1
        i32.add
        local.set $cap
      )
    )
    local.get $cap
    call $__alloc
    local.set $buf
    (block $done
      (loop $each
        local.get $total
        local.get $cap
        i32.eq
        (if
          (then
            local.get $cap
            i32.const 2
            i32.mul
            call $__alloc
            local.set $bigger
            local.get $bigger
            local.get $buf
            local.get $total
            memory.copy
            local.get $bigger
            local.set $buf
            local.get $cap
            i32.const 2
            i32.mul
            local.set $cap
          )
        )
        local.get $h
        local.get $buf
        local.get $total
        i32.add
        local.get $cap
        local.get $total
        i32.sub
        call $__std_fs_pull
        local.set $got
        local.get $got
        i32.const 0
        i32.lt_s
        (if
          (then
            local.get $mark
            global.set $__heap_ptr
            i32.const -1
            local.get $got
            i32.sub
            call $__std_fs_errCode
            return
          )
        )
        local.get $got
        i32.eqz
        br_if $done
        local.get $total
        local.get $got
        i32.add
        local.set $total
        br $each
      )
    )
    local.get $buf
    local.get $total
    call $__std_fs_toStr
    local.set $out
    local.get $mark
    global.set $__heap_ptr
    local.get $out
    call $__std_fs_okStr
  )
  (func $__std_fs_readLine (param $h i32) (result (ref null $result))
    (local $mark i32)
    (local $cap i32)
    (local $buf i32)
    (local $bigger i32)
    (local $total i32)
    (local $got i32)
    (local $i i32)
    (local $line64 i64)
    (local $out (ref null $str))
    global.get $__heap_ptr
    local.set $mark
    i32.const 256
    local.set $cap
    local.get $cap
    call $__alloc
    local.set $buf
    (block $done
      (loop $each
        local.get $total
        local.get $cap
        i32.eq
        (if
          (then
            local.get $cap
            i32.const 2
            i32.mul
            call $__alloc
            local.set $bigger
            local.get $bigger
            local.get $buf
            local.get $total
            memory.copy
            local.get $bigger
            local.set $buf
            local.get $cap
            i32.const 2
            i32.mul
            local.set $cap
          )
        )
        local.get $h
        call $__std_fs_tell
        local.set $line64
        local.get $h
        local.get $buf
        local.get $total
        i32.add
        local.get $cap
        local.get $total
        i32.sub
        call $__std_fs_pull
        local.set $got
        local.get $got
        i32.const 0
        i32.lt_s
        (if
          (then
            local.get $mark
            global.set $__heap_ptr
            i32.const -1
            local.get $got
            i32.sub
            call $__std_fs_errCode
            return
          )
        )
        local.get $total
        local.set $i
        (block $scanned
          (loop $scan
            local.get $i
            local.get $total
            local.get $got
            i32.add
            i32.ge_u
            br_if $scanned
            local.get $buf
            local.get $i
            i32.add
            i32.load8_u
            i32.const 10
            i32.eq
            (if
              (then
                local.get $h
                local.get $line64
                local.get $total
                i64.extend_i32_u
                i64.sub
                local.get $i
                i32.const 1
                i32.add
                i64.extend_i32_u
                i64.add
                i64.store offset=8
                local.get $i
                i32.const 1
                i32.add
                local.set $total
                br $done
              )
            )
            local.get $i
            i32.const 1
            i32.add
            local.set $i
            br $scan
          )
        )
        local.get $got
        i32.eqz
        br_if $done
        local.get $total
        local.get $got
        i32.add
        local.set $total
        br $each
      )
    )
    local.get $buf
    local.get $total
    call $__std_fs_toStr
    local.set $out
    local.get $mark
    global.set $__heap_ptr
    local.get $out
    call $__std_fs_okStr
  )
  (func $__std_fs_write (param $h i32) (param $data (ref null $str)) (result i32)
    (local $mark i32)
    (local $lin i32)
    (local $wrote i32)
    local.get $h
    i32.load
    i32.eqz
    i32.eqz
    (if
      (then
        local.get $h
        i32.load
        i32.const 2
        i32.eq
        (if
          (then
            i32.const -4
            return
          )
        )
        i32.const -34
        return
      )
    )
    global.get $__heap_ptr
    local.set $mark
    local.get $data
    call $__std_fs_stage
    local.set $lin
    local.get $h
    i32.load offset=4
    local.get $h
    i64.load offset=8
    local.get $lin
    i32.const 4
    i32.add
    local.get $lin
    i32.load
    call $__fs_write
    local.set $wrote
    local.get $mark
    global.set $__heap_ptr
    local.get $wrote
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $wrote
        return
      )
    )
    local.get $h
    local.get $h
    i64.load offset=8
    local.get $wrote
    i64.extend_i32_u
    i64.add
    i64.store offset=8
    local.get $wrote
  )
  (func $__std_fs_statKind (param $path (ref null $str)) (param $follow i32) (result i32)
    (local $mark i32)
    (local $lin i32)
    (local $out i32)
    (local $r i32)
    global.get $__heap_ptr
    local.set $mark
    local.get $path
    call $__std_fs_stage
    local.set $lin
    i32.const 24
    call $__alloc
    local.set $out
    local.get $lin
    i32.const 4
    i32.add
    local.get $lin
    i32.load
    local.get $follow
    local.get $out
    call $__fs_stat_at
    local.set $r
    local.get $r
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $mark
        global.set $__heap_ptr
        local.get $r
        return
      )
    )
    local.get $out
    i32.load
    local.set $r
    local.get $mark
    global.set $__heap_ptr
    local.get $r
  )
  (func $__std_fs_statSize (param $path (ref null $str)) (result (ref null $result))
    (local $mark i32)
    (local $lin i32)
    (local $out i32)
    (local $r i32)
    (local $size i64)
    global.get $__heap_ptr
    local.set $mark
    local.get $path
    call $__std_fs_stage
    local.set $lin
    i32.const 24
    call $__alloc
    local.set $out
    local.get $lin
    i32.const 4
    i32.add
    local.get $lin
    i32.load
    i32.const 1
    local.get $out
    call $__fs_stat_at
    local.set $r
    local.get $r
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $mark
        global.set $__heap_ptr
        i32.const -1
        local.get $r
        i32.sub
        call $__std_fs_errCode
        return
      )
    )
    local.get $out
    i64.load offset=8
    local.set $size
    local.get $mark
    global.set $__heap_ptr
    local.get $size
    call $__std_fs_okI64
  )
  (func $__std_fs_statMtime (param $path (ref null $str)) (result (ref null $result))
    (local $mark i32)
    (local $lin i32)
    (local $out i32)
    (local $r i32)
    (local $mtime i64)
    global.get $__heap_ptr
    local.set $mark
    local.get $path
    call $__std_fs_stage
    local.set $lin
    i32.const 24
    call $__alloc
    local.set $out
    local.get $lin
    i32.const 4
    i32.add
    local.get $lin
    i32.load
    i32.const 1
    local.get $out
    call $__fs_stat_at
    local.set $r
    local.get $r
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $mark
        global.set $__heap_ptr
        i32.const -1
        local.get $r
        i32.sub
        call $__std_fs_errCode
        return
      )
    )
    local.get $out
    i64.load offset=16
    local.set $mtime
    local.get $mark
    global.set $__heap_ptr
    local.get $mtime
    call $__std_fs_okI64
  )
  (func $__std_fs_list (param $path (ref null $str)) (result (ref null $result))
    (local $mark i32)
    (local $lin i32)
    (local $s i32)
    (local $tmp i32)
    (local $first i32)
    (local $rec i32)
    (local $n i32)
    (local $len i32)
    (local $count i32)
    (local $i i32)
    (local $names (ref null $arr_any))
    global.get $__heap_ptr
    local.set $mark
    local.get $path
    call $__std_fs_stage
    local.set $lin
    local.get $lin
    i32.const 4
    i32.add
    local.get $lin
    i32.load
    call $__fs_readdir_open
    local.set $s
    local.get $s
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $mark
        global.set $__heap_ptr
        i32.const -1
        local.get $s
        i32.sub
        call $__std_fs_errCode
        return
      )
    )
    i32.const 1024
    call $__alloc
    local.set $tmp
    global.get $__heap_ptr
    local.set $first
    (block $end
      (loop $each
        local.get $s
        local.get $tmp
        i32.const 1024
        call $__fs_readdir_next
        local.set $len
        local.get $len
        i32.const -100
        i32.eq
        br_if $end
        local.get $len
        i32.const 0
        i32.lt_s
        (if
          (then
            local.get $s
            call $__fs_readdir_close
            local.get $mark
            global.set $__heap_ptr
            i32.const -1
            local.get $len
            i32.sub
            call $__std_fs_errCode
            return
          )
        )
        local.get $len
        i32.const 4
        i32.add
        call $__alloc
        local.set $rec
        local.get $rec
        local.get $len
        i32.store
        local.get $rec
        i32.const 4
        i32.add
        local.get $tmp
        i32.const 4
        i32.add
        local.get $len
        memory.copy
        local.get $count
        i32.const 1
        i32.add
        local.set $count
        br $each
      )
    )
    local.get $s
    call $__fs_readdir_close
    local.get $count
    array.new_default $arr_any
    local.set $names
    local.get $first
    local.set $rec
    (block $filled
      (loop $fill
        local.get $i
        local.get $count
        i32.ge_u
        br_if $filled
        local.get $rec
        i32.load
        local.set $len
        local.get $names
        local.get $i
        local.get $rec
        i32.const 4
        i32.add
        local.get $len
        call $__std_fs_toStr
        array.set $arr_any
        local.get $rec
        i32.const 4
        i32.add
        local.get $len
        i32.add
        i32.const 3
        i32.add
        i32.const -4
        i32.and
        local.set $rec
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $fill
      )
    )
    local.get $mark
    global.set $__heap_ptr
    local.get $names
    call $__std_fs_okArr
  )
  (func $__std_fs_mkdir (param $path (ref null $str)) (result i32)
    (local $mark i32)
    (local $lin i32)
    (local $r i32)
    global.get $__heap_ptr
    local.set $mark
    local.get $path
    call $__std_fs_stage
    local.set $lin
    local.get $lin
    i32.const 4
    i32.add
    local.get $lin
    i32.load
    call $__fs_mkdir
    local.set $r
    local.get $mark
    global.set $__heap_ptr
    local.get $r
  )
  (func $__std_fs_rmdir (param $path (ref null $str)) (result i32)
    (local $mark i32)
    (local $lin i32)
    (local $r i32)
    global.get $__heap_ptr
    local.set $mark
    local.get $path
    call $__std_fs_stage
    local.set $lin
    local.get $lin
    i32.const 4
    i32.add
    local.get $lin
    i32.load
    call $__fs_rmdir
    local.set $r
    local.get $mark
    global.set $__heap_ptr
    local.get $r
  )
  (func $__std_fs_unlink (param $path (ref null $str)) (result i32)
    (local $mark i32)
    (local $lin i32)
    (local $r i32)
    global.get $__heap_ptr
    local.set $mark
    local.get $path
    call $__std_fs_stage
    local.set $lin
    local.get $lin
    i32.const 4
    i32.add
    local.get $lin
    i32.load
    call $__fs_unlink
    local.set $r
    local.get $mark
    global.set $__heap_ptr
    local.get $r
  )
  (func $__std_fs_symlink (param $target (ref null $str)) (param $link (ref null $str)) (result i32)
    (local $mark i32)
    (local $t i32)
    (local $l i32)
    (local $r i32)
    global.get $__heap_ptr
    local.set $mark
    local.get $target
    call $__std_fs_stage
    local.set $t
    local.get $link
    call $__std_fs_stage
    local.set $l
    local.get $t
    i32.const 4
    i32.add
    local.get $t
    i32.load
    local.get $l
    i32.const 4
    i32.add
    local.get $l
    i32.load
    call $__fs_symlink
    local.set $r
    local.get $mark
    global.set $__heap_ptr
    local.get $r
  )
  (func $__std_bytes_at (param $b (ref null $str)) (param $i i32) (result i32)
    local.get $b
    local.get $i
    array.get_u $str
  )
  (func $__std_hash_sha256Hex (param $data (ref null $str)) (result (ref null $str))
    (local $mark i32)
    (local $n i32)
    (local $total i32)
    (local $base i32)
    (local $k i32)
    (local $w i32)
    (local $h i32)
    (local $i i32)
    (local $word i32)
    (local $nib i32)
    (local $out (ref null $str))
    global.get $__heap_ptr
    local.set $mark
    local.get $data
    array.len
    local.set $n
    local.get $n
    i32.const 72
    i32.add
    i32.const -64
    i32.and
    local.set $total
    local.get $total
    i32.const 544
    i32.add
    call $__alloc
    local.set $base
    local.get $base
    local.get $total
    i32.add
    local.set $k
    local.get $k
    i32.const 256
    i32.add
    local.set $w
    local.get $w
    i32.const 256
    i32.add
    local.set $h
    (block $copied
      (loop $copy
        local.get $i
        local.get $n
        i32.ge_u
        br_if $copied
        local.get $base
        local.get $i
        i32.add
        local.get $data
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $copy
      )
    )
    local.get $base
    local.get $n
    i32.add
    i32.const 0
    local.get $total
    local.get $n
    i32.sub
    memory.fill
    local.get $base
    local.get $n
    i32.add
    i32.const 128
    i32.store8
    local.get $base
    local.get $total
    i32.add
    i32.const -8
    i32.add
    local.get $n
    i32.const 29
    i32.shr_u
    call $__std_hash_putBe32
    local.get $base
    local.get $total
    i32.add
    i32.const -4
    i32.add
    local.get $n
    i32.const 3
    i32.shl
    call $__std_hash_putBe32
    local.get $k
    local.get $h
    call $__std_hash_tables
    i32.const 0
    local.set $i
    (block $done
      (loop $blocks
        local.get $i
        local.get $total
        i32.ge_u
        br_if $done
        local.get $h
        local.get $w
        local.get $k
        local.get $base
        local.get $i
        i32.add
        call $__std_hash_block
        local.get $i
        i32.const 64
        i32.add
        local.set $i
        br $blocks
      )
    )
    i32.const 64
    array.new_default $str
    local.set $out
    i32.const 0
    local.set $i
    (block $hexed
      (loop $hex
        local.get $i
        i32.const 64
        i32.ge_u
        br_if $hexed
        local.get $h
        local.get $i
        i32.const 3
        i32.shr_u
        i32.const 2
        i32.shl
        i32.add
        i32.load
        local.set $word
        local.get $word
        i32.const 28
        local.get $i
        i32.const 7
        i32.and
        i32.const 2
        i32.shl
        i32.sub
        i32.shr_u
        i32.const 15
        i32.and
        local.set $nib
        local.get $out
        local.get $i
        local.get $nib
        i32.const 48
        i32.add
        local.get $nib
        i32.const 87
        i32.add
        local.get $nib
        i32.const 10
        i32.lt_u
        select
        array.set $str
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $hex
      )
    )
    local.get $mark
    global.set $__heap_ptr
    local.get $out
  )
  (func $__std_text_charCodeAt (param $s (ref null $str)) (param $i i32) (result i32)
    (local $len i32)
    (local $p i32)
    (local $b i32)
    (local $w i32)
    (local $cp i32)
    (local $k i32)
    local.get $i
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const -1
        return
      )
    )
    local.get $s
    array.len
    local.set $len
    (block $done
      (loop $next
        local.get $p
        local.get $len
        i32.ge_u
        br_if $done
        local.get $s
        local.get $p
        array.get_u $str
        local.set $b
        i32.const 4
        i32.const 3
        i32.const 2
        i32.const 1
        local.get $b
        i32.const 0xC0
        i32.ge_u
        select
        local.get $b
        i32.const 0xE0
        i32.ge_u
        select
        local.get $b
        i32.const 0xF0
        i32.ge_u
        select
        local.set $w
        local.get $i
        i32.eqz
        (if
          (then
            local.get $w
            i32.const 1
            i32.eq
            (if
              (then
                local.get $b
                return
              )
            )
            local.get $b
            i32.const 0x80
            local.get $w
            i32.shr_u
            i32.const 1
            i32.sub
            i32.and
            local.set $cp
            i32.const 1
            local.set $k
            (block $decoded
              (loop $more
                local.get $k
                local.get $w
                i32.ge_u
                br_if $decoded
                local.get $cp
                i32.const 6
                i32.shl
                local.get $p
                local.get $k
                i32.add
                local.get $len
                i32.lt_u
                (if (result i32)
                  (then
                    local.get $s
                    local.get $p
                    local.get $k
                    i32.add
                    array.get_u $str
                    i32.const 0x3F
                    i32.and
                  )
                  (else
                    i32.const 0
                  )
                )
                i32.or
                local.set $cp
                local.get $k
                i32.const 1
                i32.add
                local.set $k
                br $more
              )
            )
            local.get $cp
            return
          )
        )
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        local.get $p
        local.get $w
        i32.add
        local.set $p
        br $next
      )
    )
    i32.const -1
  )
  (func $__std_number_decimal (param $mag i64) (param $neg i32) (result (ref null $str))
    (local $n i32)
    (local $i i32)
    (local $t i64)
    (local $out (ref null $str))
    local.get $mag
    local.set $t
    (block $counted
      (loop $count
        local.get $n
        i32.const 1
        i32.add
        local.set $n
        local.get $t
        i64.const 10
        i64.div_u
        local.tee $t
        i64.eqz
        br_if $counted
        br $count
      )
    )
    local.get $n
    local.get $neg
    i32.add
    local.tee $i
    array.new_default $str
    local.set $out
    local.get $mag
    local.set $t
    (block $filled
      (loop $fill
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        local.get $out
        local.get $i
        local.get $t
        i64.const 10
        i64.rem_u
        i32.wrap_i64
        i32.const 48
        i32.add
        array.set $str
        local.get $t
        i64.const 10
        i64.div_u
        local.tee $t
        i64.eqz
        br_if $filled
        br $fill
      )
    )
    local.get $neg
    (if
      (then
        local.get $out
        i32.const 0
        i32.const 45
        array.set $str
      )
    )
    local.get $out
  )
  (func $__std_fs_stage (param $s (ref null $str)) (result i32)
    local.get $s
    call $__gc_to_lin_str
  )
  (func $__std_fs_toStr (param $p i32) (param $n i32) (result (ref null $str))
    (local $r (ref null $str))
    (local $i i32)
    local.get $n
    array.new_default $str
    local.set $r
    (block $done
      (loop $each
        local.get $i
        local.get $n
        i32.ge_u
        br_if $done
        local.get $r
        local.get $i
        local.get $p
        local.get $i
        i32.add
        i32.load8_u
        array.set $str
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $each
      )
    )
    local.get $r
  )
  (func $__std_fs_block (param $kind i32) (param $a i32) (param $len i32) (result i32)
    (local $p i32)
    i32.const 24
    call $__alloc
    local.set $p
    local.get $p
    local.get $kind
    i32.store
    local.get $p
    local.get $a
    i32.store offset=4
    local.get $p
    i64.const 0
    i64.store offset=8
    local.get $p
    local.get $len
    i32.store offset=16
    local.get $p
  )
  (func $__std_fs_errCode (param $code i32) (result (ref null $result))
    i32.const 1
    local.get $code
    struct.new $box_i32
    struct.new $result
  )
  (func $__std_fs_okI64 (param $v i64) (result (ref null $result))
    i32.const 0
    local.get $v
    struct.new $box_i64
    struct.new $result
  )
  (func $__std_fs_pull (param $h i32) (param $buf i32) (param $n i32) (result i32)
    (local $total i32)
    (local $got i32)
    (local $pos i64)
    (local $avail i32)
    local.get $h
    i32.load
    i32.const 2
    i32.eq
    (if
      (then
        i32.const -4
        return
      )
    )
    local.get $h
    i32.load
    i32.const 1
    i32.eq
    (if
      (then
        local.get $h
        i32.load offset=16
        local.get $h
        i64.load offset=8
        i32.wrap_i64
        i32.sub
        local.set $avail
        local.get $avail
        i32.const 0
        i32.lt_s
        (if
          (then
            i32.const 0
            local.set $avail
          )
        )
        local.get $n
        local.get $avail
        local.get $n
        local.get $avail
        i32.lt_u
        select
        local.set $got
        local.get $buf
        local.get $h
        i32.load offset=4
        local.get $h
        i64.load offset=8
        i32.wrap_i64
        i32.add
        local.get $got
        memory.copy
        local.get $h
        local.get $h
        i64.load offset=8
        local.get $got
        i64.extend_i32_u
        i64.add
        i64.store offset=8
        local.get $got
        return
      )
    )
    local.get $h
    i64.load offset=8
    local.set $pos
    (block $done
      (loop $each
        local.get $total
        local.get $n
        i32.ge_u
        br_if $done
        local.get $h
        i32.load offset=4
        local.get $pos
        local.get $buf
        local.get $total
        i32.add
        local.get $n
        local.get $total
        i32.sub
        call $__fs_read
        local.set $got
        local.get $got
        i32.const 0
        i32.lt_s
        (if
          (then
            local.get $got
            return
          )
        )
        local.get $got
        i32.eqz
        br_if $done
        local.get $pos
        local.get $got
        i64.extend_i32_u
        i64.add
        local.set $pos
        local.get $total
        local.get $got
        i32.add
        local.set $total
        br $each
      )
    )
    local.get $h
    local.get $pos
    i64.store offset=8
    local.get $total
  )
  (func $__std_fs_okStr (param $s (ref null $str)) (result (ref null $result))
    i32.const 0
    local.get $s
    struct.new $result
  )
  (func $__std_fs_okArr (param $a (ref null $arr_any)) (result (ref null $result))
    i32.const 0
    local.get $a
    struct.new $result
  )
  (func $__std_hash_be32 (param $p i32) (result i32)
    local.get $p
    i32.load8_u
    i32.const 24
    i32.shl
    local.get $p
    i32.load8_u offset=1
    i32.const 16
    i32.shl
    i32.or
    local.get $p
    i32.load8_u offset=2
    i32.const 8
    i32.shl
    i32.or
    local.get $p
    i32.load8_u offset=3
    i32.or
  )
  (func $__std_hash_putBe32 (param $p i32) (param $v i32)
    local.get $p
    local.get $v
    i32.const 24
    i32.shr_u
    i32.store8
    local.get $p
    local.get $v
    i32.const 16
    i32.shr_u
    i32.store8 offset=1
    local.get $p
    local.get $v
    i32.const 8
    i32.shr_u
    i32.store8 offset=2
    local.get $p
    local.get $v
    i32.store8 offset=3
  )
  (func $__std_hash_tables (param $k i32) (param $h i32)
    local.get $k
    i32.const 1116352408
    i32.store
    local.get $k
    i32.const 1899447441
    i32.store offset=4
    local.get $k
    i32.const -1245643825
    i32.store offset=8
    local.get $k
    i32.const -373957723
    i32.store offset=12
    local.get $k
    i32.const 961987163
    i32.store offset=16
    local.get $k
    i32.const 1508970993
    i32.store offset=20
    local.get $k
    i32.const -1841331548
    i32.store offset=24
    local.get $k
    i32.const -1424204075
    i32.store offset=28
    local.get $k
    i32.const -670586216
    i32.store offset=32
    local.get $k
    i32.const 310598401
    i32.store offset=36
    local.get $k
    i32.const 607225278
    i32.store offset=40
    local.get $k
    i32.const 1426881987
    i32.store offset=44
    local.get $k
    i32.const 1925078388
    i32.store offset=48
    local.get $k
    i32.const -2132889090
    i32.store offset=52
    local.get $k
    i32.const -1680079193
    i32.store offset=56
    local.get $k
    i32.const -1046744716
    i32.store offset=60
    local.get $k
    i32.const -459576895
    i32.store offset=64
    local.get $k
    i32.const -272742522
    i32.store offset=68
    local.get $k
    i32.const 264347078
    i32.store offset=72
    local.get $k
    i32.const 604807628
    i32.store offset=76
    local.get $k
    i32.const 770255983
    i32.store offset=80
    local.get $k
    i32.const 1249150122
    i32.store offset=84
    local.get $k
    i32.const 1555081692
    i32.store offset=88
    local.get $k
    i32.const 1996064986
    i32.store offset=92
    local.get $k
    i32.const -1740746414
    i32.store offset=96
    local.get $k
    i32.const -1473132947
    i32.store offset=100
    local.get $k
    i32.const -1341970488
    i32.store offset=104
    local.get $k
    i32.const -1084653625
    i32.store offset=108
    local.get $k
    i32.const -958395405
    i32.store offset=112
    local.get $k
    i32.const -710438585
    i32.store offset=116
    local.get $k
    i32.const 113926993
    i32.store offset=120
    local.get $k
    i32.const 338241895
    i32.store offset=124
    local.get $k
    i32.const 666307205
    i32.store offset=128
    local.get $k
    i32.const 773529912
    i32.store offset=132
    local.get $k
    i32.const 1294757372
    i32.store offset=136
    local.get $k
    i32.const 1396182291
    i32.store offset=140
    local.get $k
    i32.const 1695183700
    i32.store offset=144
    local.get $k
    i32.const 1986661051
    i32.store offset=148
    local.get $k
    i32.const -2117940946
    i32.store offset=152
    local.get $k
    i32.const -1838011259
    i32.store offset=156
    local.get $k
    i32.const -1564481375
    i32.store offset=160
    local.get $k
    i32.const -1474664885
    i32.store offset=164
    local.get $k
    i32.const -1035236496
    i32.store offset=168
    local.get $k
    i32.const -949202525
    i32.store offset=172
    local.get $k
    i32.const -778901479
    i32.store offset=176
    local.get $k
    i32.const -694614492
    i32.store offset=180
    local.get $k
    i32.const -200395387
    i32.store offset=184
    local.get $k
    i32.const 275423344
    i32.store offset=188
    local.get $k
    i32.const 430227734
    i32.store offset=192
    local.get $k
    i32.const 506948616
    i32.store offset=196
    local.get $k
    i32.const 659060556
    i32.store offset=200
    local.get $k
    i32.const 883997877
    i32.store offset=204
    local.get $k
    i32.const 958139571
    i32.store offset=208
    local.get $k
    i32.const 1322822218
    i32.store offset=212
    local.get $k
    i32.const 1537002063
    i32.store offset=216
    local.get $k
    i32.const 1747873779
    i32.store offset=220
    local.get $k
    i32.const 1955562222
    i32.store offset=224
    local.get $k
    i32.const 2024104815
    i32.store offset=228
    local.get $k
    i32.const -2067236844
    i32.store offset=232
    local.get $k
    i32.const -1933114872
    i32.store offset=236
    local.get $k
    i32.const -1866530822
    i32.store offset=240
    local.get $k
    i32.const -1538233109
    i32.store offset=244
    local.get $k
    i32.const -1090935817
    i32.store offset=248
    local.get $k
    i32.const -965641998
    i32.store offset=252
    local.get $h
    i32.const 1779033703
    i32.store
    local.get $h
    i32.const -1150833019
    i32.store offset=4
    local.get $h
    i32.const 1013904242
    i32.store offset=8
    local.get $h
    i32.const -1521486534
    i32.store offset=12
    local.get $h
    i32.const 1359893119
    i32.store offset=16
    local.get $h
    i32.const -1694144372
    i32.store offset=20
    local.get $h
    i32.const 528734635
    i32.store offset=24
    local.get $h
    i32.const 1541459225
    i32.store offset=28
  )
  (func $__std_hash_block (param $h i32) (param $w i32) (param $k i32) (param $p i32)
    (local $t i32)
    (local $x i32)
    (local $a i32)
    (local $b i32)
    (local $c i32)
    (local $d i32)
    (local $e i32)
    (local $f i32)
    (local $g i32)
    (local $hh i32)
    (local $t1 i32)
    (local $t2 i32)
    (block $loaded
      (loop $load
        local.get $t
        i32.const 16
        i32.ge_u
        br_if $loaded
        local.get $w
        local.get $t
        i32.const 2
        i32.shl
        i32.add
        local.get $p
        local.get $t
        i32.const 2
        i32.shl
        i32.add
        call $__std_hash_be32
        i32.store
        local.get $t
        i32.const 1
        i32.add
        local.set $t
        br $load
      )
    )
    (block $extended
      (loop $extend
        local.get $t
        i32.const 64
        i32.ge_u
        br_if $extended
        local.get $w
        local.get $t
        i32.const 2
        i32.sub
        i32.const 2
        i32.shl
        i32.add
        i32.load
        local.set $x
        local.get $x
        i32.const 17
        i32.rotr
        local.get $x
        i32.const 19
        i32.rotr
        i32.xor
        local.get $x
        i32.const 10
        i32.shr_u
        i32.xor
        local.get $w
        local.get $t
        i32.const 7
        i32.sub
        i32.const 2
        i32.shl
        i32.add
        i32.load
        i32.add
        local.get $w
        local.get $t
        i32.const 15
        i32.sub
        i32.const 2
        i32.shl
        i32.add
        i32.load
        local.set $x
        local.get $x
        i32.const 7
        i32.rotr
        local.get $x
        i32.const 18
        i32.rotr
        i32.xor
        local.get $x
        i32.const 3
        i32.shr_u
        i32.xor
        i32.add
        local.get $w
        local.get $t
        i32.const 16
        i32.sub
        i32.const 2
        i32.shl
        i32.add
        i32.load
        i32.add
        local.set $x
        local.get $w
        local.get $t
        i32.const 2
        i32.shl
        i32.add
        local.get $x
        i32.store
        local.get $t
        i32.const 1
        i32.add
        local.set $t
        br $extend
      )
    )
    local.get $h
    i32.load
    local.set $a
    local.get $h
    i32.load offset=4
    local.set $b
    local.get $h
    i32.load offset=8
    local.set $c
    local.get $h
    i32.load offset=12
    local.set $d
    local.get $h
    i32.load offset=16
    local.set $e
    local.get $h
    i32.load offset=20
    local.set $f
    local.get $h
    i32.load offset=24
    local.set $g
    local.get $h
    i32.load offset=28
    local.set $hh
    i32.const 0
    local.set $t
    (block $rounded
      (loop $round
        local.get $t
        i32.const 64
        i32.ge_u
        br_if $rounded
        local.get $hh
        local.get $e
        i32.const 6
        i32.rotr
        local.get $e
        i32.const 11
        i32.rotr
        i32.xor
        local.get $e
        i32.const 25
        i32.rotr
        i32.xor
        i32.add
        local.get $e
        local.get $f
        i32.and
        local.get $e
        i32.const -1
        i32.xor
        local.get $g
        i32.and
        i32.xor
        i32.add
        local.get $k
        local.get $t
        i32.const 2
        i32.shl
        i32.add
        i32.load
        i32.add
        local.get $w
        local.get $t
        i32.const 2
        i32.shl
        i32.add
        i32.load
        i32.add
        local.set $t1
        local.get $a
        i32.const 2
        i32.rotr
        local.get $a
        i32.const 13
        i32.rotr
        i32.xor
        local.get $a
        i32.const 22
        i32.rotr
        i32.xor
        local.get $a
        local.get $b
        i32.and
        local.get $a
        local.get $c
        i32.and
        i32.xor
        local.get $b
        local.get $c
        i32.and
        i32.xor
        i32.add
        local.set $t2
        local.get $g
        local.set $hh
        local.get $f
        local.set $g
        local.get $e
        local.set $f
        local.get $d
        local.get $t1
        i32.add
        local.set $e
        local.get $c
        local.set $d
        local.get $b
        local.set $c
        local.get $a
        local.set $b
        local.get $t1
        local.get $t2
        i32.add
        local.set $a
        local.get $t
        i32.const 1
        i32.add
        local.set $t
        br $round
      )
    )
    local.get $h
    local.get $h
    i32.load
    local.get $a
    i32.add
    i32.store
    local.get $h
    local.get $h
    i32.load offset=4
    local.get $b
    i32.add
    i32.store offset=4
    local.get $h
    local.get $h
    i32.load offset=8
    local.get $c
    i32.add
    i32.store offset=8
    local.get $h
    local.get $h
    i32.load offset=12
    local.get $d
    i32.add
    i32.store offset=12
    local.get $h
    local.get $h
    i32.load offset=16
    local.get $e
    i32.add
    i32.store offset=16
    local.get $h
    local.get $h
    i32.load offset=20
    local.get $f
    i32.add
    i32.store offset=20
    local.get $h
    local.get $h
    i32.load offset=24
    local.get $g
    i32.add
    i32.store offset=24
    local.get $h
    local.get $h
    i32.load offset=28
    local.get $hh
    i32.add
    i32.store offset=28
  )
  (data $__d0 "")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "integer overflow: + on i32 at src/path.bp:114:52")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "integer overflow: - on i32 at src/path.bp:120:42")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "..")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "integer overflow: - on i32 at src/path.bp:135:39")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 ".")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "panic")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "integer overflow: + on i32 at src/io/random.bp:358:15")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "0123456789abcdef")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "integer division by zero: / on i32 at src/io/random.bp:368:40")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "integer overflow: / on i32 at src/io/random.bp:368:40")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 "integer division by zero: % on i32 at src/io/random.bp:368:59")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (data $__d12 "integer overflow: + on i32 at src/io/random.bp:403:19")
  (global $__s12 (mut (ref null $str)) (ref.null $str))
  (data $__d13 "integer division by zero: / on i32 at src/io/random.bp:406:19")
  (global $__s13 (mut (ref null $str)) (ref.null $str))
  (data $__d14 "integer overflow: / on i32 at src/io/random.bp:406:19")
  (global $__s14 (mut (ref null $str)) (ref.null $str))
  (data $__d15 "not found: ")
  (global $__s15 (mut (ref null $str)) (ref.null $str))
  (data $__d16 "permission denied: ")
  (global $__s16 (mut (ref null $str)) (ref.null $str))
  (data $__d17 "is a directory: ")
  (global $__s17 (mut (ref null $str)) (ref.null $str))
  (data $__d18 "not a directory: ")
  (global $__s18 (mut (ref null $str)) (ref.null $str))
  (data $__d19 "already exists: ")
  (global $__s19 (mut (ref null $str)) (ref.null $str))
  (data $__d20 "not UTF-8: ")
  (global $__s20 (mut (ref null $str)) (ref.null $str))
  (data $__d21 " at byte ")
  (global $__s21 (mut (ref null $str)) (ref.null $str))
  (data $__d22 ": ")
  (global $__s22 (mut (ref null $str)) (ref.null $str))
  (data $__d23 "ENOENT")
  (global $__s23 (mut (ref null $str)) (ref.null $str))
  (data $__d24 "EACCES")
  (global $__s24 (mut (ref null $str)) (ref.null $str))
  (data $__d25 "EPERM")
  (global $__s25 (mut (ref null $str)) (ref.null $str))
  (data $__d26 "EISDIR")
  (global $__s26 (mut (ref null $str)) (ref.null $str))
  (data $__d27 "PATH IS A DIRECTORY")
  (global $__s27 (mut (ref null $str)) (ref.null $str))
  (data $__d28 "ENOTDIR")
  (global $__s28 (mut (ref null $str)) (ref.null $str))
  (data $__d29 "EEXIST")
  (global $__s29 (mut (ref null $str)) (ref.null $str))
  (data $__d30 "bytes.toUtf8: not valid UTF-8")
  (global $__s30 (mut (ref null $str)) (ref.null $str))
  (data $__d31 "fs.walk: dangling link \"")
  (global $__s31 (mut (ref null $str)) (ref.null $str))
  (data $__d32 "\"")
  (global $__s32 (mut (ref null $str)) (ref.null $str))
  (data $__d33 "integer overflow: + on i64 at src/io/fs.bp:653:21")
  (global $__s33 (mut (ref null $str)) (ref.null $str))
  (data $__d34 "integer overflow: + on i32 at src/io/fs.bp:655:33")
  (global $__s34 (mut (ref null $str)) (ref.null $str))
  (data $__d35 "the file is open for reading")
  (global $__s35 (mut (ref null $str)) (ref.null $str))
  (data $__d36 "EAGAIN")
  (global $__s36 (mut (ref null $str)) (ref.null $str))
  (data $__d37 "EALREADY")
  (global $__s37 (mut (ref null $str)) (ref.null $str))
  (data $__d38 "EBADF")
  (global $__s38 (mut (ref null $str)) (ref.null $str))
  (data $__d39 "EBUSY")
  (global $__s39 (mut (ref null $str)) (ref.null $str))
  (data $__d40 "EDEADLK")
  (global $__s40 (mut (ref null $str)) (ref.null $str))
  (data $__d41 "EDQUOT")
  (global $__s41 (mut (ref null $str)) (ref.null $str))
  (data $__d42 "EFBIG")
  (global $__s42 (mut (ref null $str)) (ref.null $str))
  (data $__d43 "EILSEQ")
  (global $__s43 (mut (ref null $str)) (ref.null $str))
  (data $__d44 "EINPROGRESS")
  (global $__s44 (mut (ref null $str)) (ref.null $str))
  (data $__d45 "EINTR")
  (global $__s45 (mut (ref null $str)) (ref.null $str))
  (data $__d46 "EINVAL")
  (global $__s46 (mut (ref null $str)) (ref.null $str))
  (data $__d47 "EIO")
  (global $__s47 (mut (ref null $str)) (ref.null $str))
  (data $__d48 "ELOOP")
  (global $__s48 (mut (ref null $str)) (ref.null $str))
  (data $__d49 "EMLINK")
  (global $__s49 (mut (ref null $str)) (ref.null $str))
  (data $__d50 "EMSGSIZE")
  (global $__s50 (mut (ref null $str)) (ref.null $str))
  (data $__d51 "ENAMETOOLONG")
  (global $__s51 (mut (ref null $str)) (ref.null $str))
  (data $__d52 "ENODEV")
  (global $__s52 (mut (ref null $str)) (ref.null $str))
  (data $__d53 "ENOLCK")
  (global $__s53 (mut (ref null $str)) (ref.null $str))
  (data $__d54 "ENOMEM")
  (global $__s54 (mut (ref null $str)) (ref.null $str))
  (data $__d55 "ENOSPC")
  (global $__s55 (mut (ref null $str)) (ref.null $str))
  (data $__d56 "ENOTEMPTY")
  (global $__s56 (mut (ref null $str)) (ref.null $str))
  (data $__d57 "ENOTRECOVERABLE")
  (global $__s57 (mut (ref null $str)) (ref.null $str))
  (data $__d58 "ENOTSUP")
  (global $__s58 (mut (ref null $str)) (ref.null $str))
  (data $__d59 "ENOTTY")
  (global $__s59 (mut (ref null $str)) (ref.null $str))
  (data $__d60 "ENXIO")
  (global $__s60 (mut (ref null $str)) (ref.null $str))
  (data $__d61 "EOVERFLOW")
  (global $__s61 (mut (ref null $str)) (ref.null $str))
  (data $__d62 "EPIPE")
  (global $__s62 (mut (ref null $str)) (ref.null $str))
  (data $__d63 "EROFS")
  (global $__s63 (mut (ref null $str)) (ref.null $str))
  (data $__d64 "ESPIPE")
  (global $__s64 (mut (ref null $str)) (ref.null $str))
  (data $__d65 "ETXTBSY")
  (global $__s65 (mut (ref null $str)) (ref.null $str))
  (data $__d66 "EXDEV")
  (global $__s66 (mut (ref null $str)) (ref.null $str))
  (data $__d67 "permission denied")
  (global $__s67 (mut (ref null $str)) (ref.null $str))
  (data $__d68 "resource temporarily unavailable")
  (global $__s68 (mut (ref null $str)) (ref.null $str))
  (data $__d69 "connection already in progress")
  (global $__s69 (mut (ref null $str)) (ref.null $str))
  (data $__d70 "bad file descriptor")
  (global $__s70 (mut (ref null $str)) (ref.null $str))
  (data $__d71 "resource busy or locked")
  (global $__s71 (mut (ref null $str)) (ref.null $str))
  (data $__d72 "resource deadlock avoided")
  (global $__s72 (mut (ref null $str)) (ref.null $str))
  (data $__d73 "disk quota exceeded")
  (global $__s73 (mut (ref null $str)) (ref.null $str))
  (data $__d74 "file already exists")
  (global $__s74 (mut (ref null $str)) (ref.null $str))
  (data $__d75 "file too large")
  (global $__s75 (mut (ref null $str)) (ref.null $str))
  (data $__d76 "illegal byte sequence")
  (global $__s76 (mut (ref null $str)) (ref.null $str))
  (data $__d77 "operation in progress")
  (global $__s77 (mut (ref null $str)) (ref.null $str))
  (data $__d78 "interrupted system call")
  (global $__s78 (mut (ref null $str)) (ref.null $str))
  (data $__d79 "invalid argument")
  (global $__s79 (mut (ref null $str)) (ref.null $str))
  (data $__d80 "i/o error")
  (global $__s80 (mut (ref null $str)) (ref.null $str))
  (data $__d81 "illegal operation on a directory")
  (global $__s81 (mut (ref null $str)) (ref.null $str))
  (data $__d82 "too many symbolic links encountered")
  (global $__s82 (mut (ref null $str)) (ref.null $str))
  (data $__d83 "too many links")
  (global $__s83 (mut (ref null $str)) (ref.null $str))
  (data $__d84 "message too long")
  (global $__s84 (mut (ref null $str)) (ref.null $str))
  (data $__d85 "name too long")
  (global $__s85 (mut (ref null $str)) (ref.null $str))
  (data $__d86 "no such device")
  (global $__s86 (mut (ref null $str)) (ref.null $str))
  (data $__d87 "no such file or directory")
  (global $__s87 (mut (ref null $str)) (ref.null $str))
  (data $__d88 "no locks available")
  (global $__s88 (mut (ref null $str)) (ref.null $str))
  (data $__d89 "not enough memory")
  (global $__s89 (mut (ref null $str)) (ref.null $str))
  (data $__d90 "no space left on device")
  (global $__s90 (mut (ref null $str)) (ref.null $str))
  (data $__d91 "not a directory")
  (global $__s91 (mut (ref null $str)) (ref.null $str))
  (data $__d92 "directory not empty")
  (global $__s92 (mut (ref null $str)) (ref.null $str))
  (data $__d93 "state not recoverable")
  (global $__s93 (mut (ref null $str)) (ref.null $str))
  (data $__d94 "operation not supported")
  (global $__s94 (mut (ref null $str)) (ref.null $str))
  (data $__d95 "inappropriate ioctl for device")
  (global $__s95 (mut (ref null $str)) (ref.null $str))
  (data $__d96 "no such device or address")
  (global $__s96 (mut (ref null $str)) (ref.null $str))
  (data $__d97 "value too large for defined data type")
  (global $__s97 (mut (ref null $str)) (ref.null $str))
  (data $__d98 "operation not permitted")
  (global $__s98 (mut (ref null $str)) (ref.null $str))
  (data $__d99 "broken pipe")
  (global $__s99 (mut (ref null $str)) (ref.null $str))
  (data $__d100 "read-only file system")
  (global $__s100 (mut (ref null $str)) (ref.null $str))
  (data $__d101 "invalid seek")
  (global $__s101 (mut (ref null $str)) (ref.null $str))
  (data $__d102 "text file busy")
  (global $__s102 (mut (ref null $str)) (ref.null $str))
  (data $__d103 "cross-device link not permitted")
  (global $__s103 (mut (ref null $str)) (ref.null $str))
  (data $__d104 "host")
  (global $__s104 (mut (ref null $str)) (ref.null $str))
  (data $__d105 "/")
  (global $__s105 (mut (ref null $str)) (ref.null $str))
  (data $__d106 "integer overflow: + on i32 at src/io/fs.bp:988:15")
  (global $__s106 (mut (ref null $str)) (ref.null $str))
  (data $__d107 "integer overflow: + on i32 at src/io/fs.bp:999:15")
  (global $__s107 (mut (ref null $str)) (ref.null $str))
  (data $__d108 "integer overflow: + on i32 at src/io/fs.bp:1002:19")
  (global $__s108 (mut (ref null $str)) (ref.null $str))
  (data $__d109 "integer overflow: - on i32 at src/io/fs.bp:1013:32")
  (global $__s109 (mut (ref null $str)) (ref.null $str))
  (data $__d110 "integer overflow: - on i32 at src/io/fs.bp:1013:35")
  (global $__s110 (mut (ref null $str)) (ref.null $str))
  (data $__d111 "integer overflow: - on i32 at src/io/fs.bp:1023:32")
  (global $__s111 (mut (ref null $str)) (ref.null $str))
  (data $__d112 "integer overflow: - on i32 at src/io/fs.bp:1023:35")
  (global $__s112 (mut (ref null $str)) (ref.null $str))
  (data $__d113 "integer overflow: - on i32 at src/io/fs.bp:1026:32")
  (global $__s113 (mut (ref null $str)) (ref.null $str))
  (data $__d114 "integer overflow: - on i32 at src/io/fs.bp:1026:35")
  (global $__s114 (mut (ref null $str)) (ref.null $str))
  (data $__d115 "integer overflow: - on i32 at src/io/fs.bp:1038:32")
  (global $__s115 (mut (ref null $str)) (ref.null $str))
  (data $__d116 "integer overflow: - on i32 at src/io/fs.bp:1038:35")
  (global $__s116 (mut (ref null $str)) (ref.null $str))
  (data $__d117 "integer overflow: - on i32 at src/io/fs.bp:1047:32")
  (global $__s117 (mut (ref null $str)) (ref.null $str))
  (data $__d118 "integer overflow: - on i32 at src/io/fs.bp:1047:35")
  (global $__s118 (mut (ref null $str)) (ref.null $str))
  (data $__d119 "integer overflow: + on i32 at src/io/fs.bp:1058:19")
  (global $__s119 (mut (ref null $str)) (ref.null $str))
  (data $__d120 "integer overflow: + on i32 at src/io/fs.bp:1071:15")
  (global $__s120 (mut (ref null $str)) (ref.null $str))
  (data $__d121 "integer overflow: + on i32 at src/io/fs.bp:1083:36")
  (global $__s121 (mut (ref null $str)) (ref.null $str))
  (data $__d122 "integer overflow: + on i32 at src/io/fs.bp:1087:40")
  (global $__s122 (mut (ref null $str)) (ref.null $str))
  (data $__d123 "integer overflow: + on i32 at src/io/fs.bp:1089:19")
  (global $__s123 (mut (ref null $str)) (ref.null $str))
  (data $__d124 "integer overflow: + on i32 at src/io/fs.bp:1091:15")
  (global $__s124 (mut (ref null $str)) (ref.null $str))
  (data $__d125 "integer overflow: + on i32 at src/io/fs.bp:1091:19")
  (global $__s125 (mut (ref null $str)) (ref.null $str))
  (data $__d126 "integer overflow: - on i64 at src/io/fs.bp:1093:12")
  (global $__s126 (mut (ref null $str)) (ref.null $str))
  (data $__d127 "integer overflow: - on i32 at src/io/fs.bp:1098:37")
  (global $__s127 (mut (ref null $str)) (ref.null $str))
  (data $__d128 "integer overflow: - on i32 at src/io/fs.bp:1099:15")
  (global $__s128 (mut (ref null $str)) (ref.null $str))
  (data $__d129 "integer overflow: - on i32 at src/io/fs.bp:1100:41")
  (global $__s129 (mut (ref null $str)) (ref.null $str))
  (data $__d130 "integer overflow: - on i32 at src/io/fs.bp:1100:59")
  (global $__s130 (mut (ref null $str)) (ref.null $str))
  (data $__d131 "integer overflow: - on i32 at src/io/fs.bp:1108:32")
  (global $__s131 (mut (ref null $str)) (ref.null $str))
  (data $__d132 "integer overflow: - on i32 at src/io/fs.bp:1108:35")
  (global $__s132 (mut (ref null $str)) (ref.null $str))
  (data $__d133 "integer overflow: - on i32 at src/io/fs.bp:1116:32")
  (global $__s133 (mut (ref null $str)) (ref.null $str))
  (data $__d134 "integer overflow: - on i32 at src/io/fs.bp:1116:35")
  (global $__s134 (mut (ref null $str)) (ref.null $str))
  (data $__d135 "integer overflow: - on i32 at src/io/fs.bp:1159:32")
  (global $__s135 (mut (ref null $str)) (ref.null $str))
  (data $__d136 "integer overflow: - on i32 at src/io/fs.bp:1159:35")
  (global $__s136 (mut (ref null $str)) (ref.null $str))
  (data $__d137 "integer overflow: - on i32 at src/io/fs.bp:1188:32")
  (global $__s137 (mut (ref null $str)) (ref.null $str))
  (data $__d138 "integer overflow: - on i32 at src/io/fs.bp:1188:35")
  (global $__s138 (mut (ref null $str)) (ref.null $str))
  (data $__d139 "integer overflow: + on i32 at src/io/fs.bp:1201:15")
  (global $__s139 (mut (ref null $str)) (ref.null $str))
  (data $__d140 "integer overflow: + on i32 at src/io/fs.bp:1208:15")
  (global $__s140 (mut (ref null $str)) (ref.null $str))
  (data $__d141 "integer overflow: - on i32 at src/io/fs.bp:1216:39")
  (global $__s141 (mut (ref null $str)) (ref.null $str))
  (data $__d142 "integer overflow: - on i32 at src/io/fs.bp:1216:42")
  (global $__s142 (mut (ref null $str)) (ref.null $str))
  (data $__d143 "integer overflow: - on i32 at src/io/fs.bp:1225:35")
  (global $__s143 (mut (ref null $str)) (ref.null $str))
  (data $__d144 "integer overflow: - on i32 at src/io/fs.bp:1225:38")
  (global $__s144 (mut (ref null $str)) (ref.null $str))
  (data $__d145 "integer overflow: - on i32 at src/io/fs.bp:1228:32")
  (global $__s145 (mut (ref null $str)) (ref.null $str))
  (data $__d146 "integer overflow: - on i32 at src/io/fs.bp:1228:35")
  (global $__s146 (mut (ref null $str)) (ref.null $str))
  (data $__d147 "integer overflow: - on i32 at src/io/fs.bp:1241:35")
  (global $__s147 (mut (ref null $str)) (ref.null $str))
  (data $__d148 "integer overflow: - on i32 at src/io/fs.bp:1241:38")
  (global $__s148 (mut (ref null $str)) (ref.null $str))
  (data $__d149 "integer overflow: * on i64 at src/io/fs.bp:1244:48")
  (global $__s149 (mut (ref null $str)) (ref.null $str))
  (data $__d150 "integer overflow: - on i32 at src/io/fs.bp:1252:35")
  (global $__s150 (mut (ref null $str)) (ref.null $str))
  (data $__d151 "integer overflow: - on i32 at src/io/fs.bp:1252:38")
  (global $__s151 (mut (ref null $str)) (ref.null $str))
  (data $__d152 "integer overflow: + on i32 at src/io/fs.bp:1262:21")
  (global $__s152 (mut (ref null $str)) (ref.null $str))
  (data $__d153 "integer overflow: + on i32 at src/io/fs.bp:1267:19")
  (global $__s153 (mut (ref null $str)) (ref.null $str))
  (data $__d154 "integer overflow: - on i32 at src/io/fs.bp:1271:39")
  (global $__s154 (mut (ref null $str)) (ref.null $str))
  (data $__d155 "integer overflow: - on i32 at src/io/fs.bp:1271:60")
  (global $__s155 (mut (ref null $str)) (ref.null $str))
  (data $__d156 "integer overflow: - on i32 at src/io/fs.bp:1271:63")
  (global $__s156 (mut (ref null $str)) (ref.null $str))
  (data $__d157 "integer overflow: - on i32 at src/io/fs.bp:1277:26")
  (global $__s157 (mut (ref null $str)) (ref.null $str))
  (data $__d158 "*")
  (global $__s158 (mut (ref null $str)) (ref.null $str))
  (data $__d159 "?")
  (global $__s159 (mut (ref null $str)) (ref.null $str))
  (data $__d160 "[")
  (global $__s160 (mut (ref null $str)) (ref.null $str))
  (data $__d161 "{")
  (global $__s161 (mut (ref null $str)) (ref.null $str))
  (data $__d162 "integer overflow: - on i32 at src/io/fs.bp:1291:16")
  (global $__s162 (mut (ref null $str)) (ref.null $str))
  (data $__d163 "integer overflow: + on i32 at src/io/fs.bp:1298:15")
  (global $__s163 (mut (ref null $str)) (ref.null $str))
  (data $__d164 "integer overflow: - on i32 at src/io/fs.bp:1302:17")
  (global $__s164 (mut (ref null $str)) (ref.null $str))
  (data $__d165 "integer overflow: + on i32 at src/io/fs.bp:1310:37")
  (global $__s165 (mut (ref null $str)) (ref.null $str))
  (data $__d166 "}")
  (global $__s166 (mut (ref null $str)) (ref.null $str))
  (data $__d167 "integer overflow: - on i32 at src/io/fs.bp:1311:37")
  (global $__s167 (mut (ref null $str)) (ref.null $str))
  (data $__d168 ",")
  (global $__s168 (mut (ref null $str)) (ref.null $str))
  (data $__d169 "integer overflow: + on i32 at src/io/fs.bp:1317:15")
  (global $__s169 (mut (ref null $str)) (ref.null $str))
  (data $__d170 "integer overflow: + on i32 at src/io/fs.bp:1321:31")
  (global $__s170 (mut (ref null $str)) (ref.null $str))
  (data $__d171 "integer overflow: + on i32 at src/io/fs.bp:1323:22")
  (global $__s171 (mut (ref null $str)) (ref.null $str))
  (data $__d172 "integer overflow: + on i32 at src/io/fs.bp:1330:22")
  (global $__s172 (mut (ref null $str)) (ref.null $str))
  (data $__d173 "integer overflow: + on i32 at src/io/fs.bp:1331:15")
  (global $__s173 (mut (ref null $str)) (ref.null $str))
  (data $__d174 "integer overflow: + on i32 at src/io/fs.bp:1338:16")
  (global $__s174 (mut (ref null $str)) (ref.null $str))
  (data $__d175 "!")
  (global $__s175 (mut (ref null $str)) (ref.null $str))
  (data $__d176 "^")
  (global $__s176 (mut (ref null $str)) (ref.null $str))
  (data $__d177 "integer overflow: + on i32 at src/io/fs.bp:1339:89")
  (global $__s177 (mut (ref null $str)) (ref.null $str))
  (data $__d178 "]")
  (global $__s178 (mut (ref null $str)) (ref.null $str))
  (data $__d179 "integer overflow: + on i32 at src/io/fs.bp:1340:59")
  (global $__s179 (mut (ref null $str)) (ref.null $str))
  (data $__d180 "integer overflow: + on i32 at src/io/fs.bp:1343:15")
  (global $__s180 (mut (ref null $str)) (ref.null $str))
  (data $__d181 "integer overflow: - on i32 at src/io/fs.bp:1345:12")
  (global $__s181 (mut (ref null $str)) (ref.null $str))
  (data $__d182 "integer overflow: + on i32 at src/io/fs.bp:1354:15")
  (global $__s182 (mut (ref null $str)) (ref.null $str))
  (data $__d183 "integer overflow: + on i32 at src/io/fs.bp:1359:15")
  (global $__s183 (mut (ref null $str)) (ref.null $str))
  (data $__d184 "integer overflow: + on i32 at src/io/fs.bp:1359:39")
  (global $__s184 (mut (ref null $str)) (ref.null $str))
  (data $__d185 "-")
  (global $__s185 (mut (ref null $str)) (ref.null $str))
  (data $__d186 "integer overflow: + on i32 at src/io/fs.bp:1360:31")
  (global $__s186 (mut (ref null $str)) (ref.null $str))
  (data $__d187 "integer overflow: + on i32 at src/io/fs.bp:1365:19")
  (global $__s187 (mut (ref null $str)) (ref.null $str))
  (data $__d188 "integer overflow: + on i32 at src/io/fs.bp:1368:19")
  (global $__s188 (mut (ref null $str)) (ref.null $str))
  (data $__d189 "integer overflow: + on i32 at src/io/fs.bp:1382:23")
  (global $__s189 (mut (ref null $str)) (ref.null $str))
  (data $__d190 "integer overflow: + on i32 at src/io/fs.bp:1388:23")
  (global $__s190 (mut (ref null $str)) (ref.null $str))
  (data $__d191 "integer overflow: + on i32 at src/io/fs.bp:1395:19")
  (global $__s191 (mut (ref null $str)) (ref.null $str))
  (data $__d192 "integer overflow: + on i32 at src/io/fs.bp:1396:19")
  (global $__s192 (mut (ref null $str)) (ref.null $str))
  (data $__d193 "integer overflow: + on i32 at src/io/fs.bp:1401:23")
  (global $__s193 (mut (ref null $str)) (ref.null $str))
  (data $__d194 "integer overflow: + on i32 at src/io/fs.bp:1402:23")
  (global $__s194 (mut (ref null $str)) (ref.null $str))
  (data $__d195 "integer overflow: + on i32 at src/io/fs.bp:1404:38")
  (global $__s195 (mut (ref null $str)) (ref.null $str))
  (data $__d196 "integer overflow: + on i32 at src/io/fs.bp:1405:25")
  (global $__s196 (mut (ref null $str)) (ref.null $str))
  (data $__d197 "integer overflow: + on i32 at src/io/fs.bp:1406:23")
  (global $__s197 (mut (ref null $str)) (ref.null $str))
  (data $__d198 "integer overflow: + on i32 at src/io/fs.bp:1410:19")
  (global $__s198 (mut (ref null $str)) (ref.null $str))
  (data $__d199 "integer overflow: + on i32 at src/io/fs.bp:1411:19")
  (global $__s199 (mut (ref null $str)) (ref.null $str))
  (data $__d200 "integer overflow: + on i32 at src/io/fs.bp:1423:15")
  (global $__s200 (mut (ref null $str)) (ref.null $str))
  (data $__d201 "integer overflow: + on i32 at src/io/fs.bp:1438:15")
  (global $__s201 (mut (ref null $str)) (ref.null $str))
  (data $__d202 "integer overflow: - on i32 at src/io/fs.bp:1454:33")
  (global $__s202 (mut (ref null $str)) (ref.null $str))
  (data $__d203 "**")
  (global $__s203 (mut (ref null $str)) (ref.null $str))
  (data $__d204 "integer overflow: + on i32 at src/io/fs.bp:1456:43")
  (global $__s204 (mut (ref null $str)) (ref.null $str))
  (data $__d205 "integer overflow: + on i32 at src/io/fs.bp:1461:19")
  (global $__s205 (mut (ref null $str)) (ref.null $str))
  (data $__d206 "integer overflow: + on i32 at src/io/fs.bp:1475:36")
  (global $__s206 (mut (ref null $str)) (ref.null $str))
  (data $__d207 "integer overflow: + on i32 at src/io/fs.bp:1483:15")
  (global $__s207 (mut (ref null $str)) (ref.null $str))
  (data $__d208 "integer overflow: + on i32 at src/io/fs.bp:1489:36")
  (global $__s208 (mut (ref null $str)) (ref.null $str))
  (data $__d209 "integer overflow: + on i32 at src/io/fs.bp:1504:15")
  (global $__s209 (mut (ref null $str)) (ref.null $str))
  (data $__d210 "integer overflow: + on i32 at src/io/fs.bp:1512:15")
  (global $__s210 (mut (ref null $str)) (ref.null $str))
  (data $__d211 "integer overflow: - on i32 at src/io/fs.bp:1523:16")
  (global $__s211 (mut (ref null $str)) (ref.null $str))
  (data $__d212 "integer overflow: - on i32 at src/io/fs.bp:1524:34")
  (global $__s212 (mut (ref null $str)) (ref.null $str))
  (data $__d213 "integer overflow: - on i32 at src/io/fs.bp:1524:37")
  (global $__s213 (mut (ref null $str)) (ref.null $str))
  (data $__d214 "integer overflow: - on i32 at src/io/fs.bp:1527:36")
  (global $__s214 (mut (ref null $str)) (ref.null $str))
  (data $__d215 "integer overflow: - on i32 at src/io/fs.bp:1527:39")
  (global $__s215 (mut (ref null $str)) (ref.null $str))
  (data $__d216 "integer overflow: + on i32 at src/io/fs.bp:1534:21")
  (global $__s216 (mut (ref null $str)) (ref.null $str))
  (data $__d217 "integer overflow: + on i32 at src/io/fs.bp:1539:19")
  (global $__s217 (mut (ref null $str)) (ref.null $str))
  (data $__d218 "integer overflow: - on i32 at src/io/fs.bp:1541:37")
  (global $__s218 (mut (ref null $str)) (ref.null $str))
  (data $__d219 "integer overflow: - on i32 at src/io/fs.bp:1541:58")
  (global $__s219 (mut (ref null $str)) (ref.null $str))
  (data $__d220 "integer overflow: - on i32 at src/io/fs.bp:1541:61")
  (global $__s220 (mut (ref null $str)) (ref.null $str))
  (data $__d221 "integer overflow: - on i32 at src/io/fs.bp:1545:44")
  (global $__s221 (mut (ref null $str)) (ref.null $str))
  (data $__d222 "integer overflow: - on i32 at src/io/fs.bp:1545:47")
  (global $__s222 (mut (ref null $str)) (ref.null $str))
  (data $__d223 "integer overflow: - on i32 at src/io/fs.bp:1551:15")
  (global $__s223 (mut (ref null $str)) (ref.null $str))
  (data $__d224 "integer overflow: - on i32 at src/io/fs.bp:1553:36")
  (global $__s224 (mut (ref null $str)) (ref.null $str))
  (data $__d225 "integer overflow: - on i32 at src/io/fs.bp:1553:39")
  (global $__s225 (mut (ref null $str)) (ref.null $str))
  (data $__d226 "TMPDIR")
  (global $__s226 (mut (ref null $str)) (ref.null $str))
  (data $__d227 "/tmp")
  (global $__s227 (mut (ref null $str)) (ref.null $str))
  (data $__d228 "/bp-std-fs-")
  (global $__s228 (mut (ref null $str)) (ref.null $str))
  (data $__d229 "integer overflow: + on i32 at src/io/fs.bp:1566:27")
  (global $__s229 (mut (ref null $str)) (ref.null $str))
  (data $__d230 "io.fs: no scratch directory could be made")
  (global $__s230 (mut (ref null $str)) (ref.null $str))
  (data $__d231 "io.fs: no link path")
  (global $__s231 (mut (ref null $str)) (ref.null $str))
  (data $__d232 "integer overflow: - on i32 at src/io/fs.bp:1582:40")
  (global $__s232 (mut (ref null $str)) (ref.null $str))
  (data $__d233 "integer overflow: - on i32 at src/io/fs.bp:1582:43")
  (global $__s233 (mut (ref null $str)) (ref.null $str))
  (data $__d234 "integer overflow: - on i64 at src/io/fs.bp:1656:36")
  (global $__s234 (mut (ref null $str)) (ref.null $str))
  (data $__d235 "integer overflow: - on i64 at src/io/fs.bp:1656:48")
  (global $__s235 (mut (ref null $str)) (ref.null $str))
  (data $__d236 "/app")
  (global $__s236 (mut (ref null $str)) (ref.null $str))
  (data $__d237 "/app/blog")
  (global $__s237 (mut (ref null $str)) (ref.null $str))
  (data $__d238 "/app/page.bp")
  (global $__s238 (mut (ref null $str)) (ref.null $str))
  (data $__d239 "root page")
  (global $__s239 (mut (ref null $str)) (ref.null $str))
  (data $__d240 "/app/blog/page.bp")
  (global $__s240 (mut (ref null $str)) (ref.null $str))
  (data $__d241 "blog page")
  (global $__s241 (mut (ref null $str)) (ref.null $str))
  (data $__d242 "/app/blog/notes.md")
  (global $__s242 (mut (ref null $str)) (ref.null $str))
  (data $__d243 "notes")
  (global $__s243 (mut (ref null $str)) (ref.null $str))
  (data $__d244 "<error>")
  (global $__s244 (mut (ref null $str)) (ref.null $str))
  (data $__d245 "NotFound ")
  (global $__s245 (mut (ref null $str)) (ref.null $str))
  (data $__d246 "PermissionDenied ")
  (global $__s246 (mut (ref null $str)) (ref.null $str))
  (data $__d247 "IsDirectory ")
  (global $__s247 (mut (ref null $str)) (ref.null $str))
  (data $__d248 "NotDirectory ")
  (global $__s248 (mut (ref null $str)) (ref.null $str))
  (data $__d249 "AlreadyExists ")
  (global $__s249 (mut (ref null $str)) (ref.null $str))
  (data $__d250 "InvalidUtf8 ")
  (global $__s250 (mut (ref null $str)) (ref.null $str))
  (data $__d251 " ")
  (global $__s251 (mut (ref null $str)) (ref.null $str))
  (data $__d252 "/app/.cache")
  (global $__s252 (mut (ref null $str)) (ref.null $str))
  (data $__d253 "/app/.cache/page.bp")
  (global $__s253 (mut (ref null $str)) (ref.null $str))
  (data $__d254 "cached")
  (global $__s254 (mut (ref null $str)) (ref.null $str))
  (data $__d255 "/app/.hidden.bp")
  (global $__s255 (mut (ref null $str)) (ref.null $str))
  (data $__d256 "hidden")
  (global $__s256 (mut (ref null $str)) (ref.null $str))
  (data $__d257 "/app/blog/.draft.md")
  (global $__s257 (mut (ref null $str)) (ref.null $str))
  (data $__d258 "draft")
  (global $__s258 (mut (ref null $str)) (ref.null $str))
  (data $__d259 "blog")
  (global $__s259 (mut (ref null $str)) (ref.null $str))
  (data $__d260 "/app/linked")
  (global $__s260 (mut (ref null $str)) (ref.null $str))
  (data $__d261 "page.bp")
  (global $__s261 (mut (ref null $str)) (ref.null $str))
  (data $__d262 "/app/alias.bp")
  (global $__s262 (mut (ref null $str)) (ref.null $str))
  (data $__d263 "missing.bp")
  (global $__s263 (mut (ref null $str)) (ref.null $str))
  (data $__d264 "/app/gone.bp")
  (global $__s264 (mut (ref null $str)) (ref.null $str))
  (data $__d265 "ok")
  (global $__s265 (mut (ref null $str)) (ref.null $str))
  (data $__d266 ":")
  (global $__s266 (mut (ref null $str)) (ref.null $str))
  (func $__init_strs
    i32.const 0
    i32.const 0
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 48
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 48
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 2
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 48
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 1
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 5
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 53
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 16
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 61
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 53
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 61
    array.new_data $str $__d11
    global.set $__s11
    i32.const 0
    i32.const 53
    array.new_data $str $__d12
    global.set $__s12
    i32.const 0
    i32.const 61
    array.new_data $str $__d13
    global.set $__s13
    i32.const 0
    i32.const 53
    array.new_data $str $__d14
    global.set $__s14
    i32.const 0
    i32.const 11
    array.new_data $str $__d15
    global.set $__s15
    i32.const 0
    i32.const 19
    array.new_data $str $__d16
    global.set $__s16
    i32.const 0
    i32.const 16
    array.new_data $str $__d17
    global.set $__s17
    i32.const 0
    i32.const 17
    array.new_data $str $__d18
    global.set $__s18
    i32.const 0
    i32.const 16
    array.new_data $str $__d19
    global.set $__s19
    i32.const 0
    i32.const 11
    array.new_data $str $__d20
    global.set $__s20
    i32.const 0
    i32.const 9
    array.new_data $str $__d21
    global.set $__s21
    i32.const 0
    i32.const 2
    array.new_data $str $__d22
    global.set $__s22
    i32.const 0
    i32.const 6
    array.new_data $str $__d23
    global.set $__s23
    i32.const 0
    i32.const 6
    array.new_data $str $__d24
    global.set $__s24
    i32.const 0
    i32.const 5
    array.new_data $str $__d25
    global.set $__s25
    i32.const 0
    i32.const 6
    array.new_data $str $__d26
    global.set $__s26
    i32.const 0
    i32.const 19
    array.new_data $str $__d27
    global.set $__s27
    i32.const 0
    i32.const 7
    array.new_data $str $__d28
    global.set $__s28
    i32.const 0
    i32.const 6
    array.new_data $str $__d29
    global.set $__s29
    i32.const 0
    i32.const 29
    array.new_data $str $__d30
    global.set $__s30
    i32.const 0
    i32.const 24
    array.new_data $str $__d31
    global.set $__s31
    i32.const 0
    i32.const 1
    array.new_data $str $__d32
    global.set $__s32
    i32.const 0
    i32.const 49
    array.new_data $str $__d33
    global.set $__s33
    i32.const 0
    i32.const 49
    array.new_data $str $__d34
    global.set $__s34
    i32.const 0
    i32.const 28
    array.new_data $str $__d35
    global.set $__s35
    i32.const 0
    i32.const 6
    array.new_data $str $__d36
    global.set $__s36
    i32.const 0
    i32.const 8
    array.new_data $str $__d37
    global.set $__s37
    i32.const 0
    i32.const 5
    array.new_data $str $__d38
    global.set $__s38
    i32.const 0
    i32.const 5
    array.new_data $str $__d39
    global.set $__s39
    i32.const 0
    i32.const 7
    array.new_data $str $__d40
    global.set $__s40
    i32.const 0
    i32.const 6
    array.new_data $str $__d41
    global.set $__s41
    i32.const 0
    i32.const 5
    array.new_data $str $__d42
    global.set $__s42
    i32.const 0
    i32.const 6
    array.new_data $str $__d43
    global.set $__s43
    i32.const 0
    i32.const 11
    array.new_data $str $__d44
    global.set $__s44
    i32.const 0
    i32.const 5
    array.new_data $str $__d45
    global.set $__s45
    i32.const 0
    i32.const 6
    array.new_data $str $__d46
    global.set $__s46
    i32.const 0
    i32.const 3
    array.new_data $str $__d47
    global.set $__s47
    i32.const 0
    i32.const 5
    array.new_data $str $__d48
    global.set $__s48
    i32.const 0
    i32.const 6
    array.new_data $str $__d49
    global.set $__s49
    i32.const 0
    i32.const 8
    array.new_data $str $__d50
    global.set $__s50
    i32.const 0
    i32.const 12
    array.new_data $str $__d51
    global.set $__s51
    i32.const 0
    i32.const 6
    array.new_data $str $__d52
    global.set $__s52
    i32.const 0
    i32.const 6
    array.new_data $str $__d53
    global.set $__s53
    i32.const 0
    i32.const 6
    array.new_data $str $__d54
    global.set $__s54
    i32.const 0
    i32.const 6
    array.new_data $str $__d55
    global.set $__s55
    i32.const 0
    i32.const 9
    array.new_data $str $__d56
    global.set $__s56
    i32.const 0
    i32.const 15
    array.new_data $str $__d57
    global.set $__s57
    i32.const 0
    i32.const 7
    array.new_data $str $__d58
    global.set $__s58
    i32.const 0
    i32.const 6
    array.new_data $str $__d59
    global.set $__s59
    i32.const 0
    i32.const 5
    array.new_data $str $__d60
    global.set $__s60
    i32.const 0
    i32.const 9
    array.new_data $str $__d61
    global.set $__s61
    i32.const 0
    i32.const 5
    array.new_data $str $__d62
    global.set $__s62
    i32.const 0
    i32.const 5
    array.new_data $str $__d63
    global.set $__s63
    i32.const 0
    i32.const 6
    array.new_data $str $__d64
    global.set $__s64
    i32.const 0
    i32.const 7
    array.new_data $str $__d65
    global.set $__s65
    i32.const 0
    i32.const 5
    array.new_data $str $__d66
    global.set $__s66
    i32.const 0
    i32.const 17
    array.new_data $str $__d67
    global.set $__s67
    i32.const 0
    i32.const 32
    array.new_data $str $__d68
    global.set $__s68
    i32.const 0
    i32.const 30
    array.new_data $str $__d69
    global.set $__s69
    i32.const 0
    i32.const 19
    array.new_data $str $__d70
    global.set $__s70
    i32.const 0
    i32.const 23
    array.new_data $str $__d71
    global.set $__s71
    i32.const 0
    i32.const 25
    array.new_data $str $__d72
    global.set $__s72
    i32.const 0
    i32.const 19
    array.new_data $str $__d73
    global.set $__s73
    i32.const 0
    i32.const 19
    array.new_data $str $__d74
    global.set $__s74
    i32.const 0
    i32.const 14
    array.new_data $str $__d75
    global.set $__s75
    i32.const 0
    i32.const 21
    array.new_data $str $__d76
    global.set $__s76
    i32.const 0
    i32.const 21
    array.new_data $str $__d77
    global.set $__s77
    i32.const 0
    i32.const 23
    array.new_data $str $__d78
    global.set $__s78
    i32.const 0
    i32.const 16
    array.new_data $str $__d79
    global.set $__s79
    i32.const 0
    i32.const 9
    array.new_data $str $__d80
    global.set $__s80
    i32.const 0
    i32.const 32
    array.new_data $str $__d81
    global.set $__s81
    i32.const 0
    i32.const 35
    array.new_data $str $__d82
    global.set $__s82
    i32.const 0
    i32.const 14
    array.new_data $str $__d83
    global.set $__s83
    i32.const 0
    i32.const 16
    array.new_data $str $__d84
    global.set $__s84
    i32.const 0
    i32.const 13
    array.new_data $str $__d85
    global.set $__s85
    i32.const 0
    i32.const 14
    array.new_data $str $__d86
    global.set $__s86
    i32.const 0
    i32.const 25
    array.new_data $str $__d87
    global.set $__s87
    i32.const 0
    i32.const 18
    array.new_data $str $__d88
    global.set $__s88
    i32.const 0
    i32.const 17
    array.new_data $str $__d89
    global.set $__s89
    i32.const 0
    i32.const 23
    array.new_data $str $__d90
    global.set $__s90
    i32.const 0
    i32.const 15
    array.new_data $str $__d91
    global.set $__s91
    i32.const 0
    i32.const 19
    array.new_data $str $__d92
    global.set $__s92
    i32.const 0
    i32.const 21
    array.new_data $str $__d93
    global.set $__s93
    i32.const 0
    i32.const 23
    array.new_data $str $__d94
    global.set $__s94
    i32.const 0
    i32.const 30
    array.new_data $str $__d95
    global.set $__s95
    i32.const 0
    i32.const 25
    array.new_data $str $__d96
    global.set $__s96
    i32.const 0
    i32.const 37
    array.new_data $str $__d97
    global.set $__s97
    i32.const 0
    i32.const 23
    array.new_data $str $__d98
    global.set $__s98
    i32.const 0
    i32.const 11
    array.new_data $str $__d99
    global.set $__s99
    i32.const 0
    i32.const 21
    array.new_data $str $__d100
    global.set $__s100
    i32.const 0
    i32.const 12
    array.new_data $str $__d101
    global.set $__s101
    i32.const 0
    i32.const 14
    array.new_data $str $__d102
    global.set $__s102
    i32.const 0
    i32.const 31
    array.new_data $str $__d103
    global.set $__s103
    i32.const 0
    i32.const 4
    array.new_data $str $__d104
    global.set $__s104
    i32.const 0
    i32.const 1
    array.new_data $str $__d105
    global.set $__s105
    i32.const 0
    i32.const 49
    array.new_data $str $__d106
    global.set $__s106
    i32.const 0
    i32.const 49
    array.new_data $str $__d107
    global.set $__s107
    i32.const 0
    i32.const 50
    array.new_data $str $__d108
    global.set $__s108
    i32.const 0
    i32.const 50
    array.new_data $str $__d109
    global.set $__s109
    i32.const 0
    i32.const 50
    array.new_data $str $__d110
    global.set $__s110
    i32.const 0
    i32.const 50
    array.new_data $str $__d111
    global.set $__s111
    i32.const 0
    i32.const 50
    array.new_data $str $__d112
    global.set $__s112
    i32.const 0
    i32.const 50
    array.new_data $str $__d113
    global.set $__s113
    i32.const 0
    i32.const 50
    array.new_data $str $__d114
    global.set $__s114
    i32.const 0
    i32.const 50
    array.new_data $str $__d115
    global.set $__s115
    i32.const 0
    i32.const 50
    array.new_data $str $__d116
    global.set $__s116
    i32.const 0
    i32.const 50
    array.new_data $str $__d117
    global.set $__s117
    i32.const 0
    i32.const 50
    array.new_data $str $__d118
    global.set $__s118
    i32.const 0
    i32.const 50
    array.new_data $str $__d119
    global.set $__s119
    i32.const 0
    i32.const 50
    array.new_data $str $__d120
    global.set $__s120
    i32.const 0
    i32.const 50
    array.new_data $str $__d121
    global.set $__s121
    i32.const 0
    i32.const 50
    array.new_data $str $__d122
    global.set $__s122
    i32.const 0
    i32.const 50
    array.new_data $str $__d123
    global.set $__s123
    i32.const 0
    i32.const 50
    array.new_data $str $__d124
    global.set $__s124
    i32.const 0
    i32.const 50
    array.new_data $str $__d125
    global.set $__s125
    i32.const 0
    i32.const 50
    array.new_data $str $__d126
    global.set $__s126
    i32.const 0
    i32.const 50
    array.new_data $str $__d127
    global.set $__s127
    i32.const 0
    i32.const 50
    array.new_data $str $__d128
    global.set $__s128
    i32.const 0
    i32.const 50
    array.new_data $str $__d129
    global.set $__s129
    i32.const 0
    i32.const 50
    array.new_data $str $__d130
    global.set $__s130
    i32.const 0
    i32.const 50
    array.new_data $str $__d131
    global.set $__s131
    i32.const 0
    i32.const 50
    array.new_data $str $__d132
    global.set $__s132
    i32.const 0
    i32.const 50
    array.new_data $str $__d133
    global.set $__s133
    i32.const 0
    i32.const 50
    array.new_data $str $__d134
    global.set $__s134
    i32.const 0
    i32.const 50
    array.new_data $str $__d135
    global.set $__s135
    i32.const 0
    i32.const 50
    array.new_data $str $__d136
    global.set $__s136
    i32.const 0
    i32.const 50
    array.new_data $str $__d137
    global.set $__s137
    i32.const 0
    i32.const 50
    array.new_data $str $__d138
    global.set $__s138
    i32.const 0
    i32.const 50
    array.new_data $str $__d139
    global.set $__s139
    i32.const 0
    i32.const 50
    array.new_data $str $__d140
    global.set $__s140
    i32.const 0
    i32.const 50
    array.new_data $str $__d141
    global.set $__s141
    i32.const 0
    i32.const 50
    array.new_data $str $__d142
    global.set $__s142
    i32.const 0
    i32.const 50
    array.new_data $str $__d143
    global.set $__s143
    i32.const 0
    i32.const 50
    array.new_data $str $__d144
    global.set $__s144
    i32.const 0
    i32.const 50
    array.new_data $str $__d145
    global.set $__s145
    i32.const 0
    i32.const 50
    array.new_data $str $__d146
    global.set $__s146
    i32.const 0
    i32.const 50
    array.new_data $str $__d147
    global.set $__s147
    i32.const 0
    i32.const 50
    array.new_data $str $__d148
    global.set $__s148
    i32.const 0
    i32.const 50
    array.new_data $str $__d149
    global.set $__s149
    i32.const 0
    i32.const 50
    array.new_data $str $__d150
    global.set $__s150
    i32.const 0
    i32.const 50
    array.new_data $str $__d151
    global.set $__s151
    i32.const 0
    i32.const 50
    array.new_data $str $__d152
    global.set $__s152
    i32.const 0
    i32.const 50
    array.new_data $str $__d153
    global.set $__s153
    i32.const 0
    i32.const 50
    array.new_data $str $__d154
    global.set $__s154
    i32.const 0
    i32.const 50
    array.new_data $str $__d155
    global.set $__s155
    i32.const 0
    i32.const 50
    array.new_data $str $__d156
    global.set $__s156
    i32.const 0
    i32.const 50
    array.new_data $str $__d157
    global.set $__s157
    i32.const 0
    i32.const 1
    array.new_data $str $__d158
    global.set $__s158
    i32.const 0
    i32.const 1
    array.new_data $str $__d159
    global.set $__s159
    i32.const 0
    i32.const 1
    array.new_data $str $__d160
    global.set $__s160
    i32.const 0
    i32.const 1
    array.new_data $str $__d161
    global.set $__s161
    i32.const 0
    i32.const 50
    array.new_data $str $__d162
    global.set $__s162
    i32.const 0
    i32.const 50
    array.new_data $str $__d163
    global.set $__s163
    i32.const 0
    i32.const 50
    array.new_data $str $__d164
    global.set $__s164
    i32.const 0
    i32.const 50
    array.new_data $str $__d165
    global.set $__s165
    i32.const 0
    i32.const 1
    array.new_data $str $__d166
    global.set $__s166
    i32.const 0
    i32.const 50
    array.new_data $str $__d167
    global.set $__s167
    i32.const 0
    i32.const 1
    array.new_data $str $__d168
    global.set $__s168
    i32.const 0
    i32.const 50
    array.new_data $str $__d169
    global.set $__s169
    i32.const 0
    i32.const 50
    array.new_data $str $__d170
    global.set $__s170
    i32.const 0
    i32.const 50
    array.new_data $str $__d171
    global.set $__s171
    i32.const 0
    i32.const 50
    array.new_data $str $__d172
    global.set $__s172
    i32.const 0
    i32.const 50
    array.new_data $str $__d173
    global.set $__s173
    i32.const 0
    i32.const 50
    array.new_data $str $__d174
    global.set $__s174
    i32.const 0
    i32.const 1
    array.new_data $str $__d175
    global.set $__s175
    i32.const 0
    i32.const 1
    array.new_data $str $__d176
    global.set $__s176
    i32.const 0
    i32.const 50
    array.new_data $str $__d177
    global.set $__s177
    i32.const 0
    i32.const 1
    array.new_data $str $__d178
    global.set $__s178
    i32.const 0
    i32.const 50
    array.new_data $str $__d179
    global.set $__s179
    i32.const 0
    i32.const 50
    array.new_data $str $__d180
    global.set $__s180
    i32.const 0
    i32.const 50
    array.new_data $str $__d181
    global.set $__s181
    i32.const 0
    i32.const 50
    array.new_data $str $__d182
    global.set $__s182
    i32.const 0
    i32.const 50
    array.new_data $str $__d183
    global.set $__s183
    i32.const 0
    i32.const 50
    array.new_data $str $__d184
    global.set $__s184
    i32.const 0
    i32.const 1
    array.new_data $str $__d185
    global.set $__s185
    i32.const 0
    i32.const 50
    array.new_data $str $__d186
    global.set $__s186
    i32.const 0
    i32.const 50
    array.new_data $str $__d187
    global.set $__s187
    i32.const 0
    i32.const 50
    array.new_data $str $__d188
    global.set $__s188
    i32.const 0
    i32.const 50
    array.new_data $str $__d189
    global.set $__s189
    i32.const 0
    i32.const 50
    array.new_data $str $__d190
    global.set $__s190
    i32.const 0
    i32.const 50
    array.new_data $str $__d191
    global.set $__s191
    i32.const 0
    i32.const 50
    array.new_data $str $__d192
    global.set $__s192
    i32.const 0
    i32.const 50
    array.new_data $str $__d193
    global.set $__s193
    i32.const 0
    i32.const 50
    array.new_data $str $__d194
    global.set $__s194
    i32.const 0
    i32.const 50
    array.new_data $str $__d195
    global.set $__s195
    i32.const 0
    i32.const 50
    array.new_data $str $__d196
    global.set $__s196
    i32.const 0
    i32.const 50
    array.new_data $str $__d197
    global.set $__s197
    i32.const 0
    i32.const 50
    array.new_data $str $__d198
    global.set $__s198
    i32.const 0
    i32.const 50
    array.new_data $str $__d199
    global.set $__s199
    i32.const 0
    i32.const 50
    array.new_data $str $__d200
    global.set $__s200
    i32.const 0
    i32.const 50
    array.new_data $str $__d201
    global.set $__s201
    i32.const 0
    i32.const 50
    array.new_data $str $__d202
    global.set $__s202
    i32.const 0
    i32.const 2
    array.new_data $str $__d203
    global.set $__s203
    i32.const 0
    i32.const 50
    array.new_data $str $__d204
    global.set $__s204
    i32.const 0
    i32.const 50
    array.new_data $str $__d205
    global.set $__s205
    i32.const 0
    i32.const 50
    array.new_data $str $__d206
    global.set $__s206
    i32.const 0
    i32.const 50
    array.new_data $str $__d207
    global.set $__s207
    i32.const 0
    i32.const 50
    array.new_data $str $__d208
    global.set $__s208
    i32.const 0
    i32.const 50
    array.new_data $str $__d209
    global.set $__s209
    i32.const 0
    i32.const 50
    array.new_data $str $__d210
    global.set $__s210
    i32.const 0
    i32.const 50
    array.new_data $str $__d211
    global.set $__s211
    i32.const 0
    i32.const 50
    array.new_data $str $__d212
    global.set $__s212
    i32.const 0
    i32.const 50
    array.new_data $str $__d213
    global.set $__s213
    i32.const 0
    i32.const 50
    array.new_data $str $__d214
    global.set $__s214
    i32.const 0
    i32.const 50
    array.new_data $str $__d215
    global.set $__s215
    i32.const 0
    i32.const 50
    array.new_data $str $__d216
    global.set $__s216
    i32.const 0
    i32.const 50
    array.new_data $str $__d217
    global.set $__s217
    i32.const 0
    i32.const 50
    array.new_data $str $__d218
    global.set $__s218
    i32.const 0
    i32.const 50
    array.new_data $str $__d219
    global.set $__s219
    i32.const 0
    i32.const 50
    array.new_data $str $__d220
    global.set $__s220
    i32.const 0
    i32.const 50
    array.new_data $str $__d221
    global.set $__s221
    i32.const 0
    i32.const 50
    array.new_data $str $__d222
    global.set $__s222
    i32.const 0
    i32.const 50
    array.new_data $str $__d223
    global.set $__s223
    i32.const 0
    i32.const 50
    array.new_data $str $__d224
    global.set $__s224
    i32.const 0
    i32.const 50
    array.new_data $str $__d225
    global.set $__s225
    i32.const 0
    i32.const 6
    array.new_data $str $__d226
    global.set $__s226
    i32.const 0
    i32.const 4
    array.new_data $str $__d227
    global.set $__s227
    i32.const 0
    i32.const 11
    array.new_data $str $__d228
    global.set $__s228
    i32.const 0
    i32.const 50
    array.new_data $str $__d229
    global.set $__s229
    i32.const 0
    i32.const 41
    array.new_data $str $__d230
    global.set $__s230
    i32.const 0
    i32.const 19
    array.new_data $str $__d231
    global.set $__s231
    i32.const 0
    i32.const 50
    array.new_data $str $__d232
    global.set $__s232
    i32.const 0
    i32.const 50
    array.new_data $str $__d233
    global.set $__s233
    i32.const 0
    i32.const 50
    array.new_data $str $__d234
    global.set $__s234
    i32.const 0
    i32.const 50
    array.new_data $str $__d235
    global.set $__s235
    i32.const 0
    i32.const 4
    array.new_data $str $__d236
    global.set $__s236
    i32.const 0
    i32.const 9
    array.new_data $str $__d237
    global.set $__s237
    i32.const 0
    i32.const 12
    array.new_data $str $__d238
    global.set $__s238
    i32.const 0
    i32.const 9
    array.new_data $str $__d239
    global.set $__s239
    i32.const 0
    i32.const 17
    array.new_data $str $__d240
    global.set $__s240
    i32.const 0
    i32.const 9
    array.new_data $str $__d241
    global.set $__s241
    i32.const 0
    i32.const 18
    array.new_data $str $__d242
    global.set $__s242
    i32.const 0
    i32.const 5
    array.new_data $str $__d243
    global.set $__s243
    i32.const 0
    i32.const 7
    array.new_data $str $__d244
    global.set $__s244
    i32.const 0
    i32.const 9
    array.new_data $str $__d245
    global.set $__s245
    i32.const 0
    i32.const 17
    array.new_data $str $__d246
    global.set $__s246
    i32.const 0
    i32.const 12
    array.new_data $str $__d247
    global.set $__s247
    i32.const 0
    i32.const 13
    array.new_data $str $__d248
    global.set $__s248
    i32.const 0
    i32.const 14
    array.new_data $str $__d249
    global.set $__s249
    i32.const 0
    i32.const 12
    array.new_data $str $__d250
    global.set $__s250
    i32.const 0
    i32.const 1
    array.new_data $str $__d251
    global.set $__s251
    i32.const 0
    i32.const 11
    array.new_data $str $__d252
    global.set $__s252
    i32.const 0
    i32.const 19
    array.new_data $str $__d253
    global.set $__s253
    i32.const 0
    i32.const 6
    array.new_data $str $__d254
    global.set $__s254
    i32.const 0
    i32.const 15
    array.new_data $str $__d255
    global.set $__s255
    i32.const 0
    i32.const 6
    array.new_data $str $__d256
    global.set $__s256
    i32.const 0
    i32.const 19
    array.new_data $str $__d257
    global.set $__s257
    i32.const 0
    i32.const 5
    array.new_data $str $__d258
    global.set $__s258
    i32.const 0
    i32.const 4
    array.new_data $str $__d259
    global.set $__s259
    i32.const 0
    i32.const 11
    array.new_data $str $__d260
    global.set $__s260
    i32.const 0
    i32.const 7
    array.new_data $str $__d261
    global.set $__s261
    i32.const 0
    i32.const 13
    array.new_data $str $__d262
    global.set $__s262
    i32.const 0
    i32.const 10
    array.new_data $str $__d263
    global.set $__s263
    i32.const 0
    i32.const 12
    array.new_data $str $__d264
    global.set $__s264
    i32.const 0
    i32.const 2
    array.new_data $str $__d265
    global.set $__s265
    i32.const 0
    i32.const 1
    array.new_data $str $__d266
    global.set $__s266
    call $__init_globals
  )
  (@custom "botopink.needs" "gc\0afilesystem\0a")
)
```

----- RUN LOG -----
```logs
RUNTIME TRAP (wasmtime):
unknown import: `bp_fs::open` has not been defined
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

