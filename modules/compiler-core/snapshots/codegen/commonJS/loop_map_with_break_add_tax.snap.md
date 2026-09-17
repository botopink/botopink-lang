----- SOURCE CODE -- main.bp
```botopink
val precosBrutos = [100, 250, 400];
val precosComTaxa = loop (precosBrutos) { valor ->
    val taxa = valor * 0.15;
    break valor + taxa;
};
fn main() {
    @print(precosComTaxa);
}
```

----- JAVASCRIPT -- main.js
```javascript
const precosBrutos = [100, 250, 400];

const precosComTaxa = for (const valor of precosBrutos) {
    const taxa = (valor * 0.15);
    return (valor + taxa);
};

function main() {
    console.log(precosComTaxa);
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
COMPILE ERROR (node --check):
main.js:3
const precosComTaxa = for (const valor of precosBrutos) {
                      ^^^
SyntaxError: Unexpected token 'for'
```
