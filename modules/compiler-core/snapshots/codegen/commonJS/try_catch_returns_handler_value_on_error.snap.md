----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn maybeFail(should_fail: bool) -> @Result<i32, string> {
    if (should_fail) {
        throw "boom";
    } else {
        return 42;
    }
}
fn main() {
    val v = try maybeFail(true) catch -1;
    @print(v);
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

function maybeFail(should_fail) {
    if (should_fail) { return ({ error: "boom" }); } else { return ({ ok: 42 }); }
}

function main() {
    const _try0 = maybeFail(true);
    const v = "error" in _try0 ? ((-1)) : _try0.ok;
    __bp_print(v);
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
-1
```
