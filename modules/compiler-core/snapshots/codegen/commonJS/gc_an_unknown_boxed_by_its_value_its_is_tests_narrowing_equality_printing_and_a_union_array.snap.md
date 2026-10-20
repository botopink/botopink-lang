----- SOURCE CODE -- main.bp
```botopink
fn describe(x: unknown) -> string {
    return case x {
        i32 { n ->
            "number " + n.toString()
        }
        string { s ->
            "text " + s
        }
        _ {
            "other"
        }
    };
}

fn show(x: unknown) -> string {
    if (x is i32) return "i32";
    if (x is f64) return "f64";
    if (x is string) return "string";
    if (x is bool) return "bool";
    return "other";
}

pub fn main() -> void {
    print(describe(3));
    print(describe("a"));
    print(describe(true));
    print(show(1), show(2.5), show("s"), show(false));
    val two: unknown = 2.0;
    print(two == 2, two == 3);
    val t: unknown = "hi";
    print(t == "hi", t);
    val b: unknown = true;
    print(b);
    print(300 is i8, 100 is i8, 2 is f64);
    val xs = [1, "a", true];
    print(xs);
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

function describe(x) {
    return (() => {
        const _s = x;
        if ((typeof _s === "number" && Number.isInteger(_s) && _s >= -2147483648 && _s <= 2147483647)) {
            const n = _s;
            return ("number " + n.toString());
        }
        if (typeof _s === "string") {
            const s = _s;
            return ("text " + s);
        }
        {
            return "other";
        }
    })();
}

function show(x) {
    if (((_v) => (typeof _v === "number" && Number.isInteger(_v) && _v >= -2147483648 && _v <= 2147483647))(x)) { return "i32"; }
    if (typeof x === "number") { return "f64"; }
    if (typeof x === "string") { return "string"; }
    if (typeof x === "boolean") { return "bool"; }
    return "other";
}

function main() {
    __bp_print(describe(3));
    __bp_print(describe("a"));
    __bp_print(describe(true));
    __bp_print(show(1), show(2.5), show("s"), show(false));
    const two = 2.0;
    __bp_print((two === 2), (two === 3));
    const t = "hi";
    __bp_print((t === "hi"), t);
    const b = true;
    __bp_print(b);
    __bp_print(((_v) => (typeof _v === "number" && Number.isInteger(_v) && _v >= -128 && _v <= 127))(300), ((_v) => (typeof _v === "number" && Number.isInteger(_v) && _v >= -128 && _v <= 127))(100), typeof 2 === "number");
    const xs = [1, "a", true];
    __bp_print(xs);
}
exports.main = main;

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { describe, show, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript




export declare function main(): void;

```

----- RUN LOG -----
```logs
number 3
text a
other
i32 f64 string bool
true false
true hi
true
false true true
[1, "a", true]
```
