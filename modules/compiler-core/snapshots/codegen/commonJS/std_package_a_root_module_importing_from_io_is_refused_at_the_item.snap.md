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

----- JAVASCRIPT -- std/path.js
```javascript
const __bp_surrogate = /[\uD800-\uDFFF]/;
const __bp_surrogate_k = new Array(64).fill("");
const __bp_surrogate_v = new Array(64).fill(false);
const __bp_surrogate_k2 = new Array(64).fill("");
const __bp_surrogate_v2 = new Array(64).fill(false);
function __bp_has_surrogate(s) {
    const h = s.length & 63;
    if (__bp_surrogate_k[h] === s) { return __bp_surrogate_v[h]; }
    if (__bp_surrogate_k2[h] === s) { return __bp_surrogate_v2[h]; }
    const p = __bp_surrogate.test(s);
    __bp_surrogate_k2[h] = __bp_surrogate_k[h];
    __bp_surrogate_v2[h] = __bp_surrogate_v[h];
    __bp_surrogate_k[h] = s;
    __bp_surrogate_v[h] = p;
    return p;
}

function __bp_str_count(s, u) {
    let n = 0;
    for (const c of s.substring(0, u)) { n += 1; }
    return n;
}

function __bp_str_length(s) {
    if (!__bp_has_surrogate(s)) { return s.length; }
    let n = 0;
    for (const c of s) { n += 1; }
    return n;
}

function __bp_str_index_of(s, sub) {
    const u = s.indexOf(sub);
    return (u <= 0 || !__bp_has_surrogate(s)) ? u : __bp_str_count(s, u);
}

function __bp_array_at(xs, i) { return xs.at(i) ?? null; }

function __bp_eq(a, b, d) {
    if (Object.is(a, b)) {
        return true;
    }
    if ((((((d > 32) || (a === null)) || (b === null)) || (typeof a !== "object")) || (a.constructor !== b.constructor))) {
        return false;
    }
    if (Array.isArray(a)) {
        return ((a.length === b.length) && a.every((e, i) => __bp_eq(e, b[i], (d + 1))));
    }
    const k = Object.keys(a);
    return ((k.length === Object.keys(b).length) && k.every((n) => __bp_eq(a[n], b[n], (d + 1))));
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

// behavior String
//   fn length(...)
//   fn split(...)
//   fn toUpper(...)
//   fn toLower(...)
//   fn contains(...)
//   fn startsWith(...)
//   fn endsWith(...)
//   fn trim(...)
//   fn trimStart(...)
//   fn trimEnd(...)
//   fn replace(...)
//   default fn slice(...)
//   fn at(...)
//   fn indexOf(...)
//   default fn toString(...)
//   fn fromCodepoint(...)
//   fn padStart(...)
//   fn padEnd(...)
//   fn repeat(...)
//   fn replaceAll(...)
//   fn chars(...)
//   fn lines(...)
//   fn words(...)
//   fn normalizeNewlines(...)
//   fn trimTrailingNewlines(...)
//   fn firstDifferingLine(...)
//   fn charCodeAt(...)
//   fn lastIndexOf(...)
//   default fn parseInt(...)
//   default fn parseFloat(...)
String.prototype.slice = function(start, end) {
    const self = this.valueOf();
    if ((end != null)) { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, end); } else { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, start); }
};
String.prototype.chars = function() { return (Array.from(this.valueOf())); };
String.prototype.lines = function() { return this.valueOf().split(/\r?\n/); };
String.prototype.words = function() { return this.valueOf().split(/[ \t\n\r]+/).filter(__w => __w.length > 0); };
String.prototype.normalizeNewlines = function() { return this.valueOf().replaceAll("\r\n", "\n"); };
String.prototype.trimTrailingNewlines = function() { return this.valueOf().replace(/\n+$/, ""); };
String.prototype.firstDifferingLine = function(other) { return ((__a, __b) => { const __x = __a.split("\n"), __y = __b.split("\n"); let __i = 0; while (__i < __x.length && __i < __y.length && __x[__i] === __y[__i]) __i++; return (__i === __x.length && __i === __y.length) ? 0 : __i + 1 })(this.valueOf(), other); };
String.prototype.charCodeAt = function(index) { return ((__s, __i) => { if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = __i >= 0 ? Array.from(__s)[__i] : undefined; return __c === undefined ? -1 : __c.codePointAt(0); } return (__s.codePointAt(__i) ?? -1) | 0; })(this.valueOf(), index); };
String.prototype.parseInt = function() {
    const self = this.valueOf();
    const signed = (self.startsWith("-") || self.startsWith("+"));
    const digits = (() => { if (signed) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, 1); } else { return self; } })();
    return (() => { if ((/^[0-9]+$/.test(digits))) { return ((__s) => { const __n = BigInt(__s); return (__n >= -9223372036854775808n && __n <= 9223372036854775807n) ? { ok: (__n >= -9007199254740991n && __n <= 9007199254740991n) ? Number(__n) : __n } : { error: 'parseInt: "' + __s + '" is out of range' } })(self); } else { return ({ error: "parseInt: \"" + self + "\" is not an integer" }); } })();
};
String.prototype.parseFloat = function() {
    const self = this.valueOf();
    const signed = (self.startsWith("-") || self.startsWith("+"));
    const start = (() => { if (signed) { return 1; } else { return 0; } })();
    const lowerAt = __bp_str_index_of(self, "e");
    const exponentAt = (() => { if ((lowerAt < 0)) { return __bp_str_index_of(self, "E"); } else { return lowerAt; } })();
    const mantissa = (() => { if ((exponentAt < 0)) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, start); } else { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, exponentAt); } })();
    const pointAt = __bp_str_index_of(self, ".");
    const pointed = ((pointAt >= 0) && (((exponentAt < 0) || (pointAt < exponentAt))));
    const whole = (() => { if (pointed) { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, pointAt); } else { return mantissa; } })();
    const fraction = (() => { if ((pointed === false)) { return "0"; } else { return (() => { if ((exponentAt < 0)) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, (pointAt + 1)); } else { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, (pointAt + 1), exponentAt); } })(); } })();
    const exponent = (() => { if ((exponentAt < 0)) { return "0"; } else { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, (exponentAt + 1)); } })();
    const exponentMark = (() => { if ((exponentAt < 0)) { return ""; } else { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, (exponentAt + 1), (exponentAt + 2)); } })();
    const exponentSigned = ((exponentMark === "-") || (exponentMark === "+"));
    const exponentDigits = (() => { if (exponentSigned) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, (exponentAt + 2)); } else { return exponent; } })();
    const wellFormed = (((/^[0-9]+$/.test(whole)) && (/^[0-9]+$/.test(fraction))) && (/^[0-9]+$/.test(exponentDigits)));
    return (() => { if (wellFormed) { return ((__t, __w, __f, __x) => { const __n = Number((__t.startsWith('-') ? '-' : '') + __w + '.' + __f + 'e' + __x); return Number.isFinite(__n) ? { ok: __n } : { error: 'parseFloat: "' + __t + '" overflows f64' } })(self, whole, fraction, exponent); } else { return ({ error: "parseFloat: \"" + self + "\" is not a number" }); } })();
};

// behavior Bool
//   fn toString(...)
//   default fn negate(...)
//   default fn nor(...)
//   default fn nand(...)
//   default fn exclusiveOr(...)
//   default fn exclusiveNor(...)
Boolean.prototype.negate = function() {
    const self = this.valueOf();
    return (!self);
};
Boolean.prototype.nor = function(other) {
    const self = this.valueOf();
    return (!((self || other)));
};
Boolean.prototype.nand = function(other) {
    const self = this.valueOf();
    return (!((self && other)));
};
Boolean.prototype.exclusiveOr = function(other) {
    const self = this.valueOf();
    return (self !== other);
};
Boolean.prototype.exclusiveNor = function(other) {
    const self = this.valueOf();
    return (self === other);
};

// behavior Array
//   length: i32
//   fn at(...)
//   fn push(...)
//   fn pop(...)
//   default fn slice(...)
//   fn join(...)
//   fn reverse(...)
//   fn indexOf(...)
//   default fn lastIndexOf(...)
//   fn forEach(...)
//   fn map(...)
//   fn filter(...)
//   fn zip(...)
//   default fn range(...)
//   default fn repeat(...)
//   default fn isEmpty(...)
//   default fn contains(...)
//   default fn first(...)
//   default fn rest(...)
//   default fn take(...)
//   default fn drop(...)
//   default fn fold(...)
//   default fn find(...)
//   default fn count(...)
//   default fn all(...)
//   default fn any(...)
//   default fn append(...)
//   default fn prepend(...)
//   default fn flatten(...)
//   default fn flatMap(...)
//   default fn toList(...)
//   default fn some(...)
//   default fn every(...)
//   default fn flat(...)
//   default fn findIndex(...)
//   default fn fill(...)
//   default fn chunked(...)
//   default fn sliding(...)
//   default fn unique(...)
Array.range = function(start, stop) { return ((__a, __b) => Array.from({ length: Math.max(0, __b - __a) }, (_, __i) => __a + __i))(start, stop); };
Array.repeat = function(value, times) { return ((__v, __n) => Array.from({ length: Math.max(0, __n) }, () => __v))(value, times); };
Array.prototype.slice = function(start, end) {
    if ((end != null)) { return ((__xs, __a, __e) => { const __n = __xs.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return Array.from({ length: Math.max(__f - __b, 0) }, (_, __i) => __xs[__b + __i]); })(this, start, end); } else { return ((__xs, __a) => { const __n = __xs.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return Array.from({ length: __n - __b }, (_, __i) => __xs[__b + __i]); })(this, start); }
};
Array.prototype.zip = function(other) { return this.map((__x, __i) => [__x, (other)[__i]]).slice(0, Math.min(this.length, (other).length)); };
Array.prototype.isEmpty = function() {
    return (this.length === 0);
};
Array.prototype.contains = function(x) {
    return (this.indexOf(x) !== (-1));
};
Array.prototype.first = function() {
    return __bp_array_at(this, 0);
};
Array.prototype.rest = function() {
    return this.slice(1, this.length);
};
Array.prototype.take = function(n) {
    return this.slice(0, n);
};
Array.prototype.drop = function(n) {
    return this.slice(n, this.length);
};
Array.prototype.fold = function(initial, f) {
    let acc = initial;
    this.forEach((x) => {
    acc = f(acc, x);
});
    return acc;
};
Array.prototype.count = function(pred) {
    return this.filter(pred).length;
};
Array.prototype.all = function(pred) {
    return (this.filter(pred).length === this.length);
};
Array.prototype.any = function(pred) {
    return (this.filter(pred).length !== 0);
};
Array.prototype.prepend = function(item) {
    let out = [item];
    this.forEach((x) => {
    return out.push(x);
});
    return out;
};
Array.prototype.flatten = function() {
    let out = [];
    this.forEach((inner) => {
    out = out.concat(inner);
});
    return out;
};
Array.prototype.toList = function() {
    return this;
};
Array.prototype.some = function(pred) {
    return this.any(pred);
};
Array.prototype.every = function(pred) {
    return this.all(pred);
};
Array.prototype.flat = function() {
    return this.flatten();
};
Array.prototype.findIndex = function(pred) {
    let out = (-1);
    let i = 0;
    this.forEach((x) => {
    (() => { if ((out === (-1))) { return (() => { if (pred(x)) { return out = i; } })(); } })();
    i = (i + 1);
});
    return out;
};
Array.prototype.fill = function(value) {
    return Array.repeat(value, this.length);
};
Array.prototype.chunked = function(n) {
    let out = [];
    if ((n <= 0)) { return out; }
    const len = this.length;
    for (const k of Array.from({length: Math.max(0, (len) - (0))}, (_, __i) => (0) + __i)) {
    (() => { if ((((k % n) + 0) === 0)) { return out = out.concat([this.slice(k, (k + n))]); } })();
}
    return out;
};
Array.prototype.sliding = function(n) {
    let out = [];
    if ((n <= 0)) { return out; }
    const windows = ((this.length - n) + 1);
    if ((windows <= 0)) { return out; }
    for (const k of Array.from({length: Math.max(0, (windows) - (0))}, (_, __i) => (0) + __i)) {
    out = out.concat([this.slice(k, (k + n))]);
}
    return out;
};
Array.prototype.unique = function() {
    let out = [];
    this.forEach((x) => {
    return (() => { if ((!out.any((y) => {
    return __bp_eq(y, x, 0);
}))) { return out = out.concat([x]); } })();
});
    return out;
};

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

const separator = "/";

exports.separator = separator;

const delimiter = ":";

exports.delimiter = delimiter;

// Split a path into its non-empty components. Leading-`/` paths drop the

// empty head; trailing-`/` paths drop the empty tail. A path made of pure

// separators yields the empty array. Uses `filter` rather than

// `forEach` + `push`: a `var` + `push` pattern lowers to a dead-store

// (`out ++ [p]` discarded) on Erlang because the immutable runtime never

// rebinds `Out`; `filter` round-trips through `lists:filter/2` and

// `Array.prototype.filter` directly.

function split(path) {
    const raw = path.split(separator);
    return raw.filter((p) => {
    return (p !== "");
});
}
exports.split = split;

// True when `path` starts with `/` — the posix absolute-path marker.

function isAbsolute(path) {
    return path.startsWith(separator);
}
exports.isAbsolute = isAbsolute;

// The last non-empty component of `path` (the file name, in the common

// case). Returns "" for the empty path and for pure-separator paths.

function basename(path) {
    const parts = split(path);
    const n = parts.length;
    if ((n === 0)) { return ""; }
    return (() => { const __bp_nullish = __bp_array_at(parts, __bp_int((n - 1), -2147483648, 2147483647, "- on i32 at src/path.bp:40:23")); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
}
exports.basename = basename;

// Everything except the basename — the parent directory portion. For an

// absolute path this preserves the leading `/`. For a path with no

// separator (`"foo"`), returns `""`.

function dirname(path) {
    const parts = split(path);
    const n = parts.length;
    if ((n <= 1)) { return (() => { if (isAbsolute(path)) { return separator; } else { return ""; } })(); }
    const head = parts.slice(0, __bp_int((n - 1), -2147483648, 2147483647, "- on i32 at src/path.bp:50:33"));
    const joined = head.join(separator);
    // String `+` lowers to numeric `+` on Erlang (badarith on binaries);;
    // use a 2-element array `.join("")` to concat instead — that goes;
    // through `lists:join("", …)` + `iolist_to_binary` on Erlang and;
    // `Array.prototype.join("")` on Node, both string-safe.;
    return (() => { if (isAbsolute(path)) { return [separator, joined].join(""); } else { return joined; } })();
}
exports.dirname = dirname;

// The trailing extension on the basename — the substring from the LAST

// `.` to the end, including the dot. Returns `""` when the basename has

// no extension (or is a dotfile with no further `.`s, e.g. `.bashrc`).

function extname(path) {
    const base = basename(path);
    const pieces = base.split(".");
    const n = pieces.length;
    if ((n <= 1)) { return ""; }
    const head = (() => { const __bp_nullish = __bp_array_at(pieces, 0); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    const tail = (() => { const __bp_nullish = __bp_array_at(pieces, __bp_int((n - 1), -2147483648, 2147483647, "- on i32 at src/path.bp:68:28")); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    // Dotfiles like ".bashrc" split into ["", "bashrc"] — no extension.;
    const isDotfile = ((head === "") && (n === 2));
    return (() => { if (isDotfile) { return ""; } else { return [".", tail].join(""); } })();
}
exports.extname = extname;

// Join a list of path segments with the separator. Leading separator on

// the first segment is preserved; intra-segment slashes are normalised

// (`"foo/" + "/bar"` joins to `"foo/bar"`, never `"foo//bar"`). Uses

// `map` + `filter` + `join` rather than `fold` / `flatMap`: those land

// on `Array<T>` default-fn bodies that lower to a `var` + `push` shape,

// which lowers to a dead store on Erlang's immutable runtime (the same

// trap `split` sidesteps).

function join(parts) {
    const isAbs = (() => { if ((parts.length === 0)) { return false; } else { return isAbsolute((() => { const __bp_nullish = __bp_array_at(parts, 0); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })()); } })();
    const collapsed = parts.map((p) => {
    return split(p).join(separator);
});
    const joined = collapsed.filter((p) => {
    return (p !== "");
}).join(separator);
    return (() => { if (isAbs) { return [separator, joined].join(""); } else { return joined; } })();
}
exports.join = join;

// Collapse `//` and drop `.` segments via a `filter` over the split

