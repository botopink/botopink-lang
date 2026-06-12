----- SOURCE CODE -- main.bp
```botopink
val E = struct implement @Context<E, E> { tag: string, n: i32 }
fn mk() -> E {
    return E(tag: "x", n: 5);
}
fn main() {
    @print(mk().n);
}
```

----- JAVASCRIPT -- main.js
```javascript
class E {
    constructor(tag, n) {
        this.tag = tag;
        this.n = n;
    }
}

function mk() {
    return new E("x", 5);
}

function main() {
    console.log(mk().n);
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
5
```
