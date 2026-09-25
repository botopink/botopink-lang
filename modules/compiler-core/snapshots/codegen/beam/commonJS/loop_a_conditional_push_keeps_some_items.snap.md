----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val precosBrutos = [100, 250, 400];
    var apenasGrandes = [];
    for (precosBrutos) { valor ->
        if (valor > 200) {
            apenasGrandes.push(valor);
        };
    };
    @print(apenasGrandes);
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
    const precosBrutos = [100, 250, 400];
    let apenasGrandes = [];
    for (const valor of precosBrutos) {
    (() => { if ((valor > 200)) { return apenasGrandes.push(valor); } })();
}
    __bp_print(apenasGrandes);
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
[250, 400]
```
