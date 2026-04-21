----- SOURCE CODE -- main.bp
```botopink
val processamento = loop (0..10) { i ->
    if (i % 2 == 0) {
        break i;
    };
};
```

----- JAVASCRIPT -- main.js
```javascript
const processamento = for (const [i] of Object.entries(0..10)) {
    (() => { if (((i % 2) === 0)) { return return i; } })();
};
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
