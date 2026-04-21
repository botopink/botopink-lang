----- SOURCE CODE -- main.bp
```botopink
val Counter = struct {
    count: i32 = 0,
    fn inc() {
        self.count += 1;
    }
};
```

----- JAVASCRIPT -- main.js
```javascript
class Counter {
    count = 0;

    inc() {
        this.count += 1;
    }
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
