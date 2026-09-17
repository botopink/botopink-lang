----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn validate(items: i32) -> @Result<i32, string> {
    loop (0..items) { i ->
        if (i > 2) { throw "too many"; };
    };
    return items;
}
fn main() {
    @print(validate(2).isOk());
}
```

----- JAVASCRIPT -- main.js
```javascript
function validate(items) {
    for (const i of Array.from({length: Math.max(0, (items) - (0))}, (_, __i) => (0) + __i)) {
    if ((i > 2)) { return ({ error: "too many" }); }
}
    return ({ ok: items });
}

function main() {
    console.log(((_r) => !("error" in _r))(validate(2)));
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
true
```
