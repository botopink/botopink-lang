----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val x: ?i32 = 42;
    if (x) { n -> @print(n); };
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const x = 42;
    (() => { const n = x; if (n !== null) { return console.log(n); } })();
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
