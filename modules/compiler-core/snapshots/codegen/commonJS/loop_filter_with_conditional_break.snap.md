----- SOURCE CODE -- main.bp
```botopink
val precosBrutos = [100, 250, 400];
val apenasGrandes = loop (precosBrutos) { valor ->
    if (valor > 200) {
        break valor;
    };
};
fn main() {
    @print(apenasGrandes);
}
```

----- JAVASCRIPT -- main.js
```javascript
const precosBrutos = [100, 250, 400];

const apenasGrandes = for (const valor of precosBrutos) {
    (() => { if ((valor > 200)) { return return valor; } })();
};

function main() {
    console.log(apenasGrandes);
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
const apenasGrandes = for (const valor of precosBrutos) {
                      ^^^
SyntaxError: Unexpected token 'for'
```
