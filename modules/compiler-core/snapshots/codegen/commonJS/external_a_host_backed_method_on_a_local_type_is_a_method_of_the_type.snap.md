----- SOURCE CODE -- main.bp
```botopink
pub type Meter(base: i32) {
    #[compiler.external(.JavaScript("""($0.base + $1)"""), .Erlang("""(element(2, $0) + $1)"""))]
    pub declare fn plus(self: Self, n: i32) -> i32;

    #[compiler.external(
        .JavaScript("""[$0.base, $1, $2].join("-")"""),
        .Erlang("""iolist_to_binary(lists:join(<<"-">>, [integer_to_binary(element(2, $0)), integer_to_binary($1), $2]))"""),
    )]
    pub declare fn label(self: Self, n: i32, tail: string) -> string;

    pub fn twice(self: Self) -> i32 {
        return self.plus(self.base);
    }
}

pub type Level {
    Low,
    High,

    #[compiler.external(
        .JavaScript("""($0.tag === "High" ? $1 * 10 : $1)"""),
        .Erlang("""case $0 of 'test@main@@Level__v__high' -> $1 * 10; _ -> $1 end"""),
    )]
    pub declare fn scale(self: Self, n: i32) -> i32;
}

pub fn main() -> void {
    val m = Meter(base: 3);
    print(m.plus(4));
    print(m.twice());
    print(m.label(5, "x"));
    print(Level.High.scale(2));
    print(Level.Low.scale(2));
}

import {io.terminal.print, compiler} from "std";
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

function __bp_host_mark(f) {
    const m = (e) => { if (e != null && (e.__bp_panic != null || typeof e.__bp_assert_loc === "string" || e.__bp_host === true)) { return e; } const x = (e instanceof Error) ? e : new Error(String(e)); try { Object.defineProperty(x, "__bp_host", { value: true }); } catch (_) {} return x; };
    try {
        const r = f();
        return (r != null && typeof r.then === "function" && r.__bp_fails !== true) ? r.then((v) => v, (e) => { throw m(e); }) : r;
    } catch (e) {
        throw m(e);
    }
}

class Meter {
    constructor(base) {
        this.base = base;
    }

    plus(n) {
        return __bp_host_mark(() => (this.base + n));
    }

    label(n, tail) {
        return __bp_host_mark(() => [this.base, n, tail].join("-"));
    }

    twice() {
        return this.plus(this.base);
    }
}
Meter.prototype.__bp = "Meter";
exports.Meter = Meter;

class Level {
    static scale(self, n) {
        return __bp_host_mark(() => (self.tag === "High" ? n * 10 : n));
    }

    toString() {
        return __bp_text(this);
    }
}
Level.prototype.__bp = "Level";
class Level$Low extends Level {
}
Level$Low.prototype.tag = "Low";
class Level$High extends Level {
}
Level$High.prototype.tag = "High";
Level.Low = new Level$Low();
Level.High = new Level$High();
exports.Level = Level;

function main() {
    const m = new Meter(3);
    __bp_print(m.plus(4));
    __bp_print(m.twice());
    __bp_print(m.label(5, "x"));
    __bp_print(Level.scale(Level.High, 2));
    __bp_print(Level.scale(Level.Low, 2));
}
exports.main = main;

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { Meter, Level, Level$Low, Level$High, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare class Meter {
    readonly base: number;
    constructor(base: number);
    plus(n: number): number;
    label(n: number, tail: string): string;
    twice(): number;
}


export declare class Level {
    readonly tag: "Low" | "High";
    static readonly Low: Level;
    static readonly High: Level;
    static scale(self: Level, n: number): number;
}


export declare function main(): void;

```

----- RUN LOG -----
```logs
7
6
3-5-x
20
2
```
