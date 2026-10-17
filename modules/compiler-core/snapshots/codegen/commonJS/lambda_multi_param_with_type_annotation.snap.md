----- SOURCE CODE -- main.bp
```botopink
fn main() -> i32 {
    val add: fn(i32,i32)-> i32 = {a, b ->
        return a + b;
    };
    return add(10, 20);
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function main() {
    const add = (a, b) => {
    return __bp_int((a + b), -2147483648, 2147483647, "+ on i32 at main.bp:3:18");
};
    return add(10, 20);
}

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
