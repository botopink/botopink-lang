----- SOURCE CODE -- main.bp
```botopink
record Person { name: string }
fn firstName(p: Person) -> ?string { @todo(); }
fn shout(s: string) -> ?string { @todo(); }
fn greet(p: Person) -> string {
    return firstName(p)
        .map({ n -> "Hello " + n })
        .flatMap({ n -> shout(n) })
        .unwrapOr("Hello stranger");
}
```

----- JAVASCRIPT -- main.js
```javascript
class Person {
    constructor(name) {
        this.name = name;
    }
}

function firstName(p) {
    (() => { throw new Error("not implemented") })();
}

function shout(s) {
    (() => { throw new Error("not implemented") })();
}

function greet(p) {
    return ((_o) => _o != null ? _o : ("Hello stranger"))(((_o) => _o != null ? ((n) => {
    return shout(n);
})(_o) : null)(((_o) => _o != null ? ((n) => {
    return ("Hello " + n);
})(_o) : null)(firstName(p))));
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```
