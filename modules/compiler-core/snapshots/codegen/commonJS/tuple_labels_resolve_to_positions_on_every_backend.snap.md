----- SOURCE CODE -- main.bp
```botopink
fn load() -> #(name: string, pop: i32) {
    val name = "SP";
    val pop = 12;
    return #(name, pop);
}

fn show(r: #(city: string, pop: i32)) -> i32 {
    return r.pop;
}

fn main() {
    val row = load();
    @print(row.name);
    @print(row.pop + 1);
    val a = "RJ";
    val b = 7;
    val local = #(a, b);
    @print(local.a);
    @print(show(#("BH", 3)));
    @print(show(row));
    val typed: #(x: i32, y: i32) = #(1, 2);
    @print(typed.y);
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

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function load() {
    const name = "SP";
    const pop = 12;
    return [name, pop];
}

function show(r) {
    return r[1];
}

function main() {
    const row = load();
    __bp_print(row[0]);
    __bp_print(__bp_int((row[1] + 1), -2147483648, 2147483647, "+ on i32 at main.bp:14:20"));
    const a = "RJ";
    const b = 7;
    const local = [a, b];
    __bp_print(local[0]);
    __bp_print(show(["BH", 3]));
    __bp_print(show(row));
    const typed = [1, 2];
    __bp_print(typed[1]);
}

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { load, show, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
SP
13
RJ
3
12
2
```
