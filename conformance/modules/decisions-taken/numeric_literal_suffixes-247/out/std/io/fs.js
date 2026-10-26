function __bp_array_at(xs, i) { return xs.at(i) ?? null; }

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

function __bp_case_map(t) {
    const m = new Map();
    for (const e of t.split(" ")) {
        const p = e.replace("!", "").split(",").map((x) => parseInt(x, 36));
        if (e[0] === "!") { m.set(p[0], String.fromCodePoint(...p.slice(1))); continue; }
        for (let i = 0; i < p[1]; i += 1) m.set(p[0] + i * p[2], String.fromCodePoint(p[0] + i * p[2] + p[3]));
    }
    return m;
}

function __bp_case(s, m) {
    let o = "";
    for (const c of s) {
        const r = m.get(c.codePointAt(0));
        o += (r === undefined) ? c : r;
    }
    return o;
}

function __bp_upper(s) {
    return __bp_case(s, __bp_upper.m ??= __bp_case_map("2p,q,1,-w 51,1,2,kn 68,n,1,-w 6w,7,1,-w 73,1,2,3d 75,o,2,-1 8h,1,2,-6g 8j,3,2,-1 8q,8,2,-1 97,n,2,-1 ai,3,2,-1 an,1,2,-8c ao,1,2,5f ar,2,2,-1 aw,1,2,-1 b0,1,2,-1 b6,1,2,-1 b9,1,2,2p bd,1,2,-1 be,1,2,4j bf,1,2,wu9 bi,1,2,3m bl,3,2,-1 bs,1,2,-1 bx,1,2,-1 c0,1,2,-1 c4,2,2,-1 c9,1,2,-1 cd,1,2,-1 cf,1,2,1k cl,1,2,-1 cm,1,2,-2 co,1,2,-1 cp,1,2,-2 cr,1,2,-1 cs,1,2,-2 cu,8,2,-1 d9,1,2,-27 db,9,2,-1 du,1,2,-1 dv,1,2,-2 dx,1,2,-1 e1,k,2,-1 f7,9,2,-1 fw,1,2,-1 fz,2,1,8cf g2,1,2,-1 g7,5,2,-1 gg,1,2,8bj gh,1,2,8bg gi,1,2,8bi gj,1,2,-5u gk,1,2,-5q gm,2,1,-5p gp,1,2,-5m gr,1,2,-5n gs,1,2,wnj gw,1,2,-5p gx,1,2,wnf gz,1,2,-5r h0,1,2,wo7 h1,1,2,wmg h2,1,2,wn8 h4,1,2,-5t h5,1,2,-5v h6,1,2,wn8 h7,1,2,8af h8,1,2,wn5 hb,1,2,-5v hd,1,2,8al he,1,2,-5x hh,1,2,-5y hp,1,2,89z hs,1,2,-62 hu,1,2,wn7 hv,1,2,-62 hz,1,2,wmi i0,1,2,-62 i1,1,2,-1x i2,2,1,-61 i4,1,2,-1z ia,1,2,-63 il,1,2,wlx im,1,2,wlu n9,1,2,2c oh,2,2,-1 on,1,2,-1 or,3,1,3m q4,1,2,-12 q5,3,1,-11 q9,h,1,-w qq,1,2,-v qr,9,1,-w r0,1,2,-1s r1,2,1,-1r r4,1,2,-1q r5,1,2,-1l r9,1,2,-1b ra,1,2,-1i rb,1,2,-8 rd,c,2,-1 s0,1,2,-2e s1,1,2,-28 s2,1,2,7 s3,1,2,-38 s5,1,2,-2o s8,1,2,-1 sb,1,2,-1 ts,w,1,-w uo,g,1,-28 v5,h,2,-1 wb,r,2,-1 xu,7,2,-1 y7,1,2,-f y9,1c,2,-1 129,12,1,-1c 3bk,17,1,2bk 3ct,3,1,2bk 3y0,6,1,-8 5mo,1,2,-4tq 5mp,1,2,-4tp 5mq,1,2,-4tg 5mr,2,1,-4te 5mt,1,2,-4tf 5mu,1,2,-4t8 5mv,1,2,-4rp 5mw,1,2,r7m 5my,1,2,-1 5tl,1,2,r9g 5tp,1,2,2xy 5u6,1,2,raw 5xd,23,2,-1 61n,1,2,-1n 61t,1c,2,-1 64g,8,1,8 64w,6,1,8 65c,8,1,8 65s,8,1,8 668,6,1,8 66p,4,2,8 674,8,1,8 67k,2,1,22 67m,4,1,2e 67q,2,1,2s 67s,2,1,3k 67u,2,1,34 67w,2,1,3i 69c,2,1,8 69q,1,2,-5k5 6a8,2,1,8 6ao,2,1,8 6at,1,2,7 6ku,1,2,-s 6ls,g,1,-g 6mc,1,2,-1 79s,q,1,-q 8q8,1c,1,-1c 8rl,1,2,-1 8rp,1,2,-8bv 8rq,1,2,-8bs 8rs,3,2,-1 8s3,1,2,-1 8s6,1,2,-1 8sh,1e,2,-1 8vg,2,2,-1 8vn,1,2,-1 8w0,12,1,-5ls 8x3,1,2,-5ls 8x9,1,2,-5ls wu9,n,2,-1 ww1,e,2,-1 x0j,7,2,-1 x0z,v,2,-1 x2y,2,2,-1 x33,5,2,-1 x3g,1,2,-1 x3l,2,2,-1 x3o,1,2,1c x3r,a,2,-1 x4l,8,2,-1 x54,2,2,-1 x59,8,2,-1 x6e,1,2,-1 xub,1,2,-ps xv4,28,1,-tzk 1ef5,q,1,-w 1fe0,14,1,-14 1fiw,10,1,-14 1fo7,b,1,-13 1foj,f,1,-13 1foz,7,1,-13 1fp7,2,1,-13 1h34,1f,1,-1s 1h80,m,1,-w 1jgg,w,1,-w 20dc,w,1,-w 20fv,p,1,-r 2oma,y,1,-y !67,2b,2b !95,jg,26 !ds,22,lo !pc,pl,lk,ld !q8,px,lk,ld !13b,111,11u !61i,20,mp !61j,2c,lk !61k,2f,lm !61l,2h,lm !61m,1t,ji !66o,px,lv !66q,px,lv,lc !66s,px,lv,ld !66u,px,lv,n6 !680,64o,pl !681,64p,pl !682,64q,pl !683,64r,pl !684,64s,pl !685,64t,pl !686,64u,pl !687,64v,pl !688,64o,pl !689,64p,pl !68a,64q,pl !68b,64r,pl !68c,64s,pl !68d,64t,pl !68e,64u,pl !68f,64v,pl !68g,65k,pl !68h,65l,pl !68i,65m,pl !68j,65n,pl !68k,65o,pl !68l,65p,pl !68m,65q,pl !68n,65r,pl !68o,65k,pl !68p,65l,pl !68q,65m,pl !68r,65n,pl !68s,65o,pl !68t,65p,pl !68u,65q,pl !68v,65r,pl !68w,67c,pl !68x,67d,pl !68y,67e,pl !68z,67f,pl !690,67g,pl !691,67h,pl !692,67i,pl !693,67j,pl !694,67c,pl !695,67d,pl !696,67e,pl !697,67f,pl !698,67g,pl !699,67h,pl !69a,67i,pl !69b,67j,pl !69e,69m,pl !69f,pd,pl !69g,p2,pl !69i,pd,n6 !69j,pd,n6,pl !69o,pd,pl !69u,6a2,pl !69v,pj,pl !69w,p5,pl !69y,pj,n6 !69z,pj,n6,pl !6a4,pj,pl !6aa,pl,lk,lc !6ab,pl,lk,ld !6ae,pl,n6 !6af,pl,lk,n6 !6aq,px,lk,lc !6ar,px,lk,ld !6as,pt,lv !6au,px,n6 !6av,px,lk,n6 !6b6,6be,pl !6b7,q1,pl !6b8,pb,pl !6ba,q1,n6 !6bb,q1,n6,pl !6bg,q1,pl !1dkw,1y,1y !1dkx,1y,21 !1dky,1y,24 !1dkz,1y,1y,21 !1dl0,1y,1y,24 !1dl1,2b,2c !1dl2,2b,2c !1dlf,11g,11i !1dlg,11g,111 !1dlh,11g,117 !1dli,11q,11i !1dlj,11g,119"));
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

function __bp_host_fail(F, e) {
    const n = e instanceof Error;
    return { error: new F.HostError(n ? e.message : String(e), "host", n ? F.HostErrorName.Error : F.HostErrorName.Throw, (n && typeof e.stack === "string") ? e.stack : null) };
}

function __bp_host_result(F, f) {
    try {
        return { ok: f() };
    } catch (e) {
        return __bp_host_fail(F, e);
    }
}

function __bp_adopt(v, C, p) { return (v == null) ? v : (p === "") ? ((typeof v === "object" && !(v instanceof C)) ? Object.assign(Object.create(C.prototype), v) : v) : (p[0] === "a") ? (Array.isArray(v) ? v.map((e) => __bp_adopt(e, C, p.slice(1))) : v) : (p[0] === "r" && typeof v === "object" && "ok" in v) ? { ok: __bp_adopt(v.ok, C, p.slice(1)) } : v; }

function __bp_wnorm(v, u, what) {
    if (u ? (v < 0n || v > 18446744073709551615n) : (v < -9223372036854775808n || v > 9223372036854775807n)) { throw Object.defineProperty(new Error("integer overflow: " + what), "__bp_panic", { value: true }); }
    return (v >= -9007199254740991n && v <= 9007199254740991n) ? Number(v) : v;
}

function __bp_wadd(a, b, u, what) {
    if (typeof a === "number" && typeof b === "number") { const r = a + b + 0; if (Number.isSafeInteger(r) && (r >= 0 || !u)) { return r; } }
    return __bp_wnorm(BigInt(a) + BigInt(b), u, what);
}

// behavior bool
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

// behavior bytes
//   fn fromUtf8(...)
//   fn toUtf8(...)
//   fn length(...)
//   fn concat(...)
//   default fn slice(...)
Uint8Array.prototype.toUtf8 = function() { return ((__b) => require('buffer').isUtf8(__b) ? { ok: new TextDecoder("utf-8", { ignoreBOM: true }).decode(__b) } : { error: "bytes.toUtf8: not valid UTF-8" })(this); };
Uint8Array.prototype.concat = function(other) { return ((__a, __b) => { const __r = new Uint8Array(__a.length + __b.length); __r.set(__a, 0); __r.set(__b, __a.length); return __r; })(this, other); };
Uint8Array.prototype.slice = function(start, end) {
    if ((end != null)) { return ((__b, __a, __e) => { if (__a == null) __a = 0; const __n = __b.length; const __s = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return new Uint8Array(__b.subarray(__s, Math.max(__s, __f))); })(this, start, end); } else { return ((__b, __a) => { if (__a == null) __a = 0; const __n = __b.length; const __s = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return new Uint8Array(__b.subarray(__s, __n)); })(this, start); }
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
BigInt.prototype.isEven = Number.prototype.isEven = function() {
    const self = this.valueOf();
    return ((self % 2) === 0);
};
BigInt.prototype.isOdd = Number.prototype.isOdd = function() {
    const self = this.valueOf();
    return ((self % 2) !== 0);
};
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

const { relative } = require("../../std/path.js");
const { HostError } = require("../../std/failure.js");

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

    static message(self) {
        return (() => {
            const _s = self;
            if (_s.tag === "NotFound") {
                const { path } = _s;
                return ("not found: " + path);
            }
            if (_s.tag === "PermissionDenied") {
                const { path } = _s;
                return ("permission denied: " + path);
            }
            if (_s.tag === "IsDirectory") {
                const { path } = _s;
                return ("is a directory: " + path);
            }
            if (_s.tag === "NotDirectory") {
                const { path } = _s;
                return ("not a directory: " + path);
            }
            if (_s.tag === "AlreadyExists") {
                const { path } = _s;
                return ("already exists: " + path);
            }
            if (_s.tag === "InvalidUtf8") {
                const { path, offset } = _s;
                return ((("not UTF-8: " + path) + " at byte ") + offset.toString());
            }
            if (_s.tag === "Other") {
                const { path, message } = _s;
                return ((path + ": ") + message);
            }
            throw new Error("case_clause");
        })();
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

    get $0() {
        return this.path;
    }
}
FsError$NotFound.prototype.tag = "NotFound";
class FsError$PermissionDenied extends FsError {
    constructor(path) {
        super();
        this.path = path;
    }

    get $0() {
        return this.path;
    }
}
FsError$PermissionDenied.prototype.tag = "PermissionDenied";
class FsError$IsDirectory extends FsError {
    constructor(path) {
        super();
        this.path = path;
    }

    get $0() {
        return this.path;
    }
}
FsError$IsDirectory.prototype.tag = "IsDirectory";
class FsError$NotDirectory extends FsError {
    constructor(path) {
        super();
        this.path = path;
    }

    get $0() {
        return this.path;
    }
}
FsError$NotDirectory.prototype.tag = "NotDirectory";
class FsError$AlreadyExists extends FsError {
    constructor(path) {
        super();
        this.path = path;
    }

    get $0() {
        return this.path;
    }
}
FsError$AlreadyExists.prototype.tag = "AlreadyExists";
class FsError$InvalidUtf8 extends FsError {
    constructor(path, offset) {
        super();
        this.path = path;
        this.offset = offset;
    }

    get $0() {
        return this.path;
    }

    get $1() {
        return this.offset;
    }
}
FsError$InvalidUtf8.prototype.tag = "InvalidUtf8";
class FsError$Other extends FsError {
    constructor(path, message) {
        super();
        this.path = path;
        this.message = message;
    }

    get $0() {
        return this.path;
    }

    get $1() {
        return this.message;
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

function rawReadBytes(path) { return __bp_host_result(require("../../std/failure.js"), () => (() => { return new Uint8Array(require('fs').readFileSync(path)) })()); }

// Write `contents` to `path`, creating or truncating.

// Node: `writeFileSync($0, $1)`. Erlang: `file:write_file/2`.

function rawWriteBytes(path, contents) { return __bp_host_result(require("../../std/failure.js"), () => (() => { require('fs').writeFileSync(path, contents); return 0 })()); }

// Append `contents` to `path`, creating it when it is not there.

// Node: `appendFileSync($0, $1)`. Erlang: `file:write_file/3` with `append`.

function rawAppendText(path, contents) { return __bp_host_result(require("../../std/failure.js"), () => (() => { require('fs').appendFileSync(path, contents); return 0 })()); }

// The offset of the first byte that starts a sequence that is not UTF-8 (a byte no sequence

// starts with, a sequence cut short, an overlong form, a surrogate, a code point past U+10FFFF),

// or -1 when every byte is part of a valid sequence — the same offset on every target.

// Node: a scan of the bytes. Erlang: `unicode:characters_to_binary/3`, whose `Good` prefix is the offset.

// utf8Offset: per-call template (see annotation)

// `line` without its line terminator: one trailing `\n`, and the `\r` before it.

// Node: `subarray`. Erlang: `binary:part/3`.

// stripEol: per-call template (see annotation)

// The handle of the file at `path`, open for reading. A directory is `isdir` on both hosts

// (Node opens one; the template refuses it). The handle is host-owned and opaque: a `{ fd,

// mem, pos, buf }` object on Node, an io device on Erlang (a stream reads it in its own process).

function rawOpen(path) { return __bp_host_result(require("../../std/failure.js"), () => (() => { const __fs = require('fs'); const __p = path; const __fd = __fs.openSync(__p, 'r'); if (__fs.fstatSync(__fd).isDirectory()) { __fs.closeSync(__fd); throw new Error('EISDIR: illegal operation on a directory, open ' + JSON.stringify(__p)) } return { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } })()); }

// The handle of the file at `path`, open for writing: created, or truncated.

function rawCreate(path) { return __bp_host_result(require("../../std/failure.js"), () => (() => { const __fd = require('fs').openSync(path, 'w'); return { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } })()); }

// A handle over bytes held in memory — what an `Asset` opens as. The position is a field

// on Node and a `counters` cell on Erlang.

// memHandle: per-call template (see annotation)

// The size of the file behind `handle`, in bytes. On Erlang it reads `path`.

function rawSize(handle, path) { return __bp_host_result(require("../../std/failure.js"), () => (() => { const __h = handle; return __h.mem ? __h.mem.length : require('fs').fstatSync(__h.fd).size })()); }

// Up to `n` bytes (n > 0) from the handle's position; empty at the end.

function rawRead(handle, n) { return __bp_host_result(require("../../std/failure.js"), () => (() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = handle; const __n = n; if (__h.buf.length > 0) { const __k = Math.min(__n, __h.buf.length); const __o = new Uint8Array(__h.buf.subarray(0, __k)); __h.buf = __h.buf.subarray(__k); return __o } return new Uint8Array(__more(__h, __n)) })()); }

// Every byte from the handle's position to the end.

function rawReadAll(handle) { return __bp_host_result(require("../../std/failure.js"), () => (() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = handle; const __parts = []; if (__h.buf.length > 0) { __parts.push(__h.buf); __h.buf = new Uint8Array(0) } for (;;) { const __r = __more(__h, 65536); if (__r.length === 0) break; __parts.push(new Uint8Array(__r)) } let __t = 0; for (const __x of __parts) __t += __x.length; const __o = new Uint8Array(__t); let __p = 0; for (const __x of __parts) { __o.set(__x, __p); __p += __x.length } return __o })()); }

// The next line, terminator included; empty at the end.

function rawReadLine(handle) { return __bp_host_result(require("../../std/failure.js"), () => (() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = handle; for (;;) { const __i = __h.buf.indexOf(10); if (__i >= 0) { const __l = new Uint8Array(__h.buf.subarray(0, __i + 1)); __h.buf = __h.buf.subarray(__i + 1); return __l } const __r = __more(__h, 65536); if (__r.length === 0) { const __l = __h.buf; __h.buf = new Uint8Array(0); return __l } const __nb = new Uint8Array(__h.buf.length + __r.length); __nb.set(__h.buf, 0); __nb.set(__r, __h.buf.length); __h.buf = __nb } })()); }

// The SHA-256 of the whole file behind the handle, lowercase hex — from its first byte,

// whatever the position, which it leaves where it was. On Erlang `file:pread` leaves the

// position undefined (OTP moves it), so the position is read first and restored.

function rawHash(handle) { return __bp_host_result(require("../../std/failure.js"), () => (() => { const __h = handle; const __hs = require('crypto').createHash('sha256'); if (__h.mem) { __hs.update(__h.mem) } else { const __b = new Uint8Array(65536); let __pos = 0; for (;;) { const __k = require('fs').readSync(__h.fd, __b, 0, 65536, __pos); if (__k === 0) break; __hs.update(__b.subarray(0, __k)); __pos += __k } } return __hs.digest('hex') })()); }

// Write `bytes` at the handle's position; answers how many.

function rawWrite(handle, bytes) { return __bp_host_result(require("../../std/failure.js"), () => (() => { const __h = handle; const __b = bytes; let __o = 0; while (__o < __b.length) __o += require('fs').writeSync(__h.fd, __b, __o, __b.length - __o); return __b.length })()); }

// Close the handle. A failure to close is not reported (a `Closeable`'s `close` answers nothing).

function rawClose(handle) { return __bp_host_result(require("../../std/failure.js"), () => (() => { const __h = handle; if (!__h.mem) require('fs').closeSync(__h.fd); return 0 })()); }

// Write `contents` to `path`, creating or truncating. Reds with the

// host's I/O error message.

// Node: `require('fs').writeFileSync($0, $1)`.

// Erlang: `file:write_file/2`.

function rawWriteText(path, contents) { return __bp_host_result(require("../../std/failure.js"), () => (() => { require('fs').writeFileSync(path, contents); return 0 })()); }

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

function rawList(path) { return __bp_host_result(require("../../std/failure.js"), () => (() => { return require('fs').readdirSync(path) })()); }

// Create directory at `path`. Use `mkdirRecursive` to create

// intermediate parents.

// Node: `require('fs').mkdirSync($0)`.

// Erlang: `file:make_dir/1`.

function rawMkdir(path) { return __bp_host_result(require("../../std/failure.js"), () => (() => { require('fs').mkdirSync(path); return 0 })()); }

// Create the directory at `path` and every missing directory above it. A

// directory that is already there is `Ok` too; a path that exists as anything

// else (a file) is an `Error`. What the snapshot library (`snap`) makes the

// directory of a `.snap` with (decision 391).

// Node: `require('fs').mkdirSync($0, { recursive: true })`.

// Erlang: `filelib:ensure_path/1`.

function rawMkdirRecursive(path) { return __bp_host_result(require("../../std/failure.js"), () => (() => { require('fs').mkdirSync(path, { recursive: true }); return 0 })()); }

// Delete the FILE at `path`. A directory — empty or not — is `IsDirectory` on

// both hosts (Node's `ERR_FS_EISDIR`; Erlang's `eperm` is read as `eisdir` after

// a `read_link_info`, so the variant is the same); `removeTree` removes one.

// Node: `require('fs').rmSync($0)`.

// Erlang: `file:delete/1`.

function rawRm(path) { return __bp_host_result(require("../../std/failure.js"), () => (() => { require('fs').rmSync(path); return 0 })()); }

// Copy file from `src` to `dest`. Reds when `src` is missing or

// `dest` already exists (Node's default `copyFileSync` semantics).

// Node: `require('fs').copyFileSync($0, $1)`.

// Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).

function rawCopy(src, dest) { return __bp_host_result(require("../../std/failure.js"), () => (() => { require('fs').copyFileSync(src, dest); return 0 })()); }

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

function rawStat(path) { return __bp_host_result(require("../../std/failure.js"), () => __bp_adopt((() => { const __s = require('fs').statSync(path, { bigint: true }); const __c = (__v) => (__v >= -9007199254740991n && __v <= 9007199254740991n) ? Number(__v) : __v; const __ns = __s.mtimeNs; return { size: __c(__s.size), mtime: __c(((__ns - (((__ns % 1000000000n) + 1000000000n) % 1000000000n)) / 1000000000n) * 1000n), isDir: __s.isDirectory() } })(), FileStat, "")); }

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

function rawWalk(root) { return __bp_host_result(require("../../std/failure.js"), () => __bp_adopt((() => { const __fs = require('fs'); const __p = require('path'); const __all = __fs.readdirSync(root, { recursive: true }).map(__f => String(__f).split(__p.sep).join('/')).sort(); const __out = []; const __dng = []; for (const __f of __all) { const __s = __fs.statSync(__p.join(root, __f), { throwIfNoEntry: false }); if (__s === undefined) { __dng.push(__f); continue } if (__s.isFile()) __out.push(__f) } return { files: __out, dangling: __dng } })(), Walked, "")); }

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

function rawRemoveTree(path) { return __bp_host_result(require("../../std/failure.js"), () => (() => { require('fs').rmSync(path, { recursive: true, force: true }); return 0 })()); }

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

// The `FsError` of `path` a host's failure is (decision 486), read from its code: Node's `ENOENT: …`, erlang's `enoent`.

function fsError(path, e) {
    const u = __bp_upper(e.message);
    if (u.startsWith("ENOENT")) { return FsError.NotFound(path); }
    if ((u.startsWith("EACCES") || u.startsWith("EPERM"))) { return FsError.PermissionDenied(path); }
    if ((u.startsWith("EISDIR") || u.startsWith("PATH IS A DIRECTORY"))) { return FsError.IsDirectory(path); }
    if (u.startsWith("ENOTDIR")) { return FsError.NotDirectory(path); }
    if (u.startsWith("EEXIST")) { return FsError.AlreadyExists(path); }
    return FsError.Other(path, e.message);
}

// A host cell's answer, its failure read as an `FsError` of `path`.

function lift(path, r) {
    const _case0 = (() => {
        const _s = r;
        if ("ok" in _s) {
            const v = _s.ok;
            return ({ __bp_return: true, value: ({ ok: v }) });
        }
        if ("error" in _s) {
            const e = _s.error;
            return ({ __bp_return: true, value: ({ error: fsError(path, e) }) });
        }
        throw new Error("case_clause");
    })();
    if (_case0 && _case0.__bp_return) return _case0.value;
}

// The text of `b`, or `InvalidUtf8` at the first invalid byte.

function decode(path, b) {
    const offset = ((__b) => { const __n = __b.length; let __i = 0; while (__i < __n) { const __c = __b[__i]; if (__c < 128) { __i++; continue } let __k; if (__c >= 194 && __c <= 223) __k = 1; else if (__c >= 224 && __c <= 239) __k = 2; else if (__c >= 240 && __c <= 244) __k = 3; else return __i; if (__i + __k >= __n) return __i; let __lo = 128, __hi = 191; if (__c === 224) __lo = 160; else if (__c === 237) __hi = 159; else if (__c === 240) __lo = 144; else if (__c === 244) __hi = 143; const __d = __b[__i + 1]; if (__d < __lo || __d > __hi) return __i; for (let __j = 2; __j <= __k; __j++) { const __e = __b[__i + __j]; if (__e < 128 || __e > 191) return __i } __i += __k + 1 } return -1 })(b);
    if ((offset >= 0)) { return ({ error: FsError.InvalidUtf8(path, offset) }); }
    return ({ ok: ((_r) => "error" in _r ? ("") : _r.ok)(b.toUtf8()) });
}

// What `rawWalk` finds under a root: the regular files, and the links whose

// target is missing, both as paths relative to the root, sorted.

class Walked {
    constructor(files, dangling) {
        this.files = files;
        this.dangling = dangling;
    }
}
Walked.prototype.__bp = "Walked";

// Whether the handle is one over bytes held in memory (an `Asset`'s), which cannot be written.

// rawReadOnly: per-call template (see annotation)

// ── whole-file shortcuts ─────────────────────────────────────────────────────

// The file's bytes.

function readBytes(path) {
    const _try0 = lift(path, rawReadBytes(path));
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
    const _try0 = lift(path, rawWriteBytes(path, contents));
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.writeBytes = writeBytes;

function writeText(path, contents) {
    const _try0 = lift(path, rawWriteText(path, contents));
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.writeText = writeText;

// Append `contents`, creating the file when it is not there.

function appendText(path, contents) {
    const _try0 = lift(path, rawAppendText(path, contents));
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.appendText = appendText;

// ── metadata and directories ─────────────────────────────────────────────────

function stat(path) {
    const _try0 = lift(path, rawStat(path));
    if ("error" in _try0) return _try0;
    const s = _try0.ok;
    return ({ ok: s });
}
exports.stat = stat;

function list(path) {
    const _try0 = lift(path, rawList(path));
    if ("error" in _try0) return _try0;
    const names = _try0.ok;
    return ({ ok: names });
}
exports.list = list;

function mkdir(path) {
    const _try0 = lift(path, rawMkdir(path));
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.mkdir = mkdir;

function mkdirRecursive(path) {
    const _try0 = lift(path, rawMkdirRecursive(path));
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.mkdirRecursive = mkdirRecursive;

function rm(path) {
    const _try0 = lift(path, rawRm(path));
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.rm = rm;

function removeTree(path) {
    const _try0 = lift(path, rawRemoveTree(path));
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.removeTree = removeTree;

function copy(src, dest) {
    const _try0 = lift(src, rawCopy(src, dest));
    if ("error" in _try0) return _try0;
    const n = _try0.ok;
    return ({ ok: n });
}
exports.copy = copy;

function walk(root) {
    const _try0 = lift(root, rawWalk(root));
    if ("error" in _try0) return _try0;
    const found = _try0.ok;
    if ((found.dangling.length > 0)) { const first = (() => { const __bp_nullish = __bp_array_at(found.dangling, 0); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })(); return ({ error: FsError.Other(root, ["fs.walk: dangling link \"", first, "\""].join("")) }); }
    return ({ ok: found.files });
}
exports.walk = walk;

function glob(pattern, root) {
    return ({ ok: (() => { const __fs = require('fs'); const __p = require('path'); const __root = root; const __pat = String(pattern); const __segs = __pat.split('/').filter(__s => __s !== '' && __s !== '.'); const __dirsOnly = __pat.endsWith('/'); const __lst = (__f) => { try { return __fs.lstatSync(__f, { throwIfNoEntry: false }) } catch (__e) { return undefined } }; const __realDir = (__f) => { const __s = __lst(__f); return __s !== undefined && __s.isDirectory() }; const __linkedDir = (__f) => { try { const __s = __fs.statSync(__f, { throwIfNoEntry: false }); return __s !== undefined && __s.isDirectory() } catch (__e) { return false } }; const __magic = (__s) => __s.includes('*') || __s.includes('?') || __s.includes('[') || __s.includes('{'); const __names = (__dir, __seg) => { let __all; try { __all = (__seg === '*' ? __fs.readdirSync(__dir) : __fs.globSync(__seg, { cwd: __dir })).map(String) } catch (__e) { __all = [] } return __all.filter(__n => !__n.startsWith('.') || __seg.startsWith('.')) }; const __join = (__rel, __n) => __rel === '' ? __n : __rel + '/' + __n; const __out = new Set(); const __walk = (__i, __dir, __rel) => { if (__i === __segs.length) { if (__rel !== '') __out.add(__rel); return } const __seg = __segs[__i]; const __last = __i === __segs.length - 1; if (__seg === '**') { if (!__last) __walk(__i + 1, __dir, __rel); for (const __n of __names(__dir, '*')) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); if (__realDir(__f)) __walk(__i, __f, __sub) } return } if (!__magic(__seg)) { const __f = __p.join(__dir, __seg); const __sub = __join(__rel, __seg); if (__last) { if (__lst(__f) !== undefined) __out.add(__sub) } else if (__linkedDir(__f)) __walk(__i + 1, __f, __sub); return } for (const __n of __names(__dir, __seg)) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); else if (__realDir(__f)) __walk(__i + 1, __f, __sub) } }; __walk(0, __root, ''); return Array.from(__out).filter(__r => !__dirsOnly || __realDir(__p.join(__root, __r))).sort() })() });
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
        const _try0 = lift(this.location, rawSize(this.handle, this.location));
        if ("error" in _try0) return _try0;
        const n = _try0.ok;
        return ({ ok: n });
    }

    read(n) {
        if ((n <= 0)) { return ({ ok: (new TextEncoder().encode("")) }); }
        const _try1 = lift(this.location, rawRead(this.handle, n));
        if ("error" in _try1) return _try1;
        const b = _try1.ok;
        return ({ ok: b });
    }

    bytes() {
        const _try2 = lift(this.location, rawReadAll(this.handle));
        if ("error" in _try2) return _try2;
        const b = _try2.ok;
        return ({ ok: b });
    }

    text() {
        const _try3 = this.bytes();
        if ("error" in _try3) return _try3;
        const b = _try3.ok;
        const _try4 = decode(this.location, b);
        if ("error" in _try4) return _try4;
        const s = _try4.ok;
        return ({ ok: s });
    }

    async *chunks(size) {
        while (true) {
    const _try5 = this.read(size);
        if ("error" in _try5) { yield _try5; return; }
        const b = _try5.ok;
    if ((b.length === 0)) { break; }
    yield ({ ok: b });
}
    }

    async *lines() {
        let consumed = 0;
        while (true) {
    const _try6 = lift(this.location, rawReadLine(this.handle));
        if ("error" in _try6) { yield _try6; return; }
        const raw = _try6.ok;
    if ((raw.length === 0)) { break; }
    const line = ((__b) => { let __n = __b.length; if (__n > 0 && __b[__n - 1] === 10) { __n--; if (__n > 0 && __b[__n - 1] === 13) __n-- } return __b.subarray(0, __n) })(raw);
    const offset = ((__b) => { const __n = __b.length; let __i = 0; while (__i < __n) { const __c = __b[__i]; if (__c < 128) { __i++; continue } let __k; if (__c >= 194 && __c <= 223) __k = 1; else if (__c >= 224 && __c <= 239) __k = 2; else if (__c >= 240 && __c <= 244) __k = 3; else return __i; if (__i + __k >= __n) return __i; let __lo = 128, __hi = 191; if (__c === 224) __lo = 160; else if (__c === 237) __hi = 159; else if (__c === 240) __lo = 144; else if (__c === 244) __hi = 143; const __d = __b[__i + 1]; if (__d < __lo || __d > __hi) return __i; for (let __j = 2; __j <= __k; __j++) { const __e = __b[__i + __j]; if (__e < 128 || __e > 191) return __i } __i += __k + 1 } return -1 })(line);
    if ((offset >= 0)) { yield ({ error: FsError.InvalidUtf8(this.location, __bp_wadd(consumed, offset, 0, "+ on i64 at src/io/fs.bp:561:21")) }); return; }
    const width = raw.length;
    consumed = __bp_wadd(consumed, width.toI64(), 0, "+ on i64 at src/io/fs.bp:563:33");
    yield ({ ok: ((_r) => "error" in _r ? ("") : _r.ok)(line.toUtf8()) });
}
    }

    hash() {
        const _try7 = lift(this.location, rawHash(this.handle));
        if ("error" in _try7) return _try7;
        const h = _try7.ok;
        return ({ ok: h });
    }

    write(b) {
        if (((this.handle).mem != null)) { return ({ error: FsError.Other(this.location, "the file is open for reading") }); }
        const _try8 = lift(this.location, rawWrite(this.handle, b));
        if ("error" in _try8) return _try8;
        const n = _try8.ok;
        return ({ ok: n });
    }

    close() {
        const closed = rawClose(this.handle);
    }
}
File.prototype.__bp = "File";
File.prototype["__bp_b_std@primitives@@Closeable"] = true;
exports.File = File;

// Open the file at `path` for reading. A directory is `IsDirectory` on every target.

function open(path) {
    const _try0 = lift(path, rawOpen(path));
    if ("error" in _try0) return _try0;
    const h = _try0.ok;
    return ({ ok: new File(path, h) });
}
exports.open = open;

// Open the file at `path` for writing: created, or truncated.

function create(path) {
    const _try0 = lift(path, rawCreate(path));
    if ("error" in _try0) return _try0;
    const h = _try0.ok;
    return ({ ok: new File(path, h) });
}
exports.create = create;

// An `Asset` (`@embed`, decisions 519, 538) as a `File`: the embedded bytes, read

// like a file on disk — no `Result`, the build proved the file exists — and

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
        throw new Error("case_clause");
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
        throw new Error("case_clause");
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
        throw new Error("case_clause");
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
        throw new Error("case_clause");
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

Object.defineProperty(exports, "__bp_priv__", { value: { relative, HostError, FsError, FsError$NotFound, FsError$PermissionDenied, FsError$IsDirectory, FsError$NotDirectory, FsError$AlreadyExists, FsError$InvalidUtf8, FsError$Other, FileStat, rawReadBytes, rawWriteBytes, rawAppendText, rawOpen, rawCreate, rawSize, rawRead, rawReadAll, rawReadLine, rawHash, rawWrite, rawClose, rawWriteText, exists, rawList, rawMkdir, rawMkdirRecursive, rawRm, rawCopy, rawStat, rawWalk, rawRemoveTree, fsError, lift, decode, Walked, readBytes, readText, writeBytes, writeText, appendText, stat, list, mkdir, mkdirRecursive, rm, removeTree, copy, walk, glob, File, open, create, openAsset, statOr, makeFixtureTree, walkFixture, walkFixtureFromCwd, walkRefusal, describe, makeGlobTree, globbed, variantOf, noFile } });
