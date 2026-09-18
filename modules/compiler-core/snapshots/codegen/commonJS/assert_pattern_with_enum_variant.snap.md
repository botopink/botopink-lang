----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn parse() -> @Result<i32, string> {
    return 42;
}
fn f() {
    val result = parse();
    val assert Ok(value) = result catch throw "not ok";
}
```

----- JAVASCRIPT -- main.js
```javascript
function parse() {
    return ({ ok: 42 });
}

function f() {
    const result = parse();
    (() => { const _match = result; if ((_match instanceof Ok)) { return _match; } else { throw "not ok"; } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
