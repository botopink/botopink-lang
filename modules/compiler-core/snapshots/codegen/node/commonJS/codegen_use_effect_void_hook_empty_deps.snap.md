----- SOURCE CODE -- main.bp
```botopink
val Element = struct implement @Context<Element, Element> { }
fn cleanup() {
    0;
}
fn effect() -> @Context<Element, i32> {
    0;
}
fn Widget() -> Element {
    use effect { -> cleanup(); };
    Element();
}
```

----- JAVASCRIPT -- main.js
```javascript
function cleanup() {
    0;
}

function effect() {
    0;
}

function Widget() {
    useEffect(() => {
    cleanup();
}, []);
    Element();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```
