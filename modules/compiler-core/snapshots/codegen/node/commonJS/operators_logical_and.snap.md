----- SOURCE CODE -- main.bp
```botopink
fn both(a: bool, b: bool) -> bool {
    return a && b;
}
fn main() {
    @print(both(true, false));
}
```

----- JAVASCRIPT -- main.js
```javascript
function both(a, b) {
    return (a && b);
}

function main() {
    console.log(both(true, false));
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
false
```
