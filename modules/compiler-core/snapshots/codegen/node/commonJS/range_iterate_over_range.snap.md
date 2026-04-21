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
    return 0..n.map((i) => {
    return i;
});
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
