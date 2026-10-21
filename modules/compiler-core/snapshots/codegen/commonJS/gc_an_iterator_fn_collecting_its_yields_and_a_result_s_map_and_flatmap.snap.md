----- SOURCE CODE -- main.bp
```botopink
iter fn evens(n: i32) -> Iter<i32> {
    var i = 0;
    while (i < n) {
        if (i % 2 == 0) yield i;
        i = i + 1;
    }
}

fn parse(s: string) -> Result<i32, string> {
    if (s == "") throw "empty";
    return s.length();
}

pub fn main() -> void {
    for (evens(7)) { v -> print(v); }
    print(parse("abc").map({ n -> n * 10 }).unwrapOr(-1));
    print(parse("").map({ n -> n * 10 }).unwrapOr(-1));
    print(parse("ab").flatMap({ n -> parse("xyz") }).unwrapOr(-1));
    print(parse("ab").flatMap({ n -> parse("") }).isError());
}

import {io.terminal.print} from "std";
```

----- JAVASCRIPT -- main.js
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

function __bp_str_length(s) {
    if (!__bp_has_surrogate(s)) { return s.length; }
    let n = 0;
    for (const c of s) { n += 1; }
    return n;
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

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function* evens(n) {
    let i = 0;
    while ((i < n)) {
    if ((__bp_int((i % 2), -2147483648, 2147483647, "% on i32 at main.bp:4:15") === 0)) { yield i; }
    i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at main.bp:5:15");
}
}

function parse(s) {
    let s$sp = null;
    if ((s === "")) { return ({ error: "empty" }); }
    return ({ ok: ((s$sp ??= __bp_has_surrogate(s)) ? __bp_str_length(s) : s.length) });
}

function main() {
    for (const v of evens(7)) {
    __bp_print(v);
}
    __bp_print(((_r) => "error" in _r ? ((-1)) : _r.ok)(((_r) => "error" in _r ? _r : { ok: ((n) => {
    return __bp_int((n * 10), -2147483648, 2147483647, "* on i32 at main.bp:16:37");
})(_r.ok) })(parse("abc"))));
    __bp_print(((_r) => "error" in _r ? ((-1)) : _r.ok)(((_r) => "error" in _r ? _r : { ok: ((n) => {
    return __bp_int((n * 10), -2147483648, 2147483647, "* on i32 at main.bp:17:34");
})(_r.ok) })(parse(""))));
    __bp_print(((_r) => "error" in _r ? ((-1)) : _r.ok)(((_r) => "error" in _r ? _r : ((n) => {
    return parse("xyz");
})(_r.ok))(parse("ab"))));
    __bp_print(((_r) => "error" in _r)(((_r) => "error" in _r ? _r : ((n) => {
    return parse("");
})(_r.ok))(parse("ab"))));
}
exports.main = main;

function _botopink_main() {
    main();
}
if (require.main === module) {
    const __bp_abort = (e) => { const k = (e != null && e.__bp_panic != null) ? ["panic", (typeof e.__bp_panic === "string") ? e.__bp_panic : e.message] : (e != null && typeof e.__bp_assert_loc === "string") ? ["panic", e.message] : [(e != null && e.__bp_host === true) ? "host" : "crash", (e instanceof Error) ? e.message : String(e)]; globalThis.process.stderr.write(k[0] + ": " + k[1] + "\n", () => globalThis.process.exit(1)); };
    globalThis.process.on("uncaughtException", __bp_abort);
    globalThis.process.on("unhandledRejection", __bp_abort);
    _botopink_main();
}

Object.defineProperty(exports, "__bp_priv__", { value: { evens, parse, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript




export declare function main(): void;

```

----- RUN LOG -----
```logs
0
2
4
6
30
-1
3
true
```
