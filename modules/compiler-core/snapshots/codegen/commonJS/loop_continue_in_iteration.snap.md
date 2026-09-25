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
function sumEvens(arr) {
    let out = [];
    for (const x of arr) {
    if (((x % 2) !== 0)) { continue; }
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
