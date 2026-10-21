----- SOURCE CODE -- main.bp
```botopink
val Element = type()
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

Object.defineProperty(exports, "__bp_priv__", { value: { Element, render } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
