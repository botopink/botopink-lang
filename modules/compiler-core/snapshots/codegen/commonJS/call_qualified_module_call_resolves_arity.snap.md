----- SOURCE CODE -- main.bp
```botopink
type List(tag: i32) {
    fn map(items: i32[], f: fn(item: i32) -> i32) -> i32[] {
        return items.map(f);
    }
}
type Pipeline(
    items: i32[]) {
    fn run(self: Self, f: fn(item: i32) -> i32) -> i32[] {
        return List.map(self.items, f);
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
class List {
    constructor(tag) {
        this.tag = tag;
    }

    static map(items, f) {
        return items.map(f);
    }
}

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
