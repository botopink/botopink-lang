----- SOURCE CODE -- main.bp
```botopink
loop (0..10) { i ->
    print("item");
};
```

----- JAVASCRIPT -- main.js
```javascript
const _loop = for (const [i] of Object.entries(0..10)) {
    print("item");
};
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
