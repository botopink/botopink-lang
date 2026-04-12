----- SOURCE CODE -- main.bp
```botopink
val precosBrutos = [100, 250, 400];
val apenasGrandes = loop (precosBrutos) { valor ->
    if (valor > 200) {
        break valor;
    };
};
```

----- JAVASCRIPT -- main.js
```javascript
const precosBrutos = [100, 250, 400];

const apenasGrandes = for (const [valor] of Object.entries(precosBrutos)) {
    (() => { if ((valor > 200)) { return valor; } })();
};
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```
