----- SOURCE CODE -- main.bp
```botopink
fn sumTo(n: i32) -> i32 {
    var sum = 0;
    for (0..n) { i ->
        sum = sum + i;
    };
    return sum;
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function sumTo(n) {
    let sum = 0;
    for (const i of Array.from({length: Math.max(0, (n) - (0))}, (_, __i) => (0) + __i)) {
    sum = __bp_int((sum + i), -2147483648, 2147483647, "+ on i32 at main.bp:4:19");
}
    return sum;
}

Object.defineProperty(exports, "__bp_priv__", { value: { sumTo } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
