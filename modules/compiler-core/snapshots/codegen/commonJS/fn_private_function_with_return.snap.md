----- SOURCE CODE -- main.bp
```botopink
fn double(x: i32) -> i32 {
    return x * 2;
}
val result = double(5);
fn main() {
    @print(result);
}
```

----- JAVASCRIPT -- main.js
```javascript
function double(x) {
    return (x * 2);
}

const result = double(5);

function main() {
    console.log(result);
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
10
```
