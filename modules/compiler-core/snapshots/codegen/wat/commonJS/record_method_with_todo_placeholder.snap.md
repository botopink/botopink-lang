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
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
