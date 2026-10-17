----- SOURCE CODE -- main.bp
```botopink
val parity = case 5 {
    0 | 2 | 4 -> "even";
    _      -> {
        val value = "odd";
        value
    };
};
```

----- JAVASCRIPT -- main.js
```javascript
const parity = (() => {
    const _s = 5;
    if (_s === 0 || _s === 2 || _s === 4) return "even";
    {
        const value = "odd";
        return value;
    }
})();

Object.defineProperty(exports, "__bp_priv__", { value: { parity } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
