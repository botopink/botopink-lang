----- SOURCE CODE -- main.bp
```botopink
behavior Printable {
    fn print(self: Self);
}
type Person(name: string)
val PersonPrintable = implement Printable for Person {
    fn print(self: Self) {
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
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
