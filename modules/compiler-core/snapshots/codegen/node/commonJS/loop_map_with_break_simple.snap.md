----- SOURCE CODE -- main.bp
```botopink
val ids = [10, 20, 30];
val dobrados = loop (ids) { id ->
    break id * 2;
};
```

----- JAVASCRIPT -- main.js
```javascript
const ids = [10, 20, 30];

const dobrados = for (const [id] of Object.entries(ids)) {
    return (id * 2);
};
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```
