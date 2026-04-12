----- SOURCE CODE -- main.bp
```botopink
fn describe() -> string {
    val items = ["a", "b", "c"];
    return case items {
        [] -> "empty";
        [x] -> "one";
        [first, ..rest] -> "many";
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function describe() {
    const items = ["a", "b", "c"];
    return (() => {
        const _s = items;
        if (_s.length === 0) return "empty";
        if (_s.length === 1) {
            const x = _s[0];
            return "one";
        }
        if (_s.length >= 1) {
            const rest = _s.slice(1);
            const first = _s[0];
            return "many";
        }
    })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
