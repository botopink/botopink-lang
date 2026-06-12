----- SOURCE CODE -- main.bp
```botopink
val messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
loop (messages, 0..) { msg, i ->
    @print(msg);
};
```

----- JAVASCRIPT -- main.js
```javascript
const messages = ["Erro 404", "Sucesso 200", "Aviso 500"];

const _loop = for (const [i, msg] of (messages).entries()) {
    console.log(msg);
};
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
