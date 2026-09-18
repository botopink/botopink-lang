----- SOURCE CODE -- main.bp
```botopink
type Person(name: string, age: i32)
fn f() {
    val r = Person(name: "ann", age: 30);
    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
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

function f() {
    const r = new Person("ann", 30);
    const _assert0 = (() => { const _match = r; if ((_match instanceof Person)) { return _match; } else { return new Person("bob", 12); } })();
    const { name, age } = _assert0;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
