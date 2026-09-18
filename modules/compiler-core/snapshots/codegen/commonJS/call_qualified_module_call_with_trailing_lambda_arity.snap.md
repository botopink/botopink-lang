----- SOURCE CODE -- main.bp
```botopink
type List(tag: i32) {
    fn each(items: i32[], f: fn() -> i32) -> i32[] {
        return items;
    }
}
type Pipeline(
    items: i32[]) {
    fn doubled(self: Self) -> i32[] {
        return List.each(self.items) { ->
            return 2;
        };
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
class List {
    constructor(tag) {
        this.tag = tag;
    }

    static each(items, f) {
        return items;
    }
}

class Pipeline {
    constructor(items) {
        this.items = items;
    }

    doubled() {
        return List.each(this.items, () => {
    return 2;
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
