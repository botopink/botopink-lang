----- SOURCE CODE -- main.bp
```botopink
val result = case 42 {
    0    -> "zero";
    else -> 1;
};
```

----- JAVASCRIPT -- main.js
```javascript
const result = (() => {
    const _s = 42;
    if (_s === 0) return "zero";
    return 1;
})();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
