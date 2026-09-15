----- SOURCE CODE -- main.bp
```botopink
fn sumTo(n: i32) -> i32 {
    return loop (0..n) { i ->
        yield i;
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function sumTo(n) {
    return Array.from({length: Math.max(0, (n) - (0))}, (_, __i) => (0) + __i).map((i) => {
    return i;
});
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
