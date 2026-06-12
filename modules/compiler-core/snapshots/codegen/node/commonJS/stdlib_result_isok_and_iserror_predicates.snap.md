----- SOURCE CODE -- main.bp
```botopink
*fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
fn main() {
    val r = parseAge("42");
    val ok = r.isOk();
    val bad = r.isError();
}
```

----- JAVASCRIPT -- main.js
```javascript
function parseAge(s) {
    (() => { throw new Error("not implemented") })();
}

function main() {
    const r = parseAge("42");
    const ok = ((_r) => !("error" in _r))(r);
    const bad = ((_r) => "error" in _r)(r);
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
```
