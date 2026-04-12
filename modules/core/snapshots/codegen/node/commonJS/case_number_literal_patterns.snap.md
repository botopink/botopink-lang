----- SOURCE CODE -- main.bp
```botopink
fn classify(n: i32) -> string {
    val result = case n {
        0 -> "zero";
        1 -> "one";
        else -> "many";
    };
    return result;
}
```

----- JAVASCRIPT -- main.js
```javascript
function classify(n) {
    const result = (() => {
        const _s = n;
        if (_s === 0) return "zero";
        if (_s === 1) return "one";
        return "many";
    })();
    return result;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
