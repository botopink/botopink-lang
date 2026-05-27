----- SOURCE CODE -- main.bp
```botopink
record Person { name: string, age: i32 }
fn greet({ name, .. }: Person) -> string {
    @print(name);
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

function greet({ name, ... } = ) {
    console.log(name);
    return name;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
