----- SOURCE CODE -- main.bp
```botopink
fn pick(xs: array<string>) -> string {
    var first = "";
    var last = "";
    var i = 0;
    for (xs) { x ->
        if (i == 0) { first = x; };
        last = x;
        i = i + 1;
    };
    return first + "-" + last;
}
fn weigh(xs: array<i32>) -> i32 {
    var total = 0;
    for (0..xs.length) { i ->
        total = total + (xs[i] ?? 0) * (i + 1);
    };
    return total;
}
fn main() -> void {
    print(pick(["a", "b", "c"]));
    print(weigh([10, 20, 30]));
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
    if ((typeof v === "function")) return ("fn/" + (v.__bp_arity ?? v.length));
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

function pick(xs) {
    let first = "";
    let last = "";
    let i = 0;
    for (const x of xs) {
    (() => { if ((i === 0)) { return first = x; } })();
    last = x;
    i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at main.bp:8:15");
}
    return ((first + "-") + last);
}

function weigh(xs) {
    let total = 0;
    for (const i of Array.from({length: Math.max(0, (xs.length) - (0))}, (_, __i) => (0) + __i)) {
    total = __bp_int((total + __bp_int((((() => { const __bp_nullish = __bp_array_at(xs, i); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })()) * (__bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at main.bp:15:43"))), -2147483648, 2147483647, "* on i32 at main.bp:15:38")), -2147483648, 2147483647, "+ on i32 at main.bp:15:23");
}
    return total;
}

function main() {
    __bp_print(pick(["a", "b", "c"]));
    __bp_print(weigh([10, 20, 30]));
}

function _botopink_main() {
    main();
}
if (require.main === module) {
    const __bp_abort = (e) => { const k = (e != null && e.__bp_panic != null) ? ["panic", (typeof e.__bp_panic === "string") ? e.__bp_panic : e.message] : (e != null && typeof e.__bp_assert_loc === "string") ? ["panic", e.message] : [(e != null && e.__bp_host === true) ? "host" : "crash", (e instanceof Error) ? e.message : String(e)]; globalThis.process.stderr.write(k[0] + ": " + k[1] + "\n", () => globalThis.process.exit(1)); };
    globalThis.process.on("uncaughtException", __bp_abort);
    globalThis.process.on("unhandledRejection", __bp_abort);
    _botopink_main();
}

Object.defineProperty(exports, "__bp_priv__", { value: { pick, weigh, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
a-c
140
```
