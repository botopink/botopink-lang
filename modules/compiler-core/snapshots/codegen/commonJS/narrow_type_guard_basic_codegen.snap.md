----- SOURCE CODE -- main.bp
```botopink
fn isPositive(n: i32) -> n is i32 {
    return n > 0;
}
fn main() {
    @print(isPositive(5));
}
```

----- JAVASCRIPT -- main.js
```javascript
function isPositive(n) {
    return (n > 0);
}

function main() {
    console.log(isPositive(5));
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
