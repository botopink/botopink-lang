----- SOURCE CODE -- main.bp
```botopink
behavior Sized {
    fn size(self: Self) -> i32;

    default fn isEmpty(self: Self) -> bool {
        return self.size() == 0;
    }
}

behavior Counted extends Sized {
    default fn twiceSize(self: Self) -> i32 {
        return self.size() * 2;
    }
}

type Bag<T>(
    items: Array<T>,
) implement Counted {
    pub fn size(self: Self<T>) -> i32 {
        return self.items.length;
    }
}

fn main() {
    @print(Bag(items: []).isEmpty());
    @print(Bag(items: [1]).isEmpty());
    @print(Bag(items: [1, 2]).twiceSize());
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

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

// behavior Sized
//   fn size(...)
//   default fn isEmpty(...)

// behavior Counted extends Sized
//   default fn twiceSize(...)

class Bag {
    constructor(items) {
        this.items = items;
    }

    size() {
        return this.items.length;
    }

    twiceSize() {
        return __bp_int((this.size() * 2), -2147483648, 2147483647, "* on i32 at main.bp:11:28");
    }

    isEmpty() {
        return (this.size() === 0);
    }
}
Bag.prototype.__bp = "Bag";

function main() {
    __bp_print(new Bag([]).isEmpty());
    __bp_print(new Bag([1]).isEmpty());
    __bp_print(new Bag([1, 2]).twiceSize());
}

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { Bag, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
true
false
4
```
