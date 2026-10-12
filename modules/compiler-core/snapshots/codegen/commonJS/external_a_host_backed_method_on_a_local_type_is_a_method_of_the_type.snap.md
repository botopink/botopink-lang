----- SOURCE CODE -- main.bp
```botopink
pub type Meter(base: i32) {
    #[@External.Node("""($0.base + $1)"""),
      @External.Erlang("""(element(2, $0) + $1)""")]
    pub declare fn plus(self: Self, n: i32) -> i32;

    #[@External.Node("""[$0.base, $1, $2].join("-")"""),
      @External.Erlang("""iolist_to_binary(lists:join(<<"-">>, [integer_to_binary(element(2, $0)), integer_to_binary($1), $2]))""")]
    pub declare fn label(self: Self, n: i32, tail: string) -> string;

    pub fn twice(self: Self) -> i32 {
        return self.plus(self.base);
    }
}

pub type Level {
    Low,
    High,

    #[@External.Node("""($0.tag === "High" ? $1 * 10 : $1)"""),
      @External.Erlang("""case $0 of 'test@main@@Level__v__high' -> $1 * 10; _ -> $1 end""")]
    pub declare fn scale(self: Self, n: i32) -> i32;
}

pub fn main() {
    val m = Meter(base: 3);
    @print(m.plus(4));
    @print(m.twice());
    @print(m.label(5, "x"));
    @print(Level.High.scale(2));
    @print(Level.Low.scale(2));
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_f64(v) {
    if (!Number.isFinite(v)) { return String(v); }
    const s = Object.is(v, -0) ? "-0" : String(v);
    const i = s.indexOf("e");
    if (i < 0) { return s.indexOf(".") < 0 ? s + ".0" : s; }
    const m = s.slice(0, i);
    return (m.indexOf(".") < 0 ? m + ".0" : m) + "e" + s.slice(i + 1).replace("+", "");
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
        return (((typeof v.tag === "string") ? ((v.__bp + ".") + v.tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], null, false, a))).join(", ")) + ")")));
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

class Meter {
    constructor(base) {
        this.base = base;
    }

    plus(n) {
        return (this.base + n);
    }

    label(n, tail) {
        return [this.base, n, tail].join("-");
    }

    twice() {
        return this.plus(this.base);
    }
}
Meter.prototype.__bp = "Meter";
exports.Meter = Meter;

class Level {
    static scale(self, n) {
        return (self.tag === "High" ? n * 10 : n);
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
