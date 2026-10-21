----- SOURCE CODE -- main.bp
```botopink
behavior Printable {
    fn print(self: Self) -> string;
}
type Person(name: string)
val PersonPrintable = implement Printable for Person {
    fn print(self: Self) -> string {
        return self.name;
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
// behavior Printable
//   fn print(...)

class Person {
    constructor(name) {
        this.name = name;
    }
}
Person.prototype.__bp = "Person";

// implement Printable for Person
const PersonPrintable = {
    print(self) {
        return self.name;
    },
};

Object.defineProperty(exports, "__bp_priv__", { value: { Person, PersonPrintable } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
