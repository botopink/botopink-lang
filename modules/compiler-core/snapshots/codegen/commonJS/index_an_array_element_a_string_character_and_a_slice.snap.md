----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val xs = [10, 20, 30];
    val i = 1;
    @print(xs[0]);
    @print(xs[i + 1]);
    val names = ["ana", "bo"];
    @print(names[1]);
    val s = "hello";
    @print(s[1]);
    @print(s[1..3]);
    @print(s[3..]);
    @print(xs[1..]);
}
```

----- JAVASCRIPT -- main.js
```javascript
function* __bp_range_from(n) { while (true) { yield n; n += 1; } }

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
    const xs = [10, 20, 30];
    const i = 1;
    __bp_print(@[](xs, 0));
    __bp_print(@[](xs, (i + 1)));
    const names = ["ana", "bo"];
    __bp_print(@[](names, 1));
    const s = "hello";
    __bp_print(@[](s, 1));
    __bp_print(@[](s, Array.from({length: Math.max(0, (3) - (1))}, (_, __i) => (1) + __i)));
    __bp_print(@[](s, __bp_range_from(3)));
    __bp_print(@[](xs, __bp_range_from(1)));
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
COMPILE ERROR (node --check):
main.js:37
    __bp_print(@[](xs, 0));
               ^
SyntaxError: Invalid or unexpected token
```
