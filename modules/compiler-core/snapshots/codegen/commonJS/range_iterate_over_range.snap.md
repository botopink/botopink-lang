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
function sumTo(n) {
    let sum = 0;
    for (const i of Array.from({length: Math.max(0, (n) - (0))}, (_, __i) => (0) + __i)) {
    sum = (sum + i);
}
    return sum;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
