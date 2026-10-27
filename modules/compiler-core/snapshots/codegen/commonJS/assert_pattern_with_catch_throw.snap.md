----- SOURCE CODE -- main.bp
```botopink
type Person(name: string, age: i32)
fn f() -> Result<void, string> {
    val r = Person(name: "ann", age: 30);
    val assert Person(name, age) = r catch throw "is not person";
    return;
}
```

----- JAVASCRIPT -- main.js
```javascript
class Person {
    constructor(name, age) {
        this.name = name;
        this.age = age;
    }
}
Person.prototype.__bp = "Person";

function f() {
    const r = new Person("ann", 30);
    let _assert0 = r;
    if (!((_assert0 instanceof Person))) { return ({ error: "is not person" }); }
    const { name, age } = _assert0;
    return ({ ok: null });
}

Object.defineProperty(exports, "__bp_priv__", { value: { Person, f } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
