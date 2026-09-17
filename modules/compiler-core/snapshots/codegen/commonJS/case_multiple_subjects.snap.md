----- SOURCE CODE -- main.bp
```botopink
fn process(a: i32, b: i32) {
    case a, b {
        0, 0 -> null;
        _, _ -> null;
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function process(a, b) {
    (() => {
        const _s = [a, b];
        if (_s[0] === 0 && _s[1] === 0) return null;
        return null;
    })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
