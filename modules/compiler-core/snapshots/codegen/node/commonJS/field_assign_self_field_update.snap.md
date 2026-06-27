----- SOURCE CODE -- main.bp
```botopink
val Counter = record {
    count: i32 = 0,
    fn inc() {
        self.count += 1;
    }
};
```

----- JAVASCRIPT -- main.js
```javascript
class Counter {
    constructor(count) {
        this.count = count;
    }

    static inc() {
        this.count += 1;
    }
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
