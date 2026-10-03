----- SOURCE CODE -- main.bp
```botopink
fn make() -> #(#(i32, i32), i32) {
    val outer = #(#(1, 2), 3);
    return outer;
}
```

----- JAVASCRIPT -- main.js
```javascript
function make() {
    const outer = [[1, 2], 3];
    return outer;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
