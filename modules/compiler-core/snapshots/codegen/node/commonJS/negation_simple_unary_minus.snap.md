----- SOURCE CODE -- main.bp
```botopink
fn negate(x: i32) -> i32 {
    return -x;
}
fn main() {
    @print(negate(42));
}
```

----- JAVASCRIPT -- main.js
```javascript
function negate(x) {
    return (-x);
}

function main() {
    console.log(negate(42));
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
-42
```
