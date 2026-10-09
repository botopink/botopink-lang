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
    return parts.at(n - 1).unwrapOr("");
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
    val head = pieces.at(0).unwrapOr("");
    val tail = pieces.at(n - 1).unwrapOr("");
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
    val isAbs = if (parts.length == 0)
        false
    else
        isAbsolute(parts.at(0).unwrapOr(""));
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
    val ai = a.at(i).unwrapOr("");
    val bi = b.at(i).unwrapOr("");
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
    val p = pieces.at(0).unwrapOr("");
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
    val seg = segments.at(i).unwrapOr("");
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
    assert s.at(0).unwrapOr("") == "usr";
    assert s.at(1).unwrapOr("") == "bin";
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

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

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
//   fn charCodeAt(...)
//   fn lastIndexOf(...)
//   default fn parseInt(...)
//   default fn parseFloat(...)
String.prototype.slice = function(start, end) {
    const self = this.valueOf();
    if ((end != null)) { return ((__s, __a, __e) => { const __n = __s.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, end); } else { return ((__s, __a) => { const __n = __s.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, start); }
};
String.prototype.chars = function() { return (Array.from(this.valueOf())); };
String.prototype.lines = function() { return this.valueOf().split(/\r?\n/); };
String.prototype.words = function() { return this.valueOf().split(/[ \t\n\r]+/).filter(__w => __w.length > 0); };
String.prototype.charCodeAt = function(index) { return ((this.valueOf().codePointAt(index) ?? -1) | 0); };
String.prototype.parseInt = function() {
    const self = this.valueOf();
    const signed = (self.startsWith("-") || self.startsWith("+"));
    const digits = (() => { if (signed) { return ((__s, __a) => { const __n = __s.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, 1); } else { return self; } })();
    return (() => { if ((/^[0-9]+$/.test(digits))) { return ((__s) => { const __n = Number(__s); return Number.isSafeInteger(__n) ? { ok: __n + 0 } : { error: 'parseInt: "' + __s + '" is out of range' } })(self); } else { return ({ error: "parseInt: \"" + self + "\" is not an integer" }); } })();
};
String.prototype.parseFloat = function() {
    const self = this.valueOf();
    const signed = (self.startsWith("-") || self.startsWith("+"));
    const start = (() => { if (signed) { return 1; } else { return 0; } })();
    const lowerAt = self.indexOf("e");
    const exponentAt = (() => { if ((lowerAt < 0)) { return self.indexOf("E"); } else { return lowerAt; } })();
    const mantissa = (() => { if ((exponentAt < 0)) { return ((__s, __a) => { const __n = __s.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, start); } else { return ((__s, __a, __e) => { const __n = __s.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, exponentAt); } })();
    const pointAt = self.indexOf(".");
    const pointed = ((pointAt >= 0) && (((exponentAt < 0) || (pointAt < exponentAt))));
    const whole = (() => { if (pointed) { return ((__s, __a, __e) => { const __n = __s.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, pointAt); } else { return mantissa; } })();
    const fraction = (() => { if ((pointed === false)) { return "0"; } else { return (() => { if ((exponentAt < 0)) { return ((__s, __a) => { const __n = __s.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, (pointAt + 1)); } else { return ((__s, __a, __e) => { const __n = __s.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, (pointAt + 1), exponentAt); } })(); } })();
    const exponent = (() => { if ((exponentAt < 0)) { return "0"; } else { return ((__s, __a) => { const __n = __s.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, (exponentAt + 1)); } })();
    const exponentMark = (() => { if ((exponentAt < 0)) { return ""; } else { return ((__s, __a, __e) => { const __n = __s.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, (exponentAt + 1), (exponentAt + 2)); } })();
    const exponentSigned = ((exponentMark === "-") || (exponentMark === "+"));
    const exponentDigits = (() => { if (exponentSigned) { return ((__s, __a) => { const __n = __s.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, (exponentAt + 2)); } else { return exponent; } })();
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
Array.range = function(start, stop) {
    return (() => { if ((start >= stop)) { return []; } else { const head = start; return [head, ...(Array.range((start + 1), stop))]; } })();
};
Array.repeat = function(value, times) {
    return (() => { if ((times <= 0)) { return []; } else { const head = value; return [head, ...(Array.repeat(value, (times - 1)))]; } })();
};
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
    return ((_o) => _o != null ? _o : (""))(__bp_array_at(parts, __bp_int((n - 1), -2147483648, 2147483647, "- on i32 at src/path.bp:40:23")));
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
    const head = ((_o) => _o != null ? _o : (""))(__bp_array_at(pieces, 0));
    const tail = ((_o) => _o != null ? _o : (""))(__bp_array_at(pieces, __bp_int((n - 1), -2147483648, 2147483647, "- on i32 at src/path.bp:68:28")));
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
    const isAbs = (() => { if ((parts.length === 0)) { return false; } else { return isAbsolute(((_o) => _o != null ? _o : (""))(__bp_array_at(parts, 0))); } })();
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
    const ai = ((_o) => _o != null ? _o : (""))(__bp_array_at(a, i));
    const bi = ((_o) => _o != null ? _o : (""))(__bp_array_at(b, i));
    return (() => { if (__bp_eq(ai, bi, 0)) { return commonPrefixCount(a, b, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/path.bp:117:52")); } else { return i; } })();
}

// Internal: build an array of `n` ".." strings via head/tail recursion.

// Avoids a `var` + `push` accumulator (the Erlang dead-store trap).

function makeUps(n) {
    return (() => { if ((n <= 0)) { return []; } else { return makeUps(__bp_int((n - 1), -2147483648, 2147483647, "- on i32 at src/path.bp:123:42")).prepend(".."); } })();
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
    const ups = makeUps(__bp_int((srcParts.length - common), -2147483648, 2147483647, "- on i32 at src/path.bp:138:39"));
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
    if ((pieces.length === 0)) { return acc; }
    const p = ((_o) => _o != null ? _o : (""))(__bp_array_at(pieces, 0));
    const rest = pieces.slice(1, pieces.length);
    const nextAcc = (() => { if ((p === "..")) { return (() => { if ((acc.length === 0)) { return acc; } else { return acc.slice(0, __bp_int((acc.length - 1), -2147483648, 2147483647, "- on i32 at src/path.bp:162:63")); } })(); } else { return acc.concat([p]); } })();
    return applyPieces(nextAcc, rest);
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
        const seg = ((_o) => _o != null ? _o : (""))(__bp_array_at(segments, i));
        const next = resolveStep(state, seg);
        { const __bp_tc1 = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/path.bp:178:35"); i = __bp_tc1; state = next; continue; }
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
    const ext = extname(p);
    const n = p.length;
    const stem = (() => { if ((ext === "")) { return p; } else { return p.slice(0, __bp_int((n - ext.length), -2147483648, 2147483647, "- on i32 at src/path.bp:208:51")); } })();
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
// Node: `(() => { const s = require('fs').statSync($0); return { size: s.size, mtime: Math.floor(s.mtimeMs), isDir: s.isDirectory() } })()`.
// Erlang: `file:read_file_info/1` returns a `#file_info` record; the
// template projects the `size`, `mtime`, and `type` fields.
#[@External.Node("""(() => { try { const __s = require('fs').statSync($0); return { ok: { size: __s.size, mtime: Math.floor(__s.mtimeMs), isDir: __s.isDirectory() } } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
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

----- JAVASCRIPT -- std/io/fs.js
```javascript
function __bp_adopt(v, C, p) { return (v == null) ? v : (p === "") ? ((typeof v === "object" && !(v instanceof C)) ? Object.assign(Object.create(C.prototype), v) : v) : (p[0] === "a") ? (Array.isArray(v) ? v.map((e) => __bp_adopt(e, C, p.slice(1))) : v) : (p[0] === "r" && typeof v === "object" && "ok" in v) ? { ok: __bp_adopt(v.ok, C, p.slice(1)) } : v; }

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

const { relative } = require("../../std/path.js");

class FileStat {
    constructor(size, mtime, isDir) {
        this.size = size;
        this.mtime = mtime;
        this.isDir = isDir;
    }
}
FileStat.prototype.__bp = "FileStat";
exports.FileStat = FileStat;

// Read the entire file as a UTF-8 string. Reds with the host's I/O

// error message on missing file / permission denied / etc.

// Node: `require('fs').readFileSync($0, 'utf8')`.

// Erlang: `file:read_file/1` returns `{ok, Bin}` or `{error, Reason}`.

// readText: per-call template (see annotation)
function readText(path) { return (() => { try { return { ok: require('fs').readFileSync(path, 'utf8') } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })(); }
exports.readText = readText;

// Write `contents` to `path`, creating or truncating. Reds with the

// host's I/O error message.

// Node: `require('fs').writeFileSync($0, $1)`.

// Erlang: `file:write_file/2`.

// writeText: per-call template (see annotation)
function writeText(path, contents) { return (() => { try { require('fs').writeFileSync(path, contents); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })(); }
exports.writeText = writeText;

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

// list: per-call template (see annotation)
function list(path) { return (() => { try { return { ok: require('fs').readdirSync(path) } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })(); }
exports.list = list;

// Create directory at `path`. Use `mkdirRecursive` to create

// intermediate parents (the spec's `recursive: bool = true` overload

// gates on default-fn-param-default support landing).

// Node: `require('fs').mkdirSync($0)`.

// Erlang: `file:make_dir/1`.

// mkdir: per-call template (see annotation)
function mkdir(path) { return (() => { try { require('fs').mkdirSync(path); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })(); }
exports.mkdir = mkdir;

// Delete the FILE at `path`. A directory — empty or not — is an `Error` on

// both hosts (`ERR_FS_EISDIR` / `eperm`); `removeTree` removes one.

// Node: `require('fs').rmSync($0)`.

// Erlang: `file:delete/1`.

// rm: per-call template (see annotation)
function rm(path) { return (() => { try { require('fs').rmSync(path); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })(); }
exports.rm = rm;

// Copy file from `src` to `dest`. Reds when `src` is missing or

// `dest` already exists (Node's default `copyFileSync` semantics).

// Node: `require('fs').copyFileSync($0, $1)`.

// Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).

// copy: per-call template (see annotation)
function copy(src, dest) { return (() => { try { require('fs').copyFileSync(src, dest); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })(); }
exports.copy = copy;

// File metadata. Returns a `FileStat { size, mtime, isDir }` on

// success. `mtime` is epoch milliseconds (matching `time.nowMillis()`);

// `size` is in bytes.

// Node: `(() => { const s = require('fs').statSync($0); return { size: s.size, mtime: Math.floor(s.mtimeMs), isDir: s.isDirectory() } })()`.

// Erlang: `file:read_file_info/1` returns a `#file_info` record; the

// template projects the `size`, `mtime`, and `type` fields.

// stat: per-call template (see annotation)
function stat(path) { return __bp_adopt((() => { try { const __s = require('fs').statSync(path); return { ok: { size: __s.size, mtime: Math.floor(__s.mtimeMs), isDir: __s.isDirectory() } } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })(), FileStat, "r"); }
exports.stat = stat;

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

// walk: per-call template (see annotation)
function walk(root) { return (() => { try { const __fs = require('fs'); const __p = require('path'); const __all = __fs.readdirSync(root, { recursive: true }).map(__f => String(__f).split(__p.sep).join('/')).sort(); const __out = []; for (const __f of __all) { const __s = __fs.statSync(__p.join(root, __f), { throwIfNoEntry: false }); if (__s === undefined) return { error: 'fs.walk: dangling link "' + __f + '"' }; if (__s.isFile()) __out.push(__f) } return { ok: __out } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })(); }
exports.walk = walk;

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

// glob: per-call template (see annotation)
function glob(pattern, root) { return (() => { try { const __fs = require('fs'); const __p = require('path'); const __root = root; const __pat = String(pattern); const __segs = __pat.split('/').filter(__s => __s !== '' && __s !== '.'); const __dirsOnly = __pat.endsWith('/'); const __lst = (__f) => { try { return __fs.lstatSync(__f, { throwIfNoEntry: false }) } catch (__e) { return undefined } }; const __realDir = (__f) => { const __s = __lst(__f); return __s !== undefined && __s.isDirectory() }; const __linkedDir = (__f) => { try { const __s = __fs.statSync(__f, { throwIfNoEntry: false }); return __s !== undefined && __s.isDirectory() } catch (__e) { return false } }; const __magic = (__s) => __s.includes('*') || __s.includes('?') || __s.includes('[') || __s.includes('{'); const __names = (__dir, __seg) => { let __all; try { __all = (__seg === '*' ? __fs.readdirSync(__dir) : __fs.globSync(__seg, { cwd: __dir })).map(String) } catch (__e) { __all = [] } return __all.filter(__n => !__n.startsWith('.') || __seg.startsWith('.')) }; const __join = (__rel, __n) => __rel === '' ? __n : __rel + '/' + __n; const __out = new Set(); const __walk = (__i, __dir, __rel) => { if (__i === __segs.length) { if (__rel !== '') __out.add(__rel); return } const __seg = __segs[__i]; const __last = __i === __segs.length - 1; if (__seg === '**') { if (!__last) __walk(__i + 1, __dir, __rel); for (const __n of __names(__dir, '*')) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); if (__realDir(__f)) __walk(__i, __f, __sub) } return } if (!__magic(__seg)) { const __f = __p.join(__dir, __seg); const __sub = __join(__rel, __seg); if (__last) { if (__lst(__f) !== undefined) __out.add(__sub) } else if (__linkedDir(__f)) __walk(__i + 1, __f, __sub); return } for (const __n of __names(__dir, __seg)) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); else if (__realDir(__f)) __walk(__i + 1, __f, __sub) } }; __walk(0, __root, ''); return { ok: Array.from(__out).filter(__r => !__dirsOnly || __realDir(__p.join(__root, __r))).sort() } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })(); }
exports.glob = glob;

// Remove `path` and everything under it: a file, a link (the link, never its

// target) or a directory tree. A path that is not there is `Ok` too — the

// caller wanted it gone. What a test fixture is cleared with, and what the

// snapshot engine's tests clear their scratch directories with (1.0.11-beta

// front 97).

// Node: `rmSync(path, { recursive: true, force: true })`.

// Erlang: `file:del_dir_r/1`.

// removeTree: per-call template (see annotation)
function removeTree(path) { return (() => { try { require('fs').rmSync(path, { recursive: true, force: true }); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })(); }
exports.removeTree = removeTree;

// Internal, test scaffolding: a fresh, unique, empty directory under the

// host's tmpdir. Private — every `walk`/`glob` test makes its fixture tree in

// one of these and removes it with `removeTree`, so a run leaves nothing under

// the host's tmpdir.

// scratchDir: per-call template (see annotation)

// Internal, test scaffolding: the working directory (what a relative root is

// read against) and a symbolic link `link` → `target`.

// workingDir: per-call template (see annotation)

// linkTo: per-call template (see annotation)

// ── tests ────────────────────────────────────────────────────────────────────

// (Inline tests are smoke-grade — they require the host filesystem to be

// writable at the host's `tmpdir()`. The lib-test harness runs each

// inline test as a separate process; the temp filenames are seeded with

// `time.nowMillis()` for cross-run uniqueness.)

// Internal, test scaffolding: `<dir>/app/page.bp`, `<dir>/app/blog/page.bp`,

// `<dir>/app/blog/notes.md` — the fixture tree every walk/glob test reads.

function makeFixtureTree(dir) {
    (() => { try { require('fs').mkdirSync([dir, "/app"].join("")); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })();
    (() => { try { require('fs').mkdirSync([dir, "/app/blog"].join("")); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })();
    (() => { try { require('fs').writeFileSync([dir, "/app/page.bp"].join(""), "root page"); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })();
    (() => { try { require('fs').writeFileSync([dir, "/app/blog/page.bp"].join(""), "blog page"); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })();
    (() => { try { require('fs').writeFileSync([dir, "/app/blog/notes.md"].join(""), "notes"); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })();
}

// Internal, test scaffolding: what `walk` answers for the fixture tree when

// its root is spelled `<scratch dir><suffix>` — every spelling of one root has

// to answer the same three relative paths.

function walkFixture(suffix) {
    const dir = require('fs').mkdtempSync(require('path').join(require('os').tmpdir(), 'bp-std-fs-'));
    makeFixtureTree(dir);
    const walked = ((_r) => "error" in _r ? (["<error>"]) : _r.ok)((() => { try { const __fs = require('fs'); const __p = require('path'); const __all = __fs.readdirSync([dir, suffix].join(""), { recursive: true }).map(__f => String(__f).split(__p.sep).join('/')).sort(); const __out = []; for (const __f of __all) { const __s = __fs.statSync(__p.join([dir, suffix].join(""), __f), { throwIfNoEntry: false }); if (__s === undefined) return { error: 'fs.walk: dangling link "' + __f + '"' }; if (__s.isFile()) __out.push(__f) } return { ok: __out } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })());
    (() => { try { require('fs').rmSync(dir, { recursive: true, force: true }); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })();
    return walked.join(",");
}

// Internal, test scaffolding: the same, with the root spelled relative to the

// working directory — `<prefix><path from the cwd to the fixture>`.

function walkFixtureFromCwd(prefix) {
    const dir = require('fs').mkdtempSync(require('path').join(require('os').tmpdir(), 'bp-std-fs-'));
    makeFixtureTree(dir);
    const root = [prefix, relative(process.cwd(), dir), "/app"].join("");
    const walked = ((_r) => "error" in _r ? (["<error>"]) : _r.ok)((() => { try { const __fs = require('fs'); const __p = require('path'); const __all = __fs.readdirSync(root, { recursive: true }).map(__f => String(__f).split(__p.sep).join('/')).sort(); const __out = []; for (const __f of __all) { const __s = __fs.statSync(__p.join(root, __f), { throwIfNoEntry: false }); if (__s === undefined) return { error: 'fs.walk: dangling link "' + __f + '"' }; if (__s.isFile()) __out.push(__f) } return { ok: __out } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })());
    (() => { try { require('fs').rmSync(dir, { recursive: true, force: true }); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })();
    return walked.join(",");
}

// Internal, test scaffolding: the `Error` of `walk(root)`, `""` when it walked.

function walkRefusal(root) {
    return (() => {
        const _s = (() => { try { const __fs = require('fs'); const __p = require('path'); const __all = __fs.readdirSync(root, { recursive: true }).map(__f => String(__f).split(__p.sep).join('/')).sort(); const __out = []; for (const __f of __all) { const __s = __fs.statSync(__p.join(root, __f), { throwIfNoEntry: false }); if (__s === undefined) return { error: 'fs.walk: dangling link "' + __f + '"' }; if (__s.isFile()) __out.push(__f) } return { ok: __out } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })();
        if ("ok" in _s) {
            return "";
        }
        if ("error" in _s) {
            const reason = _s.error;
            return reason;
        }
    })();
}

// Internal, test scaffolding: the fixture tree plus the names decision 177 is

// about — a dot file and a dot directory, a link to a directory, a link to a

// file and a dangling link, all under `<dir>/app`.

function makeGlobTree(dir) {
    makeFixtureTree(dir);
    (() => { try { require('fs').mkdirSync([dir, "/app/.cache"].join("")); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })();
    (() => { try { require('fs').writeFileSync([dir, "/app/.cache/page.bp"].join(""), "cached"); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })();
    (() => { try { require('fs').writeFileSync([dir, "/app/.hidden.bp"].join(""), "hidden"); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })();
    (() => { try { require('fs').writeFileSync([dir, "/app/blog/.draft.md"].join(""), "draft"); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })();
    require('fs').symlinkSync("blog", [dir, "/app/linked"].join(""));
    require('fs').symlinkSync("page.bp", [dir, "/app/alias.bp"].join(""));
    require('fs').symlinkSync("missing.bp", [dir, "/app/gone.bp"].join(""));
}

// Internal, test scaffolding: what `glob(pattern, <dir>/app)` answers over

// `makeGlobTree`, joined by `,`.

function globbed(pattern) {
    const dir = require('fs').mkdtempSync(require('path').join(require('os').tmpdir(), 'bp-std-fs-'));
    makeGlobTree(dir);
    const found = ((_r) => "error" in _r ? (["<error>"]) : _r.ok)((() => { try { const __fs = require('fs'); const __p = require('path'); const __root = [dir, "/app"].join(""); const __pat = String(pattern); const __segs = __pat.split('/').filter(__s => __s !== '' && __s !== '.'); const __dirsOnly = __pat.endsWith('/'); const __lst = (__f) => { try { return __fs.lstatSync(__f, { throwIfNoEntry: false }) } catch (__e) { return undefined } }; const __realDir = (__f) => { const __s = __lst(__f); return __s !== undefined && __s.isDirectory() }; const __linkedDir = (__f) => { try { const __s = __fs.statSync(__f, { throwIfNoEntry: false }); return __s !== undefined && __s.isDirectory() } catch (__e) { return false } }; const __magic = (__s) => __s.includes('*') || __s.includes('?') || __s.includes('[') || __s.includes('{'); const __names = (__dir, __seg) => { let __all; try { __all = (__seg === '*' ? __fs.readdirSync(__dir) : __fs.globSync(__seg, { cwd: __dir })).map(String) } catch (__e) { __all = [] } return __all.filter(__n => !__n.startsWith('.') || __seg.startsWith('.')) }; const __join = (__rel, __n) => __rel === '' ? __n : __rel + '/' + __n; const __out = new Set(); const __walk = (__i, __dir, __rel) => { if (__i === __segs.length) { if (__rel !== '') __out.add(__rel); return } const __seg = __segs[__i]; const __last = __i === __segs.length - 1; if (__seg === '**') { if (!__last) __walk(__i + 1, __dir, __rel); for (const __n of __names(__dir, '*')) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); if (__realDir(__f)) __walk(__i, __f, __sub) } return } if (!__magic(__seg)) { const __f = __p.join(__dir, __seg); const __sub = __join(__rel, __seg); if (__last) { if (__lst(__f) !== undefined) __out.add(__sub) } else if (__linkedDir(__f)) __walk(__i + 1, __f, __sub); return } for (const __n of __names(__dir, __seg)) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); else if (__realDir(__f)) __walk(__i + 1, __f, __sub) } }; __walk(0, __root, ''); return { ok: Array.from(__out).filter(__r => !__dirsOnly || __realDir(__p.join(__root, __r))).sort() } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })());
    (() => { try { require('fs').rmSync(dir, { recursive: true, force: true }); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })();
    return found.join(",");
}
```

----- TYPESCRIPT TYPEDEF -- std/io/fs.d.ts
```typescript
import { relative } from "../../std/path";


export declare class FileStat {
    readonly size: number;
    readonly mtime: number;
    readonly isDir: boolean;
    constructor(size: number, mtime: number, isDir: boolean);
}


export declare function readText(path: string): { ok: string } | { error: string };


export declare function writeText(path: string, contents: string): { ok: number } | { error: string };


export declare function exists(path: string): boolean;


export declare function list(path: string): { ok: string[] } | { error: string };


export declare function mkdir(path: string): { ok: number } | { error: string };


export declare function rm(path: string): { ok: number } | { error: string };


export declare function copy(src: string, dest: string): { ok: number } | { error: string };


export declare function stat(path: string): { ok: FileStat } | { error: string };


export declare function walk(root: string): { ok: string[] } | { error: string };


export declare function glob(pattern: string, root: string): { ok: string[] } | { error: string };


export declare function removeTree(path: string): { ok: number } | { error: string };



















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

