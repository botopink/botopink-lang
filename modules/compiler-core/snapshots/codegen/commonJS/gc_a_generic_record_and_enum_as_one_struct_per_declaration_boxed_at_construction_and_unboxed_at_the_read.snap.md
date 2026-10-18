----- SOURCE CODE -- main.bp
```botopink
type Box<T>(value: T) {
    pub fn get(self: Self<T>) -> T {
        return self.value;
    }
}

type Maybe<T> {
    Some(value: T),
    None,
}

fn orZero(m: Maybe<i32>) -> i32 {
    return case m {
        Maybe.Some(value: v) -> v;
        Maybe.None -> 0;
    };
}

fn ident<T>(x: T) -> T {
    return x;
}

pub fn main() {
    val b = Box(value: 41);
    print(b.value + 1);
    print(b.get());
    print(Box(value: "s"));
    print(Box(value: true));
    print(orZero(Maybe.Some(value: 7)), orZero(Maybe.None));
    print(Maybe.Some(value: "x"));
    print(ident(3) + 1);
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

function __bp_text(v, s) {
    const a = [];
    let i = 0;
    return __bp_show(v, s == null ? null : s, true, a).replace(/%[sO]/g, () => String(a[i++]));
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

class Box {
    constructor(value) {
        this.value = value;
    }

    get() {
        return this.value;
    }
}
Box.prototype.__bp = "Box";

class Maybe {
    static Some(value) {
        return new Maybe$Some(value);
    }

    toString() {
        return __bp_text(this);
    }
}
Maybe.prototype.__bp = "Maybe";
class Maybe$Some extends Maybe {
    constructor(value) {
        super();
        this.value = value;
    }
}
Maybe$Some.prototype.tag = "Some";
class Maybe$None extends Maybe {
}
Maybe$None.prototype.tag = "None";
Maybe.None = new Maybe$None();

function orZero(m) {
    return (() => {
        const _s = m;
        if (_s.tag === "Some") {
            const { value: v } = _s;
            return v;
        }
        if (_s.tag === "None") return 0;
        throw new Error("case_clause");
    })();
}

function ident(x) {
    return x;
}

function main() {
    const b = new Box(41);
    __bp_print(__bp_int((b.value + 1), -2147483648, 2147483647, "+ on i32 at main.bp:25:19"));
    __bp_print(b.get());
    __bp_print(new Box("s"));
    __bp_print(new Box(true));
    __bp_print(orZero(Maybe.Some(7)), orZero(Maybe.None));
    __bp_print(Maybe.Some("x"));
    __bp_print(__bp_int((ident(3) + 1), -2147483648, 2147483647, "+ on i32 at main.bp:31:20"));
}
exports.main = main;

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { Box, Maybe, Maybe$Some, Maybe$None, orZero, ident, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript








export declare function main(): void;

```

----- RUN LOG -----
```logs
42
41
Box(value: "s")
Box(value: true)
7 0
Maybe.Some(value: "x")
4
```
