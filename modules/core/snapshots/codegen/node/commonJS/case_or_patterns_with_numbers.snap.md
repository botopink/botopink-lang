----- SOURCE CODE -- main.bp
```botopink
fn classify(day: i32) -> string {
    val kind = case day {
        6 | 7 -> "weekend";
        else -> "weekday";
    };
    return kind;
}
```

----- JAVASCRIPT -- main.js
```javascript
function classify(day) {
    const kind = (() => {
        const _s = day;
        if (_s === 6 || _s === 7) return "weekend";
        return "weekday";
    })();
    return kind;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
