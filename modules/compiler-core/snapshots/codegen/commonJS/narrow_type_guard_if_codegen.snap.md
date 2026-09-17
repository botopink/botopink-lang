----- SOURCE CODE -- main.bp
```botopink
fn isString(x: ?string) -> x is string {
    if (x) { s -> return true; };
    return false;
}
fn main() {
    @print(isString("hello"));
}
```

----- JAVASCRIPT -- main.js
```javascript
function isString(x) {
    { const s = x; if (s !== null) { return true; } }
    return false;
}

function main() {
    console.log(isString("hello"));
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
