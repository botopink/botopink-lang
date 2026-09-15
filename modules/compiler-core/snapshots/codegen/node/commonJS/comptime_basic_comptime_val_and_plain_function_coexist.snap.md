----- SOURCE CODE -- main.bp
```botopink
val x = comptime 1 + 2;

fn double(n: i32) -> i32 {
    return n * 2;
}

fn main() {
    val r = double(21);
}
```

----- COMPTIME VALUES -- main
```text
ct_0 = 3
```

----- JAVASCRIPT -- main.js
```javascript
const x = 3;

function double(n) {
    return (n * 2);
}

function main() {
    const r = double(21);
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
