----- SOURCE CODE -- main.bp
```botopink
fn double(x: i32) -> i32 {
    val result = x * 2;
    return result;
}
val output = double(10);
fn main() {
    @print(output);
}
```

----- JAVASCRIPT -- main.js
```javascript
function double(x) {
    const result = (x * 2);
    return result;
}

const output = double(10);

function main() {
    console.log(output);
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
20
```
