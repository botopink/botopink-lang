----- SOURCE CODE -- main.bp
```botopink
record R { kind: i32 }
fn choose(present: bool) -> ?R {
    if (present) {
        return R(kind: 7);
    } else {
        return null;
    }
}
fn main() {
    @print(choose(false)?.kind);
}
```

----- JAVASCRIPT -- main.js
```javascript
class R {
    constructor(kind) {
        this.kind = kind;
    }
}

function choose(present) {
    if (present) { return new R(7); } else { return null; }
}

function main() {
    console.log(choose(false)?.kind);
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
undefined
```
