----- SOURCE CODE -- main.bp
```botopink
fn isPositive(n: i32) -> bool {
    return n > 0;
}
fn main() {
    @print(isPositive(5));
    @print(isPositive(-1));
}
```

----- JAVASCRIPT -- main.js
```javascript
function isPositive(n) {
    return (n > 0);
}

function main() {
    console.log(isPositive(5));
    console.log(isPositive((-1)));
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
