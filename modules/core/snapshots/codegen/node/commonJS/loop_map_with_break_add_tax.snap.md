----- SOURCE CODE -- main.bp
```botopink
val precosBrutos = [100, 250, 400];
val precosComTaxa = loop (precosBrutos) { valor ->
    val taxa = valor * 0.15;
    break valor + taxa;
};
```

----- JAVASCRIPT -- main.js
```javascript
const precosBrutos = [100, 250, 400];

const precosComTaxa = for (const [valor] of Object.entries(precosBrutos)) {
    const taxa = (valor * 0.15);
    (valor + taxa);
};
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```
