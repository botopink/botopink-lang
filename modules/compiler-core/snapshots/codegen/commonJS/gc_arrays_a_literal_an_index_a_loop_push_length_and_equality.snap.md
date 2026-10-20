----- SOURCE CODE -- main.bp
```botopink
fn total(xs: i32[]) -> i32 {
    var sum = 0;
    for (xs) { x -> sum = sum + x; }
    return sum;
}

fn longest(names: string[]) -> i32 {
    var best = 0;
    for (names) { n -> if (n.length() > best) { best = n.length(); } }
    return best;
}

pub fn main() -> void {
    val xs = [3, 1, 2];
    print(xs);
    print(total(xs));
    print(xs[1]);
    print(xs.length);
    print(xs.length());
    var ys = [10, 20];
    ys.push(30);
    print(ys);
    val names = ["ann", "bobby"];
    print(names);
    print(longest(names));
    print(names[1]);
    val fs = [1.5, 2.5];
    print(fs);
    print(xs == [3, 1, 2]);
    print(xs == ys);
    val e: i32[] = [];
    print(e.length());
    print(e);
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

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function __bp_eq_Array_i32(a, b) {
    if (a === b) return true;
    return a.length === b.length && a.every((e, i) => e === b[i]);
}

function total(xs) {
    let sum = 0;
    for (const x of xs) {
    sum = __bp_int((sum + x), -2147483648, 2147483647, "+ on i32 at main.bp:3:31");
}
    return sum;
}

function longest(names) {
    let best = 0;
    for (const n of names) {
    (() => { if ((__bp_str_length(n) > best)) { return best = __bp_str_length(n); } })();
}
    return best;
}

function main() {
    const xs = [3, 1, 2];
    __bp_print(xs);
    __bp_print(total(xs));
    __bp_print(__bp_array_at(xs, 1));
    __bp_print(xs.length);
    __bp_print(xs.length);
    let ys = [10, 20];
    ys = ys.concat([30]);
    __bp_print(ys);
    const names = ["ann", "bobby"];
    __bp_print(names);
    __bp_print(longest(names));
    __bp_print(__bp_array_at(names, 1));
    const fs = [1.5, 2.5];
    __bp_print_as([["[", "f"]], fs);
    __bp_print(__bp_eq_Array_i32(xs, [3, 1, 2]));
    __bp_print(__bp_eq_Array_i32(xs, ys));
    const e = [];
    __bp_print(e.length);
    __bp_print(e);
}
exports.main = main;

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { total, longest, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript




export declare function main(): void;

```

----- RUN LOG -----
```logs
[3, 1, 2]
6
1
3
3
[10, 20, 30]
["ann", "bobby"]
5
bobby
[1.5, 2.5]
true
false
0
[]
```
