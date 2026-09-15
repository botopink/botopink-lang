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
    val v = try maybeFail(false) catch -1;
    @print(v);
}
```

----- JAVASCRIPT -- main.js
```javascript
function maybeFail(should_fail) {
     if (should_fail) { return ({ error: "boom" }); } else { return ({ ok: 42 }); };
}

function main() {
    const _try0 = maybeFail(false);
    const v = "error" in _try0 ? ((-1)) : _try0.ok;
    console.log(v);
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
