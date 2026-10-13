----- SOURCE CODE -- main.bp
```botopink
type Token {
    Color {
        Red { 100, 500 }
        Hex(value: string),
    }
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
        return (((typeof Object.getPrototypeOf(v).tag === "string") ? ((v.__bp + ".") + Object.getPrototypeOf(v).tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], null, false, a))).join(", ")) + ")")));
    }
    if ((v === undefined)) return "null";
    a.push(v);
    return "%O";
}

function __bp_text(v) {
    const a = [];
    let i = 0;
    return __bp_show(v, null, true, a).replace(/%[sO]/g, () => String(a[i++]));
}

class __Token__Color {
    static Hex(value) {
        return new __Token__Color$Hex(value);
    }

    static Red(_inner) {
        return new __Token__Color$Red(_inner);
    }

    toString() {
        return __bp_text(this);
    }
}
__Token__Color.prototype.__bp = "__Token__Color";
class __Token__Color$Hex extends __Token__Color {
    constructor(value) {
        super();
        this.value = value;
    }
}
__Token__Color$Hex.prototype.tag = "Hex";
class __Token__Color$Red extends __Token__Color {
    constructor(_inner) {
        super();
        this._inner = _inner;
    }
}
__Token__Color$Red.prototype.tag = "Red";

class __Token__Color__Red {
    toString() {
        return __bp_text(this);
    }
}
__Token__Color__Red.prototype.__bp = "__Token__Color__Red";
class __Token__Color__Red$__100 extends __Token__Color__Red {
}
__Token__Color__Red$__100.prototype.tag = "__100";
class __Token__Color__Red$__500 extends __Token__Color__Red {
}
__Token__Color__Red$__500.prototype.tag = "__500";
__Token__Color__Red.__100 = new __Token__Color__Red$__100();
__Token__Color__Red.__500 = new __Token__Color__Red$__500();

class Token {
    static Color(_inner) {
        return new Token$Color(_inner);
    }

    toString() {
        return __bp_text(this);
    }
}
Token.prototype.__bp = "Token";
class Token$Color extends Token {
    constructor(_inner) {
        super();
        this._inner = _inner;
    }
}
Token$Color.prototype.tag = "Color";

Object.defineProperty(exports, "__bp_priv__", { value: { __Token__Color, __Token__Color$Hex, __Token__Color$Red, __Token__Color__Red, __Token__Color__Red$__100, __Token__Color__Red$__500, Token, Token$Color } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
