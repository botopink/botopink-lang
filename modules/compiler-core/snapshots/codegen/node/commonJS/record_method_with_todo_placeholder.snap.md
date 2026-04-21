----- SOURCE CODE -- main.bp
```botopink
record Unimplemented { id: i32,
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
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
