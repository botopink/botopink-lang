----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn inner(should_fail: bool) -> @Result<i32, string> {
    if (should_fail) {
        throw "inner-fail";
    } else {
        return 7;
    }
}
#[@result]
fn outer(should_fail: bool) -> @Result<i32, string> {
    val v = try inner(should_fail);
    return v + 1;
}
fn main() {
    val r = try outer(false) catch -1;
    @print(r);
}
```

----- JAVASCRIPT -- main.js
```javascript
function inner(should_fail) {
     if (should_fail) { return ({ error: "inner-fail" }); } else { return ({ ok: 7 }); };
}

function outer(should_fail) {
    const _try0 = inner(should_fail);
    if ("error" in _try0) return _try0;
    const v = _try0.ok;
    return ({ ok: (v + 1) });
}

function main() {
    const _try0 = outer(false);
    const r = "error" in _try0 ? ((-1)) : _try0.ok;
    console.log(r);
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
```
