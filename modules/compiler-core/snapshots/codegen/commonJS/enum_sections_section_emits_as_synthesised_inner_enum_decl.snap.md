----- SOURCE CODE -- main.bp
```botopink
enum Token {
    Text {
        Bold, Italic, Underline,
    }
    Hover(inner: i32),
}
```

----- JAVASCRIPT -- main.js
```javascript
const __Token__Text = Object.freeze({
    Bold: "Bold",
    Italic: "Italic",
    Underline: "Underline",
});

const Token = Object.freeze({
    Hover: (inner) => ({ tag: "Hover", inner }),
    Text: (_inner) => ({ tag: "Text", _inner }),
});
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
