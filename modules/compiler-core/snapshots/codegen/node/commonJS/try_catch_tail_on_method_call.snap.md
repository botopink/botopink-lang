----- SOURCE CODE -- main.bp
```botopink
record ParseError { msg: string }
val Parser = struct {
    fn parse(self: Self) -> @Result<i32, ParseError> {
        throw ParseError(msg: "bad input");
    }
}
fn run(p: Parser) -> i32 {
    val result = p.parse() catch 0;
    return result;
}
```

----- JAVASCRIPT -- main.js
```javascript
class ParseError {
    constructor(msg) {
        this.msg = msg;
    }
}

class Parser {

    parse() {
        throw new ParseError("bad input");
    }
}

function run(p) {
    const _try0 = p.parse();
    const result = "error" in _try0 ? (0) : _try0.ok;
    return result;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
