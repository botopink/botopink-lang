----- SOURCE CODE -- main.bp
```botopink
fn fail() {
    @panic("something went wrong");
}
```

----- JAVASCRIPT -- main.js
```javascript
function fail() {
    (() => { throw new Error("something went wrong") })();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
