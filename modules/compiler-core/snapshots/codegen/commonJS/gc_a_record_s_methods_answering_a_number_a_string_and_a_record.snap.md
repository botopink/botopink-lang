----- SOURCE CODE -- main.bp
```botopink
type Counter(n: i32, label: string) {
    pub fn bump(self: Self) -> i32 {
        return self.n + 1;
    }
    pub fn name(self: Self) -> string {
        return self.label + "!";
    }
    pub fn scaled(self: Self, k: i32) -> i32 {
        return self.n * k;
    }
    pub fn twice(self: Self) -> Counter {
        return Counter(n: self.n * 2, label: self.label);
    }
}

pub fn main() -> void {
    val c = Counter(n: 4, label: "ctr");
    print(c.bump());
    print(c.name());
    print(c.scaled(3));
    print(c.twice());
    print(c.twice().twice().n);
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

class Counter {
    constructor(n, label) {
        this.n = n;
        this.label = label;
    }

    bump() {
        return __bp_int((this.n + 1), -2147483648, 2147483647, "+ on i32 at main.bp:3:23");
    }

    name() {
        return (this.label + "!");
    }

    scaled(k) {
        return __bp_int((this.n * k), -2147483648, 2147483647, "* on i32 at main.bp:9:23");
    }

    twice() {
        return new Counter(__bp_int((this.n * 2), -2147483648, 2147483647, "* on i32 at main.bp:12:34"), this.label);
    }
}
Counter.prototype.__bp = "Counter";

function main() {
    const c = new Counter(4, "ctr");
    __bp_print(c.bump());
    __bp_print(c.name());
    __bp_print(c.scaled(3));
    __bp_print(c.twice());
    __bp_print(c.twice().twice().n);
}
exports.main = main;

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { Counter, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript


export declare function main(): void;

```

----- RUN LOG -----
```logs
5
ctr!
12
Counter(n: 8, label: "ctr")
16
```
