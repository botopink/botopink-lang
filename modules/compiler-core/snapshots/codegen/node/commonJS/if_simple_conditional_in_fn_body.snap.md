----- SOURCE CODE -- main.bp
```botopink
fn sign(n: i32) -> string {
    val r = if (n > 0) { "positive"; };
    @print(r);
    return r;
}
fn main() {
    sign(5);
    sign(-3);
}
```

----- JAVASCRIPT -- main.js
```javascript
function sign(n) {
    const r = (() => { if ((n > 0)) { return "positive"; } })();
    console.log(r);
    return r;
}

function main() {
    sign(5);
    sign((-3));
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
positive
undefined
```
