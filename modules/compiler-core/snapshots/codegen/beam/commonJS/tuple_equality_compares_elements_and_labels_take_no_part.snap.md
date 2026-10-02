----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val a = #(1, "a");
    val b = #(1, "a");
    @print(a == b);
    @print(a != b);
    val c = #(1, "b");
    @print(a == c);
    val name = "SP";
    val pop = 12;
    val labeled = #(name, pop);
    val plain = #("SP", 12);
    @print(labeled == plain);
    val n1 = #(#(1, 2), "x");
    val n2 = #(#(1, 2), "x");
    val n3 = #(#(1, 3), "x");
    @print(n1 == n2);
    @print(n1 == n3);
    val f1 = #(1.5, true);
    val f2 = #(1.5, true);
    val f3 = #(1.5, false);
    @print(f1 == f2);
    @print(f1 == f3);
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

function __bp_eq_Tuple2_i32_string(a, b) {
    if (a === b) return true;
    return a[0] === b[0] && a[1] === b[1];
}

function __bp_eq_Tuple2_string_i32(a, b) {
    if (a === b) return true;
    return a[0] === b[0] && a[1] === b[1];
}

function __bp_eq_Tuple2_Tuple2_i32_i32_string(a, b) {
    if (a === b) return true;
    return __bp_eq_Tuple2_i32_i32(a[0], b[0]) && a[1] === b[1];
}

function __bp_eq_Tuple2_i32_i32(a, b) {
    if (a === b) return true;
    return a[0] === b[0] && a[1] === b[1];
}

function __bp_eq_Tuple2_f64_bool(a, b) {
    if (a === b) return true;
    return a[0] === b[0] && a[1] === b[1];
}

function main() {
    const a = [1, "a"];
    const b = [1, "a"];
    __bp_print(__bp_eq_Tuple2_i32_string(a, b));
    __bp_print((!__bp_eq_Tuple2_i32_string(a, b)));
    const c = [1, "b"];
    __bp_print(__bp_eq_Tuple2_i32_string(a, c));
    const name = "SP";
    const pop = 12;
    const labeled = [name, pop];
    const plain = ["SP", 12];
    __bp_print(__bp_eq_Tuple2_string_i32(labeled, plain));
    const n1 = [[1, 2], "x"];
    const n2 = [[1, 2], "x"];
    const n3 = [[1, 3], "x"];
    __bp_print(__bp_eq_Tuple2_Tuple2_i32_i32_string(n1, n2));
    __bp_print(__bp_eq_Tuple2_Tuple2_i32_i32_string(n1, n3));
    const f1 = [1.5, true];
    const f2 = [1.5, true];
    const f3 = [1.5, false];
    __bp_print(__bp_eq_Tuple2_f64_bool(f1, f2));
    __bp_print(__bp_eq_Tuple2_f64_bool(f1, f3));
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
true
false
false
true
true
false
true
false
```
