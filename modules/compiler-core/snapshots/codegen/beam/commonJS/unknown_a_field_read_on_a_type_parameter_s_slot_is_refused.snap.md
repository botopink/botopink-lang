----- SOURCE CODE -- main.bp
```botopink
type Maybe<T> {
    Some(value: T),
    None,
}
fn innerLength(b: unknown) -> i32 {
    return case b {
        Maybe.Some(value: v) when (v is string) { v.length }
        Maybe.Some(value: v) { -1 }
        _ { -2 }
    };
}
fn main() {
    val s: unknown = Maybe.Some(value: "abc");
    @print(innerLength(s));
}
```

----- JAVASCRIPT -- main.js
```javascript
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
    if ((v === undefined)) return "null";
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

class Maybe {
    static Some(value) {
        return new Maybe$Some(value);
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

function innerLength(b) {
    return (() => {
        const _s = b;
        if (_s.tag === "Some") {
            const { value: v } = _s;
            if (typeof v === "string") {
                return v.length;
            }
        }
        if (_s.tag === "Some") {
            const { value: v } = _s;
            return (-1);
        }
        {
            return (-2);
        }
    })();
}

function main() {
    const s = Maybe.Some("abc");
    __bp_print(innerLength(s));
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
3
```
