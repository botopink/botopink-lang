----- SOURCE CODE -- main.bp
```botopink
type Box(n: ?i32, s: ?string)

fn first(xs: i32[]) -> ?i32 {
    return xs.at(0);
}

fn pick(flag: bool) -> ?i32 {
    if (flag) {
        return 5;
    }
    return null;
}

fn show(o: ?i32) -> i32 {
    return o ?? -1;
}

pub fn main() -> void {
    val xs = [7, 8];
    print(xs.at(1));
    print(xs.at(5));
    print(first(xs));
    print(pick(true));
    print(pick(false));
    print(show(pick(true)));
    print(show(pick(false)));
    val b = Box(n: 3, s: "x");
    print(b);
    val c = Box(n: null, s: null);
    print(c);
    if (b.n) { v -> print(v + 1); }
    val words = ["a", "b"];
    print(words.at(0));
    print(words.at(9));
    print(words[1] ?? "z");
    print(xs[0]);
    print(b.n == null);
    print(c.n == null);
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

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

class Box {
    constructor(n, s) {
        this.n = n;
        this.s = s;
    }
}
Box.prototype.__bp = "Box";

function first(xs) {
    return __bp_array_at(xs, 0);
}

function pick(flag) {
    if (flag) { return 5; }
    return null;
}

function show(o) {
    return (() => { const __bp_nullish = o; if (__bp_nullish != null) { return __bp_nullish; } else { return (-1); } })();
}

function main() {
    const xs = [7, 8];
    __bp_print(__bp_array_at(xs, 1));
    __bp_print(__bp_array_at(xs, 5));
    __bp_print(first(xs));
    __bp_print(pick(true));
    __bp_print(pick(false));
    __bp_print(show(pick(true)));
    __bp_print(show(pick(false)));
    const b = new Box(3, "x");
    __bp_print(b);
    const c = new Box(null, null);
    __bp_print(c);
    (() => { const v = b.n; if (v != null) { return __bp_print(__bp_int((v + 1), -2147483648, 2147483647, "+ on i32 at main.bp:31:29")); } })();
    const words = ["a", "b"];
    __bp_print(__bp_array_at(words, 0));
    __bp_print(__bp_array_at(words, 9));
    __bp_print((() => { const __bp_nullish = __bp_array_at(words, 1); if (__bp_nullish != null) { return __bp_nullish; } else { return "z"; } })());
    __bp_print(__bp_array_at(xs, 0));
    __bp_print((b.n == null));
    __bp_print((c.n == null));
}
exports.main = main;

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { Box, first, pick, show, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript








export declare function main(): void;

```

----- RUN LOG -----
```logs
8
null
7
5
null
5
-1
Box(n: 3, s: "x")
Box(n: null, s: null)
4
a
null
b
7
false
true
```
