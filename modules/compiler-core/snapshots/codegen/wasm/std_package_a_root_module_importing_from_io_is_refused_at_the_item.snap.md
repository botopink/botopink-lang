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
  ;; on `Array<T>` default-fn bodies that lower to a `var` + `push` shape,
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
declare fn rawReadBytes(path: string) -> Result<Bytes, HostError>;

// Write `contents` to `path`, creating or truncating.
// Node: `writeFileSync($0, $1)`. Erlang: `file:write_file/2`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').writeFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
)]
declare fn rawWriteBytes(path: string, contents: Bytes) -> Result<i32, HostError>;

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
declare fn utf8Offset(bytes: Bytes) -> i64;

// `line` without its line terminator: one trailing `\n`, and the `\r` before it.
// Node: `subarray`. Erlang: `binary:part/3`.
#[compiler.external(
    .JavaScript("""((__b) => { let __n = __b.length; if (__n > 0 && __b[__n - 1] === 10) { __n--; if (__n > 0 && __b[__n - 1] === 13) __n-- } return __b.subarray(0, __n) })($0)"""),
    .Erlang("""(fun(__B) -> __N = byte_size(__B), if __N >= 2 -> case binary:part(__B, __N - 2, 2) of <<13, 10>> -> binary:part(__B, 0, __N - 2); <<_, 10>> -> binary:part(__B, 0, __N - 1); _ -> __B end; __N =:= 1 -> case __B of <<10>> -> <<>>; _ -> __B end; true -> __B end end)($0)"""),
)]
declare fn stripEol(line: Bytes) -> Bytes;

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
declare fn memHandle(bytes: Bytes) -> unknown;

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
declare fn rawRead(handle: unknown, n: i32) -> Result<Bytes, HostError>;

// Every byte from the handle's position to the end.
#[compiler.external(
    .JavaScript("""(() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = $0; const __parts = []; if (__h.buf.length > 0) { __parts.push(__h.buf); __h.buf = new Uint8Array(0) } for (;;) { const __r = __more(__h, 65536); if (__r.length === 0) break; __parts.push(new Uint8Array(__r)) } let __t = 0; for (const __x of __parts) __t += __x.length; const __o = new Uint8Array(__t); let __p = 0; for (const __x of __parts) { __o.set(__x, __p); __p += __x.length } return __o })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), counters:add(__C, 1, byte_size(__B) - __Pos), {ok, binary:part(__B, __Pos, byte_size(__B) - __Pos)}; _ -> (fun __L(__Acc) -> case file:read(__H, 65536) of {ok, __D} -> __L([__Acc, __D]); eof -> {ok, iolist_to_binary(__Acc)}; {error, __R} -> {error, __R} end end)([]) end end)($0)""", result: true),
)]
declare fn rawReadAll(handle: unknown) -> Result<Bytes, HostError>;

// The next line, terminator included; empty at the end.
#[compiler.external(
    .JavaScript("""(() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = $0; for (;;) { const __i = __h.buf.indexOf(10); if (__i >= 0) { const __l = new Uint8Array(__h.buf.subarray(0, __i + 1)); __h.buf = __h.buf.subarray(__i + 1); return __l } const __r = __more(__h, 65536); if (__r.length === 0) { const __l = __h.buf; __h.buf = new Uint8Array(0); return __l } const __nb = new Uint8Array(__h.buf.length + __r.length); __nb.set(__h.buf, 0); __nb.set(__r, __h.buf.length); __h.buf = __nb } })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Rest = binary:part(__B, __Pos, byte_size(__B) - __Pos), case binary:match(__Rest, <<10>>) of nomatch -> counters:add(__C, 1, byte_size(__Rest)), {ok, __Rest}; {__At, _} -> counters:add(__C, 1, __At + 1), {ok, binary:part(__Rest, 0, __At + 1)} end; _ -> case file:read_line(__H) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __R} end end end)($0)""", result: true),
)]
declare fn rawReadLine(handle: unknown) -> Result<Bytes, HostError>;

