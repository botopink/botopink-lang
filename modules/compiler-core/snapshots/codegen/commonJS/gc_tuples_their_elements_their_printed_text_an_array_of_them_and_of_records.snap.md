----- SOURCE CODE -- main.bp
```botopink
type Pair(a: i32, b: string)

pub fn main() -> void {
    val t = #(1, "x", 2.5, true);
    print(t);
    print(t.0);
    print(t.1);
    print(t._2);
    print(t._3);
    val u = #(1, "x", 2.5, true);
    print(t == u);
    val rs = [Pair(a: 1, b: "p"), Pair(a: 2, b: "q")];
    print(rs);
    for r in rs { print(r.b); }
    val ts = [#(1, "a"), #(2, "b")];
    print(ts);
    print(ts[0]);
}

import {io.terminal.print} from "std";
```

----- JAVASCRIPT -- main.js
```javascript
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

function __bp_print_as(shapes) {
    const a = [];
    const f = Array.from(Array.from(arguments).slice(1), (v, i) => __bp_show(v, shapes[i], true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_eq_Tuple4_i32_string_f64_bool(a, b) {
    if (a === b) return true;
    return a[0] === b[0] && a[1] === b[1] && Object.is(a[2], b[2]) && a[3] === b[3];
}

class Pair {
    constructor(a, b) {
        this.a = a;
        this.b = b;
    }
}
Pair.prototype.__bp = "Pair";

function main() {
    const t = [1, "x", 2.5, true];
    __bp_print_as([["#", null, null, "f", null]], t);
    __bp_print(t[0]);
    __bp_print(t[1]);
    __bp_print_as(["f"], t[2]);
    __bp_print(t[3]);
    const u = [1, "x", 2.5, true];
    __bp_print(__bp_eq_Tuple4_i32_string_f64_bool(t, u));
    const rs = [new Pair(1, "p"), new Pair(2, "q")];
    __bp_print(rs);
    for (const r of rs) {
    __bp_print(r.b);
}
    const ts = [[1, "a"], [2, "b"]];
    __bp_print_as([["[", ["#", null, null]]], ts);
    __bp_print_as([["#", null, null]], __bp_array_at(ts, 0));
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

Object.defineProperty(exports, "__bp_priv__", { value: { Pair, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript


export declare function main(): void;

```

----- RUN LOG -----
```logs
#(1, "x", 2.5, true)
1
x
2.5
true
true
[Pair(a: 1, b: "p"), Pair(a: 2, b: "q")]
p
q
[#(1, "a"), #(2, "b")]
#(1, "a")
```
