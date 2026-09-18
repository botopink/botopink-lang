----- SOURCE CODE -- main.bp
```botopink
type Opt { None, Some(value: i32) }
fn describe(opt: Opt) -> string {
    return case opt {
        None -> "empty";
        Some(v) -> "value: " + v;
    };
}
fn main() {
    @print(describe(Opt.Some(value: 42)));
    @print(describe(Opt.None));
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(",")) + (t ? ")" : "]"));
    }
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

class Opt {
    static Some(value) {
        return new Opt$Some(value);
    }
}
Opt.prototype.__bp = "Opt";
class Opt$None extends Opt {
}
Opt$None.prototype.tag = "None";
class Opt$Some extends Opt {
    constructor(value) {
        super();
        this.value = value;
    }
}
Opt$Some.prototype.tag = "Some";
Opt.None = new Opt$None();

function describe(opt) {
    return (() => {
        const _s = opt;
        if (_s instanceof Opt$None) return "empty";
        if (_s.tag === "Some") {
            const { value: v } = _s;
            return ("value: " + v);
        }
    })();
}

function main() {
    __bp_print(describe(Opt.Some(42)));
    __bp_print(describe(Opt.None));
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
value: 42
empty
```
