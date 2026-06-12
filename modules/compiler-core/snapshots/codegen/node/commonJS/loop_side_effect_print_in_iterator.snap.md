----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
    loop (messages, 0..) { msg, i ->
        @print(msg);
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
    for (const [i, msg] of (messages).entries()) {
    console.log(msg);
};
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
Erro 404
Sucesso 200
Aviso 500
```
