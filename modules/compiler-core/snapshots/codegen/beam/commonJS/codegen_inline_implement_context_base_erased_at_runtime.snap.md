----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Context<Element>
fn render() -> Element {
    return Element();
}
```

----- JAVASCRIPT -- main.js
```javascript
class Element {
}
Element.prototype.__bp = "Element";

function render() {
    return new Element();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
