----- SOURCE CODE -- main.bp
```botopink
type Token {
    Text {
        Bold, Italic, Underline,
    }
    Hover(inner: i32),
}
```

----- JAVASCRIPT -- main.js
```javascript
class __Token__Text {
}
__Token__Text.prototype.__bp = "__Token__Text";
class __Token__Text$Bold extends __Token__Text {
}
__Token__Text$Bold.prototype.tag = "Bold";
class __Token__Text$Italic extends __Token__Text {
}
__Token__Text$Italic.prototype.tag = "Italic";
class __Token__Text$Underline extends __Token__Text {
}
__Token__Text$Underline.prototype.tag = "Underline";
__Token__Text.Bold = new __Token__Text$Bold();
__Token__Text.Italic = new __Token__Text$Italic();
__Token__Text.Underline = new __Token__Text$Underline();

class Token {
    static Hover(inner) {
        return new Token$Hover(inner);
    }

    static Text(_inner) {
        return new Token$Text(_inner);
    }
}
Token.prototype.__bp = "Token";
class Token$Hover extends Token {
    constructor(inner) {
        super();
        this.inner = inner;
    }
}
Token$Hover.prototype.tag = "Hover";
class Token$Text extends Token {
    constructor(_inner) {
        super();
        this._inner = _inner;
    }
}
Token$Text.prototype.tag = "Text";
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
