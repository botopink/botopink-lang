----- SOURCE CODE -- main.bp
```botopink
type Span(start: i32, end: i32, line: i32)
fn span() -> Span {
    return Span(start: 4, end: 9, line: 2);
}
fn lineNo() -> i32 {
    return span().line;
}
```

----- JAVASCRIPT -- main.js
```javascript
class Span {
    constructor(start, end, line) {
        this.start = start;
        this.end = end;
        this.line = line;
    }
}
Span.prototype.__bp = "Span";

function span() {
    return new Span(4, 9, 2);
}

function lineNo() {
    return span().line;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
