----- SOURCE CODE -- main.bp
```botopink
type Unimplemented(id: i32) {
    fn process(self: Self) -> string {
        return @todo();
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
class Unimplemented {
    constructor(id) {
        this.id = id;
    }

    process() {
        return (() => { throw new Error("not implemented") })();
    }
}
Unimplemented.prototype.__bp = "Unimplemented";

Object.defineProperty(exports, "__bp_priv__", { value: { Unimplemented } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
