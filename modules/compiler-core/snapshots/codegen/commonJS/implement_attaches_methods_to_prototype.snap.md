----- SOURCE CODE -- main.bp
```botopink
interface Printable {
    fn print(self: Self),
}
record Person { name: string }
val PersonPrintable = implement Printable for Person {
    fn print(self: Self) {
        return self.name;
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
// interface Printable
//   fn print(...)

class Person {
    constructor(name) {
        this.name = name;
    }
}

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
