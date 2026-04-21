----- SOURCE CODE -- main.bp
```botopink
fn doubles(arr: i32[]) -> i32[] {
    return loop (arr) { x ->
        yield x * 2;
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function doubles(arr) {
    return arr.map((x) => {
    return (x * 2);
});
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
