----- SOURCE CODE -- main.bp
```botopink
fn sumEvens(arr: i32[]) -> i32 {
    return loop (arr) { x ->
        if (x % 2 != 0) { continue; };
        yield x;
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function sumEvens(arr) {
    return arr.map((x) => {
    (() => { if (((x % 2) !== 0)) { return continue; } })();
    return x;
});
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
