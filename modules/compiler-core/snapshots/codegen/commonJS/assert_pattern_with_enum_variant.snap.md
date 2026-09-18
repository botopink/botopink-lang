----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn parse() -> @Result<i32, string> {
    return 42;
}
fn main() {
    val result = parse();
    val assert Ok(value) = result;
    @print(value);
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

function parse() {
    return ({ ok: 42 });
}

function main() {
    const result = parse();
    const _assert0 = (() => { const _match = result; if (("ok" in _match)) { return _match; } else { return (() => { throw new Error("assert pattern did not match") })(); } })();
    const value = _assert0.ok;
    __bp_print(value);
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
42
```
