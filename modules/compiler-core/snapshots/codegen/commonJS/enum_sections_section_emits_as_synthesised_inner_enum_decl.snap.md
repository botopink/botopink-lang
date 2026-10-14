----- SOURCE CODE -- main.bp
```botopink
type Token {
    Text {
        Bold, Italic, Underline,
    }
    Hover(inner: i32),
}
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

class __Token__Text {
    toString() {
        return __bp_text(this);
    }
}
__Token__Text.prototype.__bp = "__Token__Text";
class __Token__Text$Bold extends __Token__Text {
}
__Token__Text$Bold.prototype.tag = "Bold";
class __Token__Text$Italic extends __Token__Text {
}
__Token__Text$Italic.prototype.tag = "Italic";
class __Token__Text$Underline extends __Token__Text {
}
__Token__Text$Underline.prototype.tag = "Underline";
__Token__Text.Bold = new __Token__Text$Bold();
__Token__Text.Italic = new __Token__Text$Italic();
__Token__Text.Underline = new __Token__Text$Underline();

class Token {
    static Hover(inner) {
        return new Token$Hover(inner);
    }

    static Text(_inner) {
        return new Token$Text(_inner);
    }

    toString() {
        return __bp_text(this);
    }
}
Token.prototype.__bp = "Token";
class Token$Hover extends Token {
    constructor(inner) {
        super();
        this.inner = inner;
    }
}
Token$Hover.prototype.tag = "Hover";
class Token$Text extends Token {
    constructor(_inner) {
        super();
        this._inner = _inner;
    }
}
Token$Text.prototype.tag = "Text";

Object.defineProperty(exports, "__bp_priv__", { value: { __Token__Text, __Token__Text$Bold, __Token__Text$Italic, __Token__Text$Underline, Token, Token$Hover, Token$Text } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
