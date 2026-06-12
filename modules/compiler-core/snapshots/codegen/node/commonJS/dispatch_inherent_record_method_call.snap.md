----- SOURCE CODE -- main.bp
```botopink
record Contador {
    n: i32,
    fn atual(self: Self) {
        return self.n;
    }
}
fn main() {
    val c = Contador(5);
    @print(c.atual());
}
```

----- JAVASCRIPT -- main.js
```javascript
class Contador {
    constructor(n) {
        this.n = n;
    }

    atual() {
        return this.n;
    }
}

function main() {
    const c = new Contador(5);
    console.log(c.atual());
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
