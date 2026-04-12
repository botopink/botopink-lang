----- SOURCE CODE -- main.bp
```botopink
val parity = case 5 {
    0 | 2 | 4 -> "even";
    else      -> {
        val value = "odd";
        break value;
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
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
