----- SOURCE CODE -- main.bp
```botopink
*fn fetch() -> @Result<i32, string> {
    @todo();
}
fn process() -> i32 {
    val r = try fetch();
    @print(r);
    return r;
}
```

----- JAVASCRIPT -- main.js
```javascript
function fetch() {
    (() => { throw new Error("not implemented") })();
}

function process() {
    const _try0 = fetch();
    if ("error" in _try0) return _try0;
    const r = _try0.ok;
    console.log(r);
    return r;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
