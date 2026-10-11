----- SOURCE CODE -- main.bp
```botopink
fn classify(n: i32) -> string {
    return case n {
        x if x > 0 -> "positive";
        0 -> "zero";
        _ -> "negative";
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function classify(n) {
    return (() => {
        const _s = n;
        {
            const x = _s;
            if ((x > 0)) return "positive";
        }
        if (_s === 0) return "zero";
        return "negative";
    })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
