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
        return @@todo();
    }
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
