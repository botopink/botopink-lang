----- SOURCE CODE -- main.bp
```botopink
type Person(name: string)
fn find(p: Person) -> ?Person { @todo(); }
fn greet(p: Person) -> string {
    return find(p)?.name ?? "Hello stranger";
}
```

----- JAVASCRIPT -- main.js
```javascript
class Person {
    constructor(name) {
        this.name = name;
    }
}
Person.prototype.__bp = "Person";

function find(p) {
    (() => { throw Object.defineProperty(new Error("not implemented"), '__bp_panic', { value: true }) })();
}

function greet(p) {
    return (() => { const __bp_nullish = find(p)?.name; if (__bp_nullish != null) { return __bp_nullish; } else { return "Hello stranger"; } })();
}

Object.defineProperty(exports, "__bp_priv__", { value: { Person, find, greet } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
