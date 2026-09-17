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

const precosComTaxa = (() => {
    const _acc = [];
    for (const valor of precosBrutos) {
        const taxa = (valor * 0.15);
        _acc.push((valor + taxa));
    }
    return _acc;
})();

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
[ 115, 287.5, 460 ]
```
