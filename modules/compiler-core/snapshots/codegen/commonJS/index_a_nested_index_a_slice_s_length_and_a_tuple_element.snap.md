----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val rows = [[1, 2], [3, 4]];
    @print(rows);
    @print(rows[1]);
    @print(rows[1][0]);
    @print(rows[0].length);
    val xs = [10, 20, 30];
    @print(xs[0..2].length);
    val sl = xs[0..2];
    @print(sl.length);
    val ps = [#(1, "a"), #(2, "b")];
    @print(ps[1]);
    val s = "hello";
    @print(s[1..3].length);
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

function main() {
    const rows = [[1, 2], [3, 4]];
    __bp_print(rows);
    __bp_print(rows[1]);
    __bp_print(rows[1][0]);
    __bp_print(rows[0].length);
    const xs = [10, 20, 30];
    __bp_print(xs.slice(0, 2).length);
    const sl = xs.slice(0, 2);
    __bp_print(sl.length);
    const ps = [[1, "a"], [2, "b"]];
    __bp_print(ps[1]);
    const s = "hello";
    __bp_print(s.slice(1, 3).length);
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
[[1, 2], [3, 4]]
[3, 4]
3
2
2
2
[2, "b"]
2
```
