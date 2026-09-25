----- SOURCE CODE -- main.bp
```botopink
fn coerce(comptime v: type string | int | bool, x: i32) -> i32 {
    return x;
}

fn main() {
    val a = coerce("s", 1);
    val b = coerce(7, 2);
    val c = coerce("s", 3);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const a = coerce_$0(1);
    const b = coerce_$1(2);
    const c = coerce_$0(3);
}

function coerce_$0(x) {
    return x;
}

function coerce_$1(x) {
    return x;
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
