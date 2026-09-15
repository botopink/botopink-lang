----- SOURCE CODE -- main.bp
```botopink
fn either(a: bool, b: bool) -> bool {
    return a || b;
}
fn main() {
    @print(either(false, true));
}
```

----- JAVASCRIPT -- main.js
```javascript
function either(a, b) {
    return (a || b);
}

function main() {
    console.log(either(false, true));
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