// The SHA-256 of the whole file behind the handle, lowercase hex — from its first byte,
// whatever the position, which it leaves where it was.
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; const __hs = require('crypto').createHash('sha256'); if (__h.mem) { __hs.update(__h.mem) } else { const __b = new Uint8Array(65536); let __pos = 0; for (;;) { const __k = require('fs').readSync(__h.fd, __b, 0, 65536, __pos); if (__k === 0) break; __hs.update(__b.subarray(0, __k)); __pos += __k } } return __hs.digest('hex') })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, __B, _} -> {ok, string:lowercase(binary:encode_hex(crypto:hash(sha256, __B)))}; _ -> __L = fun __Lp(__Pos, __Ctx) -> case file:pread(__H, __Pos, 65536) of {ok, __D} -> __Lp(__Pos + byte_size(__D), crypto:hash_update(__Ctx, __D)); eof -> crypto:hash_final(__Ctx); {error, __R} -> erlang:error(__R) end end, {ok, string:lowercase(binary:encode_hex(__L(0, crypto:hash_init(sha256))))} end end)($0)""", result: true),
)]
declare fn rawHash(handle: unknown) -> Result<string, HostError>;

// Write `bytes` at the handle's position; answers how many.
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; const __b = $1; let __o = 0; while (__o < __b.length) __o += require('fs').writeSync(__h.fd, __b, __o, __b.length - __o); return __b.length })()""", result: true),
    .Erlang("""(fun(__H, __B) -> case file:write(__H, __B) of ok -> {ok, byte_size(__B)}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
)]
declare fn rawWrite(handle: unknown, bytes: Bytes) -> Result<i32, HostError>;

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
fn decode(path: string, b: Bytes) -> Result<string, FsError> {
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
pub fn readBytes(path: string) -> Result<Bytes, FsError> {
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
pub fn writeBytes(path: string, contents: Bytes) -> Result<i32, FsError> {
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
declare fn memoryHandle(bytes: Bytes) -> unknown;

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
    pub fn read(self: Self, n: i32) -> Result<Bytes, FsError> {
        if (n <= 0) return Bytes.fromUtf8("");
        val b = try lift(self.location, rawRead(self.handle, n));
        return b;
    }

    // Every byte from the position to the end.
    pub fn bytes(self: Self) -> Result<Bytes, FsError> {
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
    pub async iter fn chunks(self: Self, size: i32 = 65536) -> AsyncIter<Result<Bytes, FsError>> {
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
    pub fn write(self: Self, b: Bytes) -> Result<i32, FsError> {
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
    writeBytes(path, Bytes
        .fromUtf8("ok")
        .concat(Bytes.fromUtf8("é").slice(0, 1))
        .concat(Bytes.fromUtf8("z")));
    assert variantOf(readText(path)) == "InvalidUtf8 " + path + " 2";
    assert readBytes(path).isOk();
    // A sequence cut short at the end of the file.
    writeBytes(path, Bytes.fromUtf8("é").slice(0, 1));
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
    return File(location: "", handle: memHandle(Bytes.fromUtf8("")));
}

test "fs.File writes, then reads bytes, text, a size and a hash" {
    val dir = scratchDir();
    val path = [dir, "/data.txt"].join("");
    val w = create(path).unwrapOr(noFile());
    assert w.write(Bytes.fromUtf8("hello ")).unwrapOr(-1) == 6;
    assert w.write(Bytes.fromUtf8("world")).unwrapOr(-1) == 5;
    w.close();
    val r = open(path).unwrapOr(w);
    assert r.path() == path;
    assert r.size().unwrapOr(-1l) == 11l;
    assert r.read(5).unwrapOr(Bytes.fromUtf8("")).toUtf8().unwrapOr("")
        == "hello";
    assert r.text().unwrapOr("") == " world";
    assert r.read(5).unwrapOr(Bytes.fromUtf8("x")).length == 0;
    assert r.hash().unwrapOr("")
        == "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";
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

----- WASM TEXT -- std/io/fs.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_any (array (mut anyref)))
    (type $var_FsError_NotFound (struct (field $f0 (mut (ref null $str)))))
    (type $var_FsError_PermissionDenied (struct (field $f0 (mut (ref null $str)))))
    (type $var_FsError_IsDirectory (struct (field $f0 (mut (ref null $str)))))
    (type $var_FsError_NotDirectory (struct (field $f0 (mut (ref null $str)))))
    (type $var_FsError_AlreadyExists (struct (field $f0 (mut (ref null $str)))))
    (type $var_FsError_InvalidUtf8 (struct (field $f0 (mut (ref null $str))) (field $f1 (mut i64))))
    (type $var_FsError_Other (struct (field $f0 (mut (ref null $str))) (field $f1 (mut (ref null $str)))))
    (type $rec_HostError (struct (field $f0 (mut (ref null $str))) (field $f1 (mut (ref null $str))) (field $f2 (mut i32)) (field $f3 (mut (ref null $str)))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $rec_File (struct (field $f0 (mut (ref null $str))) (field $f1 (mut anyref))))
  )
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (start $__init_strs)
  (global $__heap_ptr (mut i32) (i32.const 1408))
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
  ;; (`*Sync` on Node, blocking BIFs on Erlang); there is no wasm binding here
  ;; (front 164: `wasi:filesystem` behind `needs: [.Filesystem]`).
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
    global.get $__s6
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
    global.get $__s7
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
    global.get $__s8
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
    global.get $__s9
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
    global.get $__s10
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
    global.get $__s11
    local.get $path
    call $__str_concat
    global.get $__s12
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
    global.get $__s13
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
  ;; declare fn rawReadBytes — no wasm implementation (host-backed)
  ;; Write `contents` to `path`, creating or truncating.
  ;; Node: `writeFileSync($0, $1)`. Erlang: `file:write_file/2`.
  ;; declare fn rawWriteBytes — no wasm implementation (host-backed)
  ;; Append `contents` to `path`, creating it when it is not there.
  ;; Node: `appendFileSync($0, $1)`. Erlang: `file:write_file/3` with `append`.
  ;; declare fn rawAppendText — no wasm implementation (host-backed)
  ;; The offset of the first byte that starts a sequence that is not UTF-8 (a byte no sequence
  ;; starts with, a sequence cut short, an overlong form, a surrogate, a code point past U+10FFFF),
  ;; or -1 when every byte is part of a valid sequence — the same offset on every target.
  ;; Node: a scan of the bytes. Erlang: `unicode:characters_to_binary/3`, whose `Good` prefix is the offset.
  ;; declare fn utf8Offset — no wasm implementation (host-backed)
  ;; `line` without its line terminator: one trailing `\n`, and the `\r` before it.
  ;; Node: `subarray`. Erlang: `binary:part/3`.
  ;; declare fn stripEol — no wasm implementation (host-backed)
  ;; The handle of the file at `path`, open for reading. A directory is `isdir` on both hosts
  ;; (Node opens one; the template refuses it). The handle is host-owned and opaque: a `{ fd,
  ;; mem, pos, buf }` object on Node, an io device on Erlang (a stream reads it in its own process).
  ;; declare fn rawOpen — no wasm implementation (host-backed)
  ;; The handle of the file at `path`, open for writing: created, or truncated.
  ;; declare fn rawCreate — no wasm implementation (host-backed)
  ;; A handle over bytes held in memory — what an `Asset` opens as. The position is a field
  ;; on Node and a `counters` cell on Erlang.
  ;; declare fn memHandle — no wasm implementation (host-backed)
  ;; The size of the file behind `handle`, in bytes. On Erlang it reads `path`.
  ;; declare fn rawSize — no wasm implementation (host-backed)
  ;; Up to `n` bytes (n > 0) from the handle's position; empty at the end.
  ;; declare fn rawRead — no wasm implementation (host-backed)
  ;; Every byte from the handle's position to the end.
  ;; declare fn rawReadAll — no wasm implementation (host-backed)
  ;; The next line, terminator included; empty at the end.
  ;; declare fn rawReadLine — no wasm implementation (host-backed)
  ;; The SHA-256 of the whole file behind the handle, lowercase hex — from its first byte,
  ;; whatever the position, which it leaves where it was.
  ;; declare fn rawHash — no wasm implementation (host-backed)
  ;; Write `bytes` at the handle's position; answers how many.
  ;; declare fn rawWrite — no wasm implementation (host-backed)
  ;; Close the handle. A failure to close is not reported (a `Closeable`'s `close` answers nothing).
  ;; declare fn rawClose — no wasm implementation (host-backed)
  ;; Write `contents` to `path`, creating or truncating. Reds with the
  ;; host's I/O error message.
  ;; Node: `require('fs').writeFileSync($0, $1)`.
  ;; Erlang: `file:write_file/2`.
  ;; declare fn rawWriteText — no wasm implementation (host-backed)
  ;; Whether a path exists, of any kind: a regular file, a directory, a
  ;; character or block device (`/dev/null`), a FIFO or a socket. A symbolic
  ;; link is followed — one whose target is missing is `false`, the answer
  ;; every read through it would give.
  ;; Node: `require('fs').existsSync($0)` (a `stat`).
  ;; Erlang: `file:read_file_info/1` (a `stat`; `filelib:is_file/1`, which it
  ;; replaces, answers only regular files and directories, so `/dev/null`
  ;; was `false` on erlang and `true` on commonJS).
  ;; declare fn exists — no wasm implementation (host-backed)
  ;; List the names of the directory entries at `path` (relative).
  ;; Node: `require('fs').readdirSync($0)`.
  ;; Erlang: `file:list_dir/1` returns `{ok, [string()]}`.
  ;; declare fn rawList — no wasm implementation (host-backed)
  ;; Create directory at `path`. Use `mkdirRecursive` to create
  ;; intermediate parents.
  ;; Node: `require('fs').mkdirSync($0)`.
  ;; Erlang: `file:make_dir/1`.
  ;; declare fn rawMkdir — no wasm implementation (host-backed)
  ;; Create the directory at `path` and every missing directory above it. A
  ;; directory that is already there is `Ok` too; a path that exists as anything
  ;; else (a file) is an `Error`. What the snapshot library (`snap`) makes the
  ;; directory of a `.snap` with (decision 391).
  ;; Node: `require('fs').mkdirSync($0, { recursive: true })`.
  ;; Erlang: `filelib:ensure_path/1`.
  ;; declare fn rawMkdirRecursive — no wasm implementation (host-backed)
  ;; Delete the FILE at `path`. A directory — empty or not — is `IsDirectory` on
  ;; both hosts (Node's `ERR_FS_EISDIR`; Erlang's `eperm` is read as `eisdir` after
  ;; a `read_link_info`, so the variant is the same); `removeTree` removes one.
  ;; Node: `require('fs').rmSync($0)`.
  ;; Erlang: `file:delete/1`.
  ;; declare fn rawRm — no wasm implementation (host-backed)
  ;; Copy file from `src` to `dest`. Reds when `src` is missing or
  ;; `dest` already exists (Node's default `copyFileSync` semantics).
  ;; Node: `require('fs').copyFileSync($0, $1)`.
  ;; Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).
  ;; declare fn rawCopy — no wasm implementation (host-backed)
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
  ;; declare fn rawStat — no wasm implementation (host-backed)
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
  ;; declare fn rawWalk — no wasm implementation (host-backed)
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
  ;; declare fn rawGlob — no wasm implementation (host-backed)
  ;; Remove `path` and everything under it: a file, a link (the link, never its
  ;; target) or a directory tree. A path that is not there is `Ok` too — the
  ;; caller wanted it gone. What a test fixture is cleared with, and what the
  ;; snapshot engine's tests clear their scratch directories with (1.0.11-beta
  ;; front 97).
  ;; Node: `rmSync(path, { recursive: true, force: true })`.
  ;; Erlang: `file:del_dir_r/1`.
  ;; declare fn rawRemoveTree — no wasm implementation (host-backed)
  ;; Internal, test scaffolding: a fresh, unique, empty directory under the
  ;; host's tmpdir. Private — every `walk`/`glob` test makes its fixture tree in
  ;; one of these and removes it with `removeTree`, so a run leaves nothing under
  ;; the host's tmpdir.
  ;; declare fn scratchDir — no wasm implementation (host-backed)
  ;; Internal, test scaffolding: the working directory (what a relative root is
  ;; read against) and a symbolic link `link` → `target`.
  ;; declare fn workingDir — no wasm implementation (host-backed)
  ;; declare fn linkTo — no wasm implementation (host-backed)
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
    (local $__gc6 (ref null $str))
    (local $__gc7 i32)
    (local $__gc8 (ref null $str))
    (local $__gc9 (ref null $str))
    (local $__gc10 i32)
    (local $__gc11 (ref null $str))
    (local $__gc12 (ref null $str))
    (local $__gc13 i32)
    (local $__gc14 (ref null $str))
    (local $__gc15 (ref null $str))
    (local $__gc16 i32)
    (local $__gc17 (ref null $str))
    (local $__gc18 (ref null $str))
    (local $__gc19 i32)
    (local $__gc20 (ref null $str))
    (local $__gc21 (ref null $str))
    (local $__gc22 i32)
    (local $__gc23 (ref null $str))
    (local $__gc24 (ref null $str))
    (local $__gc25 i32)
    (local $__gc26 (ref null $str))
    (local $__gc27 (ref null $str))
    (local $__gc28 i32)
    local.get $e
    struct.get $rec_HostError $f0
    local.set $__gc6
    global.get $__heap_ptr
    local.set $__gc7
    local.get $__gc6
    call $__gc_to_lin_str
    call $__std_text_toUpper
    call $__lin_to_gc_str
    local.get $__gc7
    global.set $__heap_ptr
    local.set $u
    local.get $u
    global.get $__s14
    local.set $__gc8
    local.set $__gc9
    global.get $__heap_ptr
    local.set $__gc10
    local.get $__gc9
    call $__gc_to_lin_str
    local.get $__gc8
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc10
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
    global.get $__s15
    local.set $__gc11
    local.set $__gc12
    global.get $__heap_ptr
    local.set $__gc13
    local.get $__gc12
    call $__gc_to_lin_str
    local.get $__gc11
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc13
    global.set $__heap_ptr
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $u
    global.get $__s16
    local.set $__gc14
    local.set $__gc15
    global.get $__heap_ptr
    local.set $__gc16
    local.get $__gc15
    call $__gc_to_lin_str
    local.get $__gc14
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc16
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
    global.get $__s17
    local.set $__gc17
    local.set $__gc18
    global.get $__heap_ptr
    local.set $__gc19
    local.get $__gc18
    call $__gc_to_lin_str
    local.get $__gc17
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc19
    global.set $__heap_ptr
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $u
    global.get $__s18
    local.set $__gc20
    local.set $__gc21
    global.get $__heap_ptr
    local.set $__gc22
    local.get $__gc21
    call $__gc_to_lin_str
    local.get $__gc20
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc22
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
    global.get $__s19
    local.set $__gc23
    local.set $__gc24
    global.get $__heap_ptr
    local.set $__gc25
    local.get $__gc24
    call $__gc_to_lin_str
    local.get $__gc23
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc25
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
    global.get $__s20
    local.set $__gc26
    local.set $__gc27
    global.get $__heap_ptr
    local.set $__gc28
    local.get $__gc27
    call $__gc_to_lin_str
    local.get $__gc26
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc28
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
    (local $v__3 anyref)
    (local $e__4 (ref null $rec_HostError))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    local.set $v__3
    i32.const 0
    local.get $v__3
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
    local.set $e__4
    i32.const 1
    local.get $path
    local.get $e__4
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
  ;; What `rawWalk` finds under a root: the regular files, and the links whose
  ;; target is missing, both as paths relative to the root, sorted.
  ;; Whether the handle is one over bytes held in memory (an `Asset`'s), which cannot be written.
  ;; declare fn rawReadOnly — no wasm implementation (host-backed)
  ;; ── whole-file shortcuts ─────────────────────────────────────────────────────
  ;; The file's bytes.
  ;; The file as UTF-8 text. Bytes that are not UTF-8 are `InvalidUtf8` on every
  ;; target — never node's silent U+FFFD nor erlang's unchecked binary.
  ;; Write `contents` to `path`, creating or truncating.
  ;; Append `contents`, creating the file when it is not there.
  ;; ── metadata and directories ─────────────────────────────────────────────────
  ;; The host's handle over embedded bytes: read like a file, never closed on disk.
  ;; declare fn memoryHandle — no wasm implementation (host-backed)
  ;; ── the handle ───────────────────────────────────────────────────────────────
  ;; An open file (decision 540 (3)). `location` is the path it was opened with and
  ;; `handle` the host's — opaque, never read by a program. Closed by the writer:
  ;; `val f = try fs.open(p); defer f.close();`.
  (func $File_path (param $self (ref null $rec_File)) (result (ref null $str))
    local.get $self
    struct.get $rec_File $f0
    return
  )
  ;; Open the file at `path` for reading. A directory is `IsDirectory` on every target.
  ;; Open the file at `path` for writing: created, or truncated.
  ;; An `Asset` (`@embed`, decisions 519, 538) as a `File`: the embedded bytes, read
  ;; like a file on disk — no `Result`, the build proved the file exists — and
  ;; closing it is a no-op.
  ;; ── tests ────────────────────────────────────────────────────────────────────
  ;; (Inline tests are smoke-grade — they require the host filesystem to be
  ;; writable at the host's `tmpdir()`. The lib-test harness runs each
  ;; inline test as a separate process; the temp filenames are seeded with
  ;; `time.nowMillis()` for cross-run uniqueness.)
  ;; Internal, test scaffolding: `stat(p)`, or a stat no file has.
  ;; Internal, test scaffolding: `<dir>/app/page.bp`, `<dir>/app/blog/page.bp`,
  ;; `<dir>/app/blog/notes.md` — the fixture tree every walk/glob test reads.
  ;; Internal, test scaffolding: what `walk` answers for the fixture tree when
  ;; its root is spelled `<scratch dir><suffix>` — every spelling of one root has
  ;; to answer the same three relative paths.
  ;; Internal, test scaffolding: the same, with the root spelled relative to the
  ;; working directory — `<prefix><path from the cwd to the fixture>`.
  ;; Internal, test scaffolding: the `Error` of `walk(root)`, `""` when it walked.
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
    global.get $__s21
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
    global.get $__s22
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
    global.get $__s23
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
    global.get $__s24
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
    global.get $__s25
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
    global.get $__s26
    local.get $p
    call $__str_concat
    global.get $__s27
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
  ;; Internal, test scaffolding: what `glob(pattern, <dir>/app)` answers over
  ;; `makeGlobTree`, joined by `,`.
  ;; ── FsError, readText and the handle ─────────────────────────────────────────
  ;; Internal, test scaffolding: the variant of an `Error`, `"ok"` for an `Ok`.
  (func $variantOf (param $r (ref null $result)) (result (ref null $str))
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $e__5 anyref)
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $str))
      (then
    global.get $__s28
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $str))
      (then
    local.get $__case_0
    struct.get $result $payload
    local.set $e__5
    local.get $e__5
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
  ;; Internal, test scaffolding: take every permission from `path`; whether that
  ;; denies this user anything (root is denied nothing), and give them back.
  ;; declare fn denyAll — no wasm implementation (host-backed)
  ;; declare fn allowAll — no wasm implementation (host-backed)
  (func $__init_globals
    global.get $__s29
    global.set $separator
    global.get $__s30
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
  ;; __std_f129 — from std_wasm.wasm (sha256 67dbdd61ea9b)
  ;; __std_f130 — from std_wasm.wasm (sha256 f15aa78ce6d6)
  ;; __std_f131 — from std_wasm.wasm (sha256 2f81dc7302bb)
  ;; __std_f132 — from std_wasm.wasm (sha256 38e98c1edeed)
  ;; __std_f133 — from std_wasm.wasm (sha256 16c99e1a095a)
  ;; __std_f134 — from std_wasm.wasm (sha256 30c514d3cfe8)
  ;; __std_f434 — from std_wasm.wasm (sha256 91fc3314249d)
  ;; __std_f446 — from std_wasm.wasm (sha256 d13a98c08300)
  ;; __std_f500 — from std_wasm.wasm (sha256 6eed520bf8fe)
  ;; std:text.toUpper — from std_wasm.wasm (sha256 72dc7de6cc0d)
  ;; std:text.startsWith — from std_wasm.wasm (sha256 322b10039271)
  ;; __std_f523 — from std_wasm.wasm (sha256 2904f8c0427d)
  ;; std:text.split — from std_wasm.wasm (sha256 d23f0fc25558)
  ;; std-wasm's .wat leaves (front 164 s3)
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
  (data $__d0 "")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "integer overflow: + on i32 at src/io/fs.bp:114:52")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "integer overflow: - on i32 at src/io/fs.bp:120:42")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "..")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "integer overflow: - on i32 at src/io/fs.bp:135:39")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 ".")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "not found: ")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "permission denied: ")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "is a directory: ")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "not a directory: ")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "already exists: ")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 "not UTF-8: ")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (data $__d12 " at byte ")
  (global $__s12 (mut (ref null $str)) (ref.null $str))
  (data $__d13 ": ")
  (global $__s13 (mut (ref null $str)) (ref.null $str))
  (data $__d14 "ENOENT")
  (global $__s14 (mut (ref null $str)) (ref.null $str))
  (data $__d15 "EACCES")
  (global $__s15 (mut (ref null $str)) (ref.null $str))
  (data $__d16 "EPERM")
  (global $__s16 (mut (ref null $str)) (ref.null $str))
  (data $__d17 "EISDIR")
  (global $__s17 (mut (ref null $str)) (ref.null $str))
  (data $__d18 "PATH IS A DIRECTORY")
  (global $__s18 (mut (ref null $str)) (ref.null $str))
  (data $__d19 "ENOTDIR")
  (global $__s19 (mut (ref null $str)) (ref.null $str))
  (data $__d20 "EEXIST")
  (global $__s20 (mut (ref null $str)) (ref.null $str))
  (data $__d21 "NotFound ")
  (global $__s21 (mut (ref null $str)) (ref.null $str))
  (data $__d22 "PermissionDenied ")
  (global $__s22 (mut (ref null $str)) (ref.null $str))
  (data $__d23 "IsDirectory ")
  (global $__s23 (mut (ref null $str)) (ref.null $str))
  (data $__d24 "NotDirectory ")
  (global $__s24 (mut (ref null $str)) (ref.null $str))
  (data $__d25 "AlreadyExists ")
  (global $__s25 (mut (ref null $str)) (ref.null $str))
  (data $__d26 "InvalidUtf8 ")
  (global $__s26 (mut (ref null $str)) (ref.null $str))
  (data $__d27 " ")
  (global $__s27 (mut (ref null $str)) (ref.null $str))
  (data $__d28 "ok")
  (global $__s28 (mut (ref null $str)) (ref.null $str))
  (data $__d29 "/")
  (global $__s29 (mut (ref null $str)) (ref.null $str))
  (data $__d30 ":")
  (global $__s30 (mut (ref null $str)) (ref.null $str))
  (func $__init_strs
    i32.const 0
    i32.const 0
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 49
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 49
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 2
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 49
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 1
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 11
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 19
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 16
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 17
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 16
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 11
    array.new_data $str $__d11
    global.set $__s11
    i32.const 0
    i32.const 9
    array.new_data $str $__d12
    global.set $__s12
    i32.const 0
    i32.const 2
    array.new_data $str $__d13
    global.set $__s13
    i32.const 0
    i32.const 6
    array.new_data $str $__d14
    global.set $__s14
    i32.const 0
    i32.const 6
    array.new_data $str $__d15
    global.set $__s15
    i32.const 0
    i32.const 5
    array.new_data $str $__d16
    global.set $__s16
    i32.const 0
    i32.const 6
    array.new_data $str $__d17
    global.set $__s17
    i32.const 0
    i32.const 19
    array.new_data $str $__d18
    global.set $__s18
    i32.const 0
    i32.const 7
    array.new_data $str $__d19
    global.set $__s19
    i32.const 0
    i32.const 6
    array.new_data $str $__d20
    global.set $__s20
    i32.const 0
    i32.const 9
    array.new_data $str $__d21
    global.set $__s21
    i32.const 0
    i32.const 17
    array.new_data $str $__d22
    global.set $__s22
    i32.const 0
    i32.const 12
    array.new_data $str $__d23
    global.set $__s23
    i32.const 0
    i32.const 13
    array.new_data $str $__d24
    global.set $__s24
    i32.const 0
    i32.const 14
    array.new_data $str $__d25
    global.set $__s25
    i32.const 0
    i32.const 12
    array.new_data $str $__d26
    global.set $__s26
    i32.const 0
    i32.const 1
    array.new_data $str $__d27
    global.set $__s27
    i32.const 0
    i32.const 2
    array.new_data $str $__d28
    global.set $__s28
    i32.const 0
    i32.const 1
    array.new_data $str $__d29
    global.set $__s29
    i32.const 0
    i32.const 1
    array.new_data $str $__d30
    global.set $__s30
    call $__init_globals
  )
  (@custom "botopink.needs" "gc\0a")
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

