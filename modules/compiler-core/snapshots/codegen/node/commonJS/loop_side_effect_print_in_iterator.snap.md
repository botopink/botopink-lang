----- SOURCE CODE -- main.bp
```botopink
val messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
loop (messages, 0..) { msg, i ->
    print("mensagem");
};
```

----- JAVASCRIPT -- main.js
```javascript
const messages = ["Erro 404", "Sucesso 200", "Aviso 500"];

const _loop = for (const [msg, i] of Object.entries(messages)) {
    print("mensagem");
};
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```
