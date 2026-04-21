----- SOURCE CODE -- main.bp
```botopink
fn find(arr: i32[]) -> i32 {
    return loop (arr) { x ->
        if (x > 10) { break x; };
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function find(arr) {
    return for (const [x] of Object.entries(arr)) {
    (() => { if ((x > 10)) { return return x; } })();
};
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
