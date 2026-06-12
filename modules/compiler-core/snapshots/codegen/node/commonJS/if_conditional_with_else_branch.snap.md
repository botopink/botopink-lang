----- SOURCE CODE -- main.bp
```botopink
fn describe(n: i32) -> string {
    return if (n > 0) "positive" else "non-positive";
}
fn main() {
    @print(describe(5));
    @print(describe(-3));
}
```

----- JAVASCRIPT -- main.js
```javascript
function describe(n) {
    return (() => { if ((n > 0)) { return "positive"; } else { return "non-positive"; } })();
}

function main() {
    console.log(describe(5));
    console.log(describe((-3)));
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
non-positive
```
