----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn fetch(ok: bool) -> @Result<string, string> {
    if (ok) { return "data"; };
    throw "fail";
}
fn main() {
    val r1 = fetch(true);
    val msg1 = case r1 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; };
    @print(msg1);
    val r2 = fetch(false);
    val msg2 = case r2 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; };
    @print(msg2);
}
```

----- JAVASCRIPT -- main.js
```javascript
function fetch(ok) {
    if (ok) { return ({ ok: "data" }); }
    return ({ error: "fail" });
}

function main() {
    const r1 = fetch(true);
    const msg1 = (() => {
        const _s = r1;
        if ("ok" in _s) {
            const v = _s.ok;
            return ("OK:" + v);
        }
        if ("error" in _s) {
            const e = _s.error;
            return ("ERR:" + e);
        }
    })();
    console.log(msg1);
    const r2 = fetch(false);
    const msg2 = (() => {
        const _s = r2;
        if ("ok" in _s) {
            const v = _s.ok;
            return ("OK:" + v);
        }
        if ("error" in _s) {
            const e = _s.error;
            return ("ERR:" + e);
        }
    })();
    console.log(msg2);
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
OK:data
ERR:fail
```
