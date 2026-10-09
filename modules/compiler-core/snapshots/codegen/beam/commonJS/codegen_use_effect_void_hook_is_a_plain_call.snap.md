----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Renderable
fn cleanup() {
    0;
}
fn effect() -> @Component<i32> {
    return 0;
}
fn Widget() -> @Component<Element> {
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

async function effect(bpContextMap__) {
    return 0;
}

async function Widget(bpContextMap__) {
    await effect(bpContextMap__, () => {
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
