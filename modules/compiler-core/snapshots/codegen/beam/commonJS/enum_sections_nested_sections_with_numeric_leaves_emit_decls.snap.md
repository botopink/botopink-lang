----- SOURCE CODE -- main.bp
```botopink
type Token {
    Color {
        Red { 100, 500 }
        Hex(value: string),
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
class __Token__Color {
    static Hex(value) {
        return new __Token__Color$Hex(value);
    }

    static Red(_inner) {
        return new __Token__Color$Red(_inner);
    }
}
__Token__Color.prototype.__bp = "__Token__Color";
class __Token__Color$Hex extends __Token__Color {
    constructor(value) {
        super();
        this.value = value;
    }
}
__Token__Color$Hex.prototype.tag = "Hex";
class __Token__Color$Red extends __Token__Color {
    constructor(_inner) {
        super();
        this._inner = _inner;
    }
}
__Token__Color$Red.prototype.tag = "Red";

class __Token__Color__Red {
}
__Token__Color__Red.prototype.__bp = "__Token__Color__Red";
class __Token__Color__Red$__100 extends __Token__Color__Red {
}
__Token__Color__Red$__100.prototype.tag = "__100";
class __Token__Color__Red$__500 extends __Token__Color__Red {
}
__Token__Color__Red$__500.prototype.tag = "__500";
__Token__Color__Red.__100 = new __Token__Color__Red$__100();
__Token__Color__Red.__500 = new __Token__Color__Red$__500();

class Token {
    static Color(_inner) {
        return new Token$Color(_inner);
    }
}
Token.prototype.__bp = "Token";
class Token$Color extends Token {
    constructor(_inner) {
        super();
        this._inner = _inner;
    }
}
Token$Color.prototype.tag = "Color";
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
