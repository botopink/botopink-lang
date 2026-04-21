----- SOURCE CODE -- main.bp
```botopink
val Color = enum {
    Red,
    Rgb(r: i32, g: i32, b: i32),
}
```

----- JAVASCRIPT -- main.js
```javascript
const Color = Object.freeze({
    Red: "Red",
    Rgb: (r, g, b) => ({ tag: "Rgb", r, g, b }),
});
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
