----- SOURCE CODE -- main.bp
```botopink
record User { name: string }

fn main() {
    val u: ?User = User(name: "ana");
    @print(u?.name);
}
```

----- JAVASCRIPT -- main.js
```javascript
class User {
    constructor(name) {
        this.name = name;
    }
}

function main() {
    const u = new User("ana");
    console.log(u?.name);
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
ana
```
