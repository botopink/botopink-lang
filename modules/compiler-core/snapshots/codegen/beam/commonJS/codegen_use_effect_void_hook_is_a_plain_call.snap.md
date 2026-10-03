----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Context<Element>
fn cleanup() {
    0;
}
fn effect() -> @Component<Element, i32> {
    return 0;
}
fn Widget() -> @Component<Element, Element> {
    use effect { -> cleanup(); };
    return Element();
}
```

----- JAVASCRIPT -- main.js
```javascript
class Element {
}
Element.prototype.__bp = "Element";

function cleanup() {
    0;
}

async function effect() {
    return 0;
}

async function Widget() {
    await effect(() => {
    return cleanup();
});
    return new Element();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```
