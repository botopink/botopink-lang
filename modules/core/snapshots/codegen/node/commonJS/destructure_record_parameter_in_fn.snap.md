----- SOURCE CODE -- main.bp
```botopink
record Person { name: string, age: i32 }
fn greet({ name, age }: Person) -> string {
    return name;
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

function greet({ name, age }) {
    return name;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```
