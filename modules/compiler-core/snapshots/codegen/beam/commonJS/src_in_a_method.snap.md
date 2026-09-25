----- SOURCE CODE -- main.bp
```botopink
type Stub(n: i32) {
    fn where(self: Self) -> SourceLocation {
        return @src();
    }
}
fn main() {
    val loc = Stub(n: 1).where();
    @print(loc.file, loc.line, loc.column, loc.fnName);
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(Number.isInteger(v) ? v.toFixed(1) : String(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof v.tag === "string") ? ((v.__bp + ".") + v.tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], null, false, a))).join(", ")) + ")")));
    }
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

class SourceLocation {
    constructor(file, line, column, fnName) {
        this.file = file;
        this.line = line;
        this.column = column;
        this.fnName = fnName;
    }
}
SourceLocation.prototype.__bp = "SourceLocation";

class Stub {
    constructor(n) {
        this.n = n;
    }

    where() {
        return new SourceLocation("main.bp", 3, 16, "Stub.where");
    }
}
Stub.prototype.__bp = "Stub";

function main() {
    const loc = new Stub(1).where();
    __bp_print(loc.file, loc.line, loc.column, loc.fnName);
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
main.bp 3 16 Stub.where
```
