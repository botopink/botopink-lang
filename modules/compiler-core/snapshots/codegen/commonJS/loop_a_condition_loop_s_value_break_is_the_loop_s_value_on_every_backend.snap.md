----- SOURCE CODE -- main.bp
```botopink
fn main() {
    var i = 0;
    val found = while (i < 10) { if (i == 4) { break i * 2; }; i = i + 1; };
    @print(found);
    @print(i);
    var k = 0;
    val r = loop { k = k + 1; if (k > 2) { break k; }; };
    @print(r);
    var n = 0;
    val never = while (n < 3) { if (n == 99) { break n; }; n = n + 1; };
    @print(never);
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
    let i = 0;
    const found = (() => {
        while ((i < 10)) {
            if ((i === 4)) { return (i * 2); }
            i = (i + 1);
        }
        return null;
    })();
    __bp_print(found);
    __bp_print(i);
    let k = 0;
    const r = (() => {
        while (true) {
            k = (k + 1);
            if ((k > 2)) { return k; }
        }
        return null;
    })();
    __bp_print(r);
    let n = 0;
    const never = (() => {
        while ((n < 3)) {
            if ((n === 99)) { return n; }
            n = (n + 1);
        }
        return null;
    })();
    __bp_print(never);
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
8
4
3
null
```
