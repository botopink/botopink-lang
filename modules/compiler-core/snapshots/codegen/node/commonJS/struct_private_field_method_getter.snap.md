----- SOURCE CODE -- main.bp
```botopink
val Counter = struct {
    _count: i32 = 0,
    fn increment(self: Self) {
        self._count += 1;
    }
    get count(self: Self) -> i32 {
        return self._count;
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
class Counter {
    constructor(_count = 0) {
        this._count = _count;
    }

    increment() {
        this._count += 1;
    }

    get count() {
        return this._count;
    }
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
