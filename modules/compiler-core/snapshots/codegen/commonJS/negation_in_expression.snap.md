----- SOURCE CODE -- main.bp
```botopink
fn diff(x: i32, y: i32) -> i32 {
    return x + -y;
}
fn main() {
    @print(diff(10, 3));
}
```

----- JAVASCRIPT -- main.js
```javascript
function diff(x, y) {
    return (x + (-y));
}

function main() {
    console.log(diff(10, 3));
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
7
```
