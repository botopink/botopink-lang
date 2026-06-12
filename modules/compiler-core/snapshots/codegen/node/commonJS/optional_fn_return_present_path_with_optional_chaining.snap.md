----- SOURCE CODE -- main.bp
```botopink
record R { kind: i32 }
fn pick(present: bool) -> ?R {
    if (present) {
        return R(kind: 7);
    } else {
        return null;
    }
}
fn main() {
    @print(pick(true)?.kind);
}
```

----- JAVASCRIPT -- main.js
```javascript
class R {
    constructor(kind) {
        this.kind = kind;
    }
}

function pick(present) {
     if (present) { return new R(7); } else { return null; };
}

function main() {
    console.log(pick(true)?.kind);
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
7
```
