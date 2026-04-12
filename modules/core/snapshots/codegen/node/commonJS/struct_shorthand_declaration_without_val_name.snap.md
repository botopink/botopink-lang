----- SOURCE CODE -- main.bp
```botopink
struct Counter {
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
    _count = 0;

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
