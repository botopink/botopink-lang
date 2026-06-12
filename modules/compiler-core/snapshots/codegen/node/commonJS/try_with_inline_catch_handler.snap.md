----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn fetch() -> @Result<i32, string> {
    @todo();
}
fn safe() -> i32 {
    val r = try fetch() catch 0;
    @print(r);
    return r;
}
fn main() {
    @print(safe());
}
```

----- JAVASCRIPT -- main.js
```javascript
function fetch() {
    (() => { throw new Error("not implemented") })();
}

function safe() {
    const _try0 = fetch();
    const r = "error" in _try0 ? (0) : _try0.ok;
    console.log(r);
    return r;
}

function main() {
    console.log(safe());
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