// pieces. Full `..` pop semantics are deferred: they need a stack-shaped

// accumulator and `var` reassignment, which lowers to a dead store on

// Erlang's immutable runtime (the same trap `split`/`join` sidestep with

// `filter`/`flatMap`).

function normalize(path) {
    if ((path === "")) { return "."; }
    const isAbs = isAbsolute(path);
    const pieces = split(path).filter((p) => {
    return (p !== ".");
});
    const joined = pieces.join(separator);
    return (() => { if (isAbs) { return [separator, joined].join(""); } else { return (() => { if ((joined === "")) { return "."; } else { return joined; } })(); } })();
}
exports.normalize = normalize;

// Internal: count how many leading components two split paths share. Tail-

// recursive on `i` so the accumulator never needs a `var` rebind (which

// lowers to a dead store on Erlang's immutable runtime).

function commonPrefixCount(a, b, i) {
    if ((i >= a.length)) { return i; }
    if ((i >= b.length)) { return i; }
    const ai = (() => { const __bp_nullish = __bp_array_at(a, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    const bi = (() => { const __bp_nullish = __bp_array_at(b, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    return (() => { if (__bp_eq(ai, bi, 0)) { return commonPrefixCount(a, b, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/path.bp:114:52")); } else { return i; } })();
}

// Internal: build an array of `n` ".." strings via head/tail recursion.

// Avoids a `var` + `push` accumulator (the Erlang dead-store trap).

function makeUps(n) {
    return (() => { if ((n <= 0)) { return []; } else { return makeUps(__bp_int((n - 1), -2147483648, 2147483647, "- on i32 at src/path.bp:120:42")).prepend(".."); } })();
}

// The relative path from `src` to `dst` — the path you would prefix to

// `src` to reach `dst`. Both inputs are treated structurally (no `cwd()`

// fallback — that belongs in `process` once it lands). Returns "." when

// the paths point at the same location.

// 

// `src` is named `src` rather than `from` because `from` is a reserved

// keyword (the `import { … } from "<lib>"` syntax) — it does not parse

// as a parameter name.

function relative(src, dst) {
    const srcParts = split(src);
    const dstParts = split(dst);
    const common = commonPrefixCount(srcParts, dstParts, 0);
    const ups = makeUps(__bp_int((srcParts.length - common), -2147483648, 2147483647, "- on i32 at src/path.bp:135:39"));
    const downs = dstParts.slice(common, dstParts.length);
    const combined = ups.concat(downs);
    const joined = combined.join(separator);
    return (() => { if ((joined === "")) { return "."; } else { return joined; } })();
}
exports.relative = relative;

// Internal accumulator for `resolve`: a list of normalised path parts

// plus whether the resolved-so-far path is absolute. The record carries

// the state through the tail-recursive `resolveAll` so no `var` is

// needed.

class PathAccum {
    constructor(isAbs, parts) {
        this.isAbs = isAbs;
        this.parts = parts;
    }
}
PathAccum.prototype.__bp = "PathAccum";

// Internal: apply each component of one segment (post-split) to the

// accumulator, popping for `..` and appending the rest. Head/tail

// recursive — no `var` rebinds.

function applyPieces(acc, pieces) {
    while (true) {
        if ((pieces.length === 0)) { return acc; }
        const p = (() => { const __bp_nullish = __bp_array_at(pieces, 0); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
        const rest = pieces.slice(1, pieces.length);
        const nextAcc = (() => { if ((p === "..")) { return (() => { if ((acc.length === 0)) { return acc; } else { return acc.slice(0, __bp_int((acc.length - 1), -2147483648, 2147483647, "- on i32 at src/path.bp:159:63")); } })(); } else { return acc.concat([p]); } })();
        { acc = nextAcc; pieces = rest; continue; }
    }
}

function resolveStep(state, seg) {
    const pieces = split(seg);
    const nextIsAbs = (isAbsolute(seg) || state.isAbs);
    const baseParts = (() => { if (isAbsolute(seg)) { return []; } else { return state.parts; } })();
    return new PathAccum(nextIsAbs, applyPieces(baseParts, pieces));
}

function resolveAll(segments, i, state) {
    while (true) {
        if ((i >= segments.length)) { return state; }
        const seg = (() => { const __bp_nullish = __bp_array_at(segments, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
        const next = resolveStep(state, seg);
        { const __bp_tc1 = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/path.bp:175:35"); i = __bp_tc1; state = next; continue; }
    }
}

// Resolve a list of path segments into a single normalised path.

// Absolute segments restart the accumulator (matches Node's

// `path.resolve`); `..` pops one component; `.` drops out (already

// filtered by `split`). The empty input resolves to ".".

function resolve(segments) {
    const finalState = resolveAll(segments, 0, new PathAccum(false, []));
    const joined = finalState.parts.join(separator);
    return (() => { if (finalState.isAbs) { return [separator, joined].join(""); } else { return (() => { if ((joined === "")) { return "."; } else { return joined; } })(); } })();
}
exports.resolve = resolve;

// ── 1.0.10-beta front 01 additions ───────────────────────────────────────────

// `p` without its trailing extension: `page.bp` → `page`, `archive.tar.gz`

// → `archive.tar`, `noext` → `noext`. The extension is what `extname`

// answers, so a dotfile keeps its name.

function withoutExtension(p) {
    let p$sp = null;
    const ext = extname(p);
    let ext$sp = null;
    const n = ((p$sp ??= __bp_has_surrogate(p)) ? __bp_str_length(p) : p.length);
    const stem = (() => { if ((ext === "")) { return p; } else { return p.slice(0, __bp_int((n - ((ext$sp ??= __bp_has_surrogate(ext)) ? __bp_str_length(ext) : ext.length)), -2147483648, 2147483647, "- on i32 at src/path.bp:205:51")); } })();
    return stem;
}
exports.withoutExtension = withoutExtension;

// True when `child` resolves inside `parent` — the traversal guard front 22

// applies before it turns a request path into a file path. Both sides go

// through `resolve`, which pops `..` (`normalize` does not), and a relative

// `child` is resolved against `parent`, so `isInside("/app", "blog/x")` is

// true and `isInside("/app", "blog/../../etc")` is false. A parent is inside

// itself. The check reads the first component of the relative path: `..`

// exactly, or `../…` — a component that merely starts with two dots

// (`..foo`) is a name, not an escape.

function isInside(parent, child) {
    const up = resolve([parent]);
    const down = resolve([parent, child]);
    const rel = relative(up, down);
    const escapes = ((rel === "..") || rel.startsWith("../"));
    return (escapes === false);
}
exports.isInside = isInside;

// ── tests ────────────────────────────────────────────────────────────────────

Object.defineProperty(exports, "__bp_priv__", { value: { separator, delimiter, split, isAbsolute, basename, dirname, extname, join, normalize, commonPrefixCount, makeUps, relative, PathAccum, applyPieces, resolveStep, resolveAll, resolve, withoutExtension, isInside } });
```

----- TYPESCRIPT TYPEDEF -- std/path.d.ts
```typescript
export declare const separator: string;


export declare const delimiter: string;


export declare function split(path: string): string[];


export declare function isAbsolute(path: string): boolean;


export declare function basename(path: string): string;


export declare function dirname(path: string): string;


export declare function extname(path: string): string;


export declare function join(parts: string[]): string;


export declare function normalize(path: string): string;






export declare function relative(src: string, dst: string): string;










export declare function resolve(segments: string[]): string;


export declare function withoutExtension(p: string): string;


export declare function isInside(parent: string, child: string): boolean;

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
//// Every function that can fail answers `@Result<…, FsError>`: the same OS error is
//// the same `FsError` variant on every target (`ENOENT`, `enoent` → `NotFound`),
//// and `Other.message` is the host's own text. The whole-file shortcuts
//// (`readBytes`, `readText`, `writeBytes`, `writeText`, `appendText`), `stat`, and
//// the directory functions (`exists`, `list`, `mkdir`, `mkdirRecursive`, `rm`,
//// `removeTree`, `copy`, `walk`, `glob`) are followed by the handle: `open`
//// and `create` answer a `File`, a `Closeable` closed by the writer with `defer`.
////
//// The host cells (`raw…`) answer `@Result<R, string>` whose error is
//// `<kind>|<host text>` — `kind` one of `notfound`, `denied`, `isdir`, `notdir`,
//// `exists`, `other` (or `dangling`, a `walk`'s own) — and `lift` turns it into the
//// `FsError` of the path the caller wrote. All operations are synchronous
//// (`*Sync` on Node, blocking BIFs on Erlang); there is no wasm binding here
//// (front 164: `wasi:filesystem` behind `needs: [.Filesystem]`).

import {path.relative};

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
}

pub type FileStat(
    size: i64,
    mtime: i64,
    isDir: bool,
)

// Read the whole file as bytes.
// Node: `readFileSync($0)` copied into a plain `Uint8Array`.
// Erlang: `file:read_file/1`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { return { ok: new Uint8Array(require('fs').readFileSync($0)) } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:read_file(__P) of {ok, __B} -> {ok, __B}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawReadBytes(path: string) -> @Result<Bytes, string>;

// Write `contents` to `path`, creating or truncating.
// Node: `writeFileSync($0, $1)`. Erlang: `file:write_file/2`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').writeFileSync($0, $1); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P, __C) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)($0, $1)""")]
declare fn rawWriteBytes(path: string, contents: Bytes) -> @Result<i32, string>;

// Append `contents` to `path`, creating it when it is not there.
// Node: `appendFileSync($0, $1)`. Erlang: `file:write_file/3` with `append`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').appendFileSync($0, $1); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P, __C) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:write_file(__P, __C, [append]) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)($0, $1)""")]
declare fn rawAppendText(path: string, contents: string) -> @Result<i32, string>;

// The offset of the first byte that starts a sequence that is not UTF-8 (a byte no sequence
// starts with, a sequence cut short, an overlong form, a surrogate, a code point past U+10FFFF),
// or -1 when every byte is part of a valid sequence — the same offset on every target.
// Node: a scan of the bytes. Erlang: `unicode:characters_to_binary/3`, whose `Good` prefix is the offset.
#[@External.Node("""((__b) => { const __n = __b.length; let __i = 0; while (__i < __n) { const __c = __b[__i]; if (__c < 128) { __i++; continue } let __k; if (__c >= 194 && __c <= 223) __k = 1; else if (__c >= 224 && __c <= 239) __k = 2; else if (__c >= 240 && __c <= 244) __k = 3; else return __i; if (__i + __k >= __n) return __i; let __lo = 128, __hi = 191; if (__c === 224) __lo = 160; else if (__c === 237) __hi = 159; else if (__c === 240) __lo = 144; else if (__c === 244) __hi = 143; const __d = __b[__i + 1]; if (__d < __lo || __d > __hi) return __i; for (let __j = 2; __j <= __k; __j++) { const __e = __b[__i + __j]; if (__e < 128 || __e > 191) return __i } __i += __k + 1 } return -1 })($0)""")]
#[@External.Erlang("""(fun(__B) -> case unicode:characters_to_binary(__B, utf8, utf8) of __S when is_binary(__S) -> -1; {error, __G, _} -> byte_size(__G); {incomplete, __G, _} -> byte_size(__G) end end)($0)""")]
declare fn utf8Offset(bytes: Bytes) -> i64;

// `line` without its line terminator: one trailing `\n`, and the `\r` before it.
// Node: `subarray`. Erlang: `binary:part/3`.
#[@External.Node("""((__b) => { let __n = __b.length; if (__n > 0 && __b[__n - 1] === 10) { __n--; if (__n > 0 && __b[__n - 1] === 13) __n-- } return __b.subarray(0, __n) })($0)""")]
#[@External.Erlang("""(fun(__B) -> __N = byte_size(__B), if __N >= 2 -> case binary:part(__B, __N - 2, 2) of <<13, 10>> -> binary:part(__B, 0, __N - 2); <<_, 10>> -> binary:part(__B, 0, __N - 1); _ -> __B end; __N =:= 1 -> case __B of <<10>> -> <<>>; _ -> __B end; true -> __B end end)($0)""")]
declare fn stripEol(line: Bytes) -> Bytes;

// The handle of the file at `path`, open for reading. A directory is `isdir` on both hosts
// (Node opens one; the template refuses it). The handle is host-owned and opaque: a
// `{ fd, mem, pos, buf }` object on Node, the raw file descriptor on Erlang.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __fs = require('fs'); const __p = $0; const __fd = __fs.openSync(__p, 'r'); if (__fs.fstatSync(__fd).isDirectory()) { __fs.closeSync(__fd); return { error: 'isdir|EISDIR: illegal operation on a directory, open ' + JSON.stringify(__p) } } return { ok: { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:open(__P, [read, binary, raw, read_ahead]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawOpen(path: string) -> @Result<unknown, string>;

// The handle of the file at `path`, open for writing: created, or truncated.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __fd = require('fs').openSync($0, 'w'); return { ok: { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:open(__P, [write, binary, raw]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawCreate(path: string) -> @Result<unknown, string>;

// A handle over bytes held in memory — what an `Asset` opens as. The position is a field
// on Node and a `counters` cell on Erlang.
#[@External.Node("""({ fd: -1, mem: $0, pos: 0, buf: new Uint8Array(0) })""")]
#[@External.Erlang("""{mem, $0, counters:new(1, [])}""")]
declare fn memHandle(bytes: Bytes) -> unknown;

// The size of the file behind `handle`, in bytes. Erlang's raw descriptor has no `fstat`, so it reads `path`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __h = $0; return { ok: __h.mem ? __h.mem.length : require('fs').fstatSync(__h.fd).size } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__H, __P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, __B, _} -> {ok, byte_size(__B)}; _ -> case file:read_file_info(__P) of {ok, __I} -> {ok, element(2, __I)}; {error, __R} -> {error, __Ek(__R)} end end end)($0, $1)""")]
declare fn rawSize(handle: unknown, path: string) -> @Result<i64, string>;

// Up to `n` bytes (n > 0) from the handle's position; empty at the end.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; try { const __h = $0; const __n = $1; if (__h.buf.length > 0) { const __k = Math.min(__n, __h.buf.length); const __o = new Uint8Array(__h.buf.subarray(0, __k)); __h.buf = __h.buf.subarray(__k); return { ok: __o } } return { ok: new Uint8Array(__more(__h, __n)) } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__H, __N) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Len = min(__N, byte_size(__B) - __Pos), counters:add(__C, 1, __Len), {ok, binary:part(__B, __Pos, __Len)}; _ -> case file:read(__H, __N) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __Ek(__R)} end end end)($0, $1)""")]
declare fn rawRead(handle: unknown, n: i32) -> @Result<Bytes, string>;

// Every byte from the handle's position to the end.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; try { const __h = $0; const __parts = []; if (__h.buf.length > 0) { __parts.push(__h.buf); __h.buf = new Uint8Array(0) } for (;;) { const __r = __more(__h, 65536); if (__r.length === 0) break; __parts.push(new Uint8Array(__r)) } let __t = 0; for (const __x of __parts) __t += __x.length; const __o = new Uint8Array(__t); let __p = 0; for (const __x of __parts) { __o.set(__x, __p); __p += __x.length } return { ok: __o } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__H) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), counters:add(__C, 1, byte_size(__B) - __Pos), {ok, binary:part(__B, __Pos, byte_size(__B) - __Pos)}; _ -> (fun __L(__Acc) -> case file:read(__H, 65536) of {ok, __D} -> __L([__Acc, __D]); eof -> {ok, iolist_to_binary(__Acc)}; {error, __R} -> {error, __Ek(__R)} end end)([]) end end)($0)""")]
declare fn rawReadAll(handle: unknown) -> @Result<Bytes, string>;

// The next line, terminator included; empty at the end.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; try { const __h = $0; for (;;) { const __i = __h.buf.indexOf(10); if (__i >= 0) { const __l = new Uint8Array(__h.buf.subarray(0, __i + 1)); __h.buf = __h.buf.subarray(__i + 1); return { ok: __l } } const __r = __more(__h, 65536); if (__r.length === 0) { const __l = __h.buf; __h.buf = new Uint8Array(0); return { ok: __l } } const __nb = new Uint8Array(__h.buf.length + __r.length); __nb.set(__h.buf, 0); __nb.set(__r, __h.buf.length); __h.buf = __nb } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__H) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Rest = binary:part(__B, __Pos, byte_size(__B) - __Pos), case binary:match(__Rest, <<10>>) of nomatch -> counters:add(__C, 1, byte_size(__Rest)), {ok, __Rest}; {__At, _} -> counters:add(__C, 1, __At + 1), {ok, binary:part(__Rest, 0, __At + 1)} end; _ -> case file:read_line(__H) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __Ek(__R)} end end end)($0)""")]
declare fn rawReadLine(handle: unknown) -> @Result<Bytes, string>;

// The SHA-256 of the whole file behind the handle, lowercase hex — from its first byte,
// whatever the position, which it leaves where it was.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __h = $0; const __hs = require('crypto').createHash('sha256'); if (__h.mem) { __hs.update(__h.mem) } else { const __b = new Uint8Array(65536); let __pos = 0; for (;;) { const __k = require('fs').readSync(__h.fd, __b, 0, 65536, __pos); if (__k === 0) break; __hs.update(__b.subarray(0, __k)); __pos += __k } } return { ok: __hs.digest('hex') } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__H) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, __B, _} -> {ok, string:lowercase(binary:encode_hex(crypto:hash(sha256, __B)))}; _ -> __L = fun __Lp(__Pos, __Ctx) -> case file:pread(__H, __Pos, 65536) of {ok, __D} -> __Lp(__Pos + byte_size(__D), crypto:hash_update(__Ctx, __D)); eof -> crypto:hash_final(__Ctx); {error, __R} -> throw({bp_fs_hash, __R}) end end, try {ok, string:lowercase(binary:encode_hex(__L(0, crypto:hash_init(sha256))))} catch throw:{bp_fs_hash, __Y} -> {error, __Ek(__Y)} end end end)($0)""")]
declare fn rawHash(handle: unknown) -> @Result<string, string>;

// Write `bytes` at the handle's position; answers how many.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __h = $0; const __b = $1; if (__h.mem) return { error: 'other|the file is open for reading' }; let __o = 0; while (__o < __b.length) __o += require('fs').writeSync(__h.fd, __b, __o, __b.length - __o); return { ok: __b.length } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__H, __B) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, _, _} -> {error, <<"other|the file is open for reading">>}; _ -> case file:write(__H, __B) of ok -> {ok, byte_size(__B)}; {error, __R} -> {error, __Ek(__R)} end end end)($0, $1)""")]
declare fn rawWrite(handle: unknown, bytes: Bytes) -> @Result<i32, string>;

// Close the handle. A failure to close is not reported (a `Closeable`'s `close` answers nothing).
#[@External.Node("""(() => { try { const __h = $0; if (!__h.mem) require('fs').closeSync(__h.fd) } catch (__e) {} })()""")]
#[@External.Erlang("""(fun(__H) -> case __H of {mem, _, _} -> ok; _ -> _ = file:close(__H), ok end end)($0)""")]
declare fn rawClose(handle: unknown) -> void;

// Write `contents` to `path`, creating or truncating. Reds with the
// host's I/O error message.
// Node: `require('fs').writeFileSync($0, $1)`.
// Erlang: `file:write_file/2`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').writeFileSync($0, $1); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P, __C) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)($0, $1)""")]
declare fn rawWriteText(
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
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { return { ok: require('fs').readdirSync($0) } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:list_dir(__P) of {ok, __L} -> {ok, [list_to_binary(__N) || __N <- __L]}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawList(path: string) -> @Result<string[], string>;

// Create directory at `path`. Use `mkdirRecursive` to create
// intermediate parents.
// Node: `require('fs').mkdirSync($0)`.
// Erlang: `file:make_dir/1`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').mkdirSync($0); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:make_dir(__P) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawMkdir(path: string) -> @Result<i32, string>;

// Create the directory at `path` and every missing directory above it. A
// directory that is already there is `Ok` too; a path that exists as anything
// else (a file) is an `Error`. What the snapshot library (`snap`) makes the
// directory of a `.snap` with (decision 391).
// Node: `require('fs').mkdirSync($0, { recursive: true })`.
// Erlang: `filelib:ensure_path/1`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').mkdirSync($0, { recursive: true }); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case filelib:ensure_path(__P) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawMkdirRecursive(path: string) -> @Result<i32, string>;

// Delete the FILE at `path`. A directory — empty or not — is `IsDirectory` on
// both hosts (Node's `ERR_FS_EISDIR`; Erlang's `eperm` is read as `eisdir` after
// a `read_link_info`, so the variant is the same); `removeTree` removes one.
// Node: `require('fs').rmSync($0)`.
// Erlang: `file:delete/1`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').rmSync($0); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:read_link_info(__P) of {ok, __I} when element(3, __I) =:= directory -> {error, __Ek(eisdir)}; _ -> case file:delete(__P) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end end)($0)""")]
declare fn rawRm(path: string) -> @Result<i32, string>;

// Copy file from `src` to `dest`. Reds when `src` is missing or
// `dest` already exists (Node's default `copyFileSync` semantics).
// Node: `require('fs').copyFileSync($0, $1)`.
// Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').copyFileSync($0, $1); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__S, __D) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:copy(__S, __D) of {ok, _} -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)($0, $1)""")]
declare fn rawCopy(src: string, dest: string) -> @Result<i32, string>;

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
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __s = require('fs').statSync($0, { bigint: true }); const __c = (__v) => (__v >= -9007199254740991n && __v <= 9007199254740991n) ? Number(__v) : __v; const __ns = __s.mtimeNs; return { ok: { size: __c(__s.size), mtime: __c(((__ns - (((__ns % 1000000000n) + 1000000000n) % 1000000000n)) / 1000000000n) * 1000n), isDir: __s.isDirectory() } } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:read_file_info(__P, [{time, posix}]) of {ok, {file_info, __Sz, __Ty, _, _, __Mt, _, _, _, _, _, _, _, _}} -> {ok, #{size => __Sz, mtime => __Mt * 1000, isDir => (__Ty =:= directory)}}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawStat(path: string) -> @Result<FileStat, string>;

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
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __fs = require('fs'); const __p = require('path'); const __all = __fs.readdirSync($0, { recursive: true }).map(__f => String(__f).split(__p.sep).join('/')).sort(); const __out = []; for (const __f of __all) { const __s = __fs.statSync(__p.join($0, __f), { throwIfNoEntry: false }); if (__s === undefined) return { error: 'dangling|fs.walk: dangling link "' + __f + '"' }; if (__s.isFile()) __out.push(__f) } return { ok: __out } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__R) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, __Root = unicode:characters_to_list(__R), case filelib:is_dir(__Root) of false -> {error, __Ek(case file:read_file_info(__Root) of {ok, _} -> enotdir; {error, __X0} -> __X0 end)}; true -> __Walk = fun __W(__Dir, __Rel, __Acc) -> case file:list_dir(__Dir) of {error, __E} -> throw({bp_fs_walk, __E}); {ok, __Names} -> lists:foldl(fun(__Name, __A) -> __Full = filename:join(__Dir, __Name), __Sub = case __Rel of [] -> __Name; _ -> __Rel ++ "/" ++ __Name end, case file:read_file_info(__Full) of {ok, __I} when element(3, __I) =:= directory -> __W(__Full, __Sub, __A); {ok, __I} when element(3, __I) =:= regular -> [{file, unicode:characters_to_binary(__Sub)} | __A]; {ok, _} -> __A; {error, enoent} -> [{dangling, unicode:characters_to_binary(__Sub)} | __A]; {error, __X} -> throw({bp_fs_walk, __X}) end end, __Acc, __Names) end end, try __Found = __Walk(__Root, [], []), case lists:sort([__D || {dangling, __D} <- __Found]) of [__First | _] -> {error, <<"dangling|fs.walk: dangling link ", 34, __First/binary, 34>>}; [] -> {ok, lists:sort([__F || {file, __F} <- __Found])} end catch throw:{bp_fs_walk, __Y} -> {error, __Ek(__Y)} end end end)($0)""")]
declare fn rawWalk(root: string) -> @Result<string[], string>;

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
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __fs = require('fs'); const __p = require('path'); const __root = $1; const __pat = String($0); const __segs = __pat.split('/').filter(__s => __s !== '' && __s !== '.'); const __dirsOnly = __pat.endsWith('/'); const __lst = (__f) => { try { return __fs.lstatSync(__f, { throwIfNoEntry: false }) } catch (__e) { return undefined } }; const __realDir = (__f) => { const __s = __lst(__f); return __s !== undefined && __s.isDirectory() }; const __linkedDir = (__f) => { try { const __s = __fs.statSync(__f, { throwIfNoEntry: false }); return __s !== undefined && __s.isDirectory() } catch (__e) { return false } }; const __magic = (__s) => __s.includes('*') || __s.includes('?') || __s.includes('[') || __s.includes('{'); const __names = (__dir, __seg) => { let __all; try { __all = (__seg === '*' ? __fs.readdirSync(__dir) : __fs.globSync(__seg, { cwd: __dir })).map(String) } catch (__e) { __all = [] } return __all.filter(__n => !__n.startsWith('.') || __seg.startsWith('.')) }; const __join = (__rel, __n) => __rel === '' ? __n : __rel + '/' + __n; const __out = new Set(); const __walk = (__i, __dir, __rel) => { if (__i === __segs.length) { if (__rel !== '') __out.add(__rel); return } const __seg = __segs[__i]; const __last = __i === __segs.length - 1; if (__seg === '**') { if (!__last) __walk(__i + 1, __dir, __rel); for (const __n of __names(__dir, '*')) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); if (__realDir(__f)) __walk(__i, __f, __sub) } return } if (!__magic(__seg)) { const __f = __p.join(__dir, __seg); const __sub = __join(__rel, __seg); if (__last) { if (__lst(__f) !== undefined) __out.add(__sub) } else if (__linkedDir(__f)) __walk(__i + 1, __f, __sub); return } for (const __n of __names(__dir, __seg)) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); else if (__realDir(__f)) __walk(__i + 1, __f, __sub) } }; __walk(0, __root, ''); return { ok: Array.from(__out).filter(__r => !__dirsOnly || __realDir(__p.join(__root, __r))).sort() } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P, __R) -> __Root = unicode:characters_to_list(__R), __Pat = unicode:characters_to_list(__P), __Segs = [__S || __S <- string:split(__Pat, "/", all), __S =/= [], __S =/= "."], __DirsOnly = lists:suffix("/", __Pat), __RealDir = fun(__F) -> case file:read_link_info(__F) of {ok, __I} -> element(3, __I) =:= directory; _ -> false end end, __Magic = fun(__S) -> lists:any(fun(__C) -> lists:member(__C, "*?[{") end, __S) end, __Names = fun(__Dir, __Seg) -> __All = case __Seg of "*" -> case file:list_dir(__Dir) of {ok, __L} -> __L; _ -> [] end; _ -> try filelib:wildcard(__Seg, __Dir) catch _:_ -> [] end end, [__N || __N <- __All, (hd(__N) =/= 46) orelse (hd(__Seg) =:= 46)] end, __Join = fun([], __N) -> __N; (__Rel, __N) -> __Rel ++ "/" ++ __N end, __Walk = fun __W([], _, [], __Acc) -> __Acc; __W([], _, __Rel, __Acc) -> [__Rel | __Acc]; __W(["**"], __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), __Sub = __Join(__Rel, __N), case __RealDir(__F) of true -> __W(["**"], __F, __Sub, [__Sub | __A]); false -> [__Sub | __A] end end, __Acc, __Names(__Dir, "*")); __W(["**" | __Rest] = __Pattern, __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), case __RealDir(__F) of true -> __W(__Pattern, __F, __Join(__Rel, __N), __A); false -> __A end end, __W(__Rest, __Dir, __Rel, __Acc), __Names(__Dir, "*")); __W([__Seg | __Rest], __Dir, __Rel, __Acc) -> case __Magic(__Seg) of false -> __F = filename:join(__Dir, __Seg), __Sub = __Join(__Rel, __Seg), case __Rest of [] -> case file:read_link_info(__F) of {ok, _} -> [__Sub | __Acc]; _ -> __Acc end; _ -> case filelib:is_dir(__F) of true -> __W(__Rest, __F, __Sub, __Acc); false -> __Acc end end; true -> lists:foldl(fun(__N, __A) -> __G = filename:join(__Dir, __N), __Under = __Join(__Rel, __N), case __Rest of [] -> [__Under | __A]; _ -> case __RealDir(__G) of true -> __W(__Rest, __G, __Under, __A); false -> __A end end end, __Acc, __Names(__Dir, __Seg)) end end, {ok, [unicode:characters_to_binary(__X) || __X <- lists:usort(__Walk(__Segs, __Root, [], [])), (not __DirsOnly) orelse __RealDir(filename:join(__Root, __X))]} end)($0, $1)""")]
declare fn rawGlob(pattern: string, root: string) -> @Result<string[], string>;

// Remove `path` and everything under it: a file, a link (the link, never its
// target) or a directory tree. A path that is not there is `Ok` too — the
// caller wanted it gone. What a test fixture is cleared with, and what the
// snapshot engine's tests clear their scratch directories with (1.0.11-beta
// front 97).
// Node: `rmSync(path, { recursive: true, force: true })`.
// Erlang: `file:del_dir_r/1`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').rmSync($0, { recursive: true, force: true }); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:del_dir_r(__P) of ok -> {ok, 0}; {error, enoent} -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawRemoveTree(path: string) -> @Result<i32, string>;

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

// ── the typed error ──────────────────────────────────────────────────────────

// `<kind>|<host text>` → the `FsError` of `path`.
fn fsError(path: string, raw: string) -> FsError {
    val bar = raw.indexOf("|");
    val kind = raw.slice(0, bar);
    val message = raw.slice(bar + 1);
    if (kind == "notfound") return FsError.NotFound(path: path);
    if (kind == "denied") return FsError.PermissionDenied(path: path);
    if (kind == "isdir") return FsError.IsDirectory(path: path);
    if (kind == "notdir") return FsError.NotDirectory(path: path);
    if (kind == "exists") return FsError.AlreadyExists(path: path);
    return FsError.Other(path: path, message: message);
}

// A host cell's answer, its error read as an `FsError` of `path`.
fn lift<T>(path: string, r: @Result<T, string>) -> @Result<T, FsError> {
    case r {
        Ok(v) -> return v;
        Error(m) -> throw fsError(path, m);
    }
}

// The text of `b`, or `InvalidUtf8` at the first invalid byte.
fn decode(path: string, b: Bytes) -> @Result<string, FsError> {
    val offset = utf8Offset(b);
    if (offset >= 0l) throw FsError.InvalidUtf8(path: path, offset: offset);
    return b.toUtf8().unwrapOr("");
}

// ── whole-file shortcuts ─────────────────────────────────────────────────────

// The file's bytes.
pub fn readBytes(path: string) -> @Result<Bytes, FsError> {
    val b = try lift(path, rawReadBytes(path));
    return b;
}

// The file as UTF-8 text. Bytes that are not UTF-8 are `InvalidUtf8` on every
// target — never node's silent U+FFFD nor erlang's unchecked binary.
pub fn readText(path: string) -> @Result<string, FsError> {
    val b = try readBytes(path);
    val s = try decode(path, b);
    return s;
}

// Write `contents` to `path`, creating or truncating.
pub fn writeBytes(path: string, contents: Bytes) -> @Result<i32, FsError> {
    val n = try lift(path, rawWriteBytes(path, contents));
    return n;
}

pub fn writeText(path: string, contents: string) -> @Result<i32, FsError> {
    val n = try lift(path, rawWriteText(path, contents));
    return n;
}

// Append `contents`, creating the file when it is not there.
pub fn appendText(path: string, contents: string) -> @Result<i32, FsError> {
    val n = try lift(path, rawAppendText(path, contents));
    return n;
}

// ── metadata and directories ─────────────────────────────────────────────────

pub fn stat(path: string) -> @Result<FileStat, FsError> {
    val s = try lift(path, rawStat(path));
    return s;
}

pub fn list(path: string) -> @Result<string[], FsError> {
    val names = try lift(path, rawList(path));
    return names;
}

pub fn mkdir(path: string) -> @Result<i32, FsError> {
    val n = try lift(path, rawMkdir(path));
    return n;
}

pub fn mkdirRecursive(path: string) -> @Result<i32, FsError> {
    val n = try lift(path, rawMkdirRecursive(path));
    return n;
}

pub fn rm(path: string) -> @Result<i32, FsError> {
    val n = try lift(path, rawRm(path));
    return n;
}

pub fn removeTree(path: string) -> @Result<i32, FsError> {
    val n = try lift(path, rawRemoveTree(path));
    return n;
}

pub fn copy(src: string, dest: string) -> @Result<i32, FsError> {
    val n = try lift(src, rawCopy(src, dest));
    return n;
}

pub fn walk(root: string) -> @Result<string[], FsError> {
    val paths = try lift(root, rawWalk(root));
    return paths;
}

pub fn glob(pattern: string, root: string) -> @Result<string[], FsError> {
    val paths = try lift(root, rawGlob(pattern, root));
    return paths;
}

// The host's handle over embedded bytes: read like a file, never closed on disk.
#[@External.Node("""({ fd: -1, mem: $0, pos: 0, buf: new Uint8Array(0) })""")]
#[@External.Erlang("""{mem, $0, counters:new(1, [])}""")]
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
    pub fn size(self: Self) -> @Result<i64, FsError> {
        val n = try lift(self.location, rawSize(self.handle, self.location));
        return n;
    }

    // Up to `n` bytes from the position; empty at the end of the file.
    pub fn read(self: Self, n: i32) -> @Result<Bytes, FsError> {
        if (n <= 0) return Bytes.fromUtf8("");
        val b = try lift(self.location, rawRead(self.handle, n));
        return b;
    }

    // Every byte from the position to the end.
    pub fn bytes(self: Self) -> @Result<Bytes, FsError> {
        val b = try lift(self.location, rawReadAll(self.handle));
        return b;
    }

    // The rest of the file as UTF-8 text (`InvalidUtf8` otherwise).
    pub fn text(self: Self) -> @Result<string, FsError> {
        val b = try self.bytes();
        val s = try decode(self.location, b);
        return s;
    }

    // The rest of the file in pieces of at most `size` bytes. An error ends the stream.
    pub fn chunks(self: Self, size: i32 = 65536) -> @Stream<@Result<Bytes, FsError>> {
        while (true) {
            val b = try self.read(size);
            if (b.length == 0) break;
            yield b;
        }
    }

    // The rest of the file line by line, `\n` and `\r\n` stripped. A line that is not
    // UTF-8 ends the stream with `InvalidUtf8`, its offset counted from the first
    // line this call read.
    pub fn lines(self: Self) -> @Stream<@Result<string, FsError>> {
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
    pub fn hash(self: Self) -> @Result<string, FsError> {
        val h = try lift(self.location, rawHash(self.handle));
        return h;
    }

    // Write `b` at the position; answers the number of bytes written.
    pub fn write(self: Self, b: Bytes) -> @Result<i32, FsError> {
        val n = try lift(self.location, rawWrite(self.handle, b));
        return n;
    }

    // Close the file. Closing twice is harmless; a failure to close is not reported.
    pub fn close(self: Self) {
        rawClose(self.handle);
    }
}

// Open the file at `path` for reading. A directory is `IsDirectory` on every target.
pub fn open(path: string) -> @Result<File, FsError> {
    val h = try lift(path, rawOpen(path));
    return File(location: path, handle: h);
}

// Open the file at `path` for writing: created, or truncated.
pub fn create(path: string) -> @Result<File, FsError> {
    val h = try lift(path, rawCreate(path));
    return File(location: path, handle: h);
}

// An `Asset` (`@embed`, decisions 519, 538) as a `File`: the embedded bytes, read
// like a file on disk — no `@Result`, the build proved the file exists — and
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
fn variantOf<T>(r: @Result<T, FsError>) -> string {
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
#[@External.Node("""(() => { require('fs').chmodSync($0, 0); return typeof process.getuid === 'function' ? process.getuid() !== 0 : false })()""")]
#[@External.Erlang("""(fun(__P) -> ok = file:change_mode(__P, 0), string:trim(os:cmd("id -u")) =/= "0" end)($0)""")]
declare fn denyAll(path: string) -> bool;

#[@External.Node("""require('fs').chmodSync($0, 0o700)""")]
#[@External.Erlang("""(fun(__P) -> ok = file:change_mode(__P, 8#700), ok end)($0)""")]
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

----- JAVASCRIPT -- std/io/fs.js
```javascript
const __bp_surrogate = /[\uD800-\uDFFF]/;
const __bp_surrogate_k = new Array(64).fill("");
const __bp_surrogate_v = new Array(64).fill(false);
const __bp_surrogate_k2 = new Array(64).fill("");
const __bp_surrogate_v2 = new Array(64).fill(false);
function __bp_has_surrogate(s) {
    const h = s.length & 63;
    if (__bp_surrogate_k[h] === s) { return __bp_surrogate_v[h]; }
    if (__bp_surrogate_k2[h] === s) { return __bp_surrogate_v2[h]; }
    const p = __bp_surrogate.test(s);
    __bp_surrogate_k2[h] = __bp_surrogate_k[h];
    __bp_surrogate_v2[h] = __bp_surrogate_v[h];
    __bp_surrogate_k[h] = s;
    __bp_surrogate_v[h] = p;
    return p;
}

function __bp_str_count(s, u) {
    let n = 0;
    for (const c of s.substring(0, u)) { n += 1; }
    return n;
}

function __bp_str_index_of(s, sub) {
    const u = s.indexOf(sub);
    return (u <= 0 || !__bp_has_surrogate(s)) ? u : __bp_str_count(s, u);
}

function __bp_f64(v) {
    if (Number.isNaN(v)) { return "NaN"; }
    if (!Number.isFinite(v)) { return (v < 0) ? "-Infinity" : "Infinity"; }
    if (v === 0) { return Object.is(v, -0) ? "-0.0" : "0.0"; }
    const t = Math.abs(v).toExponential();
    const i = t.indexOf("e");
    const d = t.slice(0, i).replace(".", "");
    const e = Number(t.slice(i + 1));
    const g = (v < 0) ? "-" : "";
    const x = g + d[0] + "." + ((d.length > 1) ? d.slice(1) : "0") + "e" + e;
    const p = e + 1;
    const f = g + ((p <= 0) ? "0." + "0".repeat(-p) + d : (p >= d.length) ? d + "0".repeat(p - d.length) + ".0" : d.slice(0, p) + "." + d.slice(p));
    return ((f.length <= x.length) && (Math.abs(v) < 9007199254740992)) ? f : x;
}

function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if ((typeof v === "bigint")) {
        a.push(String(v));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(__bp_f64(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if ((((typeof v === "object") && (v != null)) && (typeof v.__bp !== "string"))) {
        const k = Object.keys(v);
        if (((k.length === 1) && ((k[0] === "ok") || (k[0] === "error")))) {
            return ((((k[0] === "ok") ? "Ok(" : "Error(") + __bp_show(v[k[0]], null, false, a)) + ")");
        }
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof Object.getPrototypeOf(v).tag === "string") ? ((v.__bp + ".") + Object.getPrototypeOf(v).tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], v.__bp_s?.[n], false, a))).join(", ")) + ")")));
    }
    if ((v === undefined)) return "null";
    a.push(v);
    return "%O";
}

function __bp_text(v, s) {
    const a = [];
    let i = 0;
    return __bp_show(v, s == null ? null : s, true, a).replace(/%[sO]/g, () => String(a[i++]));
}

function __bp_adopt(v, C, p) { return (v == null) ? v : (p === "") ? ((typeof v === "object" && !(v instanceof C)) ? Object.assign(Object.create(C.prototype), v) : v) : (p[0] === "a") ? (Array.isArray(v) ? v.map((e) => __bp_adopt(e, C, p.slice(1))) : v) : (p[0] === "r" && typeof v === "object" && "ok" in v) ? { ok: __bp_adopt(v.ok, C, p.slice(1)) } : v; }

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function __bp_wnorm(v, u, what) {
    if (u ? (v < 0n || v > 18446744073709551615n) : (v < -9223372036854775808n || v > 9223372036854775807n)) { throw Object.defineProperty(new Error("integer overflow: " + what), "__bp_panic", { value: true }); }
    return (v >= -9007199254740991n && v <= 9007199254740991n) ? Number(v) : v;
}

function __bp_wadd(a, b, u, what) {
    if (typeof a === "number" && typeof b === "number") { const r = a + b + 0; if (Number.isSafeInteger(r) && (r >= 0 || !u)) { return r; } }
    return __bp_wnorm(BigInt(a) + BigInt(b), u, what);
}

// behavior String
//   fn length(...)
//   fn split(...)
//   fn toUpper(...)
//   fn toLower(...)
//   fn contains(...)
//   fn startsWith(...)
//   fn endsWith(...)
//   fn trim(...)
//   fn trimStart(...)
//   fn trimEnd(...)
//   fn replace(...)
//   default fn slice(...)
//   fn at(...)
//   fn indexOf(...)
//   default fn toString(...)
//   fn fromCodepoint(...)
//   fn padStart(...)
//   fn padEnd(...)
//   fn repeat(...)
//   fn replaceAll(...)
//   fn chars(...)
//   fn lines(...)
//   fn words(...)
//   fn normalizeNewlines(...)
//   fn trimTrailingNewlines(...)
//   fn firstDifferingLine(...)
//   fn charCodeAt(...)
//   fn lastIndexOf(...)
//   default fn parseInt(...)
//   default fn parseFloat(...)
String.prototype.slice = function(start, end) {
    const self = this.valueOf();
    if ((end != null)) { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, end); } else { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, start); }
};
String.prototype.chars = function() { return (Array.from(this.valueOf())); };
String.prototype.lines = function() { return this.valueOf().split(/\r?\n/); };
String.prototype.words = function() { return this.valueOf().split(/[ \t\n\r]+/).filter(__w => __w.length > 0); };
String.prototype.normalizeNewlines = function() { return this.valueOf().replaceAll("\r\n", "\n"); };
String.prototype.trimTrailingNewlines = function() { return this.valueOf().replace(/\n+$/, ""); };
String.prototype.firstDifferingLine = function(other) { return ((__a, __b) => { const __x = __a.split("\n"), __y = __b.split("\n"); let __i = 0; while (__i < __x.length && __i < __y.length && __x[__i] === __y[__i]) __i++; return (__i === __x.length && __i === __y.length) ? 0 : __i + 1 })(this.valueOf(), other); };
String.prototype.charCodeAt = function(index) { return ((__s, __i) => { if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = __i >= 0 ? Array.from(__s)[__i] : undefined; return __c === undefined ? -1 : __c.codePointAt(0); } return (__s.codePointAt(__i) ?? -1) | 0; })(this.valueOf(), index); };
String.prototype.parseInt = function() {
    const self = this.valueOf();
    const signed = (self.startsWith("-") || self.startsWith("+"));
    const digits = (() => { if (signed) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, 1); } else { return self; } })();
    return (() => { if ((/^[0-9]+$/.test(digits))) { return ((__s) => { const __n = BigInt(__s); return (__n >= -9223372036854775808n && __n <= 9223372036854775807n) ? { ok: (__n >= -9007199254740991n && __n <= 9007199254740991n) ? Number(__n) : __n } : { error: 'parseInt: "' + __s + '" is out of range' } })(self); } else { return ({ error: "parseInt: \"" + self + "\" is not an integer" }); } })();
};
String.prototype.parseFloat = function() {
    const self = this.valueOf();
    const signed = (self.startsWith("-") || self.startsWith("+"));
    const start = (() => { if (signed) { return 1; } else { return 0; } })();
    const lowerAt = __bp_str_index_of(self, "e");
    const exponentAt = (() => { if ((lowerAt < 0)) { return __bp_str_index_of(self, "E"); } else { return lowerAt; } })();
    const mantissa = (() => { if ((exponentAt < 0)) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, start); } else { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, exponentAt); } })();
    const pointAt = __bp_str_index_of(self, ".");
    const pointed = ((pointAt >= 0) && (((exponentAt < 0) || (pointAt < exponentAt))));
    const whole = (() => { if (pointed) { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, pointAt); } else { return mantissa; } })();
    const fraction = (() => { if ((pointed === false)) { return "0"; } else { return (() => { if ((exponentAt < 0)) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, (pointAt + 1)); } else { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, (pointAt + 1), exponentAt); } })(); } })();
    const exponent = (() => { if ((exponentAt < 0)) { return "0"; } else { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, (exponentAt + 1)); } })();
    const exponentMark = (() => { if ((exponentAt < 0)) { return ""; } else { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, (exponentAt + 1), (exponentAt + 2)); } })();
    const exponentSigned = ((exponentMark === "-") || (exponentMark === "+"));
    const exponentDigits = (() => { if (exponentSigned) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, (exponentAt + 2)); } else { return exponent; } })();
    const wellFormed = (((/^[0-9]+$/.test(whole)) && (/^[0-9]+$/.test(fraction))) && (/^[0-9]+$/.test(exponentDigits)));
    return (() => { if (wellFormed) { return ((__t, __w, __f, __x) => { const __n = Number((__t.startsWith('-') ? '-' : '') + __w + '.' + __f + 'e' + __x); return Number.isFinite(__n) ? { ok: __n } : { error: 'parseFloat: "' + __t + '" overflows f64' } })(self, whole, fraction, exponent); } else { return ({ error: "parseFloat: \"" + self + "\" is not a number" }); } })();
};

// behavior Bytes
//   fn fromUtf8(...)
//   fn toUtf8(...)
//   fn length(...)
//   fn concat(...)
//   default fn slice(...)
Uint8Array.prototype.toUtf8 = function() { return ((__b) => { try { return { ok: new TextDecoder("utf-8", { fatal: true, ignoreBOM: true }).decode(__b) }; } catch (__e) { return { error: "Bytes.toUtf8: not valid UTF-8" }; } })(this); };
Uint8Array.prototype.concat = function(other) { return ((__a, __b) => { const __r = new Uint8Array(__a.length + __b.length); __r.set(__a, 0); __r.set(__b, __a.length); return __r; })(this, other); };
Uint8Array.prototype.slice = function(start, end) {
    if ((end != null)) { return ((__b, __a, __e) => { if (__a == null) __a = 0; const __n = __b.length; const __s = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return new Uint8Array(__b.subarray(__s, Math.max(__s, __f))); })(this, start, end); } else { return ((__b, __a) => { if (__a == null) __a = 0; const __n = __b.length; const __s = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return new Uint8Array(__b.subarray(__s, __n)); })(this, start); }
};

// behavior Bool
//   fn toString(...)
//   default fn negate(...)
//   default fn nor(...)
//   default fn nand(...)
//   default fn exclusiveOr(...)
//   default fn exclusiveNor(...)
Boolean.prototype.negate = function() {
    const self = this.valueOf();
    return (!self);
};
Boolean.prototype.nor = function(other) {
    const self = this.valueOf();
    return (!((self || other)));
};
Boolean.prototype.nand = function(other) {
    const self = this.valueOf();
    return (!((self && other)));
};
Boolean.prototype.exclusiveOr = function(other) {
    const self = this.valueOf();
    return (self !== other);
};
Boolean.prototype.exclusiveNor = function(other) {
    const self = this.valueOf();
    return (self === other);
};

// behavior Integer extends Number
//   fn toString(...)
//   default fn isEven(...)
//   default fn isOdd(...)
//   fn toI32(...)
//   fn toI64(...)
//   fn toU32(...)
//   fn toU64(...)
//   fn toF64(...)
BigInt.prototype.isEven = Number.prototype.isEven = function() { return ((__a) => typeof __a === "bigint" ? __a % 2n === 0n : __a % 2 === 0)(this.valueOf()); };
BigInt.prototype.isOdd = Number.prototype.isOdd = function() { return ((__a) => typeof __a === "bigint" ? __a % 2n !== 0n : __a % 2 !== 0)(this.valueOf()); };
BigInt.prototype.toI32 = Number.prototype.toI32 = function() { return ((__v) => { if (__v >= -2147483648 && __v <= 2147483647) { return Number(__v); } throw new Error("integer overflow: toI32: " + __v + " does not fit i32"); })(this.valueOf()); };
BigInt.prototype.toI64 = Number.prototype.toI64 = function() { return ((__v) => { if (__v >= -9223372036854775808n && __v <= 9223372036854775807n) { return (__v >= -9007199254740991n && __v <= 9007199254740991n) ? Number(__v) : __v; } throw new Error("integer overflow: toI64: " + __v + " does not fit i64"); })(this.valueOf()); };
BigInt.prototype.toU32 = Number.prototype.toU32 = function() { return ((__v) => { if (__v >= 0 && __v <= 4294967295) { return Number(__v); } throw new Error("integer overflow: toU32: " + __v + " does not fit u32"); })(this.valueOf()); };
BigInt.prototype.toU64 = Number.prototype.toU64 = function() { return ((__v) => { if (__v >= 0 && __v <= 18446744073709551615n) { return __v; } throw new Error("integer overflow: toU64: " + __v + " does not fit u64"); })(this.valueOf()); };
BigInt.prototype.toF64 = Number.prototype.toF64 = function() { return ((__v) => { const __f = Number(__v); if (typeof __v !== "bigint" || BigInt(__f) === __v) { return __f; } throw new Error("integer overflow: toF64: " + __v + " has no exact f64"); })(this.valueOf()); };

//// std/io/fs — the file system, cross-backend (decision 540).

//// 

//// Reference:

////   Rust     — https://doc.rust-lang.org/std/fs/ (`read`, `read_to_string`,

////              `File`, `io::ErrorKind`)

////   Java     — https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/nio/file/Files.html

////   Erlang   — https://www.erlang.org/doc/man/file.html

////   Node.js  — https://nodejs.org/api/fs.html

//// 

//// Every function that can fail answers `@Result<…, FsError>`: the same OS error is

//// the same `FsError` variant on every target (`ENOENT`, `enoent` → `NotFound`),

//// and `Other.message` is the host's own text. The whole-file shortcuts

//// (`readBytes`, `readText`, `writeBytes`, `writeText`, `appendText`), `stat`, and

//// the directory functions (`exists`, `list`, `mkdir`, `mkdirRecursive`, `rm`,

//// `removeTree`, `copy`, `walk`, `glob`) are followed by the handle: `open`

//// and `create` answer a `File`, a `Closeable` closed by the writer with `defer`.

//// 

//// The host cells (`raw…`) answer `@Result<R, string>` whose error is

//// `<kind>|<host text>` — `kind` one of `notfound`, `denied`, `isdir`, `notdir`,

//// `exists`, `other` (or `dangling`, a `walk`'s own) — and `lift` turns it into the

//// `FsError` of the path the caller wrote. All operations are synchronous

//// (`*Sync` on Node, blocking BIFs on Erlang); there is no wasm binding here

//// (front 164: `wasi:filesystem` behind `needs: [.Filesystem]`).

const { relative } = require("../../std/path.js");

// The error of every `io.fs` function (decision 540). `path` is the path the

// caller wrote (for `copy`, the source; for `walk`, the root).

class FsError {
    static NotFound(path) {
        return new FsError$NotFound(path);
    }

    static PermissionDenied(path) {
        return new FsError$PermissionDenied(path);
    }

    static IsDirectory(path) {
        return new FsError$IsDirectory(path);
    }

    static NotDirectory(path) {
        return new FsError$NotDirectory(path);
    }

    static AlreadyExists(path) {
        return new FsError$AlreadyExists(path);
    }

    static InvalidUtf8(path, offset) {
        return new FsError$InvalidUtf8(path, offset);
    }

    static Other(path, message) {
        return new FsError$Other(path, message);
    }

    toString() {
        return __bp_text(this);
    }
}
FsError.prototype.__bp = "FsError";
class FsError$NotFound extends FsError {
    constructor(path) {
        super();
        this.path = path;
    }
}
FsError$NotFound.prototype.tag = "NotFound";
class FsError$PermissionDenied extends FsError {
    constructor(path) {
        super();
        this.path = path;
    }
}
FsError$PermissionDenied.prototype.tag = "PermissionDenied";
class FsError$IsDirectory extends FsError {
    constructor(path) {
        super();
        this.path = path;
    }
}
FsError$IsDirectory.prototype.tag = "IsDirectory";
class FsError$NotDirectory extends FsError {
    constructor(path) {
        super();
        this.path = path;
    }
}
FsError$NotDirectory.prototype.tag = "NotDirectory";
class FsError$AlreadyExists extends FsError {
    constructor(path) {
        super();
        this.path = path;
    }
}
FsError$AlreadyExists.prototype.tag = "AlreadyExists";
class FsError$InvalidUtf8 extends FsError {
    constructor(path, offset) {
        super();
        this.path = path;
        this.offset = offset;
    }
}
FsError$InvalidUtf8.prototype.tag = "InvalidUtf8";
class FsError$Other extends FsError {
    constructor(path, message) {
        super();
        this.path = path;
        this.message = message;
    }
}
FsError$Other.prototype.tag = "Other";
exports.FsError = FsError;

class FileStat {
    constructor(size, mtime, isDir) {
        this.size = size;
        this.mtime = mtime;
        this.isDir = isDir;
    }
}
FileStat.prototype.__bp = "FileStat";
exports.FileStat = FileStat;

// Read the whole file as bytes.

// Node: `readFileSync($0)` copied into a plain `Uint8Array`.

// Erlang: `file:read_file/1`.

// rawReadBytes: per-call template (see annotation)

// Write `contents` to `path`, creating or truncating.

// Node: `writeFileSync($0, $1)`. Erlang: `file:write_file/2`.

// rawWriteBytes: per-call template (see annotation)

// Append `contents` to `path`, creating it when it is not there.

// Node: `appendFileSync($0, $1)`. Erlang: `file:write_file/3` with `append`.

// rawAppendText: per-call template (see annotation)

// The offset of the first byte that starts a sequence that is not UTF-8 (a byte no sequence

// starts with, a sequence cut short, an overlong form, a surrogate, a code point past U+10FFFF),

// or -1 when every byte is part of a valid sequence — the same offset on every target.

// Node: a scan of the bytes. Erlang: `unicode:characters_to_binary/3`, whose `Good` prefix is the offset.

// utf8Offset: per-call template (see annotation)

// `line` without its line terminator: one trailing `\n`, and the `\r` before it.

// Node: `subarray`. Erlang: `binary:part/3`.

// stripEol: per-call template (see annotation)

// The handle of the file at `path`, open for reading. A directory is `isdir` on both hosts

// (Node opens one; the template refuses it). The handle is host-owned and opaque: a

// `{ fd, mem, pos, buf }` object on Node, the raw file descriptor on Erlang.

// rawOpen: per-call template (see annotation)

// The handle of the file at `path`, open for writing: created, or truncated.

// rawCreate: per-call template (see annotation)

// A handle over bytes held in memory — what an `Asset` opens as. The position is a field

// on Node and a `counters` cell on Erlang.

// memHandle: per-call template (see annotation)

// The size of the file behind `handle`, in bytes. Erlang's raw descriptor has no `fstat`, so it reads `path`.

// rawSize: per-call template (see annotation)

// Up to `n` bytes (n > 0) from the handle's position; empty at the end.

// rawRead: per-call template (see annotation)

// Every byte from the handle's position to the end.

// rawReadAll: per-call template (see annotation)

// The next line, terminator included; empty at the end.

// rawReadLine: per-call template (see annotation)

// The SHA-256 of the whole file behind the handle, lowercase hex — from its first byte,

// whatever the position, which it leaves where it was.

// rawHash: per-call template (see annotation)

// Write `bytes` at the handle's position; answers how many.

// rawWrite: per-call template (see annotation)

// Close the handle. A failure to close is not reported (a `Closeable`'s `close` answers nothing).

// rawClose: per-call template (see annotation)

// Write `contents` to `path`, creating or truncating. Reds with the

// host's I/O error message.

// Node: `require('fs').writeFileSync($0, $1)`.

// Erlang: `file:write_file/2`.

// rawWriteText: per-call template (see annotation)

// Whether a path exists, of any kind: a regular file, a directory, a

// character or block device (`/dev/null`), a FIFO or a socket. A symbolic

// link is followed — one whose target is missing is `false`, the answer

// every read through it would give.

// Node: `require('fs').existsSync($0)` (a `stat`).

// Erlang: `file:read_file_info/1` (a `stat`; `filelib:is_file/1`, which it

// replaces, answers only regular files and directories, so `/dev/null`

// was `false` on erlang and `true` on commonJS).

// exists: per-call template (see annotation)
function exists(path) { return require('fs').existsSync(path); }
exports.exists = exists;

// List the names of the directory entries at `path` (relative).

// Node: `require('fs').readdirSync($0)`.

// Erlang: `file:list_dir/1` returns `{ok, [string()]}`.

// rawList: per-call template (see annotation)

// Create directory at `path`. Use `mkdirRecursive` to create

// intermediate parents.

// Node: `require('fs').mkdirSync($0)`.

// Erlang: `file:make_dir/1`.

// rawMkdir: per-call template (see annotation)

// Create the directory at `path` and every missing directory above it. A

// directory that is already there is `Ok` too; a path that exists as anything

// else (a file) is an `Error`. What the snapshot library (`snap`) makes the

// directory of a `.snap` with (decision 391).

// Node: `require('fs').mkdirSync($0, { recursive: true })`.

// Erlang: `filelib:ensure_path/1`.

// rawMkdirRecursive: per-call template (see annotation)

// Delete the FILE at `path`. A directory — empty or not — is `IsDirectory` on

// both hosts (Node's `ERR_FS_EISDIR`; Erlang's `eperm` is read as `eisdir` after

// a `read_link_info`, so the variant is the same); `removeTree` removes one.

// Node: `require('fs').rmSync($0)`.

// Erlang: `file:delete/1`.

// rawRm: per-call template (see annotation)

// Copy file from `src` to `dest`. Reds when `src` is missing or

// `dest` already exists (Node's default `copyFileSync` semantics).

// Node: `require('fs').copyFileSync($0, $1)`.

// Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).

// rawCopy: per-call template (see annotation)

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

// rawStat: per-call template (see annotation)

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

// rawWalk: per-call template (see annotation)

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

// rawGlob: per-call template (see annotation)

// Remove `path` and everything under it: a file, a link (the link, never its

// target) or a directory tree. A path that is not there is `Ok` too — the

// caller wanted it gone. What a test fixture is cleared with, and what the

// snapshot engine's tests clear their scratch directories with (1.0.11-beta

// front 97).

// Node: `rmSync(path, { recursive: true, force: true })`.

// Erlang: `file:del_dir_r/1`.

// rawRemoveTree: per-call template (see annotation)

// Internal, test scaffolding: a fresh, unique, empty directory under the

// host's tmpdir. Private — every `walk`/`glob` test makes its fixture tree in

// one of these and removes it with `removeTree`, so a run leaves nothing under

// the host's tmpdir.

// scratchDir: per-call template (see annotation)

// Internal, test scaffolding: the working directory (what a relative root is

// read against) and a symbolic link `link` → `target`.

// workingDir: per-call template (see annotation)

// linkTo: per-call template (see annotation)

// ── the typed error ──────────────────────────────────────────────────────────

// `<kind>|<host text>` → the `FsError` of `path`.

function fsError(path, raw) {
    let raw$sp = null;
    const bar = ((raw$sp ??= __bp_has_surrogate(raw)) ? __bp_str_index_of(raw, "|") : raw.indexOf("|"));
    const kind = raw.slice(0, bar);
    const message = raw.slice(__bp_int((bar + 1), -2147483648, 2147483647, "+ on i32 at src/io/fs.bp:300:33"), null);
    if ((kind === "notfound")) { return FsError.NotFound(path); }
    if ((kind === "denied")) { return FsError.PermissionDenied(path); }
    if ((kind === "isdir")) { return FsError.IsDirectory(path); }
    if ((kind === "notdir")) { return FsError.NotDirectory(path); }
    if ((kind === "exists")) { return FsError.AlreadyExists(path); }
    return FsError.Other(path, message);
}

// A host cell's answer, its error read as an `FsError` of `path`.

function lift(path, r) {
    const _case0 = (() => {
        const _s = r;
        if ("ok" in _s) {
            const v = _s.ok;
            return ({ __bp_return: true, value: ({ ok: v }) });
        }
        if ("error" in _s) {
            const m = _s.error;
            return ({ __bp_return: true, value: ({ error: fsError(path, m) }) });
        }
    })();
    if (_case0 && _case0.__bp_return) return _case0.value;
}

// The text of `b`, or `InvalidUtf8` at the first invalid byte.

function decode(path, b) {
    const offset = ((__b) => { const __n = __b.length; let __i = 0; while (__i < __n) { const __c = __b[__i]; if (__c < 128) { __i++; continue } let __k; if (__c >= 194 && __c <= 223) __k = 1; else if (__c >= 224 && __c <= 239) __k = 2; else if (__c >= 240 && __c <= 244) __k = 3; else return __i; if (__i + __k >= __n) return __i; let __lo = 128, __hi = 191; if (__c === 224) __lo = 160; else if (__c === 237) __hi = 159; else if (__c === 240) __lo = 144; else if (__c === 244) __hi = 143; const __d = __b[__i + 1]; if (__d < __lo || __d > __hi) return __i; for (let __j = 2; __j <= __k; __j++) { const __e = __b[__i + __j]; if (__e < 128 || __e > 191) return __i } __i += __k + 1 } return -1 })(b);
    if ((offset >= 0)) { return ({ error: FsError.InvalidUtf8(path, offset) }); }
    return ({ ok: ((_r) => "error" in _r ? ("") : _r.ok)(b.toUtf8()) });
}

// ── whole-file shortcuts ─────────────────────────────────────────────────────

// The file's bytes.

function readBytes(path) {
    const _try0 = lift(path, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { return { ok: new Uint8Array(require('fs').readFileSync(path)) } } catch (__e) { return { error: __ek(__e) } } })());
    if ("error" in _try0) return _try0;
    const b = _try0.ok;
    return ({ ok: b });
}
exports.readBytes = readBytes;

// The file as UTF-8 text. Bytes that are not UTF-8 are `InvalidUtf8` on every

// target — never node's silent U+FFFD nor erlang's unchecked binary.

function readText(path) {
    const _try0 = readBytes(path);
    if ("error" in _try0) return _try0;
    const b = _try0.ok;
    const _try1 = decode(path, b);
    if ("error" in _try1) return _try1;
    const s = _try1.ok;
    return ({ ok: s });
}
exports.readText = readText;

// Write `contents` to `path`, creating or truncating.

function writeBytes(path, contents) {
    const _try0 = lift(path, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').writeFileSync(path, contents); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })());
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.writeBytes = writeBytes;

function writeText(path, contents) {
    const _try0 = lift(path, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').writeFileSync(path, contents); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })());
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.writeText = writeText;

// Append `contents`, creating the file when it is not there.

function appendText(path, contents) {
    const _try0 = lift(path, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').appendFileSync(path, contents); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })());
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.appendText = appendText;

// ── metadata and directories ─────────────────────────────────────────────────

function stat(path) {
    const _try0 = lift(path, __bp_adopt((() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __s = require('fs').statSync(path, { bigint: true }); const __c = (__v) => (__v >= -9007199254740991n && __v <= 9007199254740991n) ? Number(__v) : __v; const __ns = __s.mtimeNs; return { ok: { size: __c(__s.size), mtime: __c(((__ns - (((__ns % 1000000000n) + 1000000000n) % 1000000000n)) / 1000000000n) * 1000n), isDir: __s.isDirectory() } } } catch (__e) { return { error: __ek(__e) } } })(), FileStat, "r"));
    if ("error" in _try0) return _try0;
    const s = _try0.ok;
    return ({ ok: s });
}
exports.stat = stat;

function list(path) {
    const _try0 = lift(path, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { return { ok: require('fs').readdirSync(path) } } catch (__e) { return { error: __ek(__e) } } })());
    if ("error" in _try0) return _try0;
    const names = _try0.ok;
    return ({ ok: names });
}
exports.list = list;

function mkdir(path) {
    const _try0 = lift(path, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').mkdirSync(path); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })());
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.mkdir = mkdir;

function mkdirRecursive(path) {
    const _try0 = lift(path, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').mkdirSync(path, { recursive: true }); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })());
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.mkdirRecursive = mkdirRecursive;

function rm(path) {
    const _try0 = lift(path, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').rmSync(path); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })());
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.rm = rm;

function removeTree(path) {
    const _try0 = lift(path, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').rmSync(path, { recursive: true, force: true }); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })());
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.removeTree = removeTree;

function copy(src, dest) {
    const _try0 = lift(src, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').copyFileSync(src, dest); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })());
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.copy = copy;

function walk(root) {
    const _try0 = lift(root, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __fs = require('fs'); const __p = require('path'); const __all = __fs.readdirSync(root, { recursive: true }).map(__f => String(__f).split(__p.sep).join('/')).sort(); const __out = []; for (const __f of __all) { const __s = __fs.statSync(__p.join(root, __f), { throwIfNoEntry: false }); if (__s === undefined) return { error: 'dangling|fs.walk: dangling link "' + __f + '"' }; if (__s.isFile()) __out.push(__f) } return { ok: __out } } catch (__e) { return { error: __ek(__e) } } })());
    if ("error" in _try0) return _try0;
    const paths = _try0.ok;
    return ({ ok: paths });
}
exports.walk = walk;

function glob(pattern, root) {
    const _try0 = lift(root, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __fs = require('fs'); const __p = require('path'); const __root = root; const __pat = String(pattern); const __segs = __pat.split('/').filter(__s => __s !== '' && __s !== '.'); const __dirsOnly = __pat.endsWith('/'); const __lst = (__f) => { try { return __fs.lstatSync(__f, { throwIfNoEntry: false }) } catch (__e) { return undefined } }; const __realDir = (__f) => { const __s = __lst(__f); return __s !== undefined && __s.isDirectory() }; const __linkedDir = (__f) => { try { const __s = __fs.statSync(__f, { throwIfNoEntry: false }); return __s !== undefined && __s.isDirectory() } catch (__e) { return false } }; const __magic = (__s) => __s.includes('*') || __s.includes('?') || __s.includes('[') || __s.includes('{'); const __names = (__dir, __seg) => { let __all; try { __all = (__seg === '*' ? __fs.readdirSync(__dir) : __fs.globSync(__seg, { cwd: __dir })).map(String) } catch (__e) { __all = [] } return __all.filter(__n => !__n.startsWith('.') || __seg.startsWith('.')) }; const __join = (__rel, __n) => __rel === '' ? __n : __rel + '/' + __n; const __out = new Set(); const __walk = (__i, __dir, __rel) => { if (__i === __segs.length) { if (__rel !== '') __out.add(__rel); return } const __seg = __segs[__i]; const __last = __i === __segs.length - 1; if (__seg === '**') { if (!__last) __walk(__i + 1, __dir, __rel); for (const __n of __names(__dir, '*')) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); if (__realDir(__f)) __walk(__i, __f, __sub) } return } if (!__magic(__seg)) { const __f = __p.join(__dir, __seg); const __sub = __join(__rel, __seg); if (__last) { if (__lst(__f) !== undefined) __out.add(__sub) } else if (__linkedDir(__f)) __walk(__i + 1, __f, __sub); return } for (const __n of __names(__dir, __seg)) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); else if (__realDir(__f)) __walk(__i + 1, __f, __sub) } }; __walk(0, __root, ''); return { ok: Array.from(__out).filter(__r => !__dirsOnly || __realDir(__p.join(__root, __r))).sort() } } catch (__e) { return { error: __ek(__e) } } })());
    if ("error" in _try0) return _try0;
    const paths = _try0.ok;
    return ({ ok: paths });
}
exports.glob = glob;

// The host's handle over embedded bytes: read like a file, never closed on disk.

// memoryHandle: per-call template (see annotation)

// ── the handle ───────────────────────────────────────────────────────────────

// An open file (decision 540 (3)). `location` is the path it was opened with and

// `handle` the host's — opaque, never read by a program. Closed by the writer:

// `val f = try fs.open(p); defer f.close();`.

class File {
    constructor(location, handle) {
        this.location = location;
        this.handle = handle;
    }

    path() {
        return this.location;
    }

    size() {
        const _try1 = lift(this.location, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __h = this.handle; return { ok: __h.mem ? __h.mem.length : require('fs').fstatSync(__h.fd).size } } catch (__e) { return { error: __ek(__e) } } })());
        if ("error" in _try1) return _try1;
        const n = _try1.ok;
        return ({ ok: n });
    }

    read(n) {
        if ((n <= 0)) { return ({ ok: (new TextEncoder().encode("")) }); }
        const _try2 = lift(this.location, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; try { const __h = this.handle; const __n = n; if (__h.buf.length > 0) { const __k = Math.min(__n, __h.buf.length); const __o = new Uint8Array(__h.buf.subarray(0, __k)); __h.buf = __h.buf.subarray(__k); return { ok: __o } } return { ok: new Uint8Array(__more(__h, __n)) } } catch (__e) { return { error: __ek(__e) } } })());
        if ("error" in _try2) return _try2;
        const b = _try2.ok;
        return ({ ok: b });
    }

    bytes() {
        const _try3 = lift(this.location, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; try { const __h = this.handle; const __parts = []; if (__h.buf.length > 0) { __parts.push(__h.buf); __h.buf = new Uint8Array(0) } for (;;) { const __r = __more(__h, 65536); if (__r.length === 0) break; __parts.push(new Uint8Array(__r)) } let __t = 0; for (const __x of __parts) __t += __x.length; const __o = new Uint8Array(__t); let __p = 0; for (const __x of __parts) { __o.set(__x, __p); __p += __x.length } return { ok: __o } } catch (__e) { return { error: __ek(__e) } } })());
        if ("error" in _try3) return _try3;
        const b = _try3.ok;
        return ({ ok: b });
    }

    text() {
        const _try4 = this.bytes();
        if ("error" in _try4) return _try4;
        const b = _try4.ok;
        const _try5 = decode(this.location, b);
        if ("error" in _try5) return _try5;
        const s = _try5.ok;
        return ({ ok: s });
    }

    async *chunks(size) {
        while (true) {
    const _try6 = this.read(size);
        if ("error" in _try6) { yield _try6; return; }
        const b = _try6.ok;
    if ((b.length === 0)) { break; }
    yield ({ ok: b });
}
    }

    async *lines() {
        let consumed = 0;
        while (true) {
    const _try7 = lift(this.location, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; try { const __h = this.handle; for (;;) { const __i = __h.buf.indexOf(10); if (__i >= 0) { const __l = new Uint8Array(__h.buf.subarray(0, __i + 1)); __h.buf = __h.buf.subarray(__i + 1); return { ok: __l } } const __r = __more(__h, 65536); if (__r.length === 0) { const __l = __h.buf; __h.buf = new Uint8Array(0); return { ok: __l } } const __nb = new Uint8Array(__h.buf.length + __r.length); __nb.set(__h.buf, 0); __nb.set(__r, __h.buf.length); __h.buf = __nb } } catch (__e) { return { error: __ek(__e) } } })());
        if ("error" in _try7) { yield _try7; return; }
        const raw = _try7.ok;
    if ((raw.length === 0)) { break; }
    const line = ((__b) => { let __n = __b.length; if (__n > 0 && __b[__n - 1] === 10) { __n--; if (__n > 0 && __b[__n - 1] === 13) __n-- } return __b.subarray(0, __n) })(raw);
    const offset = ((__b) => { const __n = __b.length; let __i = 0; while (__i < __n) { const __c = __b[__i]; if (__c < 128) { __i++; continue } let __k; if (__c >= 194 && __c <= 223) __k = 1; else if (__c >= 224 && __c <= 239) __k = 2; else if (__c >= 240 && __c <= 244) __k = 3; else return __i; if (__i + __k >= __n) return __i; let __lo = 128, __hi = 191; if (__c === 224) __lo = 160; else if (__c === 237) __hi = 159; else if (__c === 240) __lo = 144; else if (__c === 244) __hi = 143; const __d = __b[__i + 1]; if (__d < __lo || __d > __hi) return __i; for (let __j = 2; __j <= __k; __j++) { const __e = __b[__i + __j]; if (__e < 128 || __e > 191) return __i } __i += __k + 1 } return -1 })(line);
    if ((offset >= 0)) { yield ({ error: FsError.InvalidUtf8(this.location, __bp_wadd(consumed, offset, 0, "+ on i64 at src/io/fs.bp:467:21")) }); return; }
    const width = raw.length;
    consumed = __bp_wadd(consumed, width.toI64(), 0, "+ on i64 at src/io/fs.bp:469:33");
    yield ({ ok: ((_r) => "error" in _r ? ("") : _r.ok)(line.toUtf8()) });
}
    }

    hash() {
        const _try8 = lift(this.location, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __h = this.handle; const __hs = require('crypto').createHash('sha256'); if (__h.mem) { __hs.update(__h.mem) } else { const __b = new Uint8Array(65536); let __pos = 0; for (;;) { const __k = require('fs').readSync(__h.fd, __b, 0, 65536, __pos); if (__k === 0) break; __hs.update(__b.subarray(0, __k)); __pos += __k } } return { ok: __hs.digest('hex') } } catch (__e) { return { error: __ek(__e) } } })());
        if ("error" in _try8) return _try8;
        const h = _try8.ok;
        return ({ ok: h });
    }

    write(b) {
        const _try9 = lift(this.location, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __h = this.handle; const __b = b; if (__h.mem) return { error: 'other|the file is open for reading' }; let __o = 0; while (__o < __b.length) __o += require('fs').writeSync(__h.fd, __b, __o, __b.length - __o); return { ok: __b.length } } catch (__e) { return { error: __ek(__e) } } })());
        if ("error" in _try9) return _try9;
        const n = _try9.ok;
        return ({ ok: n });
    }

    close() {
        (() => { try { const __h = this.handle; if (!__h.mem) require('fs').closeSync(__h.fd) } catch (__e) {} })();
    }
}
File.prototype.__bp = "File";
exports.File = File;

// Open the file at `path` for reading. A directory is `IsDirectory` on every target.

function open(path) {
    const _try0 = lift(path, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __fs = require('fs'); const __p = path; const __fd = __fs.openSync(__p, 'r'); if (__fs.fstatSync(__fd).isDirectory()) { __fs.closeSync(__fd); return { error: 'isdir|EISDIR: illegal operation on a directory, open ' + JSON.stringify(__p) } } return { ok: { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } } } catch (__e) { return { error: __ek(__e) } } })());
    if ("error" in _try0) return _try0;
    const h = _try0.ok;
    return ({ ok: new File(path, h) });
}
exports.open = open;

// Open the file at `path` for writing: created, or truncated.

function create(path) {
    const _try0 = lift(path, (() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __fd = require('fs').openSync(path, 'w'); return { ok: { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } } } catch (__e) { return { error: __ek(__e) } } })());
    if ("error" in _try0) return _try0;
    const h = _try0.ok;
    return ({ ok: new File(path, h) });
}
exports.create = create;

// An `Asset` (`@embed`, decisions 519, 538) as a `File`: the embedded bytes, read

// like a file on disk — no `@Result`, the build proved the file exists — and

// closing it is a no-op.

function openAsset(asset) {
    return new File(asset.path, ({ fd: -1, mem: asset.bytes, pos: 0, buf: new Uint8Array(0) }));
}
exports.openAsset = openAsset;

// ── tests ────────────────────────────────────────────────────────────────────

// (Inline tests are smoke-grade — they require the host filesystem to be

// writable at the host's `tmpdir()`. The lib-test harness runs each

// inline test as a separate process; the temp filenames are seeded with

// `time.nowMillis()` for cross-run uniqueness.)

// Internal, test scaffolding: `stat(p)`, or a stat no file has.

function statOr(p) {
    return (() => {
        const _s = stat(p);
        if ("ok" in _s) {
            const s = _s.ok;
            return s;
        }
        if ("error" in _s) {
            return new FileStat((-1), (-1), false);
        }
    })();
}

// Internal, test scaffolding: `<dir>/app/page.bp`, `<dir>/app/blog/page.bp`,

// `<dir>/app/blog/notes.md` — the fixture tree every walk/glob test reads.

function makeFixtureTree(dir) {
    mkdir([dir, "/app"].join(""));
    mkdir([dir, "/app/blog"].join(""));
    writeText([dir, "/app/page.bp"].join(""), "root page");
    writeText([dir, "/app/blog/page.bp"].join(""), "blog page");
    writeText([dir, "/app/blog/notes.md"].join(""), "notes");
}

// Internal, test scaffolding: what `walk` answers for the fixture tree when

// its root is spelled `<scratch dir><suffix>` — every spelling of one root has

// to answer the same three relative paths.

function walkFixture(suffix) {
    const dir = require('fs').mkdtempSync(require('path').join(require('os').tmpdir(), 'bp-std-fs-'));
    makeFixtureTree(dir);
    const walked = ((_r) => "error" in _r ? (["<error>"]) : _r.ok)(walk([dir, suffix].join("")));
    removeTree(dir);
    return walked.join(",");
}

// Internal, test scaffolding: the same, with the root spelled relative to the

// working directory — `<prefix><path from the cwd to the fixture>`.

function walkFixtureFromCwd(prefix) {
    const dir = require('fs').mkdtempSync(require('path').join(require('os').tmpdir(), 'bp-std-fs-'));
    makeFixtureTree(dir);
    const root = [prefix, relative(process.cwd(), dir), "/app"].join("");
    const walked = ((_r) => "error" in _r ? (["<error>"]) : _r.ok)(walk(root));
    removeTree(dir);
    return walked.join(",");
}

// Internal, test scaffolding: the `Error` of `walk(root)`, `""` when it walked.

function walkRefusal(root) {
    return (() => {
        const _s = walk(root);
        if ("ok" in _s) {
            return "";
        }
        if ("error" in _s) {
            const e = _s.error;
            return describe(e);
        }
    })();
}

// Internal, test scaffolding: an `FsError` as one line — the variant, the path

// and the message where it holds one (a dangling link is `Other`, decision 178).

function describe(e) {
    return (() => {
        const _s = e;
        if (_s.tag === "NotFound") {
            const { path: p } = _s;
            return ("NotFound " + p);
        }
        if (_s.tag === "PermissionDenied") {
            const { path: p } = _s;
            return ("PermissionDenied " + p);
        }
        if (_s.tag === "IsDirectory") {
            const { path: p } = _s;
            return ("IsDirectory " + p);
        }
        if (_s.tag === "NotDirectory") {
            const { path: p } = _s;
            return ("NotDirectory " + p);
        }
        if (_s.tag === "AlreadyExists") {
            const { path: p } = _s;
            return ("AlreadyExists " + p);
        }
        if (_s.tag === "InvalidUtf8") {
            const { path: p, offset } = _s;
            return ((("InvalidUtf8 " + p) + " ") + offset.toString());
        }
        if (_s.tag === "Other") {
            const { path: p, message } = _s;
            return message;
        }
    })();
}

// Internal, test scaffolding: the fixture tree plus the names decision 177 is

// about — a dot file and a dot directory, a link to a directory, a link to a

// file and a dangling link, all under `<dir>/app`.

function makeGlobTree(dir) {
    makeFixtureTree(dir);
    mkdir([dir, "/app/.cache"].join(""));
    writeText([dir, "/app/.cache/page.bp"].join(""), "cached");
    writeText([dir, "/app/.hidden.bp"].join(""), "hidden");
    writeText([dir, "/app/blog/.draft.md"].join(""), "draft");
    require('fs').symlinkSync("blog", [dir, "/app/linked"].join(""));
    require('fs').symlinkSync("page.bp", [dir, "/app/alias.bp"].join(""));
    require('fs').symlinkSync("missing.bp", [dir, "/app/gone.bp"].join(""));
}

// Internal, test scaffolding: what `glob(pattern, <dir>/app)` answers over

// `makeGlobTree`, joined by `,`.

function globbed(pattern) {
    const dir = require('fs').mkdtempSync(require('path').join(require('os').tmpdir(), 'bp-std-fs-'));
    makeGlobTree(dir);
    const found = ((_r) => "error" in _r ? (["<error>"]) : _r.ok)(glob(pattern, [dir, "/app"].join("")));
    removeTree(dir);
    return found.join(",");
}

// ── FsError, readText and the handle ─────────────────────────────────────────

// Internal, test scaffolding: the variant of an `Error`, `"ok"` for an `Ok`.

function variantOf(r) {
    return (() => {
        const _s = r;
        if ("ok" in _s) {
            return "ok";
        }
        if ("error" in _s) {
            const e = _s.error;
            return describe(e);
        }
    })();
}

// Internal, test scaffolding: the file a failed `open` falls back to.

function noFile() {
    return new File("", ({ fd: -1, mem: (new TextEncoder().encode("")), pos: 0, buf: new Uint8Array(0) }));
}

// Internal, test scaffolding: take every permission from `path`; whether that

// denies this user anything (root is denied nothing), and give them back.

// denyAll: per-call template (see annotation)

// allowAll: per-call template (see annotation)

Object.defineProperty(exports, "__bp_priv__", { value: { relative, FsError, FsError$NotFound, FsError$PermissionDenied, FsError$IsDirectory, FsError$NotDirectory, FsError$AlreadyExists, FsError$InvalidUtf8, FsError$Other, FileStat, exists, fsError, lift, decode, readBytes, readText, writeBytes, writeText, appendText, stat, list, mkdir, mkdirRecursive, rm, removeTree, copy, walk, glob, File, open, create, openAsset, statOr, makeFixtureTree, walkFixture, walkFixtureFromCwd, walkRefusal, describe, makeGlobTree, globbed, variantOf, noFile } });
```

----- TYPESCRIPT TYPEDEF -- std/io/fs.d.ts
```typescript
import { relative } from "../../std/path";


export declare class FsError {
    readonly tag: "NotFound" | "PermissionDenied" | "IsDirectory" | "NotDirectory" | "AlreadyExists" | "InvalidUtf8" | "Other";
    static NotFound(path: string): FsError;
    static PermissionDenied(path: string): FsError;
    static IsDirectory(path: string): FsError;
    static NotDirectory(path: string): FsError;
    static AlreadyExists(path: string): FsError;
    static InvalidUtf8(path: string, offset: number | bigint): FsError;
    static Other(path: string, message: string): FsError;
}


export declare class FileStat {
    readonly size: number | bigint;
    readonly mtime: number | bigint;
    readonly isDir: boolean;
    constructor(size: number | bigint, mtime: number | bigint, isDir: boolean);
}


































export declare function exists(path: string): boolean;
































export declare function readBytes(path: string): { ok: Uint8Array } | { error: FsError };


export declare function readText(path: string): { ok: string } | { error: FsError };


export declare function writeBytes(path: string, contents: Uint8Array): { ok: number } | { error: FsError };


export declare function writeText(path: string, contents: string): { ok: number } | { error: FsError };


export declare function appendText(path: string, contents: string): { ok: number } | { error: FsError };


export declare function stat(path: string): { ok: FileStat } | { error: FsError };


export declare function list(path: string): { ok: string[] } | { error: FsError };


export declare function mkdir(path: string): { ok: number } | { error: FsError };


export declare function mkdirRecursive(path: string): { ok: number } | { error: FsError };


export declare function rm(path: string): { ok: number } | { error: FsError };


export declare function removeTree(path: string): { ok: number } | { error: FsError };


export declare function copy(src: string, dest: string): { ok: number } | { error: FsError };


export declare function walk(root: string): { ok: string[] } | { error: FsError };


export declare function glob(pattern: string, root: string): { ok: string[] } | { error: FsError };




export declare class File {
    readonly location: string;
    readonly handle: unknown;
    constructor(location: string, handle: unknown);
    path(): string;
    size(): { ok: number | bigint } | { error: FsError };
    read(n: number): { ok: Uint8Array } | { error: FsError };
    bytes(): { ok: Uint8Array } | { error: FsError };
    text(): { ok: string } | { error: FsError };
    chunks(size: number): AsyncGenerator<{ ok: Uint8Array } | { error: FsError }>;
    lines(): AsyncGenerator<{ ok: string } | { error: FsError }>;
    hash(): { ok: string } | { error: FsError };
    write(b: Uint8Array): { ok: number } | { error: FsError };
    close(): void;
}


export declare function open(path: string): { ok: File } | { error: FsError };


export declare function create(path: string): { ok: File } | { error: FsError };


export declare function openAsset(asset: { path: string; bytes: Uint8Array; size: number | bigint; hash: string; text: () => string }): File;

























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

