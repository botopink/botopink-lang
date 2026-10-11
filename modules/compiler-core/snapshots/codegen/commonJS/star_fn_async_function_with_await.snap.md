----- SOURCE CODE -- main.bp
```botopink
fn fetch(x: i32) -> @Task<i32> {
    return x;
}
fn loadTwice(x: i32) -> @Task<i32> {
    val a = await fetch(x);
    return a + a;
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

async function fetch(x) {
    return x;
}

async function loadTwice(x) {
    const a = await fetch(x);
    return __bp_int((a + a), -2147483648, 2147483647, "+ on i32 at main.bp:6:14");
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
