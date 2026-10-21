----- SOURCE CODE -- main.bp
```botopink
fn countUp(x: i32) -> void {
    for (x..) { i ->
        if (i > 100) {
          break;
        };
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function countUp(x) {
    while (true) {
    let __for2_5_c0 = x;
    while (true) {
    const i = __for2_5_c0;
    __for2_5_c0 = __bp_int((__for2_5_c0 + 1), -2147483648, 2147483647, "+ on i32 at main.bp:2:11");
    if ((i > 100)) { break; }
}
    break;
}
}

Object.defineProperty(exports, "__bp_priv__", { value: { countUp } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
