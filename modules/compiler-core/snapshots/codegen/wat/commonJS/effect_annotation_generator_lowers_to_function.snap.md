----- SOURCE CODE -- main.bp
```botopink
#[@generator]
fn range(a: i32, b: i32) -> @Generator<i32> {
    yield a;
    yield b;
}
```

----- JAVASCRIPT -- main.js
```javascript
function* range(a, b) {
    yield a;
    yield b;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
