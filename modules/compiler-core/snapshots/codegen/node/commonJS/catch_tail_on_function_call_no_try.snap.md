----- SOURCE CODE -- main.bp
```botopink
record RiskError { level: i32 }
*fn risky() -> @Result<i32, RiskError> {
    throw RiskError(level: 5);
}
fn safe() -> i32 {
    return risky() catch -1;
}
```

----- JAVASCRIPT -- main.js
```javascript
class RiskError {
    constructor(level) {
        this.level = level;
    }
}

function risky() {
    return ({ error: new RiskError(5) });
}

function safe() {
    const _try0 = risky();
    return "error" in _try0 ? ((-1)) : _try0.ok;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
