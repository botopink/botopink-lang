----- SOURCE CODE -- main.bp
```botopink
record Pipeline {
    items: i32[],
    fn run(self: Self, f: fn(item: i32) -> i32) -> i32[] {
        return List.map(self.items, f);
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
class Pipeline {
    constructor(items) {
        this.items = items;
    }

    run(f) {
        return List.map(this.items, f);
    }
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
