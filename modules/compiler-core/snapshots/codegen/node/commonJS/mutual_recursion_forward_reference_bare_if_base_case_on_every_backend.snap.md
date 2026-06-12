----- SOURCE CODE -- main.bp
```botopink
fn main() -> bool {
    return isEven(10);
}

fn isEven(n: i32) -> bool {
    if (n == 0) { return true; };
    return isOdd(n - 1);
}

fn isOdd(n: i32) -> bool {
    if (n == 0) { return false; };
    return isEven(n - 1);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    return isEven(10);
}

function isEven(n) {
     if ((n === 0)) { return true; };
    return isOdd((n - 1));
}

function isOdd(n) {
     if ((n === 0)) { return false; };
    return isEven((n - 1));
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
```
