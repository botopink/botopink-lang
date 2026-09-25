----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element> { }
fn cleanup() {
    0;
}
#[@use]
fn effect() -> @Component<Element, i32> {
    0;
}
#[@use]
fn Widget() -> @Component<Element, Element> {
    use effect { -> cleanup(); };
    Element();
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
    0;
}

async function Widget() {
    await effect(() => {
    return cleanup();
});
    new Element();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```
