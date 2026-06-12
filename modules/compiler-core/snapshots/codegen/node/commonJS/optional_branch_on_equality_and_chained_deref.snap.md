----- SOURCE CODE -- main.bp
```botopink
record R { kind: i32 }
fn main() {
    val r = R(kind: 11);
    val maybe: ?R = r;
    if (maybe == null) {
        @print(0);
    } else {
        @print(maybe?.kind);
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
class R {
    constructor(kind) {
        this.kind = kind;
    }
}

function main() {
    const r = new R(11);
    const maybe = r;
    (() => { if ((maybe == null)) { return console.log(0); } else { return console.log(maybe?.kind); } })();
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
11
```
