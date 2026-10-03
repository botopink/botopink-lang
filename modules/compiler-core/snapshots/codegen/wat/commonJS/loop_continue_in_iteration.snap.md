----- SOURCE CODE -- main.bp
```botopink
fn sumEvens(arr: i32[]) -> i32[] {
    var out = [];
    for (arr) { x ->
        if (x % 2 != 0) { continue; };
        out.push(x);
    };
    return out;
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

function sumEvens(arr) {
    let out = [];
    for (const x of arr) {
    if ((__bp_int((x % 2), -2147483648, 2147483647, "% on i32 at main.bp:4:15") !== 0)) { continue; }
    out.push(x);
}
    return out;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
