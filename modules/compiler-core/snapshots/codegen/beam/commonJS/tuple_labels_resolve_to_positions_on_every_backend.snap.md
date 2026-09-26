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
    if ((v === undefined)) return "null";
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

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
    __bp_print((row[1] + 1));
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
_botopink_main();
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
