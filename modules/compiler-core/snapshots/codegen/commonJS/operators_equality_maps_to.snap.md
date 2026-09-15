----- SOURCE CODE -- main.bp
```botopink
fn isZero(n: i32) -> bool {
    return n == 0;
}
fn main() {
    @print(isZero(0));
    @print(isZero(42));
}
```

----- JAVASCRIPT -- main.js
```javascript
function isZero(n) {
    return (n === 0);
}

function main() {
    console.log(isZero(0));
    console.log(isZero(42));
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
false
```
