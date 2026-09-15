----- SOURCE CODE -- main.bp
```botopink
val Inner = record { value: i32 }
val Outer = record { inner: ?Inner }
fn getValue(o: Outer) -> ?i32 {
    return o.inner?.value;
}
fn main() {
    val o = Outer(inner: Inner(value: 42));
    @print(getValue(o));
}
```

----- JAVASCRIPT -- main.js
```javascript
class Inner {
    constructor(value) {
        this.value = value;
    }
}

class Outer {
    constructor(inner) {
        this.inner = inner;
    }
}

function getValue(o) {
    return o.inner?.value;
}

function main() {
    const o = new Outer(new Inner(42));
    console.log(getValue(o));
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
42
```
