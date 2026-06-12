----- SOURCE CODE -- main.bp
```botopink
enum Token {
    Color {
        Red { 100, 500 }
        Hex(value: string),
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
const __Token__Color = Object.freeze({
    Hex: (value) => ({ tag: "Hex", value }),
    Red: (_inner) => ({ tag: "Red", _inner }),
});

const __Token__Color__Red = Object.freeze({
    __100: "__100",
    __500: "__500",
});

const Token = Object.freeze({
    Color: (_inner) => ({ tag: "Color", _inner }),
});
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
