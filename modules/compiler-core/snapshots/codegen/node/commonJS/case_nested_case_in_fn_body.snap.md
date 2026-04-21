----- SOURCE CODE -- main.bp
```botopink
fn process(x: i32) -> string {
    return case (x) {
        0 -> {
            break case (x) {
                0 -> "zero";
                _ -> "other";
            };
        };
        _ -> "non-zero";
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function process(x) {
    return (() => {
        const _s = x;
        if (_s === 0) {
            return (() => {
                const _s = x;
                if (_s === 0) return "zero";
                return "other";
            })();
        }
        return "non-zero";
    })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
