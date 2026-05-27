----- SOURCE CODE -- main.bp
```botopink
record RiskError { level: i32 }
fn risky() -> @Result(i32, RiskError) {
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
    throw RiskError(5);
}

function safe() {
    return (() => { try { return risky(); } catch(_e) { return ((-1))(_e); } })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
