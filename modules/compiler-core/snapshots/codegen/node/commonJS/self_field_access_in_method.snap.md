----- SOURCE CODE -- main.bp
```botopink
val Point = struct {
    x: i32,
    y: i32,
    fn sum() -> i32 {
        return self.x + self.y;
    }
};
```

----- JAVASCRIPT -- main.js
```javascript
class Point {
    x;
    y;

    sum() {
        return (this.x + this.y);
    }
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
