----- SOURCE CODE -- main.bp
```botopink
fn half(n: i32) -> Result<i32, string> {
    if (n % 2 == 0) {
        return n / 2;
    }
    throw "odd";
}

fn twice(n: i32) -> Result<i32, string> {
    val h = try half(n);
    return try half(h);
}

fn show(r: Result<i32, string>) -> string {
    return case r {
        Ok(v) -> "ok " + v;
        Error(e) -> "err " + e;
    };
}

pub fn main() {
    print(half(4));
    print(half(3));
    print(twice(8));
    print(twice(6));
    print(show(half(10)));
    print(show(half(7)));
    print(half(6).unwrapOr(0));
    print(half(5).unwrapOr(0));
    print(half(6).isOk());
}

import {io.terminal.print} from "std";
```

----- JAVASCRIPT -- main.js
```javascript
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

function half(n) {
    if ((__bp_int((n % 2), -2147483648, 2147483647, "% on i32 at main.bp:2:11") === 0)) { return ({ ok: __bp_int(Math.trunc((n / 2)), -2147483648, 2147483647, "/ on i32 at main.bp:3:18") }); }
    return ({ error: "odd" });
}

function twice(n) {
    const _try0 = half(n);
    if ("error" in _try0) return _try0;
    const h = _try0.ok;
    return half(h);
}

function show(r) {
    return (() => {
        const _s = r;
        if ("ok" in _s) {
            const v = _s.ok;
            return ("ok " + v);
        }
        if ("error" in _s) {
            const e = _s.error;
            return ("err " + e);
        }
        throw new Error("case_clause");
    })();
}

function main() {
    __bp_print(half(4));
    __bp_print(half(3));
    __bp_print(twice(8));
    __bp_print(twice(6));
    __bp_print(show(half(10)));
    __bp_print(show(half(7)));
    __bp_print(((_r) => "error" in _r ? (0) : _r.ok)(half(6)));
    __bp_print(((_r) => "error" in _r ? (0) : _r.ok)(half(5)));
    __bp_print(((_r) => !("error" in _r))(half(6)));
}
exports.main = main;

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { half, twice, show, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript






export declare function main(): void;

```

----- RUN LOG -----
```logs
Ok(2)
Error("odd")
Ok(2)
Error("odd")
ok 5
err odd
3
0
true
```
