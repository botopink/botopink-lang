----- SOURCE CODE -- pond.bp
```botopink
pub type Pato(id: i32)
```

----- JAVASCRIPT -- pond.js
```javascript
class Pato {
    constructor(id) {
        this.id = id;
    }
}
Pato.prototype.__bp = "Pato";
exports.Pato = Pato;

Object.defineProperty(exports, "__bp_priv__", { value: { Pato } });
```

----- TYPESCRIPT TYPEDEF -- pond.d.ts
```typescript
export declare class Pato {
    readonly id: number;
    constructor(id: number);
}

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {pond.Pato};
val Swimmer = behavior {
    fn swim(self: Self);
}
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
fn main() {
    val donald = Pato(2);
    @print(donald.swim());
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

const { Pato } = require("./pond.js");

// behavior Swimmer
//   fn swim(...)

// implement Swimmer for Pato
const PatoNada = {
    swim(self) {
        return self.id;
    },
};

function main() {
    const donald = new Pato(2);
    __bp_print(PatoNada.swim(donald));
}

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { Pato, PatoNada, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { Pato } from "./pond";





```

----- RUN LOG -----
```logs
2
```
