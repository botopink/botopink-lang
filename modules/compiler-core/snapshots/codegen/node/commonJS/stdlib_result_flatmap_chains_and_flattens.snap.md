----- SOURCE CODE -- main.bp
```botopink
*fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
*fn validate(n: i32) -> @Result<i32, string> { @todo(); }
fn main() {
    val r = parseAge("42").flatMap({ n -> validate(n) });
}
```

----- JAVASCRIPT -- main.js
```javascript
function parseAge(s) {
    (() => { throw new Error("not implemented") })();
}

function validate(n) {
    (() => { throw new Error("not implemented") })();
}

function main() {
    const r = ((_r) => "error" in _r ? _r : ((n) => {
    return validate(n);
})(_r.ok))(parseAge("42"));
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
