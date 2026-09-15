----- SOURCE CODE -- main.bp
```botopink
record Pipeline {
    items: i32[],
    fn doubled(self: Self) -> i32[] {
        return List.map(self.items) { x ->
            return x * 2;
        };
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
class Pipeline {
    constructor(items) {
        this.items = items;
    }

    doubled() {
        return List.map(this.items, (x) => {
    return (x * 2);
});
    }
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
