----- SOURCE CODE -- main.bp
```botopink
*fn parse(n: i32) -> @Result<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}

fn main() {
    val r = result.map(parse(21), { x -> x * 2 });
    @print(result.unwrap(r, 0));
}
```

----- JAVASCRIPT -- main.js
```javascript
function parse(n) {
     if ((n < 0)) { return ({ error: "negative" }); };
    return ({ ok: n });
}

function main() {
    const r = ((_r) => "error" in _r ? _r : { ok: ((x) => {
    return (x * 2);
})(_r.ok) })(parse(21));
    console.log(((_r) => "error" in _r ? (0) : _r.ok)(r));
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
